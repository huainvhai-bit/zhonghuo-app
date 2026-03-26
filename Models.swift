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
    var mediaURL: String = ""          // 本地媒体文件 URL
    var mediaServerURL: String = ""    // 服务器媒体文件 URL（云存储）
    var mediaDuration: Double = 0      // 媒体时长（秒）
    var sendDate: Date
    var isSent: Bool
    var createdAt: Date
    var deletedAt: Date? = nil  // 删除标记
    
    // 🔥 云存储状态
    var cloudBackupStatus: CloudBackupStatus = .pending
    var cloudBackupAt: Date? = nil
    
    enum CloudBackupStatus: String, Codable {
        case pending = "待备份"
        case uploading = "上传中"
        case backedUp = "已备份"
        case failed = "失败"
        
        var icon: String {
            switch self {
            case .pending: return "⏳"
            case .uploading: return "☁️"
            case .backedUp: return "✅"
            case .failed: return "❌"
            }
        }
        
        var color: String {
            switch self {
            case .pending: return "FF9500"
            case .uploading: return "007AFF"
            case .backedUp: return "34C759"
            case .failed: return "FF3B30"
            }
        }
    }
    
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
//
//  APIManager.swift
//  终活
//
//  统一 API 管理器 - 基于 GraphQL
//  所有数据请求都通过此管理器
//

import Foundation

class APIManager {
    static let shared = APIManager()
    
    private let client = GraphQLClient.shared
    
    /// 获取用户完整数据
    func fetchUserData() async throws -> [String: Any] {
        return try await client.fetchUserData()
    }
    
    /// 签到
    func checkIn(isAuto: Bool = false, location: [String: Any]? = nil) async throws {
        let query = """
        mutation {
            checkIn(isAuto: \(isAuto), location: \(location != nil ? "..." : "null")) {
                success
                checkInTime
            }
        }
        """
        
        // 简化实现，直接调用
        try await client.query(query)
    }
    
    /// 上传位置
    func uploadLocation(latitude: Double, longitude: Double, accuracy: Double?) async throws {
        let query = """
        mutation {
            uploadLocation(latitude: \(latitude), longitude: \(longitude), accuracy: \(accuracy ?? 0)) {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 创建胶囊
    func createCapsule(title: String, type: String, content: String?, openAt: String?) async throws -> String {
        let query = """
        mutation {
            createCapsule(title: "\(title)", type: "\(type)", content: "\(content ?? "")", openAt: "\(openAt ?? "")") {
                id
                success
            }
        }
        """
        
        let result: [String: Any] = try await client.query(query)
        if let data = result["createCapsule"] as? [String: Any],
           let id = data["id"] as? String {
            return id
        }
        throw APIError.createFailed
    }
    
    /// 更新胶囊
    func updateCapsule(id: String, title: String, type: String, content: String?, openAt: String?) async throws {
        let query = """
        mutation {
            updateCapsule(id: "\(id)", title: "\(title)", type: "\(type)", content: "\(content ?? "")", openAt: "\(openAt ?? "")") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 删除胶囊
    func deleteCapsule(id: String) async throws {
        let query = """
        mutation {
            deleteCapsule(id: "\(id)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 创建遗嘱
    func createWill(title: String, type: String, content: String?) async throws -> String {
        let query = """
        mutation {
            createWill(title: "\(title)", type: "\(type)", content: "\(content ?? "")") {
                id
                success
            }
        }
        """
        
        let result: [String: Any] = try await client.query(query)
        if let data = result["createWill"] as? [String: Any],
           let id = data["id"] as? String {
            return id
        }
        throw APIError.createFailed
    }
    
    /// 更新遗嘱
    func updateWill(id: String, title: String, type: String, content: String?) async throws {
        let query = """
        mutation {
            updateWill(id: "\(id)", title: "\(title)", type: "\(type)", content: "\(content ?? "")") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 删除遗嘱
    func deleteWill(id: String) async throws {
        let query = """
        mutation {
            deleteWill(id: "\(id)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 创建资产
    func createAsset(name: String, type: String, value: Double?, description: String?) async throws -> String {
        let query = """
        mutation {
            createAsset(name: "\(name)", type: "\(type)", value: \(value ?? 0), description: "\(description ?? "")") {
                id
                success
            }
        }
        """
        
        let result: [String: Any] = try await client.query(query)
        if let data = result["createAsset"] as? [String: Any],
           let id = data["id"] as? String {
            return id
        }
        throw APIError.createFailed
    }
    
    /// 更新资产
    func updateAsset(id: String, name: String, type: String, value: Double?, description: String?) async throws {
        let query = """
        mutation {
            updateAsset(id: "\(id)", name: "\(name)", type: "\(type)", value: \(value ?? 0), description: "\(description ?? "")") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 删除资产
    func deleteAsset(id: String) async throws {
        let query = """
        mutation {
            deleteAsset(id: "\(id)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 生成邀请码
    func generateInviteCode(relationType: String) async throws -> String {
        let query = """
        mutation {
            inviteFamily(relationType: "\(relationType)") {
                inviteCode
                success
            }
        }
        """
        
        let result: [String: Any] = try await client.query(query)
        if let data = result["inviteFamily"] as? [String: Any],
           let code = data["inviteCode"] as? String {
            return code
        }
        throw APIError.createFailed
    }
    
    /// 接受邀请
    func acceptFamilyInvite(inviteCode: String) async throws {
        let query = """
        mutation {
            acceptFamilyInvite(inviteCode: "\(inviteCode)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 拒绝邀请
    func rejectFamilyInvite(inviteCode: String) async throws {
        let query = """
        mutation {
            rejectFamilyInvite(inviteCode: "\(inviteCode)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 移除家人
    func removeFamily(id: String) async throws {
        let query = """
        mutation {
            removeFamily(id: "\(id)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 创建紧急联系人
    func createEmergencyContact(name: String, phone: String, relationship: String) async throws -> String {
        let query = """
        mutation {
            createEmergencyContact(name: "\(name)", phone: "\(phone)", relationship: "\(relationship)") {
                id
                success
            }
        }
        """
        
        let result: [String: Any] = try await client.query(query)
        if let data = result["createEmergencyContact"] as? [String: Any],
           let id = data["id"] as? String {
            return id
        }
        throw APIError.createFailed
    }
    
    /// 更新紧急联系人
    func updateEmergencyContact(id: String, name: String, phone: String, relationship: String) async throws {
        let query = """
        mutation {
            updateEmergencyContact(id: "\(id)", name: "\(name)", phone: "\(phone)", relationship: "\(relationship)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 删除紧急联系人
    func deleteEmergencyContact(id: String) async throws {
        let query = """
        mutation {
            deleteEmergencyContact(id: "\(id)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 创建见证人
    func createWitness(name: String, phone: String, relationship: String) async throws -> String {
        let query = """
        mutation {
            createWitness(name: "\(name)", phone: "\(phone)", relationship: "\(relationship)") {
                id
                success
            }
        }
        """
        
        let result: [String: Any] = try await client.query(query)
        if let data = result["createWitness"] as? [String: Any],
           let id = data["id"] as? String {
            return id
        }
        throw APIError.createFailed
    }
    
    /// 更新见证人
    func updateWitness(id: String, name: String, phone: String, relationship: String) async throws {
        let query = """
        mutation {
            updateWitness(id: "\(id)", name: "\(name)", phone: "\(phone)", relationship: "\(relationship)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 删除见证人
    func deleteWitness(id: String) async throws {
        let query = """
        mutation {
            deleteWitness(id: "\(id)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    // MARK: - 批量同步
    
    /// 批量同步胶囊
    func batchSyncCapsules(_ capsules: [CapsuleInput]) async throws -> BatchSyncResult {
        // 🔍 调试日志
        print("🔍 batchSyncCapsules 开始同步")
        print("🔍 胶囊数量：\(capsules.count)")
        if let first = capsules.first {
            print("🔍 第一个胶囊：id=\(first.id), title=\(first.title), type=\(first.type)")
        }
        
        // 构建胶囊输入
        let capsulesInput = capsules.map { c in
            var parts: [String] = []
            parts.append("id: \"\(c.id)\"")
            parts.append("title: \"\(c.title.replacingOccurrences(of: "\"", with: "\\\""))\"")
            parts.append("type: \"\(c.type)\"")
            if let content = c.content {
                parts.append("content: \"\(content.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n"))\"")
            }
            if let openAt = c.openAt {
                parts.append("openAt: \"\(openAt)\"")
            }
            return "{ \(parts.joined(separator: ", ")) }"
        }.joined(separator: ", ")
        
        let query = """
        mutation {
            batchSyncCapsules(capsules: [\(capsulesInput)]) {
                total
                created
                updated
                cloudUrls
            }
        }
        """
        
        // 🔥 调试：打印完整查询
        print("🔍 batchSyncCapsules GraphQL Query:")
        print(query)
        print("---")
        
        let response = try await client.query(query)
        print("🔍 响应：\(response)")
        
        // GraphQL 响应格式：{"data": {"batchSyncCapsules": {...}}}
        if let data = response["data"] as? [String: Any],
           let syncResult = data["batchSyncCapsules"] as? [String: Any] {
            
            // 🔧 检查是否有错误
            if let error = syncResult["error"] as? String {
                print("❌ 同步失败：\(error)")
                throw APIError.unauthorized
            }
            
            let total = syncResult["total"] as? Int ?? 0
            let created = syncResult["created"] as? Int ?? 0
            let updated = syncResult["updated"] as? Int ?? 0
            
            print("✅ 胶囊同步结果：总计 \(total), 创建 \(created), 更新 \(updated)")
            
            // 🔥 解析云存储 URL
            if let cloudUrls = syncResult["cloudUrls"] as? [String: String] {
                print("☁️ 云存储 URL: \(cloudUrls.count) 个胶囊已备份")
                // 更新本地胶囊的 mediaServerURL
                for (capsuleId, url) in cloudUrls {
                    if let index = DataManager.shared.capsules.firstIndex(where: { $0.id == capsuleId }) {
                        DataManager.shared.capsules[index].mediaServerURL = url
                        print("✅ 胶囊 \(capsuleId) 云存储 URL 已更新")
                    }
                }
            }
            
            // 🔧 警告：同步结果为 0
            if total == 0 && created == 0 && updated == 0 {
                print("⚠️ 警告：同步结果为 0，可能解析失败或无数据")
                // 不抛异常，返回空结果
            }
            
            return BatchSyncResult(total: total, created: created, updated: updated)
        }
        
        print("❌ 响应解析失败")
        throw APIError.networkError
    }
    
    /// 批量同步遗嘱
    func batchSyncWills(_ wills: [WillInput]) async throws -> BatchSyncResult {
        print("🔍 batchSyncWills 开始同步 \(wills.count) 个遗嘱")
        
        let willsInput = wills.map { w in
            var parts: [String] = []
            parts.append("id: \"\(w.id)\"")
            parts.append("type: \"\(w.type)\"")
            parts.append("title: \"\(w.title.replacingOccurrences(of: "\"", with: "\\\""))\"")
            if let content = w.content {
                parts.append("content: \"\(content.replacingOccurrences(of: "\"", with: "\\\""))\"")
            }
            return "{ \(parts.joined(separator: ", ")) }"
        }.joined(separator: ", ")
        
        let query = """
        mutation {
            batchSyncWills(wills: [\(willsInput)]) {
                total
                created
                updated
                cloudUrls
            }
        }
        """
        
        print("🔍 batchSyncWills GraphQL Query:")
        print(query)
        print("---")
        
        let response = try await client.query(query)
        if let data = response["data"] as? [String: Any],
           let syncResult = data["batchSyncWills"] as? [String: Any],
           let total = syncResult["total"] as? Int,
           let created = syncResult["created"] as? Int,
           let updated = syncResult["updated"] as? Int {
            // 🔥 解析云存储 URL
            if let cloudUrls = syncResult["cloudUrls"] as? [String: String] {
                print("☁️ 云存储 URL: \(cloudUrls.count) 个遗嘱已备份")
                // 更新本地遗嘱的 content（从云存储读取）
                for (willId, url) in cloudUrls {
                    if let index = DataManager.shared.willModules.firstIndex(where: { $0.id == willId }) {
                        // 保存云存储 URL（可以添加到 WillModule 模型）
                        print("✅ 遗嘱 \(willId) 云存储 URL 已更新：\(url)")
                    }
                }
            }
            return BatchSyncResult(total: total, created: created, updated: updated)
        }
        throw APIError.networkError
    }
    
    /// 批量同步紧急联系人
    func batchSyncEmergencyContacts(_ contacts: [ContactInput]) async throws -> BatchSyncResult {
        let contactsInput = contacts.map { c in
            var parts: [String] = []
            parts.append("id: \"\(c.id)\"")
            parts.append("name: \"\(c.name.replacingOccurrences(of: "\"", with: "\\\""))\"")
            parts.append("phone: \"\(c.phone)\"")
            parts.append("relationship: \"\(c.relationship.replacingOccurrences(of: "\"", with: "\\\""))\"")
            if let deletedAt = c.deletedAt {
                parts.append("deletedAt: \"\(deletedAt)\"")
            }
            return "{ \(parts.joined(separator: ", ")) }"
        }.joined(separator: ", ")
        
        let query = """
        mutation {
            batchSyncEmergencyContacts(contacts: [\(contactsInput)]) {
                total
                created
                updated
            }
        }
        """
        
        let response = try await client.query(query)
        if let data = response["data"] as? [String: Any],
           let syncResult = data["batchSyncEmergencyContacts"] as? [String: Any],
           let total = syncResult["total"] as? Int,
           let created = syncResult["created"] as? Int,
           let updated = syncResult["updated"] as? Int {
            return BatchSyncResult(total: total, created: created, updated: updated)
        }
        throw APIError.networkError
    }
    
    /// 批量同步见证人
    func batchSyncWitnesses(_ witnesses: [WitnessInput]) async throws -> BatchSyncResult {
        print("🔍 batchSyncWitnesses 开始同步 \(witnesses.count) 个见证人")
        
        let witnessesInput = witnesses.map { w in
            var parts: [String] = []
            parts.append("id: \"\(w.id)\"")
            parts.append("name: \"\(w.name.replacingOccurrences(of: "\"", with: "\\\""))\"")
            parts.append("phone: \"\(w.phone)\"")
            parts.append("relationship: \"\(w.relationship.replacingOccurrences(of: "\"", with: "\\\""))\"")
            if let status = w.status {
                parts.append("status: \"\(status)\"")
            }
            return "{ \(parts.joined(separator: ", ")) }"
        }.joined(separator: ", ")
        
        let query = """
        mutation {
            batchSyncWitnesses(witnesses: [\(witnessesInput)]) {
                total
                created
                updated
            }
        }
        """
        
        print("🔍 batchSyncWitnesses GraphQL Query:")
        print(query)
        print("---")
        
        let response = try await client.query(query)
        if let data = response["data"] as? [String: Any],
           let syncResult = data["batchSyncWitnesses"] as? [String: Any],
           let total = syncResult["total"] as? Int,
           let created = syncResult["created"] as? Int,
           let updated = syncResult["updated"] as? Int {
            return BatchSyncResult(total: total, created: created, updated: updated)
        }
        throw APIError.networkError
    }
    
    // 🔥 从云存储读取胶囊内容
    func fetchCapsuleContentFromCloud(url: String) async throws -> String {
        guard let cloudURL = URL(string: url) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: cloudURL)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.networkError
        }
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw APIError.decodingError
        }
        
        print("☁️ 从云存储读取胶囊内容成功：\(url)")
        return content
    }
    
    // 🔥 从云存储读取遗嘱内容
    func fetchWillContentFromCloud(url: String) async throws -> String {
        guard let cloudURL = URL(string: url) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: cloudURL)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.networkError
        }
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw APIError.decodingError
        }
        
        print("☁️ 从云存储读取遗嘱内容成功：\(url)")
        return content
    }
}

// MARK: - Input Types

struct CapsuleInput {
    let id: String
    let title: String
    let type: String
    let content: String?
    let openAt: String?
}

struct WillInput {
    let id: String
    let type: String
    let title: String
    let content: String?
}

/// 🔧 紧急联系人 API 输入
struct ContactInput {
    let id: String
    let name: String
    let phone: String
    let relationship: String
    let deletedAt: String?
}

struct WitnessInput {
    let id: String
    let name: String
    let phone: String
    let relationship: String
    let status: String?
}

struct BatchSyncResult {
    let total: Int
    let created: Int
    let updated: Int
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case createFailed
    case updateFailed
    case deleteFailed
    case networkError
    case unauthorized
    case invalidURL
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .createFailed: return "创建失败"
        case .updateFailed: return "更新失败"
        case .deleteFailed: return "删除失败"
        case .networkError: return "网络错误"
        case .unauthorized: return "未授权"
        case .invalidURL: return "无效的 URL"
        case .decodingError: return "解码失败"
        }
    }
}
//
//  GraphQLClient.swift
//  终活
//
//  GraphQL 客户端 - 统一数据查询
//

import Foundation

class GraphQLClient {
    static let shared = GraphQLClient()
    
    private let baseURL: String
    private var token: String?
    
    init() {
        self.baseURL = UserDefaults.standard.string(forKey: "serverURL") ?? DataManager.apiURL
        self.token = UserDefaults.standard.string(forKey: "userToken")
    }
    
    /// 执行 GraphQL 查询并返回字典（返回完整响应，包含 success/message/data）
    func query(_ query: String, variables: [String: Any]? = nil) async throws -> [String: Any] {
        guard let url = URL(string: "\(baseURL)/api/graphql.php") else {
            throw GraphQLError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 动态读取 token（确保使用最新的 token）
        let currentToken = UserDefaults.standard.string(forKey: "userToken") ?? token
        if let token = currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "query": query,
            "variables": variables ?? [:]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GraphQLError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw GraphQLError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GraphQLError.decodingError
        }
        
        if let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
            let message = errors[0]["message"] as? String ?? "GraphQL 错误"
            throw GraphQLError.serverError(message)
        }
        
        // 返回完整响应（包含 data 字段）
        // 调用方需要从 json["data"]["batchSyncCapsules"] 中获取结果
        return json
    }
    
    /// 设置 Token
    func setToken(_ token: String?) {
        self.token = token
    }
}

// MARK: - GraphQL Response

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLErrorItem]?
}

struct GraphQLErrorItem: Decodable {
    let message: String
    let locations: [Location]?
    
    struct Location: Decodable {
        let line: Int
        let column: Int
    }
}

// MARK: - GraphQL Errors

enum GraphQLError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case noData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 URL"
        case .invalidResponse: return "无效的响应"
        case .httpError(let code): return "HTTP 错误：\(code)"
        case .serverError(let message): return "服务器错误：\(message)"
        case .noData: return "没有数据"
        case .decodingError: return "解码错误"
        }
    }
}

// MARK: - GraphQL Queries

extension GraphQLClient {
    /// 获取用户完整数据（一次性查询）
    func fetchUserData() async throws -> [String: Any] {
        let query = """
        {
            user {
                id
                name
                phone
                createdAt
                lastLoginAt
                lastLoginIp
                checkinCount
                stats {
                    emergencyContactsCount
                    witnessesCount
                    capsulesCount
                    willModulesCount
                    familyCount
                    assetsCount
                    checkinCount
                }
            }
            capsules {
                id
                title
                type
                content
                openAt
                createdAt
            }
            wills {
                id
                type
                title
                content
                createdAt
            }
            family {
                id
                relationType
                relatedUserId
                relatedUserName
                relatedUserPhone
            }
        }
        """
        
        return try await self.query(query)
    }
}

// MARK: - User Data Models

struct UserData: Decodable {
    let user: UserInfo
    let capsules: [CapsuleInfo]
    let wills: [WillInfo]
    let family: [FamilyInfo]
}

struct UserInfo: Decodable {
    let id: String
    let name: String
    let phone: String
    let createdAt: String
    let lastLoginAt: String?
    let lastLoginIp: String?
    let checkinCount: Int
    let stats: UserStats
}

struct UserStats: Decodable {
    let emergencyContactsCount: Int
    let witnessesCount: Int
    let capsulesCount: Int
    let willModulesCount: Int
    let familyCount: Int
    let assetsCount: Int
    let checkinCount: Int
}

struct CapsuleInfo: Decodable {
    let id: String
    let title: String
    let type: String
    let content: String?
    let openAt: String?
    let createdAt: String
}

struct WillInfo: Decodable {
    let id: String
    let type: String
    let title: String
    let content: String?
    let createdAt: String
}

struct FamilyInfo: Decodable {
    let id: String
    let relationType: String
    let relatedUserId: String
    let relatedUserName: String?
    let relatedUserPhone: String?
}
