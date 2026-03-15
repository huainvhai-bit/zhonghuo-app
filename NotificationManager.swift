//
//  NotificationManager.swift
//  终活
//
//  本地通知管理
//

import UserNotifications

class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
    }
    
    /// 请求通知权限
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 通知权限已授予")
            } else if let error = error {
                print("❌ 通知权限请求失败：\(error)")
            }
        }
    }
    
    /// 安排签到提醒
    func scheduleCheckInReminder(hoursRemaining: Double) {
        // 如果已经超过 48 小时，立即提醒
        if hoursRemaining <= 0 {
            sendImmediateReminder()
            return
        }
        
        // 计算提醒时间（提前 6 小时）
        let reminderTime = hoursRemaining * 3600 - 6 * 3600 // 6 小时前
        
        if reminderTime <= 0 {
            // 已经不到 6 小时，立即提醒
            sendImmediateReminder()
            return
        }
        
        // 安排延迟通知
        let content = UNMutableNotificationContent()
        content.title = "⏰ 签到提醒"
        content.body = "您已接近签到时间，记得及时签到哦～"
        content.sound = .default
        content.categoryIdentifier = "checkinReminder"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: reminderTime, repeats: false)
        let request = UNNotificationRequest(identifier: "checkinReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 安排签到提醒失败：\(error)")
            } else {
                print("✅ 签到提醒已安排：\(Int(reminderTime / 3600)) 小时后")
            }
        }
    }
    
    /// 立即发送提醒
    private func sendImmediateReminder() {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ 需要签到"
        content.body = "您已超过签到时间，请立即签到以确保家人安心"
        content.sound = .default
        content.categoryIdentifier = "checkinUrgent"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "checkinUrgent", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 发送紧急提醒失败：\(error)")
            } else {
                print("✅ 紧急签到提醒已发送")
            }
        }
    }
    
    /// 取消所有签到提醒
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["checkinReminder", "checkinUrgent"])
        print("✅ 已取消所有签到提醒")
    }
    
    /// 检查通知权限
    func checkAuthorization() -> Bool {
        var granted = false
        let group = DispatchGroup()
        group.enter()
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            granted = settings.authorizationStatus == .authorized
            group.leave()
        }
        
        group.wait()
        return granted
    }
}

// MARK: - 通知分类
extension NotificationManager {
    func registerCategories() {
        // 签到提醒分类
        let checkinAction = UNNotificationAction(
            identifier: "CHECKIN_ACTION",
            title: "立即签到",
            options: .foreground
        )
        
        let checkinCategory = UNNotificationCategory(
            identifier: "checkinReminder",
            actions: [checkinAction],
            intentIdentifiers: [],
            options: []
        )
        
        // 紧急签到分类
        let urgentCategory = UNNotificationCategory(
            identifier: "checkinUrgent",
            actions: [checkinAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([checkinCategory, urgentCategory])
    }
}

// MARK: - 通知代理
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 前台显示通知
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 处理通知点击
        if response.actionIdentifier == "CHECKIN_ACTION" {
            // 用户点击了"立即签到"
            DataManager.shared.checkIn()
            print("✅ 用户通过通知签到")
        }
        completionHandler()
    }
}
