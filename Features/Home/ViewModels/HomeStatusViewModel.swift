//
//  HomeStatusViewModel.swift
//  安心助手
//
//  首页状态与签到逻辑
//

import Foundation
import SwiftUI

@MainActor
final class HomeStatusViewModel: ObservableObject {
    @Published var isSafe: Bool = true
    private var didLoadInitialData = false
    private var didRetryAutoCheckIn = false

    private let dataManager = DataManager.shared
    private let userManager = UserManager.shared

    func loadInitialData() async {
        guard !didLoadInitialData else { return }
        didLoadInitialData = true
        if userManager.currentUser == nil {
            userManager.loadUser()
        }
        await dataManager.loadSystemConfig()
        await dataManager.loadReceivedCapsules()
        if AppConfig.showsFamilyFeatures {
            _ = try? await dataManager.refreshFamilyMembers()
        }
    }

    func handleAutoCheckIn() {
        let isFamilyMode = !AppConfig.isChinaReviewMode && UserDefaults.standard.bool(forKey: "isFamilyMode")
        if isFamilyMode {
            print("👨‍👩‍👧 关闭签到模式：跳过自动签到")
            return
        }

        if userManager.currentUser == nil {
            userManager.loadUser()
        }

        if userManager.currentUser == nil {
            if !didRetryAutoCheckIn {
                didRetryAutoCheckIn = true
                print("⚠️ 自动签到：用户资料尚未就绪，稍后重试")
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    self.handleAutoCheckIn()
                }
            }
            return
        }

        guard userManager.isLoggedIn else {
            print("⚠️ 自动签到：用户未登录")
            return
        }

        didRetryAutoCheckIn = false

        let now = Date()
        let lastCheckIn = userManager.lastCheckInDate
        let intervalSeconds = userManager.checkInInterval.hours * 3600

        print("🔄 打开 App 自动签到（重置倒计时，证明用户安全）")
        print("   - 当前时间：\(now)")
        print("   - lastCheckIn: \(lastCheckIn ?? Date.distantPast)")
        print("   - interval: \(intervalSeconds)s (\(userManager.checkInInterval.rawValue) 小时)")

        if let lastCheckIn {
            let elapsed = now.timeIntervalSince(lastCheckIn)
            let hoursElapsed = elapsed / 3600
            print("   - 距离上次签到：\(String(format: "%.1f", hoursElapsed)) 小时")
        } else {
            print("⏰ 首次签到：没有签到记录")
        }

        print("✅ 执行自动签到")
        let didSignIn = userManager.performAutoSignIn()

        if didSignIn {
            dataManager.lastCheckInDate = userManager.lastCheckInDate
            print("✅ 自动签到完成！倒计时已重置为 \(userManager.checkInInterval.rawValue) 小时")
            print("📍 本机状态已更新")
        } else {
            print("⏭️ 自动签到未执行：已被同轮激活去重或用户资料未就绪")
        }
    }

    func updateStatus(timerManager: CountdownTimerManager) {
        dataManager.settings.checkInInterval = UserManager.shared.checkInInterval
        dataManager.settings.lastCheckInDate = UserManager.shared.lastCheckInDate
        dataManager.lastCheckInDate = UserManager.shared.lastCheckInDate

        let status = getCheckInStatus()
        isSafe = status.isSafe
        let seconds = status.hoursRemaining * 3600
        timerManager.updateSeconds(seconds)
        print("🔄 updateStatus: secondsRemaining=\(seconds), isSafe=\(isSafe)")

        Task {
            await dataManager.recordLastActive(hoursRemaining: status.hoursRemaining)
        }
    }

    func syncStatusFromServer(timerManager: CountdownTimerManager) async {
        if let result = await dataManager.syncCheckInStatus() {
            await MainActor.run {
                timerManager.updateSeconds(result.hoursRemaining * 3600)
                self.isSafe = result.isSafe
            }
        }
    }

    func syncAppDataOnOpen() async {
        print("🔄 ====== 打开 App 智能同步数据 ======")
        print("🎯 同步策略：比对本地和云端，保持数据一致")

        guard let token = KeychainManager.shared.getToken(), !token.isEmpty else {
            print("⚠️ 同步失败：认证失败")
            return
        }

        print("📥 1. 从云端下载数据...")
        await dataManager.downloadAllData()
        if AppConfig.showsFamilyFeatures {
            _ = try? await dataManager.refreshFamilyMembers()
        }

        print("🎉 初始数据加载完成！")
        print("📊 已完成本地加载与按需同步")
        print("🔄 ====== 同步完成 ======")
    }

    private func getCheckInStatus() -> (isSafe: Bool, hoursRemaining: Double) {
        let isFamilyMode = !AppConfig.isChinaReviewMode && UserDefaults.standard.bool(forKey: "isFamilyMode")
        if isFamilyMode {
            // 👨‍👩‍👧 关闭签到模式：显示无需签到状态
            let hours = userManager.currentUser?.checkInInterval.hours ?? dataManager.settings.checkInInterval.hours
            let offlineThreshold = dataManager.systemConfig.offlineTimeoutHours

            // 找到已添加的成员
            guard let familyMember = dataManager.familyMembers.first(where: { !$0.relatedUserId.isEmpty }),
                  let lastCheckIn = familyMember.relatedUserLastCheckInDate else {
                // 没有添加数据时返回安全状态
                return (true, Double(hours))
            }

            let elapsed = Date().timeIntervalSince(lastCheckIn) / 3600
            let remaining = Double(hours) - elapsed

            if remaining > 0 {
                return (true, max(0, remaining))
            } else if remaining > -offlineThreshold {
                return (true, max(0, remaining))
            } else {
                return (false, 0)
            }
        }

        let hours = userManager.currentUser?.checkInInterval.hours ?? dataManager.settings.checkInInterval.hours
        let offlineThreshold = dataManager.systemConfig.offlineTimeoutHours

        let lastCheckIn = dataManager.lastCheckInDate ?? userManager.lastCheckInDate ?? userManager.currentUser?.lastCheckInDate
        guard let lastCheckIn else {
            return (true, Double(hours))
        }

        let elapsed = Date().timeIntervalSince(lastCheckIn) / 3600
        let remaining = Double(hours) - elapsed

        if remaining > 0 {
            return (true, max(0, remaining))
        } else if remaining > -offlineThreshold {
            return (true, max(0, remaining))
        } else {
            return (false, 0)
        }
    }

}
