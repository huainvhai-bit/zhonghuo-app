//
//  LifeCheckStatusManager.swift
//  终活
//
//  生命签到状态管理
//

import Foundation
import UserNotifications

class LifeCheckStatusManager: ObservableObject {
    static let shared = LifeCheckStatusManager()
    
    @Published var isSafe: Bool = true
    @Published var hoursRemaining: Double = 0
    @Published var lastCheckInDate: Date?
    @Published var checkInHistory: [CheckInRecord] = []
    
    private let checkInInterval: TimeInterval = 48 * 3600 // 48 小时
    
    private init() {
        loadLastCheckInDate()
        updateStatus()
    }
    
    // MARK: - 签到
    func checkIn() {
        lastCheckInDate = Date()
        saveLastCheckInDate()
        
        // 记录签到历史
        let record = CheckInRecord(date: Date(), status: .manual)
        checkInHistory.insert(record, at: 0)
        
        // 保持最近 100 条记录
        if checkInHistory.count > 100 {
            checkInHistory.removeLast()
        }
        
        updateStatus()
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
    
    /// 设置后台检查任务（App 退出后继续监控）
    func scheduleBackgroundCheck() {
        // 使用 BGTaskScheduler 安排后台检查
        // 注意：iOS 后台任务有时间限制，需要后端配合才能实现长时间监控
        // 这里使用本地通知作为替代方案
        
        print("📅 设置签到提醒通知...")
        
        // 取消之前的通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // 计算下次签到时间（48 小时后）
        let checkInInterval: TimeInterval = 48 * 3600
        let nextCheckInTime = Date().addingTimeInterval(checkInInterval)
        
        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = "⏰ 该签到啦"
        content.body = "您已经快 48 小时未签到，请打开 App 确认安全"
        content.sound = .default
        content.categoryIdentifier = "CHECKIN_REMINDER"
        
        // 创建触发器（48 小时后）
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextCheckInTime),
            repeats: true
        )
        
        // 创建请求
        let request = UNNotificationRequest(
            identifier: "checkin_reminder",
            content: content,
            trigger: trigger
        )
        
        // 添加通知
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 设置通知失败：\(error)")
            } else {
                print("✅ 签到提醒通知已设置：\(nextCheckInTime)")
            }
        }
    }
    
    /// 检查并发送超时通知给监护人
    func checkAndNotifyGuardians() {
        updateStatus()
        
        if !isSafe {
            let hoursOverdue = -hoursRemaining
            
            // 超时超过 24 小时才通知
            if hoursOverdue >= 24 {
                print("⚠️ 检测到超时，准备通知监护人...")
                
                Task {
                    await notifyGuardians()
                }
            }
        }
    }
    
    /// 通知所有监护人
    private func notifyGuardians() async {
        // 获取当前用户
        guard let user = DataManager.shared.currentUser else {
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
