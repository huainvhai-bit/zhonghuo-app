//
//  WillModel.swift
//  终活
//
//  遗嘱模块模型
//

import Foundation

// MARK: - 遗嘱模块
struct WillModule: Identifiable, Codable {
    var id: String
    var type: WillType
    var title: String
    var subtitle: String
    var content: String
    var isCompleted: Bool
    var template: String?
    
    // 🔥 云存储状态
    var cloudBackupStatus: TimeCapsule.CloudBackupStatus = .pending
    var cloudBackupAt: Date? = nil
    var cloudURL: String = ""  // 云存储 URL
    
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

struct WillInput {
    let id: String
    let type: String
    let title: String
    let content: String?
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
    
    // 兼容 relationship 字段（计算属性，不参与 Codable）
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
    
    // MARK: - Codable 自定义实现（排除计算属性）
    enum CodingKeys: String, CodingKey {
        case id, name, role, phone, isConfirmed, order, idNumber, notes, confirmedAt, createdAt, deletedAt
    }
}

struct WitnessInput {
    let id: String
    let name: String
    let phone: String
    let relationship: String
    let status: String?
    let deletedAt: String?  // 删除时间戳（ISO 8601）
}
