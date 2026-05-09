//
//  LifeCheckStatusManager.swift
//  安伴助手
//
//  生命签到状态管理
//

import Foundation
@preconcurrency import UserNotifications

// MARK: - 通知配置

/// 通知配置（可从后端获取）
struct NotificationConfig: Codable {
    /// 签到间隔（小时）- 默认 48 小时
    var checkInInterval: Int = 48

    /// 首次提醒时间（小时）- 剩余 12 小时时首次提醒
    var firstReminderHours: Int = 12

    /// 重复提醒间隔（小时）- 每 2 小时提醒一次
    var reminderInterval: Int = 2
    
    /// 签到提醒间隔（小时）- 到期后继续提醒用户本人打开 App 更新状态
    var overduePushInterval: Int = 1
    
}

// ✅ 修复 #5: 标记为 @MainActor，确保所有 @Published 属性更新在主线程执行
@MainActor
class LifeCheckStatusManager: ObservableObject {
    static let shared = LifeCheckStatusManager()
    
    @Published var isSafe: Bool = true
    @Published var hoursRemaining: Double = 0
    @Published var lastCheckInDate: Date?
    @Published var checkInHistory: [CheckInRecord] = []
    private let scheduleSignatureKey = "checkinNotificationScheduleSignature"
    private var pendingScheduleRefreshTask: Task<Void, Never>?
    
    // ✅ 修复：签到间隔以用户本地设置为准
    private var checkInInterval: TimeInterval {
        let hours = currentCheckInIntervalHours()
        return hours * 3600
    }

    private func currentCheckInIntervalHours() -> Double {
        if let currentUser = UserManager.shared.currentUser {
            return currentUser.checkInInterval.hours
        }
        return DataManager.shared.settings.checkInInterval.hours
    }
    
    private init() {
        loadLastCheckInDate()
        updateStatus()
    }
    
    func requestNotificationRefresh(reason: String = "") {
        pendingScheduleRefreshTask?.cancel()

        if !reason.isEmpty {
            print("🔄 请求刷新签到提醒：\(reason)")
        }

        pendingScheduleRefreshTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            self.scheduleCheckInNotifications()
            self.pendingScheduleRefreshTask = nil
        }
        }

    // MARK: - 签到
    func checkIn() async {
        print("✍️ 开始签到...")
        
        // ✅ 前台签到：无限制，随时可以签到
        // 签到会重置 48 小时倒计时
        
        // 1. 本地签到
        lastCheckInDate = Date()
        saveLastCheckInDate()
        if var currentUser = UserManager.shared.currentUser {
            currentUser.lastCheckInDate = lastCheckInDate
            UserManager.shared.currentUser = currentUser
            UserManager.shared.lastCheckInDate = lastCheckInDate
            UserManager.shared.checkInInterval = currentUser.checkInInterval
        }
        UserDefaults.standard.removeObject(forKey: "checkinFallbackReminderScheduled")
        
        // 记录签到历史
        let record = CheckInRecord(date: Date(), status: .manual)
        checkInHistory.insert(record, at: 0)
        
        // 保持最近 100 条记录
        if checkInHistory.count > 100 {
            checkInHistory.removeLast()
        }
        
        // 2. 后端签到（GraphQL）
        // ✅ 修复：签到前检查 token 是否存在
        guard let token = KeychainManager.shared.getToken(), !token.isEmpty else {
            print("⚠️ 后端签到跳过：Token 不存在（用户可能未登录）")
            return
        }
        
        do {
            // ✅ 修复：使用用户本地设置的签到间隔
            let checkInIntervalHours = currentCheckInIntervalHours()
            
            _ = try await DataManager.shared.checkIn(checkInIntervalHours: Int(checkInIntervalHours))
            print("✅ 后端签到成功，签到间隔：\(checkInIntervalHours) 小时")
        } catch {
            print("❌ 后端签到失败：\(error)")
        }
        
        // 3. 更新状态
        updateStatus()
        
        print("✅ 签到完成")
    }
    
    // MARK: - 状态更新
    func updateStatus() {
        let effectiveLastCheckIn = lastCheckInDate ?? UserManager.shared.currentUser?.lastCheckInDate ?? UserManager.shared.lastCheckInDate
        guard let lastCheckIn = effectiveLastCheckIn else {
            isSafe = false
            hoursRemaining = 0
            return
        }

        lastCheckInDate = lastCheckIn

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
            return "待更新"
        }
    }
    
    var statusDescription: String {
        if isSafe {
            return "一切安好，记得定期签到哦"
        } else {
            return "签到记录已到提醒时间，请打开 App 更新状态"
        }
    }
    
    // MARK: - 持久化
    private func loadLastCheckInDate() {
        if let timestamp = UserDefaults.standard.object(forKey: "lastCheckInDate") as? Date {
            lastCheckInDate = timestamp
        }

        if lastCheckInDate == nil {
            lastCheckInDate = UserManager.shared.currentUser?.lastCheckInDate ?? UserManager.shared.lastCheckInDate
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
    
    // MARK: - 本机提醒

    /// 仅保留本机提醒，不向联系人发送通知。
    func notifyGuardianIfNeeded() {
        if !isSafe {
            print("ℹ️ 签到记录已到提醒时间，仅通过本机通知提醒用户本人")
        }
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
        pendingScheduleRefreshTask?.cancel()
        pendingScheduleRefreshTask = nil

        if UserDefaults.standard.bool(forKey: "silentModeEnabled") {
            print("🤫 静默模式开启，取消并跳过签到提醒调度")
            cancelAllCheckInNotifications()
            return
        }

        // 关闭签到模式开启时，本人不再需要签到——同时取消本人所有的签到/超时提醒，
        // 避免在共享状态下还收到"您已超时"等推送
        if UserDefaults.standard.bool(forKey: "isFamilyMode") {
            print("👨‍👩‍👧 关闭签到模式开启，取消并跳过本人签到提醒调度")
            cancelAllCheckInNotifications()
            return
        }

        if UserManager.shared.currentUser == nil {
            UserManager.shared.loadUser()
        }

        let effectiveLastCheckIn = UserManager.shared.currentUser?.lastCheckInDate
            ?? UserManager.shared.lastCheckInDate
            ?? lastCheckInDate

        guard let lastCheckIn = effectiveLastCheckIn else {
            print("⚠️ 无上次签到时间，无法设置通知")
            cancelAllCheckInNotifications()
            return
        }

        lastCheckInDate = lastCheckIn
        UserManager.shared.lastCheckInDate = lastCheckIn
        saveLastCheckInDate()
        
        let now = Date()
        
        // ✅ 修复：使用用户设置的签到间隔（本地优先）
        let checkInIntervalHours = currentCheckInIntervalHours()
        let checkInIntervalSeconds = checkInIntervalHours * 3600
        let nextCheckInTime = lastCheckIn.addingTimeInterval(TimeInterval(checkInIntervalSeconds))
        
        // 计算首次提醒时间（剩余 12 小时）
        let reminderThresholdHours = DataManager.shared.systemConfig.checkinReminderThresholdHours
        let firstReminderTime = nextCheckInTime.addingTimeInterval(-TimeInterval(reminderThresholdHours * 3600))
        let scheduleSignature = [
            String(format: "%.0f", lastCheckIn.timeIntervalSince1970),
            String(format: "%.3f", checkInIntervalHours),
            String(format: "%.3f", reminderThresholdHours),
            String(format: "%.3f", DataManager.shared.systemConfig.checkinReminderIntervalHours),
            String(format: "%.3f", DataManager.shared.systemConfig.overduePushIntervalHours)
        ].joined(separator: "|")

        // 取消之前的签到通知，避免误删留言/重要事项等其他功能通知
        cancelAllCheckInNotifications()
        
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
        UserDefaults.standard.set(scheduleSignature, forKey: scheduleSignatureKey)
        
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
        let now = Date()
        
        while currentTime < endTime {
            if currentTime <= now {
                currentTime.addTimeInterval(TimeInterval(intervalSeconds))
                reminderCount += 1
                if reminderCount > 10 { break }
                continue
            }

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
    
    /// 设置到期后的本机提醒（仅提醒用户本人）
    private func scheduleOverdueNotifications(after deadline: Date) {
        let overduePushIntervalHours = DataManager.shared.systemConfig.overduePushIntervalHours
        let intervalSeconds = overduePushIntervalHours * 3600
        var currentTime = deadline.addingTimeInterval(TimeInterval(intervalSeconds))
        var notificationCount = 1
        let now = Date()
        
        // 设置 5 个本机签到提醒，不向添加用户或联系人发送通知。
        while notificationCount <= 5 {
            if currentTime <= now {
                currentTime.addTimeInterval(TimeInterval(intervalSeconds))
                notificationCount += 1
                continue
            }

            let hoursOverdue = notificationCount * Int(overduePushIntervalHours)
            
            scheduleNotification(
                identifier: "checkin_overdue_\(notificationCount)",
                title: "签到记录待更新",
                body: "您的签到记录已到提醒时间 \(hoursOverdue) 小时，请打开 App 更新状态",
                fireDate: currentTime,
                repeats: false
            )
            
            currentTime.addTimeInterval(TimeInterval(intervalSeconds))
            notificationCount += 1
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

    private func cancelAllCheckInNotifications() {
        let identifiers = [
            "checkin_first_reminder",
            "checkin_immediate"
        ] + (0..<10).map { "checkin_repeat_reminder_\($0)" } + (0..<5).map { "checkin_overdue_\($0 + 1)" } + (0..<10).map { "checkin_reminder_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UserDefaults.standard.removeObject(forKey: scheduleSignatureKey)
        print("🗑️ 已取消所有签到提醒")
    }

    // MARK: - 添加状态共享提醒

    /// 不再为添加用户的签到状态排程本地通知。
    /// 添加关系仅用于双方确认后的最近签到时间共享，不做异常推送。
    func scheduleFamilyOverdueNotifications(_ members: [FamilyMember]) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            let toCancel = requests
                .filter { $0.identifier.hasPrefix("family_overdue_") }
                .map { $0.identifier }
            if !toCancel.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: toCancel)
            }
            print("ℹ️ 添加状态仅在 App 内展示，已取消状态到期本地通知（添加人数 \(members.count)）")
        }
    }
    
    /// 通知所有联系人
    func notifyGuardians() async {
        // 见证人和紧急联系人功能已移除
        print("📞 联系人通知功能未启用：本应用不会向外部联系人发送通知")
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
