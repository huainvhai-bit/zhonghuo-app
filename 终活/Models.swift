//
//  Models.swift
//  终活
//
//  完整数据模型 - 支持增删改查
//

import Foundation

// MARK: - 时光胶囊
struct TimeCapsule: Identifiable, Codable {
    var id: String
    var title: String
    var content: String
    var type: CapsuleType
    var sendDate: Date
    var isSent: Bool
    var createdAt: Date
    
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
    
    enum AssetType: String, Codable {
        case bank = "银行存款"
        case stock = "股票投资"
        case fund = "基金理财"
        case insurance = "保险"
        
        var icon: String {
            switch self {
            case .bank: return "🏦"
            case .stock: return "📈"
            case .fund: return "💰"
            case .insurance: return "🛡️"
            }
        }
        
        var color: String {
            switch self {
            case .bank: return "34C759"
            case .stock: return "FF3B30"
            case .fund: return "AF52DE"
            case .insurance: return "007AFF"
            }
        }
    }
}

// MARK: - 见证人
struct Witness: Identifiable, Codable {
    var id: String
    var name: String
    var role: String
    var phone: String
    var isConfirmed: Bool
    var order: Int
    
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

// MARK: - 用户设置
struct UserSettings: Codable {
    var name: String
    var emergencyContact: EmergencyContact?
    var checkInInterval: Int // 小时
    var notificationsEnabled: Bool
    var cloudSyncEnabled: Bool
    
    struct EmergencyContact: Codable {
        var name: String
        var phone: String
        var relationship: String
    }
}
