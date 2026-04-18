//
//  MembershipManager.swift
//  终活
//
//  会员管理
//

import Foundation
import Combine

class MembershipManager: ObservableObject {
    static let shared = MembershipManager()
    
    // MARK: - Published Properties
    @Published var isPremium: Bool = false
    @Published var memberType: String? = nil  // monthly/yearly/lifetime
    @Published var memberExpireAt: Date? = nil
    @Published var maxCapsules: Int = 5       // 免费版默认5个
    @Published var maxVideoMinutes: Int = 2   // 免费版默认2分钟
    @Published var maxMediaCapsules: Int = 2  // 免费版默认2个语音/视频胶囊
    @Published var aiAssistEnabled: Bool = false  // AI智能辅助是否启用
    @Published var lastCheckedAt: Date? = nil   // 上次检查时间
    
    // MARK: - Limits
    struct Limits {
        // 免费版
        static let freeMaxCapsules = 5
        static let freeMaxMediaCapsules = 2
        static let freeMaxVideoMinutes = 2
        static let freeMaxEmergencyContacts = 2
        static let freeMaxWills = 3
        static let freeFamilyMembers = 1
        
        // 会员版
        static let premiumMaxCapsules = 20
        static let premiumMaxMediaCapsules = 10
        static let premiumMaxVideoMinutes = 5
        static let premiumMaxEmergencyContacts = 999
        static let premiumMaxWills = 999
        static let premiumFamilyMembers = 5
    }
    
    // 服务器配置的限制（运行时覆盖）
    struct ServerLimits {
        var freeMaxCapsules: Int
        var freeMaxMediaCapsules: Int
        var freeMaxVideoMinutes: Int
        var premiumMaxCapsules: Int
        var premiumMaxMediaCapsules: Int
        var premiumMaxVideoMinutes: Int
    }
    
    // 默认使用编译时常量
    private var serverLimits = ServerLimits(
        freeMaxCapsules: Limits.freeMaxCapsules,
        freeMaxMediaCapsules: Limits.freeMaxMediaCapsules,
        freeMaxVideoMinutes: Limits.freeMaxVideoMinutes,
        premiumMaxCapsules: Limits.premiumMaxCapsules,
        premiumMaxMediaCapsules: Limits.premiumMaxMediaCapsules,
        premiumMaxVideoMinutes: Limits.premiumMaxVideoMinutes
    )
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadFromCache()
    }
    
    // MARK: - 从用户数据更新
    func updateFromUserData(_ user: User?) {
        guard let user = user else { return }
        
        isPremium = user.isPremium ?? false
        memberType = user.memberType
        memberExpireAt = user.memberExpireAt
        maxCapsules = user.memberMaxCapsules ?? Limits.freeMaxCapsules
        maxVideoMinutes = user.memberMaxVideoMinutes ?? Limits.freeMaxVideoMinutes
        
        // ✅ 检查会员是否过期
        checkExpiration()
        
        // 更新缓存
        saveToCache()
    }
    
    /// ✅ 检查会员是否过期（基于本地缓存）
    func checkExpiration() {
        guard isPremium, let expireAt = memberExpireAt else {
            return
        }
        
        if Date() >= expireAt {
            // 会员已过期，自动降级为免费版
            deactivateMembership()
            print("⏰ 会员已过期，自动降级为免费版")
        }
    }
    
    /// ✅ 基于服务器数据更新会员状态（推荐在获取用户数据时调用）
    @MainActor
    func updateFromServer(isPremium: Bool, memberType: String?, memberExpireAt: Date?, memberMaxCapsules: Int, memberMaxVideoMinutes: Int, aiAssistEnabled: Bool = false) {
        // 检查是否过期
        if isPremium, let expireAt = memberExpireAt, Date() >= expireAt {
            // 服务器返回已过期状态，降至免费版
            self.isPremium = false
            self.memberType = nil
            self.memberExpireAt = nil
            self.maxCapsules = Limits.freeMaxCapsules
            self.maxVideoMinutes = Limits.freeMaxVideoMinutes
            self.maxMediaCapsules = Limits.freeMaxMediaCapsules
            self.aiAssistEnabled = false  // 过期时关闭AI辅助
        } else {
            self.isPremium = isPremium
            self.memberType = memberType
            self.memberExpireAt = memberExpireAt
            self.maxCapsules = memberMaxCapsules > 0 ? memberMaxCapsules : Limits.freeMaxCapsules
            self.maxVideoMinutes = memberMaxVideoMinutes > 0 ? memberMaxVideoMinutes : Limits.freeMaxVideoMinutes
            self.maxMediaCapsules = isPremium ? Limits.premiumMaxMediaCapsules : Limits.freeMaxMediaCapsules
            self.aiAssistEnabled = aiAssistEnabled && isPremium  // 仅会员且服务器启用时开启
        }
        
        lastCheckedAt = Date()
        saveToCache()
        
        print("📋 会员状态更新：isPremium=\(self.isPremium), type=\(self.memberType ?? "nil"), expireAt=\(self.memberExpireAt?.description ?? "nil"), aiAssist=\(self.aiAssistEnabled)")
    }
    
    /// ✅ 手动降级会员（当服务器通知过期时调用）
    func deactivateMembership() {
        isPremium = false
        memberType = nil
        memberExpireAt = nil
        maxCapsules = serverLimits.freeMaxCapsules
        maxVideoMinutes = serverLimits.freeMaxVideoMinutes
        maxMediaCapsules = serverLimits.freeMaxMediaCapsules
        aiAssistEnabled = false  // 关闭AI辅助
        saveToCache()
    }
    
    // MARK: - 功能检查方法
    
    /// 检查是否可以创建胶囊
    func canCreateCapsule(currentCount: Int) -> Bool {
        return currentCount < maxCapsules
    }
    
    /// 检查是否可以创建媒体胶囊（语音/视频）
    func canCreateMediaCapsule(currentMediaCount: Int) -> Bool {
        return currentMediaCount < maxMediaCapsules
    }
    
    /// 获取剩余可创建胶囊数量
    func remainingCapsules(currentCount: Int) -> Int {
        return max(0, maxCapsules - currentCount)
    }
    
    /// 获取剩余可创建媒体胶囊数量
    func remainingMediaCapsules(currentMediaCount: Int) -> Int {
        return max(0, maxMediaCapsules - currentMediaCount)
    }
    
    /// 获取视频录制最大时长（秒）
    func maxVideoRecordingSeconds() -> Int {
        return maxVideoMinutes * 60
    }
    
    /// 获取语音录制最大时长（秒）- 与视频相同
    func maxAudioRecordingSeconds() -> Int {
        return maxVideoMinutes * 60
    }
    
    /// 检查是否可以添加紧急联系人
    func canAddEmergencyContact(currentCount: Int) -> Bool {
        return isPremium || currentCount < Limits.freeMaxEmergencyContacts
    }
    
    /// 检查是否可以创建遗嘱模块
    func canCreateWill(currentCount: Int) -> Bool {
        return isPremium || currentCount < Limits.freeMaxWills
    }
    
    /// 检查是否有云端备份功能
    func hasCloudBackup() -> Bool {
        return isPremium
    }
    
    /// 检查是否有数据导出功能
    func hasDataExport() -> Bool {
        return isPremium
    }
    
    /// 检查是否有家庭守护功能
    func canAddFamilyMember(currentCount: Int) -> Bool {
        if isPremium {
            return currentCount < Limits.premiumFamilyMembers
        }
        return currentCount < Limits.freeFamilyMembers
    }
    
    /// 检查是否有AI辅助功能
    func hasAIAssistance() -> Bool {
        return isPremium
    }
    
    /// ✅ 从服务器应用会员限制配置
    func applyLimits(
        freeMaxCapsules: Int,
        freeMaxMediaCapsules: Int,
        freeMaxVideoMinutes: Int,
        premiumMaxCapsules: Int,
        premiumMaxMediaCapsules: Int,
        premiumMaxVideoMinutes: Int
    ) {
        // 更新静态常量（通过覆盖默认值）
        // 注意：这是运行时覆盖，不影响编译时常量
        self.serverLimits = ServerLimits(
            freeMaxCapsules: freeMaxCapsules,
            freeMaxMediaCapsules: freeMaxMediaCapsules,
            freeMaxVideoMinutes: freeMaxVideoMinutes,
            premiumMaxCapsules: premiumMaxCapsules,
            premiumMaxMediaCapsules: premiumMaxMediaCapsules,
            premiumMaxVideoMinutes: premiumMaxVideoMinutes
        )
        
        // 如果当前是免费版，更新当前限制
        if !isPremium {
            maxCapsules = serverLimits.freeMaxCapsules
            maxMediaCapsules = serverLimits.freeMaxMediaCapsules
            maxVideoMinutes = serverLimits.freeMaxVideoMinutes
        }
        
        print("✅ 会员限制已从服务器更新：免费\(freeMaxCapsules)胶囊/\(freeMaxMediaCapsules)媒体/\(freeMaxVideoMinutes)分钟，会员\(premiumMaxCapsules)胶囊/\(premiumMaxMediaCapsules)媒体/\(premiumMaxVideoMinutes)分钟")
    }
    
    // MARK: - 会员类型显示
    func memberTypeDisplayName() -> String {
        guard isPremium, let type = memberType else { return "免费版" }
        
        switch type {
        case "monthly": return "月卡会员"
        case "yearly": return "年卡会员"
        case "lifetime": return "终身会员"
        default: return "会员"
        }
    }
    
    func memberExpireDisplay() -> String? {
        guard let expireAt = memberExpireAt else {
            if memberType == "lifetime" { return "永久有效" }
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "有效期至：\(formatter.string(from: expireAt))"
    }
    
    // MARK: - 缓存
    private func saveToCache() {
        userDefaults.set(isPremium, forKey: "membership.isPremium")
        userDefaults.set(memberType, forKey: "membership.memberType")
        if let expireAt = memberExpireAt {
            userDefaults.set(expireAt.timeIntervalSince1970, forKey: "membership.memberExpireAt")
        }
        userDefaults.set(maxCapsules, forKey: "membership.maxCapsules")
        userDefaults.set(maxVideoMinutes, forKey: "membership.maxVideoMinutes")
    }
    
    private func loadFromCache() {
        isPremium = userDefaults.bool(forKey: "membership.isPremium")
        memberType = userDefaults.string(forKey: "membership.memberType")
        
        if let expireTimestamp = userDefaults.object(forKey: "membership.memberExpireAt") as? TimeInterval {
            memberExpireAt = Date(timeIntervalSince1970: expireTimestamp)
        }
        
        maxCapsules = userDefaults.integer(forKey: "membership.maxCapsules")
        if maxCapsules == 0 { maxCapsules = Limits.freeMaxCapsules }
        
        maxVideoMinutes = userDefaults.integer(forKey: "membership.maxVideoMinutes")
        if maxVideoMinutes == 0 { maxVideoMinutes = Limits.freeMaxVideoMinutes }
    }
    
    // MARK: - 激活会员（测试用）
    func activatePremium(type: String = "yearly") {
        isPremium = true
        memberType = type
        
        switch type {
        case "monthly":
            memberExpireAt = Calendar.current.date(byAdding: .month, value: 1, to: Date())
            maxCapsules = 20
            maxVideoMinutes = 5
        case "yearly":
            memberExpireAt = Calendar.current.date(byAdding: .year, value: 1, to: Date())
            maxCapsules = 20
            maxVideoMinutes = 5
        case "lifetime":
            memberExpireAt = nil
            maxCapsules = 20
            maxVideoMinutes = 5
        default:
            break
        }
        
        maxMediaCapsules = MembershipManager.Limits.premiumMaxMediaCapsules
        saveToCache()
    }
    
    // MARK: - 取消会员（测试用）
    func deactivatePremium() {
        isPremium = false
        memberType = nil
        memberExpireAt = nil
        maxCapsules = Limits.freeMaxCapsules
        maxVideoMinutes = Limits.freeMaxVideoMinutes
        maxMediaCapsules = Limits.freeMaxMediaCapsules
        saveToCache()
    }
}
