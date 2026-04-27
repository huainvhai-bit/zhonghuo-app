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
    @Published var showingLocationAlert = false
    @Published var showingRestoreAlert = false
    @Published var showingRestoreConfirmAlert = false
    @Published var showingUpdateAlert = false
    @Published var showingError = false
    @Published var restoreMessage = ""
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
        checkLocationPermission()
        refreshCheckInInterval()
        scheduleDeviceInfoUpload()
    }

    func onDisappear() {
        stopDeviceMonitoring()
    }

    func checkUpdate() async {
        await dataManager.loadSystemConfig()
        latestVersion = dataManager.systemConfig.latestVersion
        updateUrl = dataManager.systemConfig.updateUrl
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

    func restoreFromCloud() async {
        if let result = await dataManager.batchSyncCapsules() {
            restoreMessage = "成功从云端恢复 \(result.total) 个胶囊"
        } else {
            restoreMessage = "云端恢复失败，请检查网络连接"
        }
        showingRestoreAlert = true
    }

    func startDeviceMonitoring() {
        deviceMonitor.startMonitoring()
    }

    func stopDeviceMonitoring() {
        deviceMonitor.stopMonitoring()
    }

    func checkLocationPermission() {
        let status = userManager.locationAuthStatus
        guard status == .notDetermined || status == .denied else {
            return
        }

        if status == .denied {
            showingLocationAlert = true
            return
        }

        userManager.requestLocationPermission()
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
        // 永远停留在旧值，导致家人 tab 与后台用户列表都看不到本次更改
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
