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
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadFromCache()
    }
    
    // MARK: - 从用户数据更新
    func updateFromUserData(_ user: User?) {
        guard let user = user else { return }
        
        isPremium = user.isPremium
        memberType = user.memberType
        memberExpireAt = user.memberExpireAt
        maxCapsules = user.memberMaxCapsules
        maxVideoMinutes = user.memberMaxVideoMinutes
        
        // 更新缓存
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
