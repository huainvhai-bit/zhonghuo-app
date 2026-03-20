//
//  NotificationManager.swift
//  终活
//
//  签到提醒管理 - 倒计时低于 12 小时时每 3 小时推送一次
//

import Foundation
import UserNotifications

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
        print("🔔 检查是否需要安排签到提醒：hoursRemaining=\(hoursRemaining)小时")
        
        // 🤫 检查静默模式
        let silentMode = UserDefaults.standard.bool(forKey: "silentModeEnabled")
        if silentMode {
            print("🤫 静默模式已开启，跳过签到提醒")
            return
        }
        
        // 取消所有现有提醒
        cancelAllCheckInReminders()
        
        // 📱 优先使用后端配置，其次使用参数，最后使用默认值
        let threshold = reminderThresholdHours ?? DataManager.shared.systemConfig.checkinReminderThresholdHours ?? 12.0
        let interval = reminderIntervalHours ?? DataManager.shared.systemConfig.checkinReminderIntervalHours ?? 2.0
        
        print("   - 提醒阈值：\(threshold) 小时（后端配置）")
        print("   - 推送间隔：\(interval) 小时（后端配置）")
        
        // 只有低于阈值才需要提醒
        guard hoursRemaining < threshold else {
            print("⏰ 倒计时还有 \(hoursRemaining) 小时，不需要提醒")
            return
        }
        
        // 如果倒计时非常短（<1 小时），立即提醒
        if hoursRemaining < 1 {
            let minutesRemaining = Int(hoursRemaining * 60)
            print("⚠️ 倒计时紧急：只剩 \(minutesRemaining) 分钟，立即提醒")
            scheduleImmediateReminder(minutes: minutesRemaining)
            return
        }
        
        // 📱 使用配置的推送频率
        let intervalHours = interval
        let reminderCount = max(1, Int(hoursRemaining / intervalHours) + 1)
        print("📅 需要安排 \(reminderCount) 次提醒（每 \(intervalHours) 小时一次）")
        
        for i in 0..<reminderCount {
            let hoursFromNow = Double(i) * intervalHours
            let triggerTime = Date().addingTimeInterval(hoursFromNow * 3600)
            let hoursLeft = Int(hoursRemaining - hoursFromNow)
            
            print("   - 提醒 \(i+1): \(hoursFromNow) 小时后 (\(triggerTime))")
            
            // 智能消息：如果已过期，显示紧急提示
            let message = hoursLeft > 0 
                ? "距离下次签到还有 \(hoursLeft) 小时，记得打开 App 签到哦~"
                : "⚠️ 您已超过签到时间，请立即签到！"
            
            scheduleReminder(
                identifier: "checkin_reminder_\(i)",
                title: hoursLeft > 0 ? "⏰ 签到提醒" : "⚠️ 签到已过期",
                body: message,
                triggerDate: triggerTime
            )
        }
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
        let identifiers = (0..<10).map { "checkin_reminder_\($0)" } + ["checkin_immediate"]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ 已取消所有签到提醒")
    }
    
    func cancelReminder(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
