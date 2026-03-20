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
    
    private var updateTimer: Timer?
    
    init() {
        // 启用电池监控
        device.isBatteryMonitoringEnabled = true
        
        // 监听电池状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStatusDidChange),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStatusDidChange),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
        
        // 初始化电池信息
        updateBatteryInfo()
    }
    
    deinit {
        stopMonitoring()
        device.isBatteryMonitoringEnabled = false
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 监控控制
    
    /// 开始监控
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        print("🔋 开始设备监控")
        
        // 立即更新一次
        updateStepCount()
        updateBatteryInfo()
        
        // 定时器更新（每 5 秒）
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateStepCount()
            self?.updateBatteryInfo()
        }
        
        // 添加到 RunLoop
        RunLoop.current.add(updateTimer!, forMode: .common)
    }
    
    /// 停止监控
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
    
    // MARK: - 通知处理
    
    @objc private func batteryStatusDidChange(_ notification: Notification) {
        updateBatteryInfo()
        print("🔋 电池状态变化")
    }
    
    // MARK: - 设备信息上传
    
    /// 上传设备信息到服务器
    func uploadDeviceInfo() async {
        print("☁️ 上传设备信息...")
        
        guard !DataManager.apiURL.isEmpty else {
            print("⚠️ 上传失败：API URL 为空")
            return
        }
        
        let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
        if token.isEmpty {
            print("⚠️ 上传失败：无 token")
            return
        }
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/api.php?action=device_upload")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "step_count": stepCount,
            "battery_level": batteryLevel,
            "battery_state": batteryState.rawValue,
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 设备信息上传响应：\(httpResponse.statusCode)")
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 响应：\(jsonString)")
            }
            
        } catch {
            print("❌ 设备信息上传失败：\(error)")
        }
    }
}
