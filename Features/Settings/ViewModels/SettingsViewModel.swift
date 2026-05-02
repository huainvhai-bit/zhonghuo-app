//
//  SettingsViewModel.swift
//  终活
//
//  设置页状态与侧效控制
//

import Foundation
import SwiftUI
import UIKit

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var showingUpdateAlert = false
    @Published var showingError = false
    @Published var latestVersion = ""
    @Published var updateUrl = ""
    @Published var selectedCheckInInterval: CheckInInterval = .twoDays
    @Published var errorMessage = ""

    private let dataManager = DataManager.shared
    private let userManager = UserManager.shared
    private let deviceMonitor = DeviceMonitor.shared

    func onAppear() {
        userManager.loadUser()
        dataManager.loadAllData()
        setupNavigationBar()
        startDeviceMonitoring()
        refreshCheckInInterval()
        scheduleDeviceInfoUpload()
    }

    func onDisappear() {
        stopDeviceMonitoring()
    }

    func checkUpdate() async {
        await dataManager.loadSystemConfig()
        let config = dataManager.systemConfig
        ForceUpdateGate.shared.refresh(from: config)

        latestVersion = AppVersion.normalize(config.latestVersion)
        updateUrl = config.updateUrl.trimmingCharacters(in: .whitespacesAndNewlines)

        let current = AppVersion.marketing

        if ForceUpdateGate.shared.blocksInteraction {
            errorMessage = L10n.text(
                "当前版本已低于运营最低要求，请先从应用商店更新应用。",
                en: "Your version is below the minimum required. Please update from the App Store first.",
                ja: "現在のバージョンは運用の最低要件を下回っています。先に App Store からアップデートしてください。",
                ko: "현재 버전이 운영 최소 요구보다 낮습니다. 먼저 App Store에서 업데이트해 주세요."
            )
            showingError = true
            return
        }

        guard !latestVersion.isEmpty else {
            errorMessage = L10n.text(
                "无法获取服务器版本信息，请稍后重试。",
                en: "Could not read the latest version. Please try again later.",
                ja: "サーバーのバージョン情報が取得できません。しばらくしてからお試しください。",
                ko: "서버 버전 정보를 가져오지 못했습니다. 잠시 후 다시 시도하세요."
            )
            showingError = true
            return
        }

        if AppVersion.versionsEqual(current, latestVersion) || AppVersion.isNewer(current, than: latestVersion) {
            errorMessage = L10n.text(
                "当前已是最新版本",
                en: "You're on the latest version.",
                ja: "お使いのバージョンは最新です。",
                ko: "이미 최신 버전입니다."
            )
            showingError = true
            return
        }

        showingUpdateAlert = true
    }

    func openUpdateURL() {
        guard let url = URL(string: updateUrl), !updateUrl.isEmpty else { return }
        UIApplication.shared.open(url)
    }

    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    func startDeviceMonitoring() {
        deviceMonitor.startMonitoring()
    }

    func stopDeviceMonitoring() {
        deviceMonitor.stopMonitoring()
    }

    func updateCheckInInterval(_ interval: CheckInInterval) async {
        selectedCheckInInterval = interval
        userManager.checkInInterval = interval
        dataManager.settings.checkInInterval = interval
        dataManager.saveSettingsToFile()

        if var currentUser = userManager.currentUser {
            currentUser.checkInInterval = interval
            userManager.currentUser = currentUser
            _ = userManager.saveUser(currentUser)
        }

        LifeCheckStatusManager.shared.requestNotificationRefresh(reason: "签到间隔设置变更")

        // 关键修复：把新的签到间隔同步到服务端，否则后端 users.check_in_interval / checkin_expire_at
        // 永远停留在旧值，导致添加 tab 与后台用户列表都看不到本次更改
        let intervalHoursInt = Int(interval.hours)
        do {
            _ = try await APIManager.shared.updateCheckInInterval(hours: intervalHoursInt)
        } catch {
            print("⚠️ 同步签到间隔到服务端失败: \(error)")
        }

        // 间隔改变意味着"安全倒计时重置"。立即把新的剩余小时数上报，
        // 让后台用户列表的"安全倒计时"列即时反映本次更改
        _ = await dataManager.recordLastActive(hoursRemaining: Double(intervalHoursInt))
    }

    private func scheduleDeviceInfoUpload() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await deviceMonitor.uploadDeviceInfo()
        }
    }

    private func refreshCheckInInterval() {
        if let userInterval = userManager.currentUser?.checkInInterval {
            selectedCheckInInterval = userInterval
        } else {
            selectedCheckInInterval = dataManager.settings.checkInInterval
        }
        userManager.checkInInterval = selectedCheckInInterval
    }

    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "6366F1")
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}
