//
//  LifeCheckStatusManager.swift
//  终活
//
//  生命签到状态管理
//

import Foundation
import UserNotifications
import BackgroundTasks

// MARK: - 通知配置

/// 通知配置（可从后端获取）
struct NotificationConfig: Codable {
    /// 签到间隔（小时）- 默认 48 小时
    var checkInInterval: Int = 48
    
    /// 首次提醒时间（小时）- 剩余 12 小时时首次提醒
    var firstReminderHours: Int = 12
    
    /// 重复提醒间隔（小时）- 每 2 小时提醒一次
    var reminderInterval: Int = 2
    
    /// 超时后推送间隔（小时）- 超时后每 1 小时推送一次
    var overduePushInterval: Int = 1
    
    /// 是否启用短信通知（App 在后台运行时）
    var enableSmsNotification: Bool = true
}

// ✅ 修复 #5: 标记为 @MainActor，确保所有 @Published 属性更新在主线程执行
@MainActor
class LifeCheckStatusManager: ObservableObject {
    static let shared = LifeCheckStatusManager()
    
    @Published var isSafe: Bool = true
    @Published var hoursRemaining: Double = 0
    @Published var lastCheckInDate: Date?
    @Published var checkInHistory: [CheckInRecord] = []
    
    // ✅ 修复：从 DataManager 获取用户设置的签到间隔（而不是硬编码 48 小时）
    private var checkInInterval: TimeInterval {
        let hours = DataManager.shared.systemConfig.checkinIntervalHours
        return hours * 3600
    }
    
    private init() {
        loadLastCheckInDate()
        updateStatus()
    }
    
    // MARK: - 签到
    func checkIn() async {
        print("✍️ 开始签到...")
        
        // ✅ 前台签到：无限制，随时可以签到
        // 签到会重置 48 小时倒计时
        
        // 1. 本地签到
        lastCheckInDate = Date()
        saveLastCheckInDate()
        
        // 记录签到历史
        let record = CheckInRecord(date: Date(), status: .manual)
        checkInHistory.insert(record, at: 0)
        
        // 保持最近 100 条记录
        if checkInHistory.count > 100 {
            checkInHistory.removeLast()
        }
        
        // 2. 后端签到（GraphQL）
        do {
            // ✅ 修复：使用 DataManager 统一函数
            let checkInInterval = DataManager.shared.systemConfig.checkinIntervalHours
            let result = try await DataManager.shared.checkIn(
                checkInIntervalHours: Int(checkInInterval),
                location: nil // TODO: 添加当前位置
            )
            print("✅ 后端签到成功，签到间隔：\(checkInInterval) 小时")
        } catch {
            print("❌ 后端签到失败：\(error)")
        }
        
        // 3. 更新状态
        updateStatus()
        
        print("✅ 签到完成")
    }
    
    // MARK: - 状态更新
    func updateStatus() {
        guard let lastCheckIn = lastCheckInDate else {
            isSafe = false
            hoursRemaining = 0
            return
        }
        
        let elapsed = Date().timeIntervalSince(lastCheckIn)
        let remaining = checkInInterval - elapsed
        
        if remaining > 0 {
            isSafe = true
            hoursRemaining = remaining / 3600
        } else {
            isSafe = false
            hoursRemaining = 0
        }
        
        objectWillChange.send()
    }
    
    // MARK: - 获取状态文本
    var statusText: String {
        if isSafe {
            let hours = Int(hoursRemaining)
            let minutes = Int((hoursRemaining - Double(hours)) * 60)
            return "\(hours)小时\(minutes)分"
        } else {
            return "已超时"
        }
    }
    
    var statusDescription: String {
        if isSafe {
            return "一切安好，记得定期签到哦"
        } else {
            return "您已超时未签到，请尽快确认安全"
        }
    }
    
    // MARK: - 持久化
    private func loadLastCheckInDate() {
        if let timestamp = UserDefaults.standard.object(forKey: "lastCheckInDate") as? Date {
            lastCheckInDate = timestamp
        }
        
        if let historyData = UserDefaults.standard.data(forKey: "checkInHistory") {
            if let history = try? JSONDecoder().decode([CheckInRecord].self, from: historyData) {
                checkInHistory = history
            }
        }
    }
    
    private func saveLastCheckInDate() {
        UserDefaults.standard.set(lastCheckInDate, forKey: "lastCheckInDate")
        
        if let historyData = try? JSONEncoder().encode(checkInHistory) {
            UserDefaults.standard.set(historyData, forKey: "checkInHistory")
        }
    }
    
    // MARK: - 通知监护人
    
    /// 在需要时通知监护人
    func notifyGuardianIfNeeded() {
        if !isSafe {
            // 计算超时时长
            let hoursOverdue = -hoursRemaining
            
            // 只在超时超过 24 小时后才通知（避免误报）
            if hoursOverdue >= 24 {
                print("⚠️ 用户已超时\(Int(hoursOverdue))小时未签到，需要通知监护人")
                
                // 异步通知监护人
                Task {
                    await notifyGuardians()
                }
            }
        }
    }
    
    // MARK: - 后台任务处理
    
    /// 处理后台短信通知任务
    func handleBackgroundSmsTask(task: BGAppRefreshTask) {
        print("📱 执行后台短信通知任务...")
        
        // 设置任务过期处理
        task.expirationHandler = {
            print("⏰ 后台任务时间到")
            task.setTaskCompleted(success: false)
        }
        
        // 检查是否需要发送短信
        updateStatus()
        
        if !isSafe && config.enableSmsNotification {
            let hoursOverdue = -hoursRemaining
            
            // 超时即发送短信（不再等待 24 小时）
            if hoursOverdue > 0 {
                print("⚠️ 用户已超时\(Int(hoursOverdue))小时，发送短信通知监护人")
                
                Task {
                    await notifyGuardians()
                }
            }
        }
        
        task.setTaskCompleted(success: true)
        print("✅ 后台短信通知任务完成")
    }
    
    // MARK: - 通知配置
    
    /// 通知配置（从后端获取）
    private var config: NotificationConfig {
        // 优先使用缓存的配置，如果没有则使用默认值
        if let cachedConfig = UserDefaults.standard.object(forKey: "notificationConfig") as? Data,
           let config = try? JSONDecoder().decode(NotificationConfig.self, from: cachedConfig) {
            return config
        }
        return NotificationConfig()
    }
    
    /// 从后端加载通知配置
    func loadNotificationConfig() async {
        print("🔄 从后端加载通知配置...")
        
        if let config = await DataManager.shared.fetchNotificationConfig() {
            // 缓存配置
            if let encoded = try? JSONEncoder().encode(config) {
                UserDefaults.standard.set(encoded, forKey: "notificationConfig")
                print("✅ 通知配置已加载并缓存")
            }
        } else {
            print("⚠️ 使用默认通知配置")
        }
    }
    
    // MARK: - 通知调度
    
    /// 设置签到提醒通知（完整流程）
    func scheduleCheckInNotifications() {
        print("📅 设置签到提醒通知流程...")
        
        // 取消之前的通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard let lastCheckIn = UserManager.shared.currentUser?.lastCheckInDate else {
            print("⚠️ 无上次签到时间，无法设置通知")
            return
        }
        
        let now = Date()
        
        // ✅ 修复：使用用户设置的签到间隔（从 DataManager 获取）
        let checkInIntervalHours = DataManager.shared.systemConfig.checkinIntervalHours
        let checkInIntervalSeconds = checkInIntervalHours * 3600
        let nextCheckInTime = lastCheckIn.addingTimeInterval(TimeInterval(checkInIntervalSeconds))
        
        // 计算首次提醒时间（剩余 12 小时）
        let reminderThresholdHours = DataManager.shared.systemConfig.checkinReminderThresholdHours
        let firstReminderTime = nextCheckInTime.addingTimeInterval(-TimeInterval(reminderThresholdHours * 3600))
        
        // 如果已经过了首次提醒时间，立即设置
        if firstReminderTime <= now {
            print("⏰ 已到首次提醒时间，立即设置提醒")
            scheduleFirstReminder()
        } else {
            // 设置首次提醒
            scheduleNotification(
                identifier: "checkin_first_reminder",
                title: "⏰ 签到提醒",
                body: "您将在 \(config.firstReminderHours) 小时后需要签到",
                fireDate: firstReminderTime,
                repeats: false
            )
        }
        
        // 设置重复提醒（每 2 小时）
        scheduleRepeatReminders(from: firstReminderTime, to: nextCheckInTime, intervalHours: checkInIntervalHours)
        
        // 设置超时通知
        scheduleOverdueNotifications(after: nextCheckInTime)
        
        print("✅ 通知流程设置完成")
        print("   - 首次提醒：\(firstReminderTime)")
        print("   - 下次签到：\(nextCheckInTime)")
        print("   - 签到间隔：\(checkInIntervalHours) 小时")
    }
    
    /// 设置首次提醒
    private func scheduleFirstReminder() {
        scheduleNotification(
            identifier: "checkin_first_reminder",
            title: "⏰ 该签到啦",
            body: "您即将需要签到，请打开 App 确认安全",
            fireDate: Date().addingTimeInterval(60), // 1 分钟后
            repeats: false
        )
    }
    
    /// 设置重复提醒（每 2 小时）
    private func scheduleRepeatReminders(from startTime: Date, to endTime: Date, intervalHours: Double) {
        let reminderIntervalHours = DataManager.shared.systemConfig.checkinReminderIntervalHours
        let intervalSeconds = reminderIntervalHours * 3600
        var currentTime = startTime.addingTimeInterval(TimeInterval(intervalSeconds))
        var reminderCount = 1
        
        while currentTime < endTime {
            let hoursLeft = Int(endTime.timeIntervalSince(currentTime) / 3600)
            scheduleNotification(
                identifier: "checkin_repeat_reminder_\(reminderCount)",
                title: "⏰ 签到提醒",
                body: "您还有 \(hoursLeft) 小时需要签到",
                fireDate: currentTime,
                repeats: false
            )
            
            currentTime.addTimeInterval(TimeInterval(intervalSeconds))
            reminderCount += 1
            
            // 最多设置 10 个重复提醒
            if reminderCount > 10 { break }
        }
    }
    
    /// 设置超时通知（倒计时结束后）
    private func scheduleOverdueNotifications(after deadline: Date) {
        let overduePushIntervalHours = DataManager.shared.systemConfig.checkinReminderIntervalHours
        let intervalSeconds = overduePushIntervalHours * 3600
        var currentTime = deadline.addingTimeInterval(TimeInterval(intervalSeconds))
        var notificationCount = 1
        
        // 设置 5 个超时通知
        while notificationCount <= 5 {
            let hoursOverdue = notificationCount * Int(overduePushIntervalHours)
            
            scheduleNotification(
                identifier: "checkin_overdue_\(notificationCount)",
                title: "⚠️ 已超时",
                body: "您已超过签到时间 \(hoursOverdue) 小时，请打开 App 确认安全",
                fireDate: currentTime,
                repeats: false
            )
            
            currentTime.addTimeInterval(TimeInterval(intervalSeconds))
            notificationCount += 1
        }
        
        // ✅ 启用后台任务（在超时后安排短信通知）
        scheduleBackgroundSmsTask(after: deadline)
    }
    
    /// 后台短信通知任务（用户超时未签到时触发）
    private func scheduleBackgroundSmsTask(after deadline: Date) {
        if #available(iOS 13.0, *) {
            let request = BGAppRefreshTaskRequest(identifier: "com.zhonghuo.app.sms_notify")
            request.earliestBeginDate = deadline.addingTimeInterval(60)
            
            do {
                try BGTaskScheduler.shared.submit(request)
                print("📱 后台短信通知任务已安排")
            } catch {
                print("❌ 安排后台短信任务失败：\(error)")
            }
        }
    }
    
    /// 通用通知调度方法
    private func scheduleNotification(identifier: String, title: String, body: String, fireDate: Date, repeats: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "CHECKIN_REMINDER"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate),
            repeats: repeats
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 设置通知失败 [\(identifier)]：\(error)")
            } else {
                print("✅ 通知已设置 [\(identifier)]：\(fireDate)")
            }
        }
    }
    
    /// 通知所有监护人
    func notifyGuardians() async {
        // 获取当前用户
        guard let user = await DataManager.shared.currentUser else {
            print("❌ 无用户数据，无法通知监护人")
            return
        }
        
        // 获取紧急联系人列表
        let emergencyContacts = user.emergencyContacts
        
        // 计算超时时长
        let hoursOverdue = -hoursRemaining
        
        print("📞 开始通知 \(emergencyContacts.count) 位紧急联系人...")
        
        // 遍历通知所有紧急联系人
        for contact in emergencyContacts {
            do {
                let success = try await DataManager.shared.notifyGuardian(
                    guardianPhone: contact.phone,
                    userName: user.name,
                    hoursOverdue: hoursOverdue
                )
                
                if success {
                    print("✅ 已通知紧急联系人：\(contact.name) (\(contact.phone))")
                } else {
                    print("❌ 通知失败：\(contact.name)")
                }
            } catch {
                print("❌ 通知异常：\(contact.name), 错误：\(error)")
            }
        }
        
        print("📞 监护人通知完成")
    }
}

// MARK: - 签到记录
struct CheckInRecord: Codable {
    let id: String
    let date: Date
    let status: CheckInStatus
    
    enum CheckInStatus: String, Codable {
        case manual = "手动签到"
        case auto = "自动签到"
        case emergency = "紧急签到"
    }
    
    init(id: String = UUID().uuidString, date: Date, status: CheckInStatus) {
        self.id = id
        self.date = date
        self.status = status
    }
}
