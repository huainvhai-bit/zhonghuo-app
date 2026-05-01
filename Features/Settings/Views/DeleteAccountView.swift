//
//  DeleteAccountView.swift
//  终活
//
//  注销账号
//  职责：复用"找回密码"风格的密保问答二次校验，校验通过后调用后端 deleteAccount
//        mutation 永久删除账号及其全部数据，再清掉本地缓存并强制退出登录。
//

import SwiftUI
import UserNotifications

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = AppLanguageManager.shared
    @ObservedObject private var userManager = UserManager.shared

    /// 与 ResetPasswordView 保持一致的密保题库，确保用户看到的选项一一对应
    private static var securityQuestions: [String] {
        [
            L10n.text("我的第一所学校名称是？", en: "What was the name of my first school?", ja: "最初の学校の名前は？", ko: "내 첫 번째 학교 이름은?"),
            L10n.text("我最喜欢的城市是？", en: "What is my favorite city?", ja: "一番好きな都市は？", ko: "내가 가장 좋아하는 도시는?"),
            L10n.text("我母亲的姓氏是？", en: "What is my mother's maiden name?", ja: "母の旧姓は？", ko: "어머니의 성은?"),
            L10n.text("我最喜欢的电影是？", en: "What is my favorite movie?", ja: "一番好きな映画は？", ko: "내가 가장 좋아하는 영화는?"),
            L10n.text("我童年最好的朋友名字是？", en: "What is the name of my childhood best friend?", ja: "子どもの頃の親友の名前は？", ko: "어릴 때 가장 친했던 친구의 이름은?")
        ]
    }
    private var securityQuestions: [String] { Self.securityQuestions }

    @State private var selectedSecurityQuestion: String = Self.securityQuestions.first ?? ""
    @State private var securityAnswer: String = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingFinalConfirm = false
    @State private var showingSuccess = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    accountSection
                    securitySection
                    submitButton
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .frame(maxWidth: .infinity)
            }
            .background(Color("BackgroundColor"))
            .navigationTitle(L10n.text("注销账号", en: "Delete Account", ja: "アカウント削除", ko: "계정 삭제"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.string(.cancel)) { dismiss() }
                }
            }
            .alert(L10n.string(.error), isPresented: $showingError) {
                Button(L10n.string(.confirm), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            // 最终二次确认弹窗 —— 通过密保校验之前先吓阻一次，避免误触
            .alert(
                L10n.text("确定要永久注销账号吗？", en: "Permanently delete this account?", ja: "本当にアカウントを完全に削除しますか？", ko: "정말로 이 계정을 영구 삭제하시겠습니까?"),
                isPresented: $showingFinalConfirm
            ) {
                Button(L10n.string(.cancel), role: .cancel) {}
                Button(
                    L10n.text("确认注销", en: "Delete", ja: "削除する", ko: "삭제"),
                    role: .destructive
                ) {
                    Task { await performDelete() }
                }
            } message: {
                Text(L10n.text(
                    "账号一旦注销，您的留言、重要事项、资产、家人关系、签到记录等将被永久删除且无法恢复。",
                    en: "Once deleted, your messages, important notes, assets, family relations and check-in records will be permanently removed and cannot be restored.",
                    ja: "削除すると、メッセージ、重要事項、資産、家族関係、チェックイン記録などが完全に削除され、復元できません。",
                    ko: "삭제하면 메시지, 중요 사항, 자산, 가족 관계, 체크인 기록 등이 영구히 삭제되며 복구할 수 없습니다."
                ))
            }
            .alert(
                L10n.text("账号已注销", en: "Account deleted", ja: "アカウントを削除しました", ko: "계정이 삭제되었습니다"),
                isPresented: $showingSuccess
            ) {
                Button(L10n.string(.confirm), role: .cancel) {
                    finishAndLogout()
                }
            } message: {
                Text(L10n.text(
                    "您的账号及全部数据已永久删除。",
                    en: "Your account and all data have been permanently deleted.",
                    ja: "アカウントとすべてのデータは完全に削除されました。",
                    ko: "계정과 모든 데이터가 영구적으로 삭제되었습니다."
                ))
            }
        }
        .stackNavigationStyle()
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text(L10n.text("注销账号", en: "Delete Account", ja: "アカウント削除", ko: "계정 삭제"))
                .font(.system(size: 24, weight: .bold))

            Text(L10n.text(
                "注销前请仔细阅读：账号一旦删除，所有云端与本地数据都将被永久清除，且无法恢复。",
                en: "Please read carefully: once deleted, all cloud and local data will be permanently removed and cannot be restored.",
                ja: "ご注意：削除するとクラウドとローカルのデータがすべて完全に削除され、復元できません。",
                ko: "주의: 삭제하면 클라우드와 로컬의 모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다."
            ))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("当前账号", en: "Current account", ja: "現在のアカウント", ko: "현재 계정"))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Text(currentAccountText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
        }
    }

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text(
                "请回答您注册时设置的密保问题以验证身份",
                en: "Please answer your security question to verify your identity.",
                ja: "本人確認のため、登録時に設定した秘密の質問にお答えください。",
                ko: "본인 확인을 위해 등록 시 설정한 보안 질문에 답해주세요."
            ))
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            Picker(L10n.string(.securityQuestionPicker), selection: $selectedSecurityQuestion) {
                ForEach(securityQuestions, id: \.self) { question in
                    Text(question).tag(question)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            TextField(L10n.string(.securityAnswer), text: $securityAnswer)
                .textFieldStyle(CustomTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .font(.system(size: 16, weight: .medium))
        }
    }

    private var submitButton: some View {
        Button(action: validateThenConfirm) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                Text(isLoading
                     ? L10n.text("正在注销…", en: "Deleting…", ja: "削除中…", ko: "삭제 중…")
                     : L10n.text("注销账号", en: "Delete Account", ja: "アカウントを削除", ko: "계정 삭제"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.red)
            .cornerRadius(12)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1)
    }

    // MARK: - Actions

    private var currentAccountText: String {
        if let user = userManager.currentUser {
            let account = user.loginAccount?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let phone = user.phone.trimmingCharacters(in: .whitespacesAndNewlines)
            if !account.isEmpty, !phone.isEmpty, account != phone {
                return "\(account) · \(phone)"
            }
            if !account.isEmpty { return account }
            if !phone.isEmpty { return phone }
            return user.name
        }
        return L10n.text("未登录", en: "Not signed in", ja: "未ログイン", ko: "로그인되지 않음")
    }

    private func validateThenConfirm() {
        let trimmedAnswer = securityAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAnswer.isEmpty else {
            errorMessage = L10n.text("请输入密保答案", en: "Please enter the security answer.", ja: "秘密の答えを入力してください。", ko: "보안 답변을 입력하세요.")
            showingError = true
            return
        }
        showingFinalConfirm = true
    }

    private func performDelete() async {
        await MainActor.run { isLoading = true }
        let trimmedAnswer = securityAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            _ = try await DataManager.shared.deleteAccount(
                securityQuestion: selectedSecurityQuestion,
                securityAnswer: trimmedAnswer
            )
            await MainActor.run {
                isLoading = false
                showingSuccess = true
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = mapError(error)
                showingError = true
            }
        }
    }

    /// 注销成功后清掉所有本地缓存并退出登录
    /// - 再调 UserManager.logout()：解除沙箱、清内存、删 user_*.json、清 Token、广播 UserDidLogout
    /// - 最后取消所有本地通知（签到提醒、家人超时提醒等）
    @MainActor
    private func finishAndLogout() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        userManager.logout()
        dismiss()
    }

    private func mapError(_ error: Error) -> String {
        let raw = graphqlBusinessMessage(for: error)

        func matchesCode(_ code: String) -> Bool {
            raw.hasPrefix("\(code):") || raw.contains("\(code):")
        }

        // 后端业务码（CODE:可读文案）；与 graphql.php 「含冒号为业务错误」对齐。
        if matchesCode("SECURITY_QA_WRONG") {
            return L10n.text(
                "密保问题或答案填写错误",
                en: "The security question or answer is incorrect.",
                ja: "秘密の質問または答えが正しくありません。",
                ko: "보안 질문 또는 답변이 올바르지 않습니다."
            )
        }
        if matchesCode("DELETE_ACCOUNT_LOCKED") {
            if let suffix = graphqlPayloadAfterFirstColon(raw), !suffix.isEmpty {
                return suffix
            }
            return L10n.text(
                "因注销验证已连续错误三次，请在 24 小时后再尝试注销账号。",
                en: "You have answered incorrectly too many times. Please try deleting your account again after 24 hours.",
                ja: "本人確認が連続で誤っているため、アカウント削除は24時間後に再度お試しください。",
                ko: "확인이 연속으로 틀려 계정 삭제는 24시간 후 다시 시도해주세요."
            )
        }
        if matchesCode("DELETE_ACCOUNT_ERR") || matchesCode("DELETE_ACCOUNT_FAIL") {
            if let suffix = graphqlPayloadAfterFirstColon(raw), !suffix.isEmpty {
                return suffix
            }
        }
        if matchesCode("UNAUTHORIZED_DELETE") {
            if let suffix = graphqlPayloadAfterFirstColon(raw), !suffix.isEmpty {
                return suffix
            }
            return L10n.text(
                "登录已失效，请重新登录后再试",
                en: "Your session has expired. Please sign in again.",
                ja: "セッションが切れました。再度ログインしてください。",
                ko: "세션이 만료되었습니다. 다시 로그인해주세요."
            )
        }

        if raw.contains("密保问题不匹配") || raw.contains("密保答案错误") {
            return L10n.text(
                "密保问题或答案填写错误",
                en: "The security question or answer is incorrect.",
                ja: "秘密の質問または答えが正しくありません。",
                ko: "보안 질문 또는 답변이 올바르지 않습니다."
            )
        }
        if raw.contains("未授权") || raw.contains("登录") {
            return L10n.text(
                "登录已失效，请重新登录后再试",
                en: "Your session has expired. Please sign in again.",
                ja: "セッションが切れました。再度ログインしてください。",
                ko: "세션이 만료되었습니다. 다시 로그인해주세요."
            )
        }

        let display: String
        if raw.contains(":") {
            let rest = graphqlPayloadAfterFirstColon(raw)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? raw
            display = rest.isEmpty ? raw : rest
        } else {
            display = raw
        }
        let trimmed = display.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "服务器内部错误" || trimmed.isEmpty {
            return L10n.text(
                "注销失败，请稍后重试",
                en: "Failed to delete account. Please try again later.",
                ja: "アカウントの削除に失敗しました。後でもう一度お試しください。",
                ko: "계정 삭제에 실패했습니다. 잠시 후 다시 시도하세요."
            )
        }
        if trimmed.lowercased().contains("network") || trimmed.contains("网络") || trimmed.lowercased().contains("timed out") {
            return L10n.text(
                "网络连接失败，请检查网络后重试",
                en: "Network error. Please check your connection and try again.",
                ja: "ネットワーク接続に失敗しました。接続を確認してください。",
                ko: "네트워크 오류입니다. 연결을 확인하고 다시 시도하세요."
            )
        }
        return trimmed
    }

    /// GraphQL JSON `errors[0].message` 可能带 CODE:中文 前缀；NSError 也常把同源字符串塞进 localizedDescription。
    private func graphqlBusinessMessage(for error: Error) -> String {
        var s = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixesToStrip = ["服务器错误：", "服务器錯誤：", "Server error: ", "GraphQL Error: "]
        for p in prefixesToStrip where s.hasPrefix(p) {
            s = String(s.dropFirst(p.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return s
    }

    /// 取第一条 `前缀:后缀`（业务码冒号后为可读文案）。
    private func graphqlPayloadAfterFirstColon(_ message: String) -> String? {
        guard let r = message.range(of: ":") else { return nil }
        return String(message[r.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
