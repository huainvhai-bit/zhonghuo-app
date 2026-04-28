//
//  ForceUpdateGate.swift
//  强制更新「门控」：当前版本低于后台配置的底线版本时阻断主界面交互，直到用户升级到满足条件的版本后再消失。
//

import Foundation
import SwiftUI

@MainActor
final class ForceUpdateGate: ObservableObject {
    static let shared = ForceUpdateGate()

    /// true 时需全屏挡板，禁止使用 App（不可点「稍后」消除）
    @Published private(set) var blocksInteraction = false

    /// 最近一次用于判断的版本信息（文案用）
    @Published private(set) var minimumSupportedVersionDisplay = ""
    @Published private(set) var latestVersionDisplay = ""
    @Published private(set) var updateUrl = ""

    private init() {}

    func refresh(from config: SystemConfig) {
        let minV = AppVersion.normalize(config.forceUpdateVersion)
        minimumSupportedVersionDisplay = minV
        latestVersionDisplay = AppVersion.normalize(config.latestVersion)
        updateUrl = config.updateUrl.trimmingCharacters(in: .whitespacesAndNewlines)

        let blocked = AppVersion.requiresForcedUpgradeMinimum(minimumSupported: minV)
        blocksInteraction = blocked

        if blocked {
            // 避免出现「挡板 + 可关闭的软性更新弹窗」叠在一起
            UserDefaults.standard.set(false, forKey: "showingUpdateAlert")
        }
    }

    func refreshFromRemote() async {
        guard !DataManager.apiURL.isEmpty else { return }
        await DataManager.shared.loadSystemConfig()
        refresh(from: DataManager.shared.systemConfig)
    }
}
