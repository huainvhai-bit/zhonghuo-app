//
//  BackendSecurityPolicy.swift
//  终活
//
//  与后端风控前缀（ACCOUNT_BANNED / IP_BANNED_*）对接：统一展示「因用户违规……」类人读文案，
//  并可广播 SecurityPolicyViolation 通知以触发登出 + 全局提示。
//

import Foundation

enum BackendSecurityPolicy {
    static let violationNotificationName = Notification.Name("SecurityPolicyViolation")

    private static let accountBannedPrefix = "ACCOUNT_BANNED:"
    private static let ipBannedLoginPrefix = "IP_BANNED_LOGIN:"
    private static let ipBannedRegisterPrefix = "IP_BANNED_REGISTER:"

    static func isRestrictedServerMessage(_ raw: String) -> Bool {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.contains(accountBannedPrefix)
            || t.contains(ipBannedLoginPrefix)
            || t.contains(ipBannedRegisterPrefix)
    }

    /// `raw` 通常为 GraphQL errors[0].message 整段字符串（含前缀）
    static func userFacingMessage(for rawMessage: String) -> String {
        let trimmed = rawMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix(accountBannedPrefix) {
            let suffix = trimmed.dropFirst(accountBannedPrefix.count).trimmingCharacters(in: .whitespacesAndNewlines)
            return fallbackIfEmpty(suffix,
                zh: "因用户违规，已被禁止登录",
                en: "Access denied due to policy violation.",
                ja: "ポリシー違反のため、このアカウントはログインできません。",
                ko: "정책 위반으로 이 계정의 로그인이 제한되었습니다.")
        }
        if trimmed.hasPrefix(ipBannedLoginPrefix) {
            let suffix = trimmed.dropFirst(ipBannedLoginPrefix.count).trimmingCharacters(in: .whitespacesAndNewlines)
            return fallbackIfEmpty(suffix,
                zh: "因用户违规，已被禁止登录",
                en: "Access denied due to policy violation.",
                ja: "ポリシー違反のため、ログインが禁止されています。",
                ko: "정책 위반으로 로그인이 제한되었습니다.")
        }
        if trimmed.hasPrefix(ipBannedRegisterPrefix) {
            let suffix = trimmed.dropFirst(ipBannedRegisterPrefix.count).trimmingCharacters(in: .whitespacesAndNewlines)
            return fallbackIfEmpty(suffix,
                zh: "因用户违规，已被禁止注册",
                en: "Registration is not allowed due to policy violation.",
                ja: "ポリシー違反のため、登録が禁止されています。",
                ko: "정책 위반으로 가입할 수 없습니다.")
        }
        return trimmed.isEmpty ? L10n.text("请求失败", en: "Request failed.", ja: "失敗しました。", ko: "요청에 실패했습니다.") : trimmed
    }

    private static func fallbackIfEmpty(
        _ suffix: String,
        zh: String,
        en: String,
        ja: String,
        ko: String
    ) -> String {
        if suffix.isEmpty {
            return L10n.text(zh, en: en, ja: ja, ko: ko)
        }
        return suffix
    }

    /// 若服务端返回封号 / 封 IP 前缀，在主线程派发通知（ContentViewModel 捕获后弹框并 logout）
    static func postViolationIfNeeded(_ rawGraphQLMessage: String) {
        let m = rawGraphQLMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isRestrictedServerMessage(m) else { return }
        let readable = userFacingMessage(for: m)
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: violationNotificationName,
                object: nil,
                userInfo: ["message": readable]
            )
        }
    }
}
