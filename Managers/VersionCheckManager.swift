//
//  VersionCheckManager.swift
//  终活
//
//  版本检查更新管理器
//  功能：检查 App 版本，提示更新（支持强制更新和非强制更新）
//

import Foundation
import SwiftUI

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
        if !isVersionNewer(serverVersion, than: currentVersion) {
            print("✅ 已是最新版本")
            return
        }
        
        // 判断是否强制更新
        let forceUpdate = isVersionNewerOrEqual(forceUpdateVersion, than: currentVersion)
        
        self.isForceUpdate = forceUpdate
        self.updateUrl = updateUrl
        self.updateMessage = "发现新版本 \(serverVersion)，是否立即更新？"
        
        if forceUpdate {
            self.updateMessage = "当前版本已过时，请更新到最新版本 \(serverVersion) 后继续使用"
        }
        
        print("📢 发现新版本：\(serverVersion), 强制更新=\(forceUpdate)")
        showingUpdateAlert = true
    }
    
    /// 比较版本号（v1 > v2 返回 true）
    private func isVersionNewer(_ v1: String, than v2: String) -> Bool {
        let v1Components = v1.split(separator: ".").compactMap { Int($0) }
        let v2Components = v2.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(v1Components.count, v2Components.count) {
            let v1Part = i < v1Components.count ? v1Components[i] : 0
            let v2Part = i < v2Components.count ? v2Components[i] : 0
            
            if v1Part > v2Part {
                return true
            } else if v1Part < v2Part {
                return false
            }
        }
        
        return false // 版本相同
    }
    
    /// 比较版本号（v1 >= v2 返回 true）
    private func isVersionNewerOrEqual(_ v1: String, than v2: String) -> Bool {
        if v1 == v2 {
            return true
        }
        return isVersionNewer(v1, than: v2)
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

// MARK: - 更新提示视图
struct UpdateAlertView: View {
    @ObservedObject var versionManager = VersionCheckManager.shared
    @Binding var isPresented: Bool
    
    var body: some View {
        Alert(
            title: Text("版本更新"),
            message: Text(versionManager.updateMessage),
            primaryButton: .default(Text("立即更新")) {
                versionManager.openUpdateUrl()
                
                // 如果是强制更新，不允许取消
                if !versionManager.isForceUpdate {
                    isPresented = false
                }
            },
            secondaryButton: versionManager.isForceUpdate ? .cancel {
                // 强制更新不允许取消，退出 App
                exit(0)
            } : .cancel {
                isPresented = false
            }
        )
    }
}
