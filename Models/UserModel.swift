//
//  UserModel.swift
//  终活
//
//  用户模型
//

import Foundation

// MARK: - 待办事项
struct ChecklistItem: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var category: ChecklistCategory
    var isCompleted: Bool
    var tags: [String]
    
    enum ChecklistCategory: String, Codable {
        case finance = "财务"
        case digital = "数字账号"
        case document = "文件"
        case wish = "愿望"
        
        var tagColor: String {
            switch self {
            case .finance: return "34C759"
            case .digital: return "007AFF"
            case .document: return "FF9500"
            case .wish: return "AF52DE"
            }
        }
    }
}

// MARK: - 签到间隔
enum CheckInInterval: String, Codable, CaseIterable {
    case oneMinute = "1 分钟"
    case oneDay = "1 天"
    case twoDays = "2 天"
    case threeDays = "3 天"
    case fourDays = "4 天"
    case fiveDays = "5 天"
    case sixDays = "6 天"
    case sevenDays = "7 天"
    
    var hours: Double {
        switch self {
        case .oneMinute: return 0.017
        case .oneDay: return 24
        case .twoDays: return 48
        case .threeDays: return 72
        case .fourDays: return 96
        case .fiveDays: return 120
        case .sixDays: return 144
        case .sevenDays: return 168
        }
    }
}

// MARK: - 用户模型
struct User: Codable, Identifiable {
    var id: String
    var name: String
    var phone: String
    var createdAt: Date
    var emergencyContacts: [EmergencyContact]
    var checkInInterval: CheckInInterval
    var notificationsEnabled: Bool
    var cloudSyncEnabled: Bool
    var lastCheckInDate: Date?
    
    // 登录信息
    var lastLoginAt: Date?
    var lastLoginIp: String?
    var checkinCount: Int
    
    // 新增身份信息字段
    var ethnicity: String?  // 民族
    var birthday: Date?     // 出生日期
    var idCard: String?     // 身份证号码
    var address: String?    // 住址
    
    // 统计信息（带默认值）
    var emergencyContactsCount: Int = 0
    var witnessesCount: Int = 0
    var capsulesCount: Int = 0
    var willModulesCount: Int = 0
    var familyCount: Int = 0
    
    struct EmergencyContact: Codable, Identifiable {
        var id: String = UUID().uuidString
        var name: String
        var phone: String
        var relationship: String
        var isConfirmed: Bool = false
        var createdAt: Date = Date()
        var deletedAt: Date? = nil  // 删除标记
    }
}

// MARK: - 用户设置
struct UserSettings: Codable {
    var name: String
    var emergencyContact: EmergencyContact?
    var emergencyContacts: [EmergencyContact] = [] // 新增：支持多个紧急联系人
    var checkInInterval: CheckInInterval = .twoDays
    var notificationsEnabled: Bool
    var cloudSyncEnabled: Bool
    var lastCheckInDate: Date?
    
    struct EmergencyContact: Codable, Identifiable {
        var id: String = UUID().uuidString
        var name: String
        var phone: String
        var relationship: String
        var isConfirmed: Bool = false
        var createdAt: Date = Date()
        var deletedAt: Date? = nil  // 删除标记
    }
}

// MARK: - 系统配置（后端可配置）
struct SystemConfig: Codable {
    /// 签到提醒：倒计时剩余多少小时开始推送（默认 12 小时）
    var checkinReminderThresholdHours: Double = 12.0
    
    /// 签到提醒：推送间隔时间（小时）（默认 2 小时）
    var checkinReminderIntervalHours: Double = 2.0
    
    /// 紧急联系人：最少数量要求（默认 2 人）
    var minimumEmergencyContacts: Int = 2
    
    /// 签到间隔时间（小时）（默认 48 小时）
    var checkinIntervalHours: Double = 48.0
    
    /// 离线超时阈值（小时）- 超过这个时间未签到会变成红色警告（默认 24 小时）
    var offlineTimeoutHours: Double = 24.0
    
    /// 最新版本号
    var appVersionLatest: String = "2.0.0"
    
    /// 强制更新最低版本
    var appVersionForceUpdate: String = "1.0.0"
    
    /// 维护模式开关
    var appMaintenanceMode: Bool = false
    
    /// 维护模式提示信息
    var appMaintenanceMessage: String = "系统维护中，请稍后再试"
}

// MARK: - 配置 API 响应
struct ConfigResponse: Codable {
    let status: String
    let data: SystemConfig
    let timestamp: TimeInterval?
    let message: String?
}
