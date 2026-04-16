//
//  PushNotificationManager.swift
//  终活
//
//  APNs 消息推送管理器
//  功能：推送倒计时提醒、胶囊开启提醒、遗嘱提醒
//

import Foundation
import UIKit
import UserNotifications

class PushNotificationManager: ObservableObject {
    static let shared = PushNotificationManager()
    
    private init() {
        // 请求推送权限
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if granted {
                Logger.shared.i("PushNotificationManager: 推送权限已授予")
                
                // 注册远程通知
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                Logger.shared.w("PushNotificationManager: 推送权限被拒绝：\(error?.localizedDescription ?? "未知错误")")
            }
        }
    }
    
    // MARK: - 用户设备 Token
    
    /// 保存设备 Token 到 Keychain
    func saveDeviceToken(_ token: Data) {
        let tokenString = token.reduce("") { $0 + String(format: "%02x", $1) }
        Logger.shared.i("PushNotificationManager: 设备 Token 已保存：\(tokenString)")
        
        // 上传到服务器
        Task {
            await uploadDeviceToken(tokenString)
        }
    }
    
    /// 上传设备 Token 到服务器
    private func uploadDeviceToken(_ tokenString: String) async {
        guard !DataManager.apiURL.isEmpty else {
            Logger.shared.w("API URL 未设置，跳过上传设备 Token")
            return
        }
        
        do {
            let query = """
            mutation {
                updateDeviceToken(token: "\(tokenString)") {
                    success
                    message
                }
            }
            """
            
            let _ = try await APIClient.shared.query(query)
            Logger.shared.i("设备 Token 上传成功")
        } catch {
            Logger.shared.e("设备 Token 上传失败：\(error)")
        }
    }
    
    /// 处理设备 Token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        saveDeviceToken(deviceToken)
    }
    
    /// 处理注册失败
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Logger.shared.e("PushNotificationManager: 注册推送失败：\(error.localizedDescription)")
    }
    
    // MARK: - 通知内容
    
    /// 创建倒计时提醒通知
    func scheduleCountdownNotification(
        title: String,
        body: String,
        triggerDate: Date,
        identifier: String,
        userInfo: [String: Any]? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        // 5 分钟前触发
        let triggerDate = Date().addingTimeInterval(-300)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.shared.e("PushNotificationManager: 添加通知失败：\(error.localizedDescription)")
            } else {
                Logger.shared.i("PushNotificationManager: 倒计时通知已添加")
            }
        }
    }
    
    /// 创建胶囊开启提醒
    func scheduleCapsuleOpenNotification(capsule: TimeCapsule) {
        guard let openAt = capsule.sendDate, openAt > Date() else {
            return
        }
        
        let timeUntilOpen = openAt.timeIntervalSince(Date())
        guard timeUntilOpen > 300 else { return } // 5 分钟内不提醒
        
        let content = UNMutableNotificationContent()
        content.title = "⏳ 时间胶囊即将开启"
        content.body = "「\(capsule.title)」将在 \(formatTimeRemaining(timeUntilOpen)) 后开启"
        content.sound = .default
        content.categoryIdentifier = "capsule_open"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeUntilOpen - 300, repeats: false)
        let request = UNNotificationRequest(identifier: "capsule_\(capsule.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.shared.e("PushNotificationManager: 胶囊通知失败：\(error.localizedDescription)")
            }
        }
    }
    
    /// 创建遗嘱提醒
    func scheduleWillReminderNotification(will: WillModule) {
        let content = UNMutableNotificationContent()
        content.title = "📄 遗嘱提醒"
        content.body = "您有未完成的遗嘱「\(will.type)」，请尽快补充"
        content.sound = .default
        content.categoryIdentifier = "will_reminder"
        
        // 立即触发
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "will_\(will.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.shared.e("PushNotificationManager: 遗嘱通知失败：\(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 通知管理
    
    /// 取消所有通知
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        Logger.shared.i("PushNotificationManager: 所有通知已取消")
    }
    
    /// 取消特定通知
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        Logger.shared.i("PushNotificationManager: 通知已取消：\(identifier)")
    }
    
    // MARK: - 辅助函数
    
    /// 格式化剩余时间
    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let hours = minutes / 60
        let days = hours / 24
        
        if days > 0 {
            return "\(days)天\(hours % 24)小时"
        } else if hours > 0 {
            return "\(hours)小时\(minutes % 60)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    // MARK: - 通知处理
    
    /// 处理前台通知
    func applicationDidBecomeActive(_ application: UIApplication) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            Logger.shared.d("PushNotificationManager: 待处理通知：\(requests.count) 个")
        }
    }
}

// MARK: - 应用生命周期集成

extension PushNotificationManager {
    /// App 启动时初始化
    func initialize() {
        Logger.shared.d("PushNotificationManager: 初始化...")
        
        // 检查授权状态
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                Logger.shared.i("PushNotificationManager: 授权状态正常")
            case .denied:
                Logger.shared.w("PushNotificationManager: 推送被拒绝，请在设置中启用")
            case .notDetermined:
                Logger.shared.d("PushNotificationManager: 等待用户授权")
            @unknown default:
                break
            }
        }
        
        // 注册通知类型
        UNUserNotificationCenter.current().notificationCategories = [
            UNNotificationCategory(
                identifier: "capsule_open",
                actions: [],
                intentIdentifiers: [],
                options: []
            ),
            UNUserNotificationCenter.current().notificationCategories.first(where: { $0.identifier == "will_reminder" }) ?? UNNotificationCategory(
                identifier: "will_reminder",
                actions: [],
                intentIdentifiers: [],
                options: []
            )
        ]
        
        Logger.shared.i("PushNotificationManager: 初始化完成")
    }
}
