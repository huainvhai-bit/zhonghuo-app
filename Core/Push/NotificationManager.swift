//
//  NotificationManager.swift
//  安伴助手
//
//  签到提醒管理 - 倒计时低于 12 小时时每 3 小时推送一次
//

import Foundation
import UserNotifications

// ✅ 修复 #1: 添加 @MainActor 标注以访问 @MainActor 的 DataManager
@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    
    init() {
        requestPermission()
    }
    
    // MARK: - 权限请求
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 通知权限已获取")
            } else if let error = error {
                print("❌ 通知权限失败：\(error)")
            }
        }
    }
    
    // MARK: - 签到提醒
    /// 当倒计时低于阈值时，按配置的间隔推送签到提醒（后端可配置）
    /// 如果倒计时很短（<1 小时），则立即提醒
    func scheduleCheckInReminders(hoursRemaining: Double, reminderThresholdHours: Double? = nil, reminderIntervalHours: Double? = nil) {
        print("🔔 旧版兜底签到提醒接口已废弃，改由 LifeCheckStatusManager 统一调度")
    }
    
    // MARK: - 立即提醒
    /// 用于测试或紧急情况
    func scheduleImmediateReminder(minutes: Int = 1) {
        print("🔔 安排立即提醒（\(minutes) 分钟后）")
        
        // 立即推送（10 秒后）
        let triggerDate = Date().addingTimeInterval(10)
        scheduleReminder(
            identifier: "checkin_immediate",
            title: "⏰ 签到提醒",
            body: "距离下次签到还有 \(minutes) 分钟，记得打开 App 签到哦~",
            triggerDate: triggerDate
        )
    }
    
    // MARK: - 测试立即推送
    /// 测试用：5 秒后推送
    func testImmediatePush() {
        print("🧪 测试推送（5 秒后）")
        let triggerDate = Date().addingTimeInterval(5)
        scheduleReminder(
            identifier: "test_push",
            title: "🧪 测试通知",
            body: "如果你收到这条消息，说明通知系统正常工作！",
            triggerDate: triggerDate
        )
    }
    
    // MARK: - 私有方法
    private func scheduleReminder(identifier: String, title: String, body: String, triggerDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "checkin"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ 添加提醒失败：\(error)")
            } else {
                print("✅ 提醒已安排：\(identifier)")
            }
        }
    }
    
    // MARK: - 取消提醒
    func cancelAllCheckInReminders() {
        let identifiers = [
            "checkin_first_reminder",
            "checkin_immediate"
        ] + (0..<10).map { "checkin_reminder_\($0)" } + (0..<10).map { "checkin_repeat_reminder_\($0)" } + (0..<5).map { "checkin_overdue_\($0 + 1)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ 已取消所有签到提醒")
    }
    
    func cancelReminder(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
