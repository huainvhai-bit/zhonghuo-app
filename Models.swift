//
//  Models.swift
//  终活
//
//  完整数据模型 - 支持增删改查
//

import Foundation

// MARK: - 服务器配置
struct ServerConfig: Codable {
    let success: Bool
    let data: ServerConfigData?
    let error: String?
    
    struct ServerConfigData: Codable {
        let apiVersion: String
        let serverName: String
        let endpoints: Endpoints
        let features: Features
        let limits: Limits
        let sms: SMSConfig?  // 短信配置
        let serverInfo: ServerInfo?  // 服务器信息（用于调试）
        
        struct Endpoints: Codable {
            let base: String
            let api: String
            let upload: String
        }
        
        struct Features: Codable {
            let userSync: Bool
            let capsuleSync: Bool
            let willSync: Bool
            let checkinSync: Bool
            let witnessSync: Bool
        }
        
        struct Limits: Codable {
            let maxUploadSize: Int
            let maxCapsules: Int
            let maxWillModules: Int
        }
        
        struct SMSConfig: Codable {
            let enabled: Bool
            let provider: String
            let isDevelopment: Bool
        }
        
        struct ServerInfo: Codable {
            let configuredUrl: String
            let detectedUrl: String
            let usingConfigured: Bool
        }
    }
}

// MARK: - 签到同步响应
struct ServerCheckInResponse: Codable {
    let success: Bool
    let data: CheckInData
    let message: String?
    
    struct CheckInData: Codable {
        let isSafe: Bool
        let hoursRemaining: Double
        let interval: String
        let intervalHours: Double
        let lastCheckIn: String?
        let nextCheckIn: String
        let autoCheckInPerformed: Bool
        let needCheckIn: Bool
    }
}

// MARK: - 时光胶囊
struct TimeCapsule: Identifiable, Codable {
    var id: String
    var title: String
    var content: String
    var type: CapsuleType
    var mediaURL: String = ""
    var sendDate: Date
    var isSent: Bool
    var createdAt: Date
    var deletedAt: Date? = nil  // 删除标记
    
    enum CapsuleType: String, Codable {
        case text = "文字"
        case audio = "语音"
        case video = "视频"
        
        var icon: String {
            switch self {
            case .text: return "✉️"
            case .audio: return "🎙️"
            case .video: return "🎥"
            }
        }
        
        var systemImage: String {
            switch self {
            case .text: return "doc.text.fill"
            case .audio: return "mic.fill"
            case .video: return "video.fill"
            }
        }
        
        var color: String {
            switch self {
            case .text: return "007AFF"
            case .audio: return "FF9500"
            case .video: return "AF52DE"
            }
        }
    }
}

// MARK: - 遗嘱模块
struct WillModule: Identifiable, Codable {
    var id: String
    var type: WillType
    var title: String
    var subtitle: String
    var content: String
    var isCompleted: Bool
    var template: String?
    
    enum WillType: String, Codable, CaseIterable {
        case property = "财产分配"
        case heirs = "继承人指定"
        case specialItems = "特殊物品"
        case funeral = "丧葬意愿"
        case otherInstructions = "其他嘱托"
        
        var icon: String {
            switch self {
            case .property: return "🏠"
            case .heirs: return "👥"
            case .specialItems: return "🎁"
            case .funeral: return "🍃"
            case .otherInstructions: return "💬"
            }
        }
        
        var subtitle: String {
            switch self {
            case .property: return "房产、存款、投资等"
            case .heirs: return "指定遗产继承人"
            case .specialItems: return "有纪念意义的物品"
            case .funeral: return "葬礼安排偏好"
            case .otherInstructions: return "其他想交代的事"
            }
        }
        
        var color: String {
            switch self {
            case .property: return "007AFF"
            case .heirs: return "34C759"
            case .specialItems: return "AF52DE"
            case .funeral: return "FF9500"
            case .otherInstructions: return "FF3B30"
            }
        }
    }
}

// MARK: - 资产
struct Asset: Identifiable, Codable {
    var id: String
    var type: AssetType
    var name: String
    var institution: String
    var balance: Double
    var accountNumber: String
    var details: [String: String]
    var createdAt: Date
    
    enum AssetType: String, Codable, CaseIterable {
        case bank = "银行存款"
        case stock = "股票投资"
        case fund = "基金理财"
        case insurance = "保险"
        case cash = "现金"
        case property = "房产"
        case gameAccount = "游戏账号"
        case crypto = "虚拟币"
        
        var icon: String {
            switch self {
            case .bank: return "🏦"
            case .stock: return "📈"
            case .fund: return "💰"
            case .insurance: return "🛡️"
            case .cash: return "💵"
            case .property: return "🏠"
            case .gameAccount: return "🎮"
            case .crypto: return "₿"
            }
        }
        
        var color: String {
            switch self {
            case .bank: return "34C759"
            case .stock: return "FF3B30"
            case .fund: return "AF52DE"
            case .insurance: return "007AFF"
            case .cash: return "34C759"
            case .property: return "FF9500"
            case .gameAccount: return "BF5AF2"
            case .crypto: return "FFD60A"
            }
        }
    }
}

// MARK: - 见证人
struct WillWitness: Identifiable, Codable {
    var id: String
    var name: String
    var relationship: String
    var phone: String
    var idNumber: String
    var notes: String
    var isConfirmed: Bool
    var createdAt: Date
    var confirmedAt: Date?
}

// 兼容旧代码
struct Witness: Identifiable, Codable {
    var id: String
    var name: String
    var role: String
    var phone: String
    var isConfirmed: Bool
    var order: Int
    var idNumber: String = ""
    var notes: String = ""
    var confirmedAt: Date?
    var createdAt: Date = Date()
    var deletedAt: Date? = nil  // 删除标记
    
    // 兼容 relationship 字段（别名）
    var relationship: String {
        get { role }
        set { role = newValue }
    }
    
    var statusText: String {
        isConfirmed ? "已确认" : "待确认"
    }
    
    var statusColor: String {
        isConfirmed ? "34C759" : "FF9500"
    }
}

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
    
    // 新增身份信息字段
    var ethnicity: String?  // 民族
    var birthday: Date?     // 出生日期
    var idCard: String?     // 身份证号码
    var address: String?    // 住址
    
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
