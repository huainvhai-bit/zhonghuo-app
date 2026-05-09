//
//  VersionCheckManager.swift
//  安伴助手
//
//  版本检查更新管理器
//  功能：检查 App 版本，提示更新（支持强制更新和非强制更新）
//

import Foundation
import SwiftUI
import UIKit

@MainActor
class VersionCheckManager: ObservableObject {
    static let shared = VersionCheckManager()
    
    @Published var showingUpdateAlert = false
    @Published var isForceUpdate = false
    @Published var updateMessage = ""
    @Published var updateUrl = ""
    
    private let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    
    private init() {}
    
    /// 检查版本更新
    func checkVersion(serverVersion: String, forceUpdateVersion: String, updateUrl: String) {
        print("🔍 版本检查：当前版本=\(currentVersion), 最新版本=\(serverVersion), 强制更新版本=\(forceUpdateVersion)")
        
        // 判断是否需要更新（版本比较）
        if !AppVersion.isNewer(serverVersion, than: currentVersion) {
            print("✅ 已是最新版本")
            return
        }
        
        // 判断是否强制更新（语义：安装在「强制更新底线版本」以下则必须先升级）
        let forceUpdate = AppVersion.requiresForcedUpgradeMinimum(minimumSupported: forceUpdateVersion)
        
        self.isForceUpdate = forceUpdate
        self.updateUrl = updateUrl
        self.updateMessage = "发现新版本 \(serverVersion)，是否立即更新？"
        
        if forceUpdate {
            self.updateMessage = "当前版本已过时，请更新到最新版本 \(serverVersion) 后继续使用"
        }

        print("📢 发现新版本：\(serverVersion), 强制更新=\(forceUpdate)")
        showingUpdateAlert = true
    }

    /// 打开更新地址
    func openUpdateUrl() {
        guard !updateUrl.isEmpty else {
            print("❌ 更新地址为空")
            return
        }
        
        if let url = URL(string: updateUrl) {
            UIApplication.shared.open(url)
            print("🌐 已打开更新地址：\(updateUrl)")
        }
    }
}

