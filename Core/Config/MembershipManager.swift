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
    @Published var maxCapsules: Int = 6       // 免费版默认6个总胶囊
    @Published var maxTextCapsules: Int = 2   // 免费版默认2个文字胶囊
    @Published var maxAudioCapsules: Int = 2  // 免费版默认2个录音胶囊
    @Published var maxVideoCapsules: Int = 2  // 免费版默认2个视频胶囊
    @Published var maxVideoMinutes: Int = 2   // 免费版默认2分钟
    @Published var maxMediaCapsules: Int = 4  // 免费版默认4个媒体胶囊（录音+视频）
    @Published var aiAssistEnabled: Bool = false  // AI智能辅助是否启用
    @Published var lastCheckedAt: Date? = nil   // 上次检查时间
    
    // MARK: - Limits
    struct Limits {
        // 免费版
        static let freeMaxCapsules = 6
        static let freeMaxTextCapsules = 2
        static let freeMaxAudioCapsules = 2
        static let freeMaxVideoCapsules = 2
        static let freeMaxMediaCapsules = 4
        static let freeMaxVideoMinutes = 2
        static let freeMaxWills = 5
        static let freeFamilyMembers = 1
        static let freeMaxWillModules = 5
        static let freeMaxFamily = 1
        static let freeCloudBackup = false
        static let freeDataExport = false
        static let freeAiAssist = false
        
        // 会员版
        static let premiumMaxCapsules = 30
        static let premiumMaxTextCapsules = 10
        static let premiumMaxAudioCapsules = 10
        static let premiumMaxVideoCapsules = 10
        static let premiumMaxMediaCapsules = 20
        static let premiumMaxVideoMinutes = 5
        static let premiumMaxWills = 999
        static let premiumFamilyMembers = 5
        static let premiumMaxWillModules = 999
        static let premiumMaxFamily = 5
        static let premiumCloudBackup = true
        static let premiumDataExport = true
        static let premiumAiAssist = true
    }
    
    // 服务器配置的限制（运行时覆盖）
    struct ServerLimits {
        var freeMaxCapsules: Int
        var freeMaxTextCapsules: Int
        var freeMaxAudioCapsules: Int
        var freeMaxVideoCapsules: Int
        var freeMaxMediaCapsules: Int
        var freeMaxVideoMinutes: Int
        var freeMaxWillModules: Int
        var freeMaxFamily: Int
        var freeCloudBackup: Bool
        var freeDataExport: Bool
        var freeAiAssist: Bool
        var premiumMaxCapsules: Int
        var premiumMaxTextCapsules: Int
        var premiumMaxAudioCapsules: Int
        var premiumMaxVideoCapsules: Int
        var premiumMaxMediaCapsules: Int
        var premiumMaxVideoMinutes: Int
        var premiumMaxWillModules: Int
        var premiumMaxFamily: Int
        var premiumCloudBackup: Bool
        var premiumDataExport: Bool
        var premiumAiAssist: Bool
    }
    
    // 默认使用编译时常量
    private var serverLimits = ServerLimits(
        freeMaxCapsules: Limits.freeMaxCapsules,
        freeMaxTextCapsules: Limits.freeMaxTextCapsules,
        freeMaxAudioCapsules: Limits.freeMaxAudioCapsules,
        freeMaxVideoCapsules: Limits.freeMaxVideoCapsules,
        freeMaxMediaCapsules: Limits.freeMaxMediaCapsules,
        freeMaxVideoMinutes: Limits.freeMaxVideoMinutes,
        freeMaxWillModules: Limits.freeMaxWillModules,
        freeMaxFamily: Limits.freeMaxFamily,
        freeCloudBackup: Limits.freeCloudBackup,
        freeDataExport: Limits.freeDataExport,
        freeAiAssist: Limits.freeAiAssist,
        premiumMaxCapsules: Limits.premiumMaxCapsules,
        premiumMaxTextCapsules: Limits.premiumMaxTextCapsules,
        premiumMaxAudioCapsules: Limits.premiumMaxAudioCapsules,
        premiumMaxVideoCapsules: Limits.premiumMaxVideoCapsules,
        premiumMaxMediaCapsules: Limits.premiumMaxMediaCapsules,
        premiumMaxVideoMinutes: Limits.premiumMaxVideoMinutes,
        premiumMaxWillModules: Limits.premiumMaxWillModules,
        premiumMaxFamily: Limits.premiumMaxFamily,
        premiumCloudBackup: Limits.premiumCloudBackup,
        premiumDataExport: Limits.premiumDataExport,
        premiumAiAssist: Limits.premiumAiAssist
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
        maxCapsules = isPremium ? serverLimits.premiumMaxCapsules : serverLimits.freeMaxCapsules
        maxTextCapsules = isPremium ? serverLimits.premiumMaxTextCapsules : serverLimits.freeMaxTextCapsules
        maxAudioCapsules = isPremium ? serverLimits.premiumMaxAudioCapsules : serverLimits.freeMaxAudioCapsules
        maxVideoCapsules = isPremium ? serverLimits.premiumMaxVideoCapsules : serverLimits.freeMaxVideoCapsules
        maxMediaCapsules = isPremium ? serverLimits.premiumMaxMediaCapsules : serverLimits.freeMaxMediaCapsules
        maxVideoMinutes = isPremium ? serverLimits.premiumMaxVideoMinutes : serverLimits.freeMaxVideoMinutes
        
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
    func updateFromServer(
        isPremium: Bool,
        memberType: String?,
        memberExpireAt: Date?,
        memberMaxCapsules: Int,
        memberMaxTextCapsules: Int,
        memberMaxAudioCapsules: Int,
        memberMaxVideoCapsules: Int,
        memberMaxVideoMinutes: Int,
        aiAssistEnabled: Bool = false
    ) {
        // 检查是否过期
        if isPremium, let expireAt = memberExpireAt, Date() >= expireAt {
            // 服务器返回已过期状态，降至免费版
            self.isPremium = false
            self.memberType = nil
            self.memberExpireAt = nil
            self.maxCapsules = Limits.freeMaxCapsules
            self.maxTextCapsules = Limits.freeMaxTextCapsules
            self.maxAudioCapsules = Limits.freeMaxAudioCapsules
            self.maxVideoCapsules = Limits.freeMaxVideoCapsules
            self.maxVideoMinutes = Limits.freeMaxVideoMinutes
            self.maxMediaCapsules = Limits.freeMaxMediaCapsules
            self.aiAssistEnabled = false  // 过期时关闭AI辅助
        } else {
            self.isPremium = isPremium
            self.memberType = memberType
            self.memberExpireAt = memberExpireAt
            self.maxCapsules = memberMaxCapsules > 0 ? memberMaxCapsules : (isPremium ? Limits.premiumMaxCapsules : Limits.freeMaxCapsules)
            self.maxTextCapsules = memberMaxTextCapsules > 0 ? memberMaxTextCapsules : (isPremium ? Limits.premiumMaxTextCapsules : Limits.freeMaxTextCapsules)
            self.maxAudioCapsules = memberMaxAudioCapsules > 0 ? memberMaxAudioCapsules : (isPremium ? Limits.premiumMaxAudioCapsules : Limits.freeMaxAudioCapsules)
            self.maxVideoCapsules = memberMaxVideoCapsules > 0 ? memberMaxVideoCapsules : (isPremium ? Limits.premiumMaxVideoCapsules : Limits.freeMaxVideoCapsules)
            // 会员录制时长以服务端「会员默认」为下限，避免库里旧值（如 3）低于产品承诺的会员分钟数
            if isPremium {
                let persisted = memberMaxVideoMinutes > 0 ? memberMaxVideoMinutes : serverLimits.premiumMaxVideoMinutes
                self.maxVideoMinutes = max(persisted, serverLimits.premiumMaxVideoMinutes)
            } else {
                self.maxVideoMinutes = memberMaxVideoMinutes > 0 ? memberMaxVideoMinutes : serverLimits.freeMaxVideoMinutes
            }
            self.maxMediaCapsules = isPremium ? Limits.premiumMaxMediaCapsules : Limits.freeMaxMediaCapsules
            self.aiAssistEnabled = aiAssistEnabled && isPremium  // 仅会员且服务器启用时开启
        }
        
        lastCheckedAt = Date()
        saveToCache()
        
        print("📋 会员状态更新：isPremium=\(self.isPremium), type=\(self.memberType ?? "nil"), expireAt=\(self.memberExpireAt?.description ?? "nil"), aiAssist=\(self.aiAssistEnabled)")
    }

    /// 与 `updateFromServer` 互补：用户在系统「订阅管理」中升降级/切换方案后，由 StoreKit `Transaction` 刷新本地展示与到期时间。
    @MainActor
    func applySubscriptionFromAppleStore(productId: String, expiresAt: Date) {
        isPremium = true
        switch productId {
        case "zhonghuo.month1":
            memberType = "monthly"
        case "zhonghuo.year1":
            memberType = "yearly"
        default:
            break
        }
        memberExpireAt = expiresAt
        maxCapsules = serverLimits.premiumMaxCapsules
        maxTextCapsules = serverLimits.premiumMaxTextCapsules
        maxAudioCapsules = serverLimits.premiumMaxAudioCapsules
        maxVideoCapsules = serverLimits.premiumMaxVideoCapsules
        maxVideoMinutes = serverLimits.premiumMaxVideoMinutes
        maxMediaCapsules = serverLimits.premiumMaxMediaCapsules
        aiAssistEnabled = true
        lastCheckedAt = Date()
        saveToCache()
        print("📱 会员展示已从 StoreKit 同步：productId=\(productId), type=\(memberType ?? "nil"), 到期=\(expiresAt)")
    }
    
    /// ✅ 手动降级会员（当服务器通知过期时调用）
    func deactivateMembership() {
        isPremium = false
        memberType = nil
        memberExpireAt = nil
        maxCapsules = serverLimits.freeMaxCapsules
        maxTextCapsules = serverLimits.freeMaxTextCapsules
        maxAudioCapsules = serverLimits.freeMaxAudioCapsules
        maxVideoCapsules = serverLimits.freeMaxVideoCapsules
        maxMediaCapsules = serverLimits.freeMaxMediaCapsules
        maxVideoMinutes = serverLimits.freeMaxVideoMinutes
        aiAssistEnabled = false  // 关闭AI辅助
        saveToCache()
    }
    
    // MARK: - 功能检查方法
    
    /// 检查是否可以创建胶囊
    func canCreateCapsule(currentCount: Int) -> Bool {
        return currentCount < maxCapsules
    }

    /// 检查是否可以创建指定类型胶囊
    func canCreateCapsule(of type: TimeCapsule.CapsuleType, currentCount: Int) -> Bool {
        return currentCount < capsuleLimit(for: type)
    }
    
    /// 检查是否可以创建媒体胶囊（语音/视频）
    func canCreateMediaCapsule(currentMediaCount: Int) -> Bool {
        return currentMediaCount < maxMediaCapsules
    }
    
    /// 获取剩余可创建胶囊数量
    func remainingCapsules(currentCount: Int) -> Int {
        return max(0, maxCapsules - currentCount)
    }

    /// 获取指定类型胶囊的剩余可创建数量
    func remainingCapsules(of type: TimeCapsule.CapsuleType, currentCount: Int) -> Int {
        return max(0, capsuleLimit(for: type) - currentCount)
    }
    
    /// 获取剩余可创建媒体胶囊数量
    func remainingMediaCapsules(currentMediaCount: Int) -> Int {
        return max(0, maxMediaCapsules - currentMediaCount)
    }

    /// 获取指定类型胶囊的上限
    func capsuleLimit(for type: TimeCapsule.CapsuleType) -> Int {
        switch type {
        case .text:
            return maxTextCapsules
        case .audio, .voice:
            return maxAudioCapsules
        case .video:
            return maxVideoCapsules
        case .image, .sticker:
            return maxCapsules
        }
    }
    
    /// 获取视频录制最大时长（秒）
    func maxVideoRecordingSeconds() -> Int {
        return maxVideoMinutes * 60
    }
    
    /// 获取语音录制最大时长（秒）- 与视频相同
    func maxAudioRecordingSeconds() -> Int {
        return maxVideoMinutes * 60
    }
    
    /// 检查是否可以创建遗嘱模块
    func canCreateWill(currentCount: Int) -> Bool {
        return canCreateCustomWill()
    }

    /// 检查是否可以创建自定义嘱托
    func canCreateCustomWill() -> Bool {
        return isPremium
    }

    /// 检查是否可以一键从云端恢复到本地（会员功能）
    func hasCloudBackup() -> Bool {
        return canRestoreFromCloud()
    }

    /// 检查是否可以一键从云端恢复到本地（会员功能）
    func canRestoreFromCloud() -> Bool {
        return currentCloudRestoreEnabled()
    }

    /// 检查是否有数据导出功能
    func hasDataExport() -> Bool {
        return currentDataExportEnabled()
    }

    /// 检查是否有家庭守护功能
    func canAddFamilyMember(currentCount: Int) -> Bool {
        return currentCount < currentFamilyLimit()
    }

    /// 检查是否有AI辅助功能
    func hasAIAssistance() -> Bool {
        return currentAIAssistanceEnabled()
    }

    /// 检查是否可以分享时光胶囊给家人
    func canShareCapsule() -> Bool {
        return isPremium
    }

    /// 检查是否允许导出数据（会员功能）
    @MainActor
    func canExportData() -> Bool {
        return currentDataExportEnabled()
    }

    /// 当前可创建的遗嘱模块数量
    func currentWillLimit() -> Int {
        return isPremium ? serverLimits.premiumMaxWillModules : serverLimits.freeMaxWillModules
    }

    /// 当前可绑定的家人数量
    func currentFamilyLimit() -> Int {
        return isPremium ? serverLimits.premiumMaxFamily : serverLimits.freeMaxFamily
    }

    /// 当前是否允许一键云端恢复
    func currentCloudRestoreEnabled() -> Bool {
        return isPremium ? serverLimits.premiumCloudBackup : serverLimits.freeCloudBackup
    }

    /// 当前数据导出是否可用
    func currentDataExportEnabled() -> Bool {
        return isPremium ? serverLimits.premiumDataExport : serverLimits.freeDataExport
    }

    /// 当前 AI 辅助是否可用
    func currentAIAssistanceEnabled() -> Bool {
        return isPremium ? serverLimits.premiumAiAssist : serverLimits.freeAiAssist
    }
    
    /// ✅ 从服务器应用会员限制配置
    func applyLimits(
        freeMaxCapsules: Int,
        freeMaxTextCapsules: Int,
        freeMaxAudioCapsules: Int,
        freeMaxVideoCapsules: Int,
        freeMaxMediaCapsules: Int,
        freeMaxVideoMinutes: Int,
        freeMaxWillModules: Int,
        freeMaxFamily: Int,
        freeCloudBackup: Bool,
        freeDataExport: Bool,
        freeAiAssist: Bool,
        premiumMaxCapsules: Int,
        premiumMaxTextCapsules: Int,
        premiumMaxAudioCapsules: Int,
        premiumMaxVideoCapsules: Int,
        premiumMaxMediaCapsules: Int,
        premiumMaxVideoMinutes: Int,
        premiumMaxWillModules: Int,
        premiumMaxFamily: Int,
        premiumCloudBackup: Bool,
        premiumDataExport: Bool,
        premiumAiAssist: Bool
    ) {
        // 更新服务器限制
        self.serverLimits = ServerLimits(
            freeMaxCapsules: freeMaxCapsules,
            freeMaxTextCapsules: freeMaxTextCapsules,
            freeMaxAudioCapsules: freeMaxAudioCapsules,
            freeMaxVideoCapsules: freeMaxVideoCapsules,
            freeMaxMediaCapsules: freeMaxMediaCapsules,
            freeMaxVideoMinutes: freeMaxVideoMinutes,
            freeMaxWillModules: freeMaxWillModules,
            freeMaxFamily: freeMaxFamily,
            freeCloudBackup: freeCloudBackup,
            freeDataExport: freeDataExport,
            freeAiAssist: freeAiAssist,
            premiumMaxCapsules: premiumMaxCapsules,
            premiumMaxTextCapsules: premiumMaxTextCapsules,
            premiumMaxAudioCapsules: premiumMaxAudioCapsules,
            premiumMaxVideoCapsules: premiumMaxVideoCapsules,
            premiumMaxMediaCapsules: premiumMaxMediaCapsules,
            premiumMaxVideoMinutes: premiumMaxVideoMinutes,
            premiumMaxWillModules: premiumMaxWillModules,
            premiumMaxFamily: premiumMaxFamily,
            premiumCloudBackup: premiumCloudBackup,
            premiumDataExport: premiumDataExport,
            premiumAiAssist: premiumAiAssist
        )
        
        // 如果当前是免费版，更新当前限制
        if !isPremium {
            maxCapsules = serverLimits.freeMaxCapsules
            maxTextCapsules = serverLimits.freeMaxTextCapsules
            maxAudioCapsules = serverLimits.freeMaxAudioCapsules
            maxVideoCapsules = serverLimits.freeMaxVideoCapsules
            maxMediaCapsules = serverLimits.freeMaxMediaCapsules
            maxVideoMinutes = serverLimits.freeMaxVideoMinutes
        }
        
        print("✅ 会员限制已从服务器更新")
        print("   免费版：\(freeMaxCapsules)胶囊（文字\(freeMaxTextCapsules)/录音\(freeMaxAudioCapsules)/视频\(freeMaxVideoCapsules)）/\(freeMaxVideoMinutes)分钟")
        print("   会员版：\(premiumMaxCapsules)胶囊（文字\(premiumMaxTextCapsules)/录音\(premiumMaxAudioCapsules)/视频\(premiumMaxVideoCapsules)）/\(premiumMaxVideoMinutes)分钟")
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
        
        return "有效期至：\(expireAt.chineseDateString())"
    }
    
    // MARK: - 缓存
    private func saveToCache() {
        userDefaults.set(isPremium, forKey: "membership.isPremium")
        userDefaults.set(memberType, forKey: "membership.memberType")
        if let expireAt = memberExpireAt {
            userDefaults.set(expireAt.timeIntervalSince1970, forKey: "membership.memberExpireAt")
        }
        userDefaults.set(maxCapsules, forKey: "membership.maxCapsules")
        userDefaults.set(maxTextCapsules, forKey: "membership.maxTextCapsules")
        userDefaults.set(maxAudioCapsules, forKey: "membership.maxAudioCapsules")
        userDefaults.set(maxVideoCapsules, forKey: "membership.maxVideoCapsules")
        userDefaults.set(maxVideoMinutes, forKey: "membership.maxVideoMinutes")
        userDefaults.set(maxMediaCapsules, forKey: "membership.maxMediaCapsules")
    }
    
    private func loadFromCache() {
        isPremium = userDefaults.bool(forKey: "membership.isPremium")
        memberType = userDefaults.string(forKey: "membership.memberType")
        
        if let expireTimestamp = userDefaults.object(forKey: "membership.memberExpireAt") as? TimeInterval {
            memberExpireAt = Date(timeIntervalSince1970: expireTimestamp)
        }
        
        maxCapsules = userDefaults.integer(forKey: "membership.maxCapsules")
        if maxCapsules == 0 { maxCapsules = Limits.freeMaxCapsules }

        maxTextCapsules = userDefaults.integer(forKey: "membership.maxTextCapsules")
        if maxTextCapsules == 0 { maxTextCapsules = Limits.freeMaxTextCapsules }

        maxAudioCapsules = userDefaults.integer(forKey: "membership.maxAudioCapsules")
        if maxAudioCapsules == 0 { maxAudioCapsules = Limits.freeMaxAudioCapsules }

        maxVideoCapsules = userDefaults.integer(forKey: "membership.maxVideoCapsules")
        if maxVideoCapsules == 0 { maxVideoCapsules = Limits.freeMaxVideoCapsules }
        
        maxVideoMinutes = userDefaults.integer(forKey: "membership.maxVideoMinutes")
        if maxVideoMinutes == 0 { maxVideoMinutes = Limits.freeMaxVideoMinutes }

        maxMediaCapsules = userDefaults.integer(forKey: "membership.maxMediaCapsules")
        if maxMediaCapsules == 0 { maxMediaCapsules = Limits.freeMaxMediaCapsules }
    }
    
    // MARK: - 激活会员
    /// - Parameter appleSubscriptionExpiresAt: App Store 返回的订阅到期时间；应始终从购买/交易结果传入，避免用「今天 +1 月/年」与系统真实周期不一致或产生叠加感。
    func activatePremium(type: String = "yearly", appleSubscriptionExpiresAt: Date? = nil) {
        isPremium = true
        memberType = type
        
        if let appleExpires = appleSubscriptionExpiresAt {
            memberExpireAt = appleExpires
        } else {
            switch type {
            case "monthly":
                memberExpireAt = Calendar.current.date(byAdding: .month, value: 1, to: Date())
            case "yearly":
                memberExpireAt = Calendar.current.date(byAdding: .year, value: 1, to: Date())
            default:
                break
            }
        }
        
        switch type {
        case "monthly", "yearly":
            maxCapsules = serverLimits.premiumMaxCapsules
            maxTextCapsules = serverLimits.premiumMaxTextCapsules
            maxAudioCapsules = serverLimits.premiumMaxAudioCapsules
            maxVideoCapsules = serverLimits.premiumMaxVideoCapsules
            maxVideoMinutes = serverLimits.premiumMaxVideoMinutes
        default:
            break
        }
        
        maxMediaCapsules = serverLimits.premiumMaxMediaCapsules
        aiAssistEnabled = true  // 开通会员时自动启用 AI 辅助
        saveToCache()
        
        // IAP 成功路径由调用方携带收据走 activateMembership；此处仅保留无系统日期的兼容/测试分支
        if appleSubscriptionExpiresAt == nil {
            Task {
                await syncMembershipToServer(type: type)
            }
        }
    }
    
    // MARK: - 同步会员到服务器
    @MainActor
    private func syncMembershipToServer(type: String) async {
        let mutation = """
        mutation($memberType: String!, $receipt: String) {
            activateMembership(memberType: $memberType, receipt: $receipt) {
                success
                isPremium
                memberType
                memberExpireAt
                memberMaxCapsules
                memberMaxVideoMinutes
            }
        }
        """
        
        let variables: [String: Any] = [
            "memberType": type,
            "receipt": ""  // 测试模式，无收据
        ]
        
        do {
            let result = try await GraphQLClient.shared.query(mutation, variables: variables)
            if let data = result["data"] as? [String: Any],
               let activation = data["activateMembership"] as? [String: Any],
               let success = activation["success"] as? Bool, success {
                print("✅ 会员激活已同步到服务器")
            } else {
                print("⚠️ 会员激活同步失败，但本地已激活")
            }
        } catch {
            print("❌ 会员激活同步异常：\(error)")
        }
    }
    
    // MARK: - 取消会员（测试用）
    func deactivatePremium() {
        isPremium = false
        memberType = nil
        memberExpireAt = nil
        maxCapsules = Limits.freeMaxCapsules
        maxTextCapsules = Limits.freeMaxTextCapsules
        maxAudioCapsules = Limits.freeMaxAudioCapsules
        maxVideoCapsules = Limits.freeMaxVideoCapsules
        maxVideoMinutes = Limits.freeMaxVideoMinutes
        maxMediaCapsules = Limits.freeMaxMediaCapsules
        saveToCache()
    }
}
