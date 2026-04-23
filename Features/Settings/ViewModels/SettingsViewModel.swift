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
    @Published var restoreMessage = ""
    @Published var latestVersion = ""
    @Published var updateUrl = ""

    private let dataManager = DataManager.shared
    private let userManager = UserManager.shared
    private let deviceMonitor = DeviceMonitor.shared

    func onAppear() {
        setupNavigationBar()
        startDeviceMonitoring()
        checkLocationPermission()
        scheduleDeviceInfoUpload()
    }

    func onDisappear() {
        stopDeviceMonitoring()
    }

    func checkUpdate() async {
        await dataManager.loadSystemConfig()
        latestVersion = dataManager.systemConfig.latestVersion
        updateUrl = dataManager.systemConfig.updateUrl.isEmpty
            ? "https://apps.apple.com/app/终活/id123456789"
            : dataManager.systemConfig.updateUrl
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

    private func scheduleDeviceInfoUpload() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await deviceMonitor.uploadDeviceInfo()
        }
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
