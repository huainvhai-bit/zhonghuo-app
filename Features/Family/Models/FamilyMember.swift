//
//  FamilyMember.swift
//  终活
//
//  家人关系数据模型
//

import Foundation
import CoreLocation

/// 家人成员
struct FamilyMember: Identifiable, Codable {
    var id: String           // 成员 ID
    var relationId: String   // 关系 ID
    var name: String         // 姓名
    var phone: String        // 电话
    var avatar: String       // 头像 URL
    var relationship: String // 关系（配偶、父母等）
    var status: Status       // 关系状态
    var statusText: String   // 状态文本
    var lastCheckInDate: Date? = nil  // 被守护端最后签到时间
    var nextCheckInDeadline: Date? = nil  // 被守护端下次应签到的截止时间（来自 checkin_expire_at）
    /// 对方是否处于"家人守护"模式（开启后对方不再需要签到，本端家人卡片应显示"家人守护中"）
    var isFamilyMode: Bool = false
    var createdAt: Date      // 创建时间
    var deviceInfo: DeviceInfo?  // 设备信息
    
    enum Status: Int, Codable {
        case pending = 1    // 待接受
        case accepted = 2   // 已绑定
        case rejected = 3   // 已拒绝
        case removed = 4    // 已解除
        
        var text: String {
            switch self {
            case .pending: return "待接受"
            case .accepted: return "已绑定"
            case .rejected: return "已拒绝"
            case .removed: return "已解除"
            }
        }
    }
    
    /// 是否已确认
    var isConfirmed: Bool {
        return status == .accepted
    }

    init(
        id: String,
        relationId: String,
        name: String,
        phone: String,
        avatar: String,
        relationship: String,
        status: Status,
        statusText: String,
        lastCheckInDate: Date? = nil,
        nextCheckInDeadline: Date? = nil,
        isFamilyMode: Bool = false,
        createdAt: Date,
        deviceInfo: DeviceInfo? = nil
    ) {
        self.id = id
        self.relationId = relationId
        self.name = name
        self.phone = phone
        self.avatar = avatar
        self.relationship = relationship
        self.status = status
        self.statusText = statusText
        self.lastCheckInDate = lastCheckInDate
        self.nextCheckInDeadline = nextCheckInDeadline
        self.isFamilyMode = isFamilyMode
        self.createdAt = createdAt
        self.deviceInfo = deviceInfo
    }
}

/// 设备信息
struct DeviceInfo: Codable {
    var stepCount: Int          // 今日步数
    var batteryLevel: Float     // 电量百分比（0-1）
    var batteryState: Int       // 充电状态（0=未知，1=未充电，2=充电中，3=充满）
    var lastUpdate: Date?       // 最后更新时间
    var latitude: Double?       // 纬度（可选）
    var longitude: Double?      // 经度（可选）
    var address: String?        // 地址文本（可选）
    var accuracy: Double?       // 定位精度（米，可选）
    
    /// 电量百分比文本
    var batteryLevelText: String {
        return "\(Int(batteryLevel * 100))%"
    }
    
    /// 充电状态文本
    var batteryStateText: String {
        switch batteryState {
        case 0: return "未知"
        case 1: return "未充电"
        case 2: return "充电中"
        case 3: return "已充满"
        default: return "未知"
        }
    }
    
    /// 充电状态图标
    var batteryStateIcon: String {
        switch batteryState {
        case 0: return "❓"
        case 1: return "🔋"
        case 2: return "⚡️"
        case 3: return "✅"
        default: return "❓"
        }
    }
    
    /// 步数格式化
    var stepCountText: String {
        if stepCount >= 10000 {
            return String(format: "%.1f 万", Double(stepCount) / 10000)
        } else {
            return "\(stepCount) 步"
        }
    }
    
    /// 是否有位置信息
    var hasLocation: Bool {
        return latitude != nil && longitude != nil
    }
    
    /// 创建 CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

/// 家人邀请码预览信息
struct FamilyInvitePreview: Identifiable, Codable {
    var id: String
    var inviteCode: String
    var inviterId: String
    var inviterName: String
    var inviterPhone: String
    var inviterAccount: String
    var relationType: String
    var requiresConfirmation: Bool
    var status: String
}

/// 待确认的家人绑定请求
struct FamilyPendingRequest: Identifiable, Codable {
    var id: String
    var inviteCode: String
    var inviterId: String
    var inviterName: String
    var inviterPhone: String
    var inviterAccount: String
    var acceptedById: String
    var acceptedByName: String
    var acceptedByPhone: String
    var acceptedByAccount: String
    var displayName: String
    var displayPhone: String
    var displayAccount: String
    var relationType: String
    var status: String
    var needsMyApproval: Bool
    var createdAt: Date?
}
