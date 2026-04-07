//
//  AssetModel.swift
//  终活
//
//  资产模型
//

import Foundation

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

struct ContactInput {
    let id: String
    let name: String
    let phone: String
    let relationship: String
    let deletedAt: String?
}
