//
//  Models.swift
//  终活 - 数据模型
//

import Foundation

/// 时光胶囊
struct TimeCapsule: Identifiable {
    let id = UUID()
    var title: String
    var content: String
    var openDate: Date
    var isLocked: Bool
    var recipient: String?
}

/// 用户
struct User: Identifiable {
    let id = UUID()
    var name: String
    var email: String
    var avatar: String?
}

/// 检查清单项
struct ChecklistItem: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted: Bool
    var category: String
}

/// 紧急联系人
struct EmergencyContact: Identifiable {
    let id = UUID()
    var name: String
    var relationship: String
    var phone: String
}

/// 资产
struct Asset: Identifiable {
    let id = UUID()
    var name: String
    var type: String
    var value: Double
    var notes: String?
}
