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
        }
        
        struct Limits: Codable {
            let maxUploadSize: Int
            let maxCapsules: Int
            let maxWillModules: Int
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

// MARK: - 本地持久化日期（capsules.json / wills / assets）

/// `JSONEncoder` 默认将 `Date` 编码为 **`timeIntervalSinceReferenceDate`**（以 2001-01-01 为基点）。
/// 旧解码逻辑误用 **`Date(timeIntervalSince1970:)`**，会与「参照时间戳 Double」不匹配，磁盘重载后会显示成 **1994～1997 年前后**。
/// - 解码数字时分流：毫秒 / UNIX 秒 / Apple 参照秒。
/// - 编码时统一写成 `yyyy-MM-dd HH:mm:ss` 字符串，与后端、`batchSync` 一致，消除歧义。
enum PersistedJSONDate {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        return f
    }()

    static func date(fromDecodedString string: String) -> Date {
        if let d = formatter.date(from: string) { return d }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: string) { return d }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: string) ?? Date()
    }

    static func optionalDate(fromDecodedString string: String) -> Date? {
        if let d = formatter.date(from: string) { return d }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: string) { return d }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: string)
    }

    static func decodeDate(fromFlexibleNumber value: Double) -> Date {
        if value >= 1_000_000_000_000 { return Date(timeIntervalSince1970: value / 1000.0) }
        if value >= 1_000_000_000 { return Date(timeIntervalSince1970: value) }
        return Date(timeIntervalSinceReferenceDate: value)
    }

    static func decodeDate(fromFlexibleInteger value: Int) -> Date {
        decodeDate(fromFlexibleNumber: Double(value))
    }

    static func decodeOptionalFlexibleDate<Key: CodingKey>(
        _ container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) throws -> Date? {
        guard container.contains(key) else { return nil }
        if try container.decodeNil(forKey: key) { return nil }
        if let s = try? container.decode(String.self, forKey: key), !s.isEmpty {
            return optionalDate(fromDecodedString: s)
        }
        if let d = try? container.decode(Double.self, forKey: key) {
            return decodeDate(fromFlexibleNumber: d)
        }
        if let i = try? container.decode(Int.self, forKey: key) {
            return decodeDate(fromFlexibleInteger: i)
        }
        return nil
    }

    /// 必填字段：解码失败最后用 `fallback`。
    static func decodeFlexibleRequiredDate<Key: CodingKey>(
        _ container: KeyedDecodingContainer<Key>,
        forKey key: Key,
        fallback: Date = Date()
    ) throws -> Date {
        guard container.contains(key) else { return fallback }
        if try container.decodeNil(forKey: key) { return fallback }
        if let s = try? container.decode(String.self, forKey: key), !s.isEmpty {
            return date(fromDecodedString: s)
        }
        if let d = try? container.decode(Double.self, forKey: key) {
            return decodeDate(fromFlexibleNumber: d)
        }
        if let i = try? container.decode(Int.self, forKey: key) {
            return decodeDate(fromFlexibleInteger: i)
        }
        return fallback
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
    
    // MARK: - 手动初始化（用于预览和代码创建）
    init(id: String = UUID().uuidString, title: String, content: String, type: CapsuleType,
         mediaURL: String = "", mediaServerURL: String = "", mediaDuration: Double = 0,
         sendDate: Date, isSent: Bool, createdAt: Date, deletedAt: Date? = nil,
         cloudBackupStatus: CloudBackupStatus = .pending, cloudBackupAt: Date? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.type = type
        self.mediaURL = mediaURL
        self.mediaServerURL = mediaServerURL
        self.mediaDuration = mediaDuration
        self.sendDate = sendDate
        self.isSent = isSent
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.cloudBackupStatus = cloudBackupStatus
        self.cloudBackupAt = cloudBackupAt
    }
    
    // MARK: - Codable 字段映射（后端使用 snake_case）
    enum CodingKeys: String, CodingKey {
        case id, title, content, type
        case mediaURL = "media_url"
        case mediaServerURL = "media_server_url"
        case mediaDuration = "media_duration"
        case sendDate = "open_at"       // 后端 open_at -> 前端 sendDate
        case isSent = "is_opened"       // 后端 is_opened (0/1) -> 前端 isSent (Bool)
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
        case cloudBackupStatus = "cloud_backup_status"
        case cloudBackupAt = "cloud_backup_at"
    }
    
    // 🔧 自定义解码逻辑，处理 is_opened (0/1) -> Bool 转换
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        type = try container.decode(CapsuleType.self, forKey: .type)
        mediaURL = try container.decodeIfPresent(String.self, forKey: .mediaURL) ?? ""
        mediaServerURL = try container.decodeIfPresent(String.self, forKey: .mediaServerURL) ?? ""
        mediaDuration = try container.decodeIfPresent(Double.self, forKey: .mediaDuration) ?? 0

        sendDate = try PersistedJSONDate.decodeFlexibleRequiredDate(container, forKey: .sendDate)

        // 处理 is_opened (0/1 或 true/false) -> Bool 转换
        do {
            let isOpenedInt = try container.decode(Int.self, forKey: .isSent)
            isSent = isOpenedInt != 0
        } catch {
            do {
                let isOpenedBool = try container.decode(Bool.self, forKey: .isSent)
                isSent = isOpenedBool
            } catch {
                isSent = false
            }
        }

        createdAt = try PersistedJSONDate.decodeFlexibleRequiredDate(container, forKey: .createdAt)

        deletedAt = try PersistedJSONDate.decodeOptionalFlexibleDate(container, forKey: .deletedAt)

        if let raw = try container.decodeIfPresent(String.self, forKey: .cloudBackupStatus),
           let parsed = CloudBackupStatus(rawValue: raw) {
            cloudBackupStatus = parsed
        } else {
            cloudBackupStatus = .pending
        }
        cloudBackupAt = try PersistedJSONDate.decodeOptionalFlexibleDate(container, forKey: .cloudBackupAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(content, forKey: .content)
        try c.encode(type, forKey: .type)
        try c.encode(mediaURL, forKey: .mediaURL)
        try c.encode(mediaServerURL, forKey: .mediaServerURL)
        try c.encode(mediaDuration, forKey: .mediaDuration)
        try c.encode(PersistedJSONDate.formatter.string(from: sendDate), forKey: .sendDate)
        try c.encode(isSent, forKey: .isSent)
        try c.encode(PersistedJSONDate.formatter.string(from: createdAt), forKey: .createdAt)
        if let deletedAt {
            try c.encode(PersistedJSONDate.formatter.string(from: deletedAt), forKey: .deletedAt)
        } else {
            try c.encodeNil(forKey: .deletedAt)
        }
        try c.encode(cloudBackupStatus.rawValue, forKey: .cloudBackupStatus)
        if let cloudBackupAt {
            try c.encode(PersistedJSONDate.formatter.string(from: cloudBackupAt), forKey: .cloudBackupAt)
        } else {
            try c.encodeNil(forKey: .cloudBackupAt)
        }
    }

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
        case image = "图片"
        case sticker = "表情"
        case voice = "录音"
        
        var icon: String {
            switch self {
            case .text: return "✉️"
            case .audio: return "🎙️"
            case .video: return "🎥"
            case .image: return "🖼️"
            case .sticker: return "😊"
            case .voice: return "🎤"
            }
        }
        
        var systemImage: String {
            switch self {
            case .text: return "doc.text.fill"
            case .audio: return "mic.fill"
            case .video: return "video.fill"
            case .image: return "photo.fill"
            case .sticker: return "face.smiling.fill"
            case .voice: return "waveform.rectangle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .text: return "007AFF"
            case .audio: return "FF9500"
            case .video: return "AF52DE"
            case .image: return "34C759"
            case .sticker: return "FFD60A"
            case .voice: return "5856D6"
            }
        }
        
        var mediaType: String {
            switch self {
            case .text, .sticker: return "image"
            case .audio, .voice: return "audio"
            case .video: return "video"
            case .image: return "image"
            }
        }
    }
}

// MARK: - 收到的时光胶囊
struct ReceivedCapsule: Identifiable, Codable {
    let id: String
    let capsuleId: String
    let title: String
    let type: String  // text/audio/video
    let content: String?
    let mediaUrl: String?
    let mediaServerUrl: String?
    let openAt: String?
    let isOpened: Bool
    let sentAt: String
    let senderId: String
    let senderName: String
    let senderPhone: String?
    let createdAt: String
    
    var typeEnum: TimeCapsule.CapsuleType {
        switch type {
        case "audio", "voice": return .audio
        case "video": return .video
        case "image": return .image
        default: return .text
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, capsuleId, title, type, content, mediaUrl, mediaServerUrl, openAt, isOpened, sentAt, senderId, senderName, senderPhone, createdAt
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
    var createdAt: Date = Date()  // 后端返回 created_at
    var template: String?
    var deletedAt: Date? = nil  // 删除标记
    
    // 🔥 云存储状态
    var cloudBackupStatus: TimeCapsule.CloudBackupStatus = .pending
    var cloudBackupAt: Date? = nil
    var cloudURL: String = ""  // 云存储 URL
    
    // MARK: - 手动初始化（用于预览和代码创建）
    init(id: String = UUID().uuidString, type: WillType, title: String, subtitle: String = "",
         content: String = "", isCompleted: Bool = false, createdAt: Date = Date(),
         template: String? = nil, deletedAt: Date? = nil,
         cloudBackupStatus: TimeCapsule.CloudBackupStatus = .pending,
         cloudBackupAt: Date? = nil, cloudURL: String = "") {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.template = template
        self.deletedAt = deletedAt
        self.cloudBackupStatus = cloudBackupStatus
        self.cloudBackupAt = cloudBackupAt
        self.cloudURL = cloudURL
    }
    
    // MARK: - Codable 字段映射
    enum CodingKeys: String, CodingKey {
        case id, type, title, subtitle, content, template
        case isCompleted = "is_completed"  // 后端 is_completed -> 前端 isCompleted
        case createdAt = "created_at"     // 后端 created_at -> 前端 createdAt
        case deletedAt = "deleted_at"
    }
    
    // 🔧 自定义解码逻辑
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(WillType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) ?? ""
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        template = try container.decodeIfPresent(String.self, forKey: .template)
        
        // 处理 is_completed (0/1 或 true/false) -> Bool 转换
        do {
            let isCompletedInt = try container.decode(Int.self, forKey: .isCompleted)
            isCompleted = isCompletedInt != 0
        } catch {
            do {
                let isCompletedBool = try container.decode(Bool.self, forKey: .isCompleted)
                isCompleted = isCompletedBool
            } catch {
                isCompleted = false
            }
        }
        
        createdAt = try PersistedJSONDate.decodeFlexibleRequiredDate(container, forKey: .createdAt)
        deletedAt = try PersistedJSONDate.decodeOptionalFlexibleDate(container, forKey: .deletedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        try c.encode(title, forKey: .title)
        try c.encode(subtitle, forKey: .subtitle)
        try c.encode(content, forKey: .content)
        try c.encodeIfPresent(template, forKey: .template)
        try c.encode(isCompleted, forKey: .isCompleted)
        try c.encode(PersistedJSONDate.formatter.string(from: createdAt), forKey: .createdAt)
        if let deletedAt {
            try c.encode(PersistedJSONDate.formatter.string(from: deletedAt), forKey: .deletedAt)
        } else {
            try c.encodeNil(forKey: .deletedAt)
        }
    }
    
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
    var deletedAt: Date?  // 删除时间（软删除）
    
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
    
    // MARK: - 手动初始化（用于代码创建）
    init(id: String = UUID().uuidString, type: AssetType, name: String, institution: String = "",
         balance: Double = 0, accountNumber: String = "", details: [String: String] = [:],
         createdAt: Date = Date(), deletedAt: Date? = nil) {
        self.id = id
        self.type = type
        self.name = name
        self.institution = institution
        self.balance = balance
        self.accountNumber = accountNumber
        self.details = details
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }
    
    // MARK: - Codable 字段映射（后端使用 snake_case）
    enum CodingKeys: String, CodingKey {
        case id, name, details
        case type = "type"
        case institution = "institution"
        case balance = "balance"
        case accountNumber = "accountNumber"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }
    
    // 🔧 自定义解码逻辑
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        institution = try container.decodeIfPresent(String.self, forKey: .institution) ?? ""
        balance = try container.decodeIfPresent(Double.self, forKey: .balance) ?? 0
        accountNumber = try container.decodeIfPresent(String.self, forKey: .accountNumber) ?? ""
        details = try container.decodeIfPresent([String: String].self, forKey: .details) ?? [:]
        
        // 处理 type 字段
        if let typeString = try container.decodeIfPresent(String.self, forKey: .type) {
            type = AssetType(rawValue: typeString) ?? .bank
        } else {
            type = .bank
        }
        
        createdAt = try PersistedJSONDate.decodeFlexibleRequiredDate(container, forKey: .createdAt)
        deletedAt = try PersistedJSONDate.decodeOptionalFlexibleDate(container, forKey: .deletedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        try c.encode(name, forKey: .name)
        try c.encode(institution, forKey: .institution)
        try c.encode(balance, forKey: .balance)
        try c.encode(accountNumber, forKey: .accountNumber)
        try c.encode(details, forKey: .details)
        try c.encode(PersistedJSONDate.formatter.string(from: createdAt), forKey: .createdAt)
        if let deletedAt {
            try c.encode(PersistedJSONDate.formatter.string(from: deletedAt), forKey: .deletedAt)
        } else {
            try c.encodeNil(forKey: .deletedAt)
        }
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
    var loginAccount: String?
    var phone: String
    var createdAt: Date
    var checkInInterval: CheckInInterval
    var notificationsEnabled: Bool
    var cloudSyncEnabled: Bool
    var lastCheckInDate: Date?
    
    // 登录信息
    var lastLoginAt: Date?
    var lastLoginIp: String?
    var checkinCount: Int
    
    // 会员信息（使用 Optional 以兼容旧版缓存）
    var isPremium: Bool?
    var memberType: String?
    var memberExpireAt: Date?
    var memberMaxCapsules: Int?
    var memberMaxVideoMinutes: Int?
    var aiAssistEnabled: Bool?  // AI智能辅助是否启用（Optional兼容旧缓存）
    
    // 新增身份信息字段
    var ethnicity: String?  // 民族
    var birthday: Date?     // 出生日期
    var idCard: String?     // 身份证号码
    var address: String?    // 住址
    var gender: Gender?  // 性别
    var avatar: String?  // 头像名称
    
    enum Gender: String, Codable, CaseIterable {
        case male = "男"
        case female = "女"
    }

    // 财产信息
    var propertyId: String?
    var bank: String?
    var bankAccount: String?
    var stock: String?
    var fund: String?
    var carPlate: String?
    var otherProperty: String?
    
    // 数字资产
    var wechat: String?
    var qq: String?
    var weibo: String?
    var bitcoin: String?
    var walletPassword: String?
    var iCloud: String?
    var baidu: String?
    var gamePlatform: String?
    var gameAccount: String?
    var email: String?
    var emailPassword: String?
    
    // 继承人信息
    var spouseName: String?
    var childName: String?
    var relativeName: String?
    var socialInheritor: String?
    var cryptoInheritor: String?
    var cloudInheritor: String?
    var gameInheritor: String?
    var emailInheritor: String?
    var primaryInheritor: String?
    var houseInheritor: String?
    var carInheritor: String?
    var otherInheritor: String?
    var moneyInheritor: String?
    var propertyInheritor: String?
    
    // 遗嘱执行人
    var executorName: String?
    var executorContact: String?
    var digitalExecutor: String?
    var digitalContact: String?
    
    // 指示说明
    var socialInstruction: String?
    var cryptoInstruction: String?
    var cloudInstruction: String?
    var gameInstruction: String?
    
    
    // 统计信息（带默认值）
    var capsulesCount: Int = 0
    var willModulesCount: Int = 0
    var familyCount: Int = 0
    
    // 指示说明
    
    // 监护人
    var primaryGuardian: String?
    var secondaryGuardian: String?
    var propertyGuardian: String?
    
    // 抚养安排
    var monthlyAllowance: String?
    var visitation: String?
    var education: String?
    var medical: String?
    
    // 丧葬安排
    var funeralType: String?
    var funeralLocation: String?
    var burialType: String?
    var cemetery: String?
    var funeralFund: String?
    var funeralExecutor: String?
    var otherArrangement: String?
    
    // 身份证号
    var idNumber: String?
}

// MARK: - 用户设置
struct UserSettings: Codable {
    var name: String
    var checkInInterval: CheckInInterval = .twoDays
    var notificationsEnabled: Bool
    var cloudSyncEnabled: Bool
    var lastCheckInDate: Date?
}

// MARK: - 系统配置（后端可配置）
struct SystemConfig: Codable {
    /// 签到提醒：倒计时剩余多少小时开始推送（默认 12 小时）
    var checkinReminderThresholdHours: Double = 12.0
    
    /// 签到提醒：推送间隔时间（小时）（默认 2 小时）
    var checkinReminderIntervalHours: Double = 2.0
    
    /// 超时推送间隔（小时）（默认 1 小时）
    var overduePushIntervalHours: Double = 1.0
    
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
    
    /// 最新版本号（用于检查更新）
    var latestVersion: String = "1.0.0"
    
    /// 强制更新最低版本
    var forceUpdateVersion: String = "0.0.0"
    
    /// 更新地址（App Store 或下载链接）
    var updateUrl: String = ""
    
    // MARK: - 会员价格配置
    var memberPriceMonthly: Double = 8.0
    var memberPriceYearly: Double = 68.0
    
    // MARK: - 免费版限制
    var freeMaxCapsules: Int = 6
    var freeMaxTextCapsules: Int = 2
    var freeMaxAudioCapsules: Int = 2
    var freeMaxVideoCapsules: Int = 2
    var freeMaxMediaCapsules: Int = 4
    var freeMaxVideoMinutes: Int = 2
    var freeMaxWillModules: Int = 5
    var freeMaxFamily: Int = 1
    var freeCloudBackup: Bool = false
    var freeDataExport: Bool = false
    var freeAiAssist: Bool = false
    
    // MARK: - 会员版限制
    var premiumMaxCapsules: Int = 30
    var premiumMaxTextCapsules: Int = 10
    var premiumMaxAudioCapsules: Int = 10
    var premiumMaxVideoCapsules: Int = 10
    var premiumMaxMediaCapsules: Int = 20
    var premiumMaxVideoMinutes: Int = 5
    var premiumMaxWillModules: Int = 999
    var premiumMaxFamily: Int = 5
    var premiumCloudBackup: Bool = true
    var premiumDataExport: Bool = true
    var premiumAiAssist: Bool = true
    
    // MARK: - 客服配置
    var customerServicePhone: String = "400-123-4567"
    /// 对外展示邮箱，由服务端 `getConfig.customerServiceEmail` 提供；未配置时为空字符串
    var customerServiceEmail: String = ""
}

extension SystemConfig {
    /// 运营在后台配置的对外邮箱（去首尾空白）
    var trimmedCustomerServiceEmail: String {
        customerServiceEmail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 「关于」mailto 链接；后端未填写时不可用
    var customerServiceMailURL: URL? {
        let e = trimmedCustomerServiceEmail
        guard !e.isEmpty else { return nil }
        return URL(string: "mailto:\(e)")
    }
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


// MARK: - Input Types



// MARK: - CapsuleInput Extension
extension CapsuleInput {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "title": title,
            "type": type
        ]
        if let mediaType = mediaType { dict["mediaType"] = mediaType }
        // ✅ Bug修复：content 为空字符串时也要上传（if let 无法判断空字符串）
        if content != nil { dict["content"] = content! }
        // ✅ 新增：媒体文件服务器URL
        if let mediaUrl = mediaUrl, !mediaUrl.isEmpty { dict["mediaUrl"] = mediaUrl }
        if let openAt = openAt { dict["openAt"] = openAt }
        if let deletedAt = deletedAt { dict["deletedAt"] = deletedAt }
        return dict
    }
}
struct CapsuleInput {
    let id: String
    let title: String
    let type: String
    let mediaType: String?  // 媒体类型：text/audio/video
    let content: String?
    let mediaUrl: String?   // 媒体文件服务器URL（语音/视频）
    let openAt: String?
    let deletedAt: String?  // 删除标记（ISO8601 格式）
}



// MARK: - WillInput Extension
extension WillInput {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "type": type,
            "title": title,
            "content": content
        ]
        if let deletedAt = deletedAt { dict["deletedAt"] = deletedAt }
        return dict
    }
}
struct WillInput {
    let id: String
    let type: String
    let title: String
    let subtitle: String?  // 副标题
    let content: String?
    let deletedAt: String?  // 删除标记
}

/// 🔧 紧急联系人 API 输入


// MARK: - ContactInput Extension
extension ContactInput {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "phone": phone,
            "relationship": relationship
        ]
        if let deletedAt = deletedAt { dict["deletedAt"] = deletedAt }
        return dict
    }
}
struct ContactInput {
    let id: String
    let name: String
    let phone: String
    let relationship: String
    let deletedAt: String?
}

/// 资产 API 输入


// MARK: - AssetInput Extension
extension AssetInput {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "type": type,
            "name": name,
            "institution": institution,
            "balance": balance,
            "accountNumber": accountNumber
        ]
        if let details = details { dict["details"] = details }
        if let deletedAt = deletedAt { dict["deletedAt"] = deletedAt }
        return dict
    }
}
struct AssetInput {
    let id: String
    let type: String
    let name: String
    let institution: String
    let balance: Double
    let accountNumber: String
    let details: [String: String]?
    let deletedAt: String?
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
    case invalidResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .createFailed: return "创建失败"
        case .updateFailed: return "更新失败"
        case .deleteFailed: return "删除失败"
        case .networkError: return "网络错误"
        case .unauthorized: return "未授权"
        case .invalidURL: return "无效的 URL"
        case .invalidResponse: return "无效的响应"
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
        self.token = KeychainManager.shared.getToken()
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
        let currentToken = KeychainManager.shared.getToken() ?? token
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
            BackendSecurityPolicy.postViolationIfNeeded(message)
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

// ✅ P0 修复 #2: 完善错误类型定义
enum GraphQLError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case noData
    case decodingError
    case unauthorized
    case forbidden
    case notFound
    case serviceUnavailable
    case networkError
    case timeout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 URL"
        case .invalidResponse: return "无效的响应"
        case .httpError(let code):
            switch code {
            case 401: return "未授权，请重新登录"
            case 403: return "禁止访问"
            case 404: return "资源不存在"
            case 500: return "服务器内部错误"
            case 503: return "服务不可用"
            default: return "HTTP 错误：\(code)"
            }
        case .serverError(let message): return "服务器错误：\(message)"
        case .noData: return "没有数据"
        case .decodingError: return "解码错误"
        case .unauthorized: return "未授权，请重新登录"
        case .forbidden: return "禁止访问"
        case .notFound: return "资源不存在"
        case .serviceUnavailable: return "服务不可用"
        case .networkError: return "网络连接失败"
        case .timeout: return "请求超时"
        case .unknown: return "未知错误"
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
    // 会员信息
    let isPremium: Bool?
    let memberType: String?
    let memberExpireAt: String?
    let memberMaxCapsules: Int?
    let memberMaxVideoMinutes: Int?
}

struct UserStats: Decodable {
    let capsulesCount: Int
    let willModulesCount: Int
    let familyCount: Int
    let assetsCount: Int
    let checkinCount: Int
}

struct CapsuleInfo: Codable {
    let id: String
    let title: String
    let type: String
    let content: String?
    let openAt: String?
    let createdAt: String
}

struct WillInfo: Codable {
    let id: String
    let type: String
    let title: String
    let content: String?
    let createdAt: String
}

struct FamilyInfo: Decodable, Identifiable {
    let id: String
    let relationType: String
    let relatedUserId: String
    let relatedUserName: String?
    let relatedUserPhone: String?
    let relatedUserLastCheckInDate: Date?
}

// MARK: - User Mutation

extension GraphQLClient {
    /// 发送重置密码验证码
    func sendResetPasswordCode(phone: String) async throws -> [String: Any] {
        throw NSError(domain: "短信验证码功能已关闭", code: -1, userInfo: [NSLocalizedDescriptionKey: "短信验证码功能已关闭"])
    }
    
    /// 重置密码
    func resetPassword(phone: String, newPassword: String, securityQuestion: String, securityAnswer: String) async throws -> [String: Any] {
        let mutation = """
        mutation($phone: String!, $newPassword: String!, $securityQuestion: String!, $securityAnswer: String!) {
            resetPassword(phone: $phone, newPassword: $newPassword, securityQuestion: $securityQuestion, securityAnswer: $securityAnswer) {
                success
                message
            }
        }
        """
        let variables: [String: Any] = [
            "phone": phone,
            "newPassword": newPassword,
            "securityQuestion": securityQuestion,
            "securityAnswer": securityAnswer
        ]
        return try await self.query(mutation, variables: variables)
    }
    
    /// 签到
    func checkIn(checkInIntervalHours: Int = 48, location: [String: Any]? = nil) async throws -> [String: Any] {
        let mutation = """
        mutation($checkInIntervalHours: Int, $location: JSON) {
            checkIn(checkInIntervalHours: $checkInIntervalHours, location: $location) {
                success
                checkInTime
                expireTimestamp
            }
        }
        """
        var variables: [String: Any] = [:]
        variables["checkInIntervalHours"] = checkInIntervalHours
        if let location = location {
            variables["location"] = location
        }
        return try await self.query(mutation, variables: variables)
    }
    
    /// 更新签到间隔
    func updateCheckInInterval(userId: String, interval: Int) async throws -> [String: Any] {
        let mutation = """
        mutation($checkInIntervalHours: Int!) {
            updateCheckInInterval(checkInIntervalHours: $checkInIntervalHours) {
                success
                message
            }
        }
        """
        let variables: [String: Any] = [
            "checkInIntervalHours": interval
        ]
        return try await self.query(mutation, variables: variables)
    }
}

// MARK: - Token 刷新服务（P0 修复）

/// Token 自动刷新服务
/// 功能：Token 过期时自动调用 refreshToken API 获取新 Token
/// 优先级：P0（高风险 - 用户体验差）
class TokenRefreshService {
    static let shared = TokenRefreshService()
    
    private let apiManager = APIManager()
    private var isRefreshing = false
    private var refreshQueue: [(_ token: String?) -> Void] = []
    
    /// 刷新 Token（如果已过期）
    func refreshTokenIfNeeded() async -> String? {
        // 检查 Token 是否存在
        guard let token = KeychainManager.shared.getToken() else {
            return nil
        }
        
        // 检查 Token 是否即将过期（5分钟内）
        guard let expirationTime = KeychainManager.shared.getTokenExpiration(),
              Date().timeIntervalSince1970 >= expirationTime.timeIntervalSince1970 - 300 else {
            return token // Token 仍然有效
        }
        
        // 标记正在刷新（避免并发刷新）
        guard !isRefreshing else {
            // 等待 Refresh 完成
            return await withCheckedContinuation { continuation in
                refreshQueue.append { continuation.resume(returning: $0) }
            }
        }
        
        isRefreshing = true
        
        // 获取 Refresh Token
        guard let refreshToken = KeychainManager.shared.getRefreshToken() else {
            isRefreshing = false
            print("❌ 没有 Refresh Token，无法刷新")
            return nil
        }
        
        print("🔵 Token 即将过期，开始刷新...")
        
        // 调用后端 refreshToken API
        do {
            let result = try await apiManager.refreshToken(refreshToken)
            isRefreshing = false
            
            // 更新 Token 和 Refresh Token
            if let newToken = result.token {
                KeychainManager.shared.saveToken(newToken, expiration: result.expiresIn)
                print("✅ Token 刷新成功")
            }
            if let newRefreshToken = result.refreshToken {
                KeychainManager.shared.saveRefreshToken(newRefreshToken)
            }
            
            // 唤醒等待队列
            let callbacks = refreshQueue
            refreshQueue.removeAll()
            callbacks.forEach { $0(result.token) }
            
            return result.token
        } catch {
            isRefreshing = false
            print("❌ Token 刷新失败：\(error.localizedDescription)")
            
            // 刷新失败，清空 Token
            KeychainManager.shared.clearToken()
            
            // 唤醒等待队列
            let callbacks = refreshQueue
            refreshQueue.removeAll()
            callbacks.forEach { $0(nil) }
            
            return nil
        }
    }
    
    /// 重置刷新状态（登录成功后调用）
    func resetRefreshState() {
        isRefreshing = false
        refreshQueue.forEach { $0(nil) }
        refreshQueue.removeAll()
    }
}

// MARK: - Token Refresh Response

struct TokenRefreshResult {
    let token: String?
    let refreshToken: String?
    let expiresIn: Int
}

// MARK: - Token Refresh API

extension APIManager {
    /// 刷新 Token
    /// - Parameter refreshToken: Refresh Token
    /// - Returns: TokenRefreshResult (包含新 token 和 refresh token)
    func refreshToken(_ refreshToken: String) async throws -> TokenRefreshResult {
        print("🔵 APIManager.refreshToken 开始...")
        
        // GraphQL 查询
        let query = """
        mutation {
            refreshToken(refreshToken: "\\(refreshToken)") {
                token
                refreshToken
                expiresIn
            }
        }
        """
        
        do {
            // 执行查询
            let result = try await APIClient.shared.query(query)
            
            // 解析结果
            if let data = result["data"] as? [String: Any],
               let refreshData = data["refreshToken"] as? [String: Any],
               let token = refreshData["token"] as? String,
               let newRefreshToken = refreshData["refreshToken"] as? String,
               let expiresIn = refreshData["expiresIn"] as? Int {
                Logger.shared.i("Token 刷新成功")
                return TokenRefreshResult(token: token, refreshToken: newRefreshToken, expiresIn: expiresIn)
            } else {
                Logger.shared.w("Token 刷新返回数据格式异常")
                throw APIError.invalidResponse
            }
        } catch {
            Logger.shared.e("Token 刷新失败：\(error)")
            throw error
        }
    }
}
