//
//  DeviceMonitor.swift
//  终活
//
//  设备信息监控 - 步数、电量、充电状态
//

import Foundation
import CoreMotion
import UIKit
import SwiftUI

/// 设备信息监控器
// ✅ 修复 #5: 标记为 @MainActor，确保所有 @Published 属性更新在主线程执行
@MainActor
class DeviceMonitor: ObservableObject {
    static let shared = DeviceMonitor()
    
    private let pedometer = CMPedometer()
    private let device = UIDevice.current
    
    /// 今日步数
    @Published var stepCount: Int = 0
    
    /// 电量百分比（0.0-1.0）
    @Published var batteryLevel: Float = 0.0
    
    /// 充电状态
    @Published var batteryState: UIDevice.BatteryState = .unknown
    
    /// 最后更新时间
    @Published var lastUpdateTime: Date = Date()
    
    /// 是否正在监控
    @Published var isMonitoring = false
    
    // 🔋 性能监控属性
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Int = 0
    @Published var batteryTemperature: Double = 36.5  // 默认体温
    @Published var availableStorage: Double = 0.0
    @Published var networkType: String = "WiFi"
    @Published var networkSignalStrength: Int = -50
    
    /// 电量状态文本
    var batteryStateText: String {
        switch batteryState {
        case .unknown:
            return "未知"
        case .unplugged:
            return "未充电"
        case .charging:
            return "充电中"
        case .full:
            return "已充满"
        @unknown default:
            return "未知"
        }
    }
    
    /// 电量状态图标
    var batteryStateIcon: String {
        switch batteryState {
        case .unknown:
            return "❓"
        case .unplugged:
            return "🔋"
        case .charging:
            return "⚡️"
        case .full:
            return "✅"
        @unknown default:
            return "❓"
        }
    }
    
    /// 电量百分比文本
    var batteryLevelText: String {
        return "\(Int(batteryLevel * 100))%"
    }
    
    /// 电量图标
    var batteryIcon: String {
        let level = Int(batteryLevel * 100)
        if level >= 80 {
            return "battery.100"
        } else if level >= 60 {
            return "battery.75"
        } else if level >= 40 {
            return "battery.50"
        } else if level >= 20 {
            return "battery.25"
        } else {
            return "battery.0"
        }
    }
    
    /// 电量颜色
    var batteryColor: Color {
        let level = Int(batteryLevel * 100)
        if level >= 60 {
            return .green
        } else if level >= 20 {
            return .orange
        } else {
            return .red
        }
    }
    
    /// 充电状态颜色
    var batteryStateColor: Color {
        switch batteryState {
        case .charging, .full:
            return .green.opacity(0.2)
        case .unplugged:
            return .gray.opacity(0.2)
        @unknown default:
            return .gray.opacity(0.2)
        }
    }
    
    // 🔴 使用 Set 存储观察者 token，便于正确移除
    private var updateTimer: Timer?
    private var notificationTokens: [NSObjectProtocol] = []
    
    init() {
        // 启用电池监控
        device.isBatteryMonitoringEnabled = true
        
        // 监听电池状态变化 - 🔴 使用 token 存储以便移除
        let token1 = NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.batteryStatusDidChange()
        }
        notificationTokens.append(token1)
        
        let token2 = NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.batteryStatusDidChange()
        }
        notificationTokens.append(token2)
        
        // 初始化电池信息
        updateBatteryInfo()
    }
    
    deinit {
        // ✅ 修复：在 deinit 中直接访问，不需要 @MainActor
        updateTimer?.invalidate()
        updateTimer = nil
        device.isBatteryMonitoringEnabled = false
        // 🔴 正确移除所有观察者
        notificationTokens.forEach { NotificationCenter.default.removeObserver($0) }
        notificationTokens.removeAll()
    }
    
    // MARK: - 监控控制
    
    /// 开始监控
    @MainActor
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        print("🔋 开始设备监控")
        
        // 立即更新一次
        updateStepCount()
        updateBatteryInfo()
        
        // 定时器更新（每 5 秒）- ✅ 修复：确保在主线程执行
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateStepCount()
                self?.updateBatteryInfo()
            }
        }
        
        // 添加到 RunLoop
        RunLoop.current.add(updateTimer!, forMode: .common)
    }
    
    /// 停止监控
    @MainActor
    func stopMonitoring() {
        isMonitoring = false
        updateTimer?.invalidate()
        updateTimer = nil
        print("🔋 停止设备监控")
    }
    
    // MARK: - 信息更新
    
    /// 更新步数
    func updateStepCount() {
        // 模拟器不支持 CMPedometer，暂时返回 0
        #if targetEnvironment(simulator)
        self.stepCount = 0
        self.lastUpdateTime = Date()
        #else
        // 真机上使用 pedometer 实例
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        pedometer.queryPedometerData(from: startOfDay, to: now) { [weak self] pedometerData, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ 获取步数失败：\(error)")
                return
            }
            
            if let data = pedometerData {
                DispatchQueue.main.async {
                    self.stepCount = data.numberOfSteps.intValue
                    self.lastUpdateTime = Date()
                }
            }
        }
        #endif
    }
    
    /// 更新电量信息
    func updateBatteryInfo() {
        DispatchQueue.main.async {
            self.batteryLevel = self.device.batteryLevel
            self.batteryState = self.device.batteryState
            self.lastUpdateTime = Date()
            // print("🔋 电量：\(Int(self.batteryLevel * 100))%, 状态：\(self.batteryState)")
        }
    }
    
    func updateCPUUsage() {
        // iOS 不直接提供 CPU 使用率，这里使用模拟值
        // 实际应用中可以通过 host_processor_info 获取
        DispatchQueue.main.async {
            self.cpuUsage = Double.random(in: 0.1...0.9)
            self.lastUpdateTime = Date()
        }
    }
    
    func updateMemoryUsage() {
        // 获取内存使用情况（模拟值，iOS 不直接提供）
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        DispatchQueue.main.async {
            // 使用随机值模拟（实际应用需要通过 mach_task_basic_info 获取）
            self.memoryUsage = Int(Double(totalMemory) / 1024 / 1024 * 0.5)  // 假设使用 50%
            self.lastUpdateTime = Date()
        }
    }
    
    func updateStorageInfo() {
        // 获取存储信息
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let freeSize = attributes[.systemFreeSize] as? UInt64 {
                DispatchQueue.main.async {
                    self.availableStorage = Double(freeSize) / 1024 / 1024 / 1024  // 转换为 GB
                    self.lastUpdateTime = Date()
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.availableStorage = 0
            }
        }
    }
    
    // MARK: - 通知处理
    
    // 🔴 已改用闭包方式处理通知，此方法保留兼容性
    @objc private func batteryStatusDidChange() {
        Task { @MainActor in
            updateBatteryInfo()
            print("🔋 电池状态变化")
        }
    }
    
    // MARK: - 设备信息上传
    
    /// 上传设备信息到服务器（GraphQL）
    @MainActor
    func uploadDeviceInfo() async {
        print("☁️ 上传设备信息（GraphQL）...")
        
        let apiURL = DataManager.apiURL
        guard !apiURL.isEmpty else {
            print("⚠️ 上传失败：API URL 为空")
            return
        }
        
        let token = KeychainManager.shared.getToken() ?? ""
        if token.isEmpty {
            print("⚠️ 上传失败：无 token")
            return
        }
        
        do {
            let query = """
            mutation($deviceId: String!, $deviceModel: String!, $osVersion: String!, $appVersion: String!) {
                uploadDeviceInfo(deviceId: $deviceId, deviceModel: $deviceModel, osVersion: $osVersion, appVersion: $appVersion) {
                    success
                    message
                }
            }
            """
            
            let variables: [String: Any] = [
                "deviceId": UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                "deviceModel": UIDevice.current.model,
                "osVersion": UIDevice.current.systemVersion,
                "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            ]
            
            let result = try await GraphQLClient.shared.query(query, variables: variables)
            print("📡 设备信息上传响应：\(result)")
            
        } catch {
            print("❌ 设备信息上传失败：\(error)")
        }
    }
    
    // MARK: - 性能数据上传
    
    /// 上传性能数据到服务器
}
