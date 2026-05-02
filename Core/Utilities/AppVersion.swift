//
//  AppVersion.swift
//  Marketing 版本号语义比较（CFBundleShortVersionString），供更新检查、强制更新门控共用。
//

import Foundation

enum AppVersion {
    /// App Store / `Info.plist` 对外版本号
    static var marketing: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "0.0.0"
    }

    /// v1 **严格大于** v2（如 2.0.1 > 2.0.0）；相等则 false。
    static func isNewer(_ v1: String, than v2: String) -> Bool {
        let a = normalize(v1)
        let b = normalize(v2)
        let parts1 = a.split(separator: ".").compactMap { Int($0) }
        let parts2 = b.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(parts1.count, parts2.count) {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0
            if p1 > p2 { return true }
            if p1 < p2 { return false }
        }
        return false
    }

    static func versionsEqual(_ a: String, _ b: String) -> Bool {
        !isNewer(a, than: b) && !isNewer(b, than: a)
    }

    /// 后台配置的「强制更新最低版本」**高于**当前安装版本 → 必须先升级后才能使用。
    ///（即：安装在最低要求以下的版本会被拦在门外。）
    static func requiresForcedUpgradeMinimum(minimumSupported: String, currentVersion: String = marketing) -> Bool {
        let minV = normalize(minimumSupported)
        guard !minV.isEmpty, minV != "0.0.0" else { return false }
        return isNewer(minV, than: currentVersion)
    }

    /// 服务端「最新版本」字符串（去空白）
    static func normalize(_ v: String) -> String {
        v.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// App 内法务与文档固定链接（不与 `getConfig` 混用）
enum OfficialDocumentLinks {
    static let privacy = URL(string: "https://zhonghuo.zhonghuo.xyz/docs/privacy.html")!
    static let terms = URL(string: "https://zhonghuo.zhonghuo.xyz/docs/terms.html")!
    static let support = URL(string: "https://zhonghuo.zhonghuo.xyz/docs/index.html")!
}
