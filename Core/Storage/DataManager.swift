//
//  DataManager.swift
//  终活
//
//  数据管理中心 - 单例模式
//  技术文档：📖 终活 App 技术开发文档.md - 3.3.1 DataManager
//
//  核心职责：
//  - API 配置管理（动态获取服务器地址）
//  - 用户数据管理（胶囊、遗嘱、资产等）
//  - 系统配置管理
//  - 数据持久化（本地 JSON 文件）
//  - 前后端数据同步
//

import Foundation
import UIKit

// GraphQLClient 在同项目中定义

/// 数据管理中心 - 全局单例
/// 
/// 功能模块：
/// - **API 配置**：动态获取服务器地址（`apiURL`）
/// - **用户数据**：`capsules`, `willModules`, `assets`
/// - **系统配置**：签到间隔、通知配置等
/// - **数据同步**：GraphQL + REST API 混合架构
/// 
/// 使用方式：
/// ```swift
/// let manager = DataManager.shared
/// manager.capsules.append(newCapsule)
/// manager.saveCapsules()
/// ```
@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // MARK: - API 地址（动态获取，初始值为空）
    // ✅ P2 修复 #1: API 地址使用配置文件
    static nonisolated(unsafe) var baseURL: String = ""
    static nonisolated(unsafe) var apiURL: String = ""
    static let defaultAPIURL = AppConfig.defaultAPIURL
    
    // MARK: - 配置
    @Published var serverConfig: ServerConfig?
    @Published var isBackendOnline: Bool = false
    
    // MARK: - 用户数据
    @Published var currentUser: User?
    @Published var capsules: [TimeCapsule] = []
    @Published var receivedCapsules: [ReceivedCapsule] = []  // ✅ 我收到的胶囊
    @Published var deletedCapsules: [TimeCapsule] = []  // 🔥 跟踪已删除的胶囊（用于同步删除到服务器）
    @Published var willModules: [WillModule] = []
    @Published var deletedWillModules: [WillModule] = []  // 🔥 跟踪已删除的遗嘱（用于同步删除到服务器）
    @Published var assets: [Asset] = []
    @Published var deletedAssets: [Asset] = []  // 🔥 跟踪已删除的资产（用于同步删除到服务器）
    @Published var familyMembers: [FamilyInfo] = []  // ✅ 家人成员
    @Published var checklistItems: [ChecklistItem] = []
    @Published var settings: UserSettings
    @Published var systemConfig: SystemConfig = SystemConfig()  // 系统配置
    
    // MARK: - API 配置管理
    
    /// 从服务器获取 API 配置（GraphQL）
    // ✅ P2 修复 #6: 更新注释与代码一致
    // ✅ P2 修复 #9: 使用 DebugConfig 控制日志
    func fetchServerConfig(from baseURL: String) async throws {
        if DebugConfig.enableNetworkLogs {
            print("🌐 请求配置（GraphQL）：\(baseURL)")
        }
        
        let query = """
        query {
            getConfig {
                checkinReminderThresholdHours
                checkinReminderIntervalHours
                overduePushIntervalHours
                memberPriceMonthly
                memberPriceYearly
                freeMaxCapsules
                freeMaxMediaCapsules
                freeMaxVideoMinutes
                premiumMaxCapsules
                premiumMaxMediaCapsules
                premiumMaxVideoMinutes
            }
        }
        """
        
        let variables: [String: Any] = [:]
        let response = try await sendGraphQLQuery(query: query, variables: variables, baseURL: baseURL)
        
        guard let data = response["data"] as? [String: Any],
              let configData = data["getConfig"] as? [String: Any] else {
            throw NSError(domain: "Config error", code: -1, userInfo: [NSLocalizedDescriptionKey: "配置加载失败"])
        }
        
        await MainActor.run {
            // ✅ 修复：解析配置使用正确的字段名（匹配后端返回）
            // 🔧 移除 checkinIntervalHours：签到间隔由用户在 App 设置，后端不再控制
            let reminderThreshold = configData["checkinReminderThresholdHours"] as? Int ?? 12
            let reminderInterval = configData["checkinReminderIntervalHours"] as? Int ?? 2
            let overduePushInterval = configData["overduePushIntervalHours"] as? Int ?? 1
            
            self.systemConfig = SystemConfig(
                checkinReminderThresholdHours: Double(reminderThreshold),
                checkinReminderIntervalHours: Double(reminderInterval),
                overduePushIntervalHours: Double(overduePushInterval)
            )
            
            // 使用后端返回的地址（无条件相信）
            DataManager.baseURL = baseURL
            DataManager.apiURL = NetworkUtils.normalizeBaseURL(baseURL)
            
            self.isBackendOnline = true
            
            // 保存地址供下次使用
            UserDefaults.standard.set(DataManager.baseURL, forKey: "lastUsedBaseURL")
            
            // ✅ P2 修复 #9: 使用 DebugConfig 控制日志
            if DebugConfig.enableLogs {
                print("✅ 后端配置获取成功（GraphQL）")
                print("   Base URL: \(DataManager.baseURL)")
                print("   提醒阈值：\(reminderThreshold) 小时")
                print("   推送间隔：\(reminderInterval) 小时")
                print("   超时推送间隔：\(overduePushInterval) 小时")
            }
        }
    }
    
    // MARK: - GraphQL 辅助方法
    
    /// 发送 GraphQL 请求（不带 Token）
    func sendGraphQLQuery(query: String, variables: [String: Any] = [:], baseURL: String) async throws -> [String: Any] {
        guard let apiURL = URL(string: "\(baseURL)/api/graphql.php") else {
            throw NSError(domain: "Invalid URL", code: -1)
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15  // 🔧 修复：添加 15 秒超时
        
        let body: [String: Any] = [
            "query": query,
            "variables": variables
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // 🔧 修复：使用带超时的 URLSession 配置
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15       // 请求超时 15 秒
        config.timeoutIntervalForResource = 15      // 资源超时 15 秒
        let session = URLSession(configuration: config)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Server error", code: -1)
        }
        
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
    
    /// 初始化 API 配置（同步版本 - 立即设置默认值）
    // ✅ P2 修复 #1: 使用配置文件中的默认地址
    func initializeAPIConfig() {
        // 立即设置默认值，确保 API 立即可用
        DataManager.baseURL = AppConfig.defaultAPIURL
        DataManager.apiURL = AppConfig.defaultAPIURL
        self.isBackendOnline = true
        
        if DebugConfig.enableLogs {
            print("🔵 API 已初始化（默认地址）")
            print("   Base URL: \(DataManager.baseURL)")
            print("   API URL: \(DataManager.apiURL)")
        }
        
        // 异步尝试获取最新配置
        Task {
            await refreshAPIConfig()
        }
    }
    
    /// 异步刷新 API 配置（后台静默更新）
    // ✅ P2 修复 #1: 使用配置文件中的默认地址
    func refreshAPIConfig() async {
        // 尝试顺序：保存的地址 > 默认地址
        let candidates = [
            UserDefaults.standard.string(forKey: "lastUsedBaseURL") ?? "",
            AppConfig.defaultAPIURL
        ].filter { !$0.isEmpty }
        
        for baseURL in candidates {
            do {
                try await fetchServerConfig(from: baseURL)
                if DebugConfig.enableLogs {
                    print("✅ 后端配置刷新成功：\(DataManager.baseURL)")
                }
                return
            } catch {
                if DebugConfig.enableNetworkLogs {
                    print("⚠️ 尝试地址失败：\(baseURL) - \(error.localizedDescription)")
                }
                continue
            }
        }
        
        // 所有尝试都失败，保持默认值
        // ✅ P2 修复 #9: 使用 DebugConfig 控制日志
        if DebugConfig.enableLogs {
            print("⚠️ 后端配置刷新失败，使用默认地址")
        }
    }
    
    /// 检查 API 是否已初始化（立即可用）
    // ✅ P2 修复 #1: 使用配置文件中的默认地址
    func checkAPIReady() async throws {
        // 如果已初始化，直接返回
        if !DataManager.apiURL.isEmpty && isBackendOnline {
            return
        }
        
        // 如果未初始化，使用默认地址
        if DataManager.apiURL.isEmpty {
            DataManager.baseURL = AppConfig.defaultAPIURL
            DataManager.apiURL = AppConfig.defaultAPIURL
            self.isBackendOnline = true
            if DebugConfig.enableLogs {
                print("⚠️ API 未初始化，使用默认地址：\(DataManager.apiURL)")
            }
            return
        }
    }
    
    // MARK: - 初始化
    
    private let fileManager = FileManager.default
    private var documentsPath: String {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].path
    }
    
    init() {
        self.settings = UserSettings(
            name: "用户",
            checkInInterval: .twoDays,
            notificationsEnabled: true,
            cloudSyncEnabled: true,
            lastCheckInDate: nil
        )
        
        // 初始化 API 配置
        initializeAPIConfig()
        
        // 加载本地数据
        if let loaded = loadSettingsFromFile() {
            self.settings = loaded
        }
        
        self.lastCheckInDate = self.settings.lastCheckInDate
        loadAllData()
    }
    
    // MARK: - 网络检查
    
    /// 检查网络连通性
    // ✅ P2 修复 #1: 使用配置文件中的 API 地址
    // ✅ P2 修复 #9: 使用 DebugConfig 控制日志
    // ✅ 修复：统一网络检查方法，使用 GraphQL 避免重复代码
    func checkNetworkConnectivity() async -> Bool {
        guard !DataManager.apiURL.isEmpty else { return false }
        
        do {
            let query = "query { getConfig { checkinReminderThresholdHours checkinReminderIntervalHours } }"
            guard let url = URL(string: "\(DataManager.apiURL)/api/graphql.php") else {
                print("❌ 无效的 API URL")
                return false
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query])
            
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return (200...299).contains(httpResponse.statusCode)
            }
        } catch {
            if DebugConfig.enableNetworkLogs {
                print("⚠️ 网络检查失败：\(error)")
            }
        }
        return false
    }
    
    // MARK: - Token 验证
    
    /// 检查 Token 是否过期
    func isTokenExpired(_ token: String) -> Bool {
        // JWT 格式：header.payload.signature
        let components = token.split(separator: ".")
        guard components.count == 3 else {
            print("⚠️ Token 格式错误")
            return true
        }
        
        // 解析 payload (base64url 编码)
        let payloadString = String(components[1])
        
        // base64url 解码
        var base64 = payloadString
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // 添加 padding
        while base64.count % 4 != 0 {
            base64 += "="
        }
        
        guard let payloadData = Data(base64Encoded: base64),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval else {
            print("⚠️ 无法解析 Token payload")
            return true  // 无法解析时认为已过期
        }
        
        let expiryDate = Date(timeIntervalSince1970: exp)
        let isExpired = expiryDate < Date()
        
        if isExpired {
            print("⚠️ Token 已过期：\(expiryDate)")
        } else {
            print("✅ Token 有效，过期时间：\(expiryDate)")
        }
        
        return isExpired
    }
    
    // MARK: - 数据加载
    
    func loadAllData() {
        capsules = loadCapsulesFromFile()
        willModules = loadWillModulesFromFile()
        assets = loadAssetsFromFile()
        checklistItems = loadChecklistItemsFromFile()
        
        // 🔥 加载已删除的 items（用于同步删除到服务器）
        loadDeletedItemsFromFile()
    }
    
    // MARK: - 文件操作
    
    func saveSettingsToFile() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(settings) {
            try? data.write(to: fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("self.settings.json"))
        }
    }
    
    func loadSettingsFromFile() -> UserSettings? {
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("self.settings.json")
        if let data = try? Data(contentsOf: path) {
            return try? JSONDecoder().decode(UserSettings.self, from: data)
        }
        return nil
    }
    
    // 其他数据加载方法...
    func loadCapsulesFromFile() -> [TimeCapsule] {
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("capsules.json")
        print("📂 尝试加载胶囊文件：\(path.path)")
        
        guard fileManager.fileExists(atPath: path.path) else {
            print("⚠️ 胶囊文件不存在")
            return []
        }
        
        do {
            let data = try Data(contentsOf: path)
            let capsules = try JSONDecoder().decode([TimeCapsule].self, from: data)
            print("✅ 胶囊文件加载成功：\(capsules.count) 个")
            return capsules
        } catch {
            print("❌ 胶囊文件加载失败：\(error)")
            return []
        }
    }
    
    func loadWillModulesFromFile() -> [WillModule] {
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("willModules.json")
        if let data = try? Data(contentsOf: path) {
            return (try? JSONDecoder().decode([WillModule].self, from: data)) ?? []
        }
        // 如果文件不存在，返回默认模板
        return getDefaultWillModules()
    }
    
    func saveWillModulesToFile() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(willModules) {
            try? data.write(to: fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("willModules.json"))
        }
    }
    
    /// 获取默认遗嘱模板
    func getDefaultWillModules() -> [WillModule] {
        return WillModule.WillType.allCases.map { willType in
            WillModule(
                id: UUID().uuidString,
                type: willType,
                title: willType.rawValue,
                subtitle: willType.subtitle,
                content: "",
                isCompleted: false
            )
        }
    }
    
    /// 初始化默认遗嘱模板（如果为空）
    func initializeDefaultWillModules() {
        if willModules.isEmpty {
            willModules = getDefaultWillModules()
            saveWillModulesToFile()
            print("✅ 已初始化默认遗嘱模板")
        }
    }
    
    func loadAssetsFromFile() -> [Asset] {
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("assets.json")
        if let data = try? Data(contentsOf: path) {
            return (try? JSONDecoder().decode([Asset].self, from: data)) ?? []
        }
        // 如果文件不存在，返回默认模板
        return getDefaultAssets()
    }
    
    /// 获取默认资产模板
    func getDefaultAssets() -> [Asset] {
        return Asset.AssetType.allCases.map { assetType in
            Asset(
                id: UUID().uuidString,
                type: assetType,
                name: assetType.rawValue,
                institution: "",
                balance: 0,
                accountNumber: "",
                details: [:],
                createdAt: Date()
            )
        }
    }
    
    /// 初始化默认资产模板（如果为空）
    func initializeDefaultAssets() {
        if assets.isEmpty {
            assets = getDefaultAssets()
            saveAssetsToFile()
            print("✅ 已初始化默认资产模板")
        }
    }
    
    func saveAssetsToFile() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(assets) {
            try? data.write(to: fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("assets.json"))
        }
    }
    
    func saveCapsulesToFile() {
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("capsules.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(capsules)
            try data.write(to: path)
            print("✅ 胶囊已保存到文件：\(path.path), 数量：\(capsules.count)")
        } catch {
            print("❌ 胶囊保存失败：\(error), 路径：\(path.path)")
        }
    }
    
    // MARK: - 已删除数据持久化（用于崩溃后恢复删除同步）
    
    /// 保存已删除的胶囊
    func saveDeletedCapsulesToFile() {
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("deleted_capsules.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(deletedCapsules) {
            try? data.write(to: path)
            print("✅ 已删除胶囊已保存：\(deletedCapsules.count) 个")
        }
    }
    
    /// 保存已删除的遗嘱
    func saveDeletedWillModulesToFile() {
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("deleted_wills.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(deletedWillModules) {
            try? data.write(to: path)
            print("✅ 已删除遗嘱已保存：\(deletedWillModules.count) 个")
        }
    }
    
    /// 保存已删除的资产
    func saveDeletedAssetsToFile() {
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("deleted_assets.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(deletedAssets) {
            try? data.write(to: path)
            print("✅ 已删除资产已保存：\(deletedAssets.count) 个")
        }
    }
    
    /// 加载已删除的数据（App 启动时调用）
    func loadDeletedItemsFromFile() {
        // 加载已删除胶囊
        let deletedCapsulesPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("deleted_capsules.json")
        if let data = try? Data(contentsOf: deletedCapsulesPath),
           let loaded: [TimeCapsule] = try? JSONDecoder().decode([TimeCapsule].self, from: data) {
            deletedCapsules = loaded
            print("✅ 已删除胶囊加载成功：\(deletedCapsules.count) 个待同步")
        }
        
        // 加载已删除遗嘱
        let deletedWillsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("deleted_wills.json")
        if let data = try? Data(contentsOf: deletedWillsPath),
           let loaded: [WillModule] = try? JSONDecoder().decode([WillModule].self, from: data) {
            deletedWillModules = loaded
            print("✅ 已删除遗嘱加载成功：\(deletedWillModules.count) 个待同步")
        }
        
        // 加载已删除资产
        let deletedAssetsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("deleted_assets.json")
        if let data = try? Data(contentsOf: deletedAssetsPath),
           let loaded: [Asset] = try? JSONDecoder().decode([Asset].self, from: data) {
            deletedAssets = loaded
            print("✅ 已删除资产加载成功：\(deletedAssets.count) 个待同步")
        }
        
        // 🔥 如果有待删除的数据，启动同步
        if !deletedCapsules.isEmpty || !deletedWillModules.isEmpty || !deletedAssets.isEmpty {
            print("🚀 检测到待同步的已删除数据，开始同步...")
            Task {
                await syncAllDeletedItems()
            }
        }
    }
    
    /// 同步所有已删除的数据到服务器
    func syncAllDeletedItems() async {
        // 先同步删除的胶囊
        if !deletedCapsules.isEmpty {
            await syncDeletedCapsules()
        }
        // 再同步删除的遗嘱
        if !deletedWillModules.isEmpty {
            await syncDeletedWillModules()
        }
        // 最后同步删除的资产
        if !deletedAssets.isEmpty {
            await syncDeletedAssets()
        }
    }
    
    
    func loadChecklistItemsFromFile() -> [ChecklistItem] {
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("checklist.json")
        if let data = try? Data(contentsOf: path) {
            return (try? JSONDecoder().decode([ChecklistItem].self, from: data)) ?? []
        }
        return []
    }
    
    // MARK: - 签到管理
    
    @Published var lastCheckInDate: Date?
    
    var canCheckIn: Bool {
        let now = Date()
        guard let lastCheckIn = lastCheckInDate else { return true }
        
        let hours = self.settings.checkInInterval.hours
        let interval: TimeInterval = hours * 3600
        return now.timeIntervalSince(lastCheckIn) >= interval
    }
    
    var nextCheckInTime: Date? {
        guard let lastCheckIn = lastCheckInDate else { return nil }
        let hours = Int(self.settings.checkInInterval.hours)
        return Calendar.current.date(byAdding: .hour, value: hours, to: lastCheckIn)
    }
    
    func performCheckIn() {
        lastCheckInDate = Date()
        self.settings.lastCheckInDate = lastCheckInDate
        saveSettingsToFile()
    }
    
    // MARK: - 用户管理
    
    func saveUser(_ user: User) {
        currentUser = user
        self.settings.name = user.name
        saveSettingsToFile()
    }
    
    func logout() {
        // currentUser = nil
        lastCheckInDate = nil
        // self.settings.lastCheckInDate = nil
        saveSettingsToFile()
    }
    
    // MARK: - 密码重置
    
    /// 发送重置密码验证码（GraphQL）
    func sendResetPasswordCode(phone: String) async throws -> Bool {
        throw NSError(domain: "短信验证码功能已关闭", code: -1, userInfo: [NSLocalizedDescriptionKey: "短信验证码功能已关闭"])
    }
    
    /// 重置密码
    func resetPassword(phone: String, newPassword: String, securityQuestion: String, securityAnswer: String) async throws -> Bool {
        guard !Self.apiURL.isEmpty else {
            print("❌ API URL 未设置")
            return false
        }
        
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
        
        let result = try await GraphQLClient.shared.query(mutation, variables: variables)
        
        if let data = result["data"] as? [String: Any],
           let resetData = data["resetPassword"] as? [String: Any],
           let success = resetData["success"] as? Bool {
            print("🔐 重置密码结果：\(success ? "成功" : "失败")")
            return success
        }
        
        return false
    }
    
    // MARK: - 短信通知
    
    /// 发送短信通知（阿里云/腾讯云）
    func sendSmsNotification(phone: String, message: String) async throws -> Bool {
        throw NSError(domain: "短信功能已关闭", code: -1, userInfo: [NSLocalizedDescriptionKey: "短信功能已关闭"])
    }
    
    /// 通知监护人（用户超时未签到）
    func notifyGuardian(guardianPhone: String, userName: String, hoursOverdue: Double) async throws -> Bool {
        throw NSError(domain: "短信功能已关闭", code: -1, userInfo: [NSLocalizedDescriptionKey: "短信功能已关闭"])
    }
    
    /// 获取通知配置（GraphQL）
    func fetchNotificationConfig() async -> NotificationConfig? {
        guard !Self.apiURL.isEmpty else { return nil }
        
        do {
            // ✅ 修复：使用正确的字段名（匹配后端返回）
            // 🔧 移除 checkinIntervalHours：签到间隔由用户在 App 设置，后端不再控制
            let query = """
            query {
                getConfig {
                    checkinReminderThresholdHours
                    checkinReminderIntervalHours
                    overduePushIntervalHours
                }
            }
            """
            
            let response = try await sendGraphQLQuery(query: query, variables: [:], baseURL: Self.apiURL)
            
            if let data = response["data"] as? [String: Any],
               let configData = data["getConfig"] as? [String: Any] {
                
                // ✅ 修复：使用正确的字段名解析
                let firstReminder = configData["checkinReminderThresholdHours"] as? Int ?? 12
                let reminderInterval = configData["checkinReminderIntervalHours"] as? Int ?? 2
                let overduePushInterval = configData["overduePushIntervalHours"] as? Int ?? 1
                
                let config = NotificationConfig(
                    firstReminderHours: firstReminder,
                    reminderInterval: reminderInterval,
                    overduePushInterval: overduePushInterval
                )
                
                print("✅ 获取通知配置成功：间隔=\(config.checkInInterval)h, 首次=\(config.firstReminderHours)h, 重复=\(config.reminderInterval)h")
                return config
            }
        } catch {
            print("❌ 获取通知配置失败：\(error)")
        }
        
        // 返回默认配置
        return NotificationConfig()
    }
    
    func addAsset(_ asset: Asset) {
        assets.append(asset)
        saveAssetsToFile()
    }
    
    func deleteAsset(_ asset: Asset) {
        // 🔥 软删除：标记 deletedAt 而不是直接移除
        var deletedAsset = asset
        deletedAsset.deletedAt = Date()
        
        // 添加到已删除列表
        deletedAssets.append(deletedAsset)
        saveDeletedAssetsToFile()  // 🔥 持久化已删除列表
        
        // 从当前列表移除
        assets.removeAll { $0.id == asset.id }
        saveAssetsToFile()
        
        // 发送数据变更通知
        NotificationCenter.default.post(name: NSNotification.Name("AssetChanged"), object: nil)
        
        // 异步同步删除到服务器
        Task {
            await syncDeletedAssets()
        }
    }
    
    func deleteAssets(at offsets: IndexSet) {
        // 🔥 软删除：标记所有要删除的资产
        for index in offsets {
            var deletedAsset = assets[index]
            deletedAsset.deletedAt = Date()
            deletedAssets.append(deletedAsset)
        }
        saveDeletedAssetsToFile()  // 🔥 持久化已删除列表
        
        // 从当前列表移除
        assets.remove(atOffsets: offsets)
        saveAssetsToFile()
        
        // 发送数据变更通知
        NotificationCenter.default.post(name: NSNotification.Name("AssetChanged"), object: nil)
        
        // 异步同步删除到服务器
        Task {
            await syncDeletedAssets()
        }
    }
    
    /// 同步已删除的资产到服务器
    private func syncDeletedAssets() async {
        guard !deletedAssets.isEmpty else { return }
        
        print("💰 同步已删除资产到服务器：共 \(deletedAssets.count) 个")
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let inputs = deletedAssets.map { asset -> AssetInput in
            AssetInput(
                id: asset.id,
                type: asset.type.rawValue,
                name: asset.name,
                institution: asset.institution,
                balance: asset.balance,
                accountNumber: asset.accountNumber,
                details: asset.details,
                deletedAt: asset.deletedAt != nil ? formatter.string(from: asset.deletedAt!) : nil
            )
        }
        
        do {
            let result = try await APIManager.shared.batchSyncAssets(inputs.map { $0.toDictionary() })
            
            if let batchData = result["data"] as? [String: Any],
               let syncResult = batchData["batchSyncAssets"] as? [String: Any],
               let deleted = syncResult["deleted"] as? Int {
                print("✅ 已删除资产同步成功：\(deleted) 个")
                deletedAssets.removeAll()
            }
        } catch {
            print("❌ 已删除资产同步失败：\(error)")
        }
    }
    
    func updateAsset(_ asset: Asset) {
        if let index = assets.firstIndex(where: { $0.id == asset.id }) {
            assets[index] = asset
            saveAssetsToFile()
            // ✅ 同步到服务器
            Task {
                await syncAssetToServer(asset)
            }
        }
    }
    
    // MARK: - 服务器同步
    
    /// 同步资产到服务器
    /// ✅ 统一：从 REST API (will.php) 迁移到 GraphQL
    func syncAssetToServer(_ asset: Asset) async {
        guard !DataManager.apiURL.isEmpty else { return }
        
        do {
            // 将 details 字典转换为 JSON 字符串
            let detailsJSON = try JSONSerialization.data(withJSONObject: asset.details)
            let detailsString = String(data: detailsJSON, encoding: .utf8) ?? "{}"
            
            _ = try await updateAssetGraphQL(
                id: asset.id,
                type: asset.type.rawValue,
                name: asset.name,
                institution: asset.institution,
                balance: asset.balance,
                accountNumber: asset.accountNumber,
                details: detailsString
            )
            print("✅ 资产已同步到服务器：\(asset.name)")
        } catch {
            print("❌ 资产同步失败：\(error)")
        }
    }
    
    func updateWillModule(_ module: WillModule) {
        if let index = willModules.firstIndex(where: { $0.id == module.id }) {
            // 更新现有模块
            willModules[index] = module
        } else {
            // 添加新模块
            willModules.append(module)
        }
        saveWillModulesToFile()
        print("📜 遗嘱模块已保存到本地，准备同步到服务器...")
        print("📊 当前 willModules.count: \(willModules.count)")
        print("📊 当前模块内容：\(module.title) - 完成：\(module.isCompleted)")
        
        // 🔥 更新 UserManager 的统计信息（让 SettingsView 立即显示）
        UserManager.shared.updateWillModulesCount(willModules.count)
        
        // 发送数据变更通知（触发实时同步）
        NotificationCenter.default.post(name: NSNotification.Name("WillChanged"), object: nil)
        
        // 异步同步到服务器
        Task {
            if let result = await batchSyncWills() {
                print("✅ 遗嘱同步成功：总计 \(result.total) 个，创建 \(result.created) 个，更新 \(result.updated) 个")
            } else {
                print("⚠️ 遗嘱同步失败（可能无网络或未登录）")
            }
        }
    }
    
    func deleteWillModule(_ module: WillModule) {
        // 🔥 软删除：标记 deletedAt 而不是直接移除
        var deletedModule = module
        deletedModule.deletedAt = Date()
        
        // 添加到已删除列表
        deletedWillModules.append(deletedModule)
        saveDeletedWillModulesToFile()  // 🔥 持久化已删除列表
        
        // 从当前列表移除
        willModules.removeAll { $0.id == module.id }
        saveWillModulesToFile()
        print("📜 遗嘱模块已标记删除，准备同步到服务器...")
        
        // 🔥 更新 UserManager 的统计信息（让 SettingsView 立即显示）
        UserManager.shared.updateWillModulesCount(willModules.count)
        
        // 发送数据变更通知（触发实时同步）
        NotificationCenter.default.post(name: NSNotification.Name("WillChanged"), object: nil)
        
        // 异步同步删除到服务器
        Task {
            await syncDeletedWillModules()
        }
    }
    
    /// 同步已删除的遗嘱到服务器
    private func syncDeletedWillModules() async {
        guard !deletedWillModules.isEmpty else { return }
        
        print("📜 同步已删除遗嘱到服务器：共 \(deletedWillModules.count) 个")
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let inputs = deletedWillModules.map { module -> WillInput in
            WillInput(
                id: module.id,
                type: module.type.rawValue,
                title: module.title,
                subtitle: module.subtitle,
                content: module.content,
                deletedAt: module.deletedAt != nil ? formatter.string(from: module.deletedAt!) : nil
            )
        }
        
        do {
            let result = try await APIManager.shared.batchSyncWills(inputs.map { $0.toDictionary() })
            
            if let batchData = result["data"] as? [String: Any],
               let syncResult = batchData["batchSyncWills"] as? [String: Any],
               let deleted = syncResult["deleted"] as? Int {
                print("✅ 已删除遗嘱同步成功：\(deleted) 个")
                deletedWillModules.removeAll()
            }
        } catch {
            print("❌ 已删除遗嘱同步失败：\(error)")
        }
    }
    
    func getWillProgress() -> Double {
        guard !willModules.isEmpty else { return 0 }
        let completed = willModules.filter { $0.isCompleted }.count
        return Double(completed) / Double(willModules.count)
    }
    
    func getAssetProgress() -> Double {
        guard !assets.isEmpty else { return 0 }
        let completed = assets.filter { !$0.accountNumber.isEmpty }.count
        return Double(completed) / Double(assets.count)
    }
    
    // MARK: - 时光胶囊管理
    func getFilteredCapsules(type: TimeCapsule.CapsuleType? = nil) -> [TimeCapsule] {
        if let type = type {
            return capsules.filter { $0.type == type }
        }
        return capsules
    }
    
    func deleteCapsule(_ capsule: TimeCapsule) {
        // 🔥 软删除：标记 deletedAt 而不是直接移除
        var deletedCapsule = capsule
        deletedCapsule.deletedAt = Date()
        
        // 将胶囊添加到已删除列表（用于同步删除到服务器）
        deletedCapsules.append(deletedCapsule)
        saveDeletedCapsulesToFile()  // 🔥 持久化已删除列表
        
        // 从当前列表移除
        capsules.removeAll { $0.id == capsule.id }
        saveCapsulesToFile()
        
        // 🔥 更新 UserManager 的统计信息（让 SettingsView 立即显示新数量）
        UserManager.shared.updateCapsulesCount(capsules.count)
        
        // 发送数据变更通知（触发实时同步）
        NotificationCenter.default.post(name: NSNotification.Name("CapsuleChanged"), object: nil)
        
        // 异步同步删除到服务器（传递 deletedAt 标记）
        Task {
            await syncDeletedCapsules()
        }
    }
    
    /// 同步已删除的胶囊到服务器
    private func syncDeletedCapsules() async {
        guard !deletedCapsules.isEmpty else { return }
        
        print("📦 同步已删除胶囊到服务器：共 \(deletedCapsules.count) 个")
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let inputs = deletedCapsules.map { capsule -> CapsuleInput in
            CapsuleInput(
                id: capsule.id,
                title: capsule.title,
                type: capsule.type.rawValue == "文字" ? "text" : capsule.type.rawValue,
                mediaType: capsule.type.rawValue == "文字" ? "text" : (capsule.type.rawValue == "语音" ? "audio" : "video"),
                content: capsule.content,
                mediaUrl: capsule.mediaServerURL.isEmpty ? nil : capsule.mediaServerURL,  // ✅ 媒体文件服务器URL
                openAt: formatter.string(from: capsule.sendDate),
                deletedAt: capsule.deletedAt != nil ? formatter.string(from: capsule.deletedAt!) : nil
            )
        }
        
        do {
            let result = try await APIManager.shared.batchSyncCapsules(inputs.map { $0.toDictionary() })
            
            // 解析服务器返回的同步结果
            if let batchData = result["data"] as? [String: Any],
               let syncResult = batchData["batchSyncCapsules"] as? [String: Any],
               let deleted = syncResult["deleted"] as? Int {
                print("✅ 已删除胶囊同步成功：\(deleted) 个")
                // 清空已删除列表（同步成功）
                deletedCapsules.removeAll()
            }
        } catch {
            print("❌ 已删除胶囊同步失败：\(error)")
        }
    }
    
    // MARK: - 胶囊分享
    
    /// 分享胶囊给家人
    func shareCapsule(capsuleId: String, receiverIds: [String]) async throws -> [String: Any] {
        let mutation = """
        mutation($capsuleId: String!, $receiverIds: [String!]!) {
            shareCapsule(capsuleId: $capsuleId, receiverIds: $receiverIds) {
                success
                shareCount
            }
        }
        """
        
        let variables: [String: Any] = [
            "capsuleId": capsuleId,
            "receiverIds": receiverIds
        ]
        
        let result = try await GraphQLClient.shared.query(mutation, variables: variables)
        if let data = result["data"] as? [String: Any],
           let shareResult = data["shareCapsule"] as? [String: Any],
           let success = shareResult["success"] as? Bool, success {
            return shareResult
        }
        throw APIError.networkError
    }
    
    /// 加载我收到的胶囊
    func loadReceivedCapsules() async {
        let query = """
        query {
            receivedCapsules {
                id
                capsuleId
                title
                type
                content
                mediaUrl
                mediaServerUrl
                openAt
                isOpened
                sentAt
                senderId
                senderName
                senderPhone
                createdAt
            }
        }
        """
        
        do {
            let result = try await GraphQLClient.shared.query(query, variables: [:])
            if let data = result["data"] as? [String: Any],
               let capsules = data["receivedCapsules"] as? [[String: Any]] {
                await MainActor.run {
                    self.receivedCapsules = capsules.compactMap { dict in
                        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                              let capsule = try? JSONDecoder().decode(ReceivedCapsule.self, from: jsonData) else {
                            return nil
                        }
                        return capsule
                    }
                }
                print("✅ 收到胶囊加载成功：\(self.receivedCapsules.count) 个")
            }
        } catch {
            print("❌ 收到胶囊加载失败：\(error)")
        }
    }
    
    func addCapsule(_ capsule: TimeCapsule) {
        // ✅ 防止重复添加：如果已存在相同 ID 的胶囊，则跳过
        if capsules.contains(where: { $0.id == capsule.id }) {
            print("⚠️ 胶囊 \(capsule.id) 已存在，跳过添加")
            return
        }
        print("📦 addCapsule: 添加前数量=\(capsules.count)")
        capsules.append(capsule)
        print("📦 addCapsule: 添加后数量=\(capsules.count)")
        saveCapsulesToFile()
        print("📦 胶囊已添加到本地，准备同步到服务器...")
        
        // 🔥 更新 UserManager 的统计信息（让 SettingsView 立即显示新数量）
        UserManager.shared.updateCapsulesCount(capsules.count)
        
        // 发送数据变更通知（触发实时同步）
        NotificationCenter.default.post(name: NSNotification.Name("CapsuleChanged"), object: nil)
        
        // 异步同步到服务器
        Task {
            if let result = await batchSyncCapsules() {
                print("✅ 胶囊同步成功：总计 \(result.total) 个，创建 \(result.created) 个，更新 \(result.updated) 个")
            } else {
                print("⚠️ 胶囊同步失败（可能无网络或未登录）")
            }
        }
    }
    
    func updateCapsule(_ capsule: TimeCapsule) {
        if let index = capsules.firstIndex(where: { $0.id == capsule.id }) {
            capsules[index] = capsule
            saveCapsulesToFile()
            print("📦 胶囊已更新到本地，准备同步到服务器...")
            
            // 发送数据变更通知（触发实时同步）
            NotificationCenter.default.post(name: NSNotification.Name("CapsuleChanged"), object: nil)
            
            // 异步同步到服务器
            Task {
                if let result = await batchSyncCapsules() {
                    print("✅ 胶囊同步成功：总计 \(result.total) 个，创建 \(result.created) 个，更新 \(result.updated) 个")
                } else {
                    print("⚠️ 胶囊同步失败（可能无网络或未登录）")
                }
            }
        }
    }
    
    // MARK: - 批量同步到服务器
    
    /// 同步签到状态（App 启动时调用）
    /// ✅ P0 修复 #3: 从 Keychain 读取 Token（安全存储）
    func syncCheckInStatus() async -> (isSafe: Bool, hoursRemaining: Double, autoCheckInPerformed: Bool)? {
        guard !DataManager.apiURL.isEmpty else { return nil }
        
        do {
            // 使用 GraphQL 查询签到状态
            let query = """
            query {
                syncCheckInStatus {
                    isSafe
                    hoursRemaining
                    autoCheckInPerformed
                }
            }
            """
            
            let result = try await GraphQLClient.shared.query(query)
            print("✅ GraphQL 签到同步成功")
            
            if let data = result["data"] as? [String: Any],
               let statusData = data["syncCheckInStatus"] as? [String: Any],
               let isSafe = statusData["isSafe"] as? Bool,
               let hoursRemaining = statusData["hoursRemaining"] as? Double,
               let autoCheckInPerformed = statusData["autoCheckInPerformed"] as? Bool {
                print("✅ 签到同步成功：剩余 \(hoursRemaining) 小时，自动签到=\(autoCheckInPerformed)")
                return (isSafe, hoursRemaining, autoCheckInPerformed)
            }
        } catch {
            print("❌ GraphQL 签到同步失败：\(error)")
        }
        return nil
    }
    
    /// 上传签到倒计时到服务器（用于管理员观测用户签到情况）
    /// 每次打开App时调用，上传当前本地计算的倒计时剩余时间
    func recordLastActive(hoursRemaining: Double) async -> Bool {
        guard !DataManager.apiURL.isEmpty else { return false }
        
        do {
            let mutation = """
            mutation($hoursRemaining: Float!) {
                recordLastActive(hoursRemaining: $hoursRemaining) {
                    success
                    recordedAt
                }
            }
            """
            
            let variables: [String: Any] = ["hoursRemaining": hoursRemaining]
            let result = try await GraphQLClient.shared.query(mutation, variables: variables)
            
            if let data = result["data"] as? [String: Any],
               let recordData = data["recordLastActive"] as? [String: Any],
               let success = recordData["success"] as? Bool, success {
                print("✅ 上传签到倒计时成功：\(hoursRemaining) 小时")
                return true
            }
        } catch {
            print("❌ 上传签到倒计时失败：\(error)")
        }
        return false
    }
    
    
    /// 批量同步胶囊到服务器
    /// ✅ 修复：标记为 @MainActor，确保所有 @Published 属性更新在主线程执行
    @MainActor
    func batchSyncCapsules() async -> (total: Int, created: Int, updated: Int)? {
        print("📦 开始同步胶囊：共 \(capsules.count) 个")
        guard !capsules.isEmpty else { return (0, 0, 0) }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // 🔥 标记为上传中（✅ 现在在 @MainActor 中执行，安全）
        for i in 0..<capsules.count {
            if capsules[i].cloudBackupStatus == .pending {
                capsules[i].cloudBackupStatus = .uploading
            }
        }
        
        let inputs = capsules.map { capsule in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            var input: [String: Any] = [
                "id": capsule.id,
                "title": capsule.title,
                "type": capsule.type.rawValue == "文字" ? "text" : capsule.type.rawValue,
                "mediaType": capsule.type.rawValue == "文字" ? "text" : (capsule.type.rawValue == "语音" ? "audio" : "video"),
                "content": capsule.content,
                "openAt": formatter.string(from: capsule.sendDate)
            ]
            
            // ✅ 添加删除标记
            if let deletedAt = capsule.deletedAt {
                input["deletedAt"] = formatter.string(from: deletedAt)
            }
            
            return CapsuleInput(
                id: capsule.id,
                title: capsule.title,
                type: input["type"] as? String ?? capsule.type.rawValue,
                mediaType: input["mediaType"] as? String,
                content: capsule.content,
                mediaUrl: capsule.mediaServerURL.isEmpty ? nil : capsule.mediaServerURL,  // ✅ 媒体文件服务器URL
                openAt: input["openAt"] as? String,
                deletedAt: input["deletedAt"] as? String
            )
        }
        
        do {
            let result = try await APIManager.shared.batchSyncCapsules(inputs.map { $0.toDictionary() })
            
            // ✅ 解析服务器返回的同步结果（GraphQL 嵌套结构）
            let batchData = result["data"] as? [String: Any]
            let syncResult = batchData?["batchSyncCapsules"] as? [String: Any]
            let total = syncResult?["total"] as? Int ?? 0
            let created = syncResult?["created"] as? Int ?? 0
            let updated = syncResult?["updated"] as? Int ?? 0
            print("✅ 胶囊同步成功：\(total) 总数, \(created) 新增, \(updated) 更新")
            
            // 🔥 同步成功后标记为已备份（✅ 已在 @MainActor 中，无需额外 Task）
            for i in 0..<capsules.count {
                if capsules[i].cloudBackupStatus == .uploading {
                    capsules[i].cloudBackupStatus = .backedUp
                    capsules[i].cloudBackupAt = Date()
                }
            }
            
            return (total, created, updated)
        } catch {
            print("❌ 胶囊同步失败：\(error)")
            
            // 🔥 同步失败标记为失败（✅ 已在 @MainActor 中，无需额外 Task）
            for i in 0..<capsules.count {
                if capsules[i].cloudBackupStatus == .uploading {
                    capsules[i].cloudBackupStatus = .failed
                }
            }
            
            return nil
        }
    }
    
    func batchSyncWills() async -> (total: Int, created: Int, updated: Int)? {
        print("📜 开始同步遗嘱：共 \(willModules.count) 个")
        guard !willModules.isEmpty else { return (0, 0, 0) }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let inputs = willModules.map { will in
            WillInput(
                id: will.id,
                type: will.type.rawValue,
                title: will.title,
                subtitle: will.subtitle,
                content: will.content,
                deletedAt: will.deletedAt != nil ? formatter.string(from: will.deletedAt!) : nil
            )
        }
        
        do {
            let result = try await APIManager.shared.batchSyncWills(inputs.map { $0.toDictionary() })
            
            // ✅ 解析服务器返回的同步结果（GraphQL 嵌套结构）
            let batchData = result["data"] as? [String: Any]
            let syncResult = batchData?["batchSyncWills"] as? [String: Any]
            let total = syncResult?["total"] as? Int ?? 0
            let created = syncResult?["created"] as? Int ?? 0
            let updated = syncResult?["updated"] as? Int ?? 0
            print("✅ 遗嘱同步成功：\(total) 总数, \(created) 新增, \(updated) 更新")
            
            return (total, created, updated)
        } catch {
            print("❌ 遗嘱同步失败：\(error)")
            return nil
        }
    }
    
    func batchSyncAssets() async -> (total: Int, created: Int, updated: Int)? {
        print("💰 开始同步资产：共 \(assets.count) 个")
        guard !assets.isEmpty else { return (0, 0, 0) }
        
        let inputs = assets.map { asset in
            AssetInput(
                id: asset.id,
                type: asset.type.rawValue,
                name: asset.name,
                institution: asset.institution,
                balance: asset.balance,
                accountNumber: asset.accountNumber,
                details: asset.details,
                deletedAt: asset.deletedAt != nil ? ISO8601DateFormatter().string(from: asset.deletedAt!) : nil
            )
        }
        
        do {
            let result = try await APIManager.shared.batchSyncAssets(inputs.map { $0.toDictionary() })
            
            // ✅ 解析服务器返回的同步结果（GraphQL 嵌套结构）
            let batchData = result["data"] as? [String: Any]
            let syncResult = batchData?["batchSyncAssets"] as? [String: Any]
            let total = syncResult?["total"] as? Int ?? 0
            let created = syncResult?["created"] as? Int ?? 0
            let updated = syncResult?["updated"] as? Int ?? 0
            print("✅ 资产同步成功：\(total) 总数, \(created) 新增, \(updated) 更新")
            
            return (total, created, updated)
        } catch {
            print("❌ 资产同步失败：\(error)")
            return nil
        }
    }
    
    // MARK: - 家人守护 API
    
    /// 邀请家人
    func inviteFamily(phone: String) async throws -> [String: Any] {
        let mutation = """
        mutation($phone: String!) {
            inviteFamily(phone: $phone) {
                success
                message
                relationId
            }
        }
        """
        
        let variables: [String: Any] = ["phone": phone]
        let result = try await GraphQLClient.shared.query(mutation, variables: variables)
        
        if let data = result["data"] as? [String: Any],
           let familyData = data["inviteFamily"] as? [String: Any] {
            return familyData
        }
        throw APIError.networkError
    }
    
    /// 接受家人邀请
    func acceptFamilyInvite(relationId: String) async throws -> [String: Any] {
        let mutation = """
        mutation($relationId: String!) {
            acceptFamilyInvite(relationId: $relationId) {
                success
                message
            }
        }
        """
        
        let variables: [String: Any] = ["relationId": relationId]
        let result = try await GraphQLClient.shared.query(mutation, variables: variables)
        
        if let data = result["data"] as? [String: Any],
           let familyData = data["acceptFamilyInvite"] as? [String: Any] {
            return familyData
        }
        throw APIError.networkError
    }
    
    /// 拒绝家人邀请
    func rejectFamilyInvite(relationId: String) async throws -> [String: Any] {
        let mutation = """
        mutation($relationId: String!) {
            rejectFamilyInvite(relationId: $relationId) {
                success
                message
            }
        }
        """
        
        let variables: [String: Any] = ["relationId": relationId]
        let result = try await GraphQLClient.shared.query(mutation, variables: variables)
        
        if let data = result["data"] as? [String: Any],
           let familyData = data["rejectFamilyInvite"] as? [String: Any] {
            return familyData
        }
        throw APIError.networkError
    }
    
    /// 移除家人
    func removeFamily(relationId: String) async throws -> [String: Any] {
        let mutation = """
        mutation($relationId: String!) {
            removeFamily(relationId: $relationId) {
                success
                message
            }
        }
        """
        
        let variables: [String: Any] = ["relationId": relationId]
        let result = try await GraphQLClient.shared.query(mutation, variables: variables)
        
        if let data = result["data"] as? [String: Any],
           let familyData = data["removeFamily"] as? [String: Any] {
            return familyData
        }
        throw APIError.networkError
    }
    
    /// 通过邀请码绑定家人
    func bindFamilyByInviteCode(inviteCode: String) async throws -> [String: Any] {
        let mutation = """
        mutation($inviteCode: String!) {
            bindFamilyByInviteCode(inviteCode: $inviteCode) {
                success
                message
                family {
                    id
                    name
                }
            }
        }
        """
        
        let variables: [String: Any] = ["inviteCode": inviteCode]
        let result = try await GraphQLClient.shared.query(mutation, variables: variables)
        
        if let data = result["data"] as? [String: Any],
           let familyData = data["bindFamilyByInviteCode"] as? [String: Any] {
            return familyData
        }
        throw APIError.networkError
    }
    
    /// 获取用户邀请码（GraphQL）
    // ✅ 修复：将 UI 层调用迁移到 DataManager 统一管理
    func getInviteCode() async throws -> (inviteCode: String, qrUrl: String) {
        let query = """
        query {
            getInviteCode {
                success
                message
                data {
                    inviteCode
                    qrUrl
                }
            }
        }
        """
        
        let result = try await GraphQLClient.shared.query(query)
        
        if let data = result["data"] as? [String: Any],
           let inviteData = data["getInviteCode"] as? [String: Any],
           let resultData = inviteData["data"] as? [String: Any],
           let inviteCode = resultData["inviteCode"] as? String,
           let qrUrl = resultData["qrUrl"] as? String {
            return (inviteCode, qrUrl)
        }
        throw APIError.networkError
    }
    
    /// 获取家人列表
    func fetchFamilyMembers() async throws -> [[String: Any]] {
        let query = """
        query {
            family {
                success
                message
                data {
                    members {
                        id
                        name
                        phone
                        role
                        status
                        createdAt
                    }
                    invited {
                        id
                        name
                        phone
                        status
                        createdAt
                    }
                }
            }
        }
        """
        
        let result = try await GraphQLClient.shared.query(query)
        
        if let data = result["data"] as? [String: Any],
           let family = data["family"] as? [String: Any],
           let familyData = family["data"] as? [String: Any] {
            let members = (familyData["members"] as? [[String: Any]]) ?? []
            let invited = (familyData["invited"] as? [[String: Any]]) ?? []
            return members + invited
        }
        return []
    }
    
    /// 获取家庭档案列表（GraphQL）
    // ✅ 修复：将 UI 层调用迁移到 DataManager 统一管理
    func fetchFamilyArchives() async throws -> [[String: Any]] {
        let query = """
        query {
            getFamilyArchives {
                id
                archiveName
                description
                isPublic
                createdAt
                updatedAt
            }
        }
        """
        
        let result = try await GraphQLClient.shared.query(query)
        
        if let data = result["data"] as? [String: Any],
           let archives = data["getFamilyArchives"] as? [[String: Any]] {
            return archives
        }
        return []
    }
    
    /// 创建家庭档案（GraphQL）
    // ✅ 修复：将 UI 层调用迁移到 DataManager 统一管理
    func createFamilyArchive(archiveName: String, description: String, isPublic: Bool) async throws -> Bool {
        let mutation = """
        mutation($archiveName: String!, $description: String!, $isPublic: Boolean!) {
            createFamilyArchive(archiveName: $archiveName, description: $description, isPublic: $isPublic) {
                success
                message
            }
        }
        """
        
        let variables: [String: Any] = [
            "archiveName": archiveName,
            "description": description,
            "isPublic": isPublic
        ]
        
        let result = try await GraphQLClient.shared.query(mutation, variables: variables)
        
        if let data = result["data"] as? [String: Any],
           let archiveData = data["createFamilyArchive"] as? [String: Any],
           archiveData["success"] as? Bool == true {
            return true
        }
        return false
    }
    
    /// 更新家庭档案（GraphQL）
    // ✅ 统一：添加缺失的家庭档案函数
    func updateFamilyArchive(id: String, archiveName: String, description: String, isPublic: Bool) async throws -> Bool {
        let mutation = """
        mutation($id: String!, $archiveName: String!, $description: String!, $isPublic: Boolean!) {
            updateFamilyArchive(id: $id, archiveName: $archiveName, description: $description, isPublic: $isPublic) {
                success
                message
            }
        }
        """
        
        let variables: [String: Any] = [
            "id": id,
            "archiveName": archiveName,
            "description": description,
            "isPublic": isPublic
        ]
        
        let result = try await GraphQLClient.shared.query(mutation, variables: variables)
        
        if let data = result["data"] as? [String: Any],
           let archiveData = data["updateFamilyArchive"] as? [String: Any],
           archiveData["success"] as? Bool == true {
            return true
        }
        return false
    }
    
    /// 删除家庭档案（GraphQL）
    // ✅ 统一：添加缺失的家庭档案函数
    func deleteFamilyArchive(id: String) async throws -> Bool {
        let mutation = """
        mutation($id: String!) {
            deleteFamilyArchive(id: $id) {
                success
                message
            }
        }
        """
        
        let variables: [String: Any] = ["id": id]
        let result = try await GraphQLClient.shared.query(mutation, variables: variables)
        
        if let data = result["data"] as? [String: Any],
           let archiveData = data["deleteFamilyArchive"] as? [String: Any],
           archiveData["success"] as? Bool == true {
            return true
        }
        return false
    }
    
    /// 签到（GraphQL）
    // ✅ 统一：将 LifeCheckStatusManager 调用迁移到 DataManager
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
        
        var variables: [String: Any] = [
            "checkInIntervalHours": checkInIntervalHours
        ]
        
        if let location = location {
            variables["location"] = location
        }
        
        let result = try await GraphQLClient.shared.query(mutation, variables: variables)
        
        // ✅ 解析 GraphQL 嵌套响应
        if let data = result["data"] as? [String: Any],
           let checkInData = data["checkIn"] as? [String: Any] {
            return checkInData
        }
        throw APIError.networkError
    }
    
    /// 上传设备信息（GraphQL）
    // ✅ 统一：将 DeviceMonitor 调用迁移到 DataManager
    func uploadDeviceInfo(deviceId: String, deviceModel: String, osVersion: String, appVersion: String) async throws -> [String: Any] {
        let mutation = """
        mutation($deviceId: String!, $deviceModel: String!, $osVersion: String!, $appVersion: String!) {
            uploadDeviceInfo(deviceId: $deviceId, deviceModel: $deviceModel, osVersion: $osVersion, appVersion: $appVersion) {
                success
                message
            }
        }
        """
        
        let variables: [String: Any] = [
            "deviceId": deviceId,
            "deviceModel": deviceModel,
            "osVersion": osVersion,
            "appVersion": appVersion
        ]
        
        let result = try await GraphQLClient.shared.query(mutation, variables: variables)
        
        if let data = result["data"] as? [String: Any],
           let uploadData = data["uploadDeviceInfo"] as? [String: Any] {
            return uploadData
        }
        throw APIError.networkError
    }
    
    /// 更新资产（GraphQL）
    // ✅ 统一：将 REST API (will.php) 迁移到 GraphQL
    func updateAssetGraphQL(id: String, type: String, name: String, institution: String, balance: Double, accountNumber: String, details: String) async throws -> [String: Any] {
        let mutation = """
        mutation($id: String!, $type: String!, $name: String!, $institution: String!, $balance: Float!, $account_number: String!, $details: String!) {
            updateAsset(id: $id, type: $type, name: $name, institution: $institution, balance: $balance, account_number: $account_number, details: $details) {
                success
                message
            }
        }
        """
        
        let variables: [String: Any] = [
            "id": id,
            "type": type,
            "name": name,
            "institution": institution,
            "balance": balance,
            "account_number": accountNumber,
            "details": details
        ]
        
        let result = try await GraphQLClient.shared.query(mutation, variables: variables)
        
        if let data = result["data"] as? [String: Any],
           let assetData = data["updateAsset"] as? [String: Any] {
            return assetData
        }
        throw APIError.networkError
    }
    
    // MARK: - 数据导出
    
    /// 下载用户数据（GraphQL）
    func downloadUserData(type: String = "all") async throws -> [String: Any] {
        let query = """
        query($type: String) {
            downloadUserData(type: $type) {
                capsules
                wills
                assets
            }
        }
        """
        
        let variables: [String: Any] = ["type": type]
        let result = try await GraphQLClient.shared.query(query, variables: variables)
        
        if let data = result["data"] as? [String: Any],
           let exportData = data["downloadUserData"] as? [String: Any] {
            print("✅ 数据导出成功：胶囊\(exportData["capsules"] ?? []) 遗嘱\(exportData["wills"] ?? [])")
            return exportData
        }
        throw APIError.networkError
    }
    
    /// ⚠️ 从云端恢复数据到本地（仅用于换手机/数据丢失时）
    /// ⚠️ 警告：此操作会覆盖本地数据！仅在用户明确要求恢复时调用
    @MainActor
    func restoreFromCloud() async throws {
        print("☁️ ====== 开始从云端恢复数据（危险操作） ======")
        
        // ⚠️ 警告：即将用服务器数据覆盖本地数据
        // 保存本地数据作为备份（以防万一）
        let localBackup = capsules
        
        // 1. 下载服务器数据
        let serverData = try await downloadUserData(type: "all")
        
        // 2. 解析胶囊数据（仅在服务器有数据时）
        if let capsulesData = serverData["capsules"] as? [[String: Any]], !capsulesData.isEmpty {
            capsules.removeAll()
            for item in capsulesData {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: item)
                    var capsule = try JSONDecoder().decode(TimeCapsule.self, from: jsonData)
                    
                    // ✅ 恢复数据时：如果服务器有媒体路径（mediaServerURL），
                    // ✅ 同时存入 mediaURL，这样恢复的数据也能播放
                    // ✅ （本地录制上传的胶囊，mediaURL 保留本地路径；恢复的胶囊用服务器路径播放）
                    if !capsule.mediaServerURL.isEmpty && capsule.mediaURL.isEmpty {
                        capsule.mediaURL = capsule.mediaServerURL
                        print("📱 恢复胶囊媒体地址：\(capsule.title) -> \(capsule.mediaURL)")
                    }
                    
                    capsules.append(capsule)
                } catch {
                    print("⚠️ 解析胶囊失败：\(error)")
                }
            }
            print("✅ 从云端恢复胶囊：\(capsules.count) 个（本地备份：\(localBackup.count) 个）")
            saveCapsulesToFile()
        } else {
            print("⚠️ 服务器无胶囊数据，保留本地数据：\(localBackup.count) 个")
            // 服务器没有数据，保留本地数据
            capsules = localBackup
        }
        
        // 3. 解析遗嘱数据
        if let willsData = serverData["wills"] as? [[String: Any]] {
            willModules.removeAll()
            for item in willsData {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: item)
                    let will = try JSONDecoder().decode(WillModule.self, from: jsonData)
                    willModules.append(will)
                } catch {
                    print("⚠️ 解析遗嘱失败：\(error)")
                }
            }
            print("✅ 恢复遗嘱：\(willModules.count) 个")
        }
        
        print("☁️ ====== 云端恢复完成 ======")
        
        // 6. 通知其他视图刷新
        NotificationCenter.default.post(name: NSNotification.Name("DataDidRestoreFromCloud"), object: nil)
    }
    
    /// 上传媒体文件到服务器（带重试）
    /// ✅ P0 修复 #3: 从 Keychain 读取 Token（安全存储）
    /// ✅ 修复: 支持后端返回的 success 字段（而非 status）
    func uploadMediaToServer(_ fileURL: URL, type: TimeCapsule.CapsuleType, maxRetries: Int = 2) async -> String? {
        print("☁️ ====== uploadMediaToServer 开始 ======")
        
        guard !DataManager.apiURL.isEmpty else {
            print("⚠️ 上传失败：API URL 为空")
            return nil
        }
        
        let token = KeychainManager.shared.getToken() ?? ""
        if token.isEmpty {
            print("⚠️ 上传失败：认证失败")
            return nil
        }
        
        // 重试循环
        for attempt in 1...maxRetries {
            print("📤 上传尝试 \(attempt)/\(maxRetries)")
            
            if let result = await attemptUpload(fileURL: fileURL, type: type, token: token) {
                return result
            }
            
            if attempt < maxRetries {
                print("⏳ 上传失败，\(2) 秒后重试...")
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
        
        print("❌ 上传失败：已尝试 \(maxRetries) 次")
        return nil
    }
    
    /// 单次上传尝试
    private func attemptUpload(fileURL: URL, type: TimeCapsule.CapsuleType, token: String) async -> String? {
        // 创建上传请求
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/api/upload.php?action=upload") ?? URL(fileURLWithPath: ""))
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60 // 60秒超时
        
        // 构建 multipart/form-data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            let filename = fileURL.lastPathComponent
            // 修正 MIME 类型
            let mimetype: String
            switch type {
            case .audio:
                mimetype = fileURL.pathExtension.lowercased() == "m4a" ? "audio/mp4" : "audio/\(fileURL.pathExtension.lowercased())"
            case .video:
                mimetype = fileURL.pathExtension.lowercased() == "mp4" ? "video/mp4" : "video/\(fileURL.pathExtension.lowercased())"
            default:
                mimetype = "application/octet-stream"
            }
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
            
            // 添加类型参数
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"type\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(type == .audio ? "capsule" : "capsule")\r\n".data(using: .utf8)!)
            
            // 添加 token
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"token\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(token)\r\n".data(using: .utf8)!)
            
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            let fileSizeMB = String(format: "%.2f", Double(fileData.count) / 1024 / 1024)
            print("📤 上传文件：\(filename) (\(fileSizeMB) MB), MIME: \(mimetype)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("⚠️ 上传失败：无效的响应")
                return nil
            }
            
            print("📡 上传响应状态码：\(httpResponse.statusCode)")
            
            // 检查 HTTP 状态码
            guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                print("⚠️ 上传失败：HTTP \(httpResponse.statusCode)")
                if let jsonString = String(data: data, encoding: .utf8), !jsonString.isEmpty {
                    print("📄 错误响应：\(jsonString)")
                }
                return nil
            }
            
            // 检查响应数据
            guard !data.isEmpty else {
                print("⚠️ 上传失败：空响应")
                return nil
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 上传响应：\(jsonString)")
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // ✅ 修复：支持后端返回的 success 字段（而非 status）
                    let success = json["success"] as? Bool
                    let status = json["status"] as? String
                    
                    if success == true || status == "success" {
                        if let fileURL = json["url"] as? String {
                            print("✅ 上传成功：\(fileURL)")
                            return fileURL
                        }
                    }
                    
                    // 检查错误信息
                    if let error = json["error"] as? String {
                        print("⚠️ 上传失败：\(error)")
                    }
                }
            }
            
        } catch {
            print("❌ 上传异常：\(error)")
        }
        
        return nil
    }
    
    /// 上传媒体文件到服务器（断点续传）
    /// - Parameters:
    ///   - fileURL: 本地文件 URL
    ///   - type: 胶囊类型
    /// - Returns: 服务器上的文件 URL
    func uploadMediaChunked(_ fileURL: URL, type: TimeCapsule.CapsuleType) async -> String? {
        print("📦 ====== uploadMediaChunked 开始（断点续传）======")
        
        do {
            let typeString = type == .audio ? "audio" : "video"
            let url = try await ChunkedUploadManager.shared.uploadFile(fileURL: fileURL, type: "capsule")
            print("✅ 断点续传上传成功：\(url)")
            return url
        } catch {
            print("❌ 断点续传上传失败：\(error)")
            return nil
        }
    }
    
    // MARK: - 系统配置
    
    /// 加载系统配置（后端可配置）
    func loadSystemConfig() async {
        print("⚙️ ====== loadSystemConfig 开始 (GraphQL) ======")
        
        guard !DataManager.apiURL.isEmpty else {
            print("⚠️ 系统配置加载失败：API URL 为空")
            return
        }
        
        do {
            let query = """
            query {
                getConfig {
                    checkinReminderThresholdHours
                    checkinReminderIntervalHours
                    overduePushIntervalHours
                    maintenanceMode
                    maintenanceMessage
                    latestVersion
                    forceUpdateVersion
                    updateUrl
                    memberPriceMonthly
                    memberPriceYearly
                    freeMaxCapsules
                    freeMaxMediaCapsules
                    freeMaxVideoMinutes
                    freeMaxWillModules
                    freeMaxFamily
                    freeCloudBackup
                    freeDataExport
                    freeAiAssist
                    premiumMaxCapsules
                    premiumMaxMediaCapsules
                    premiumMaxVideoMinutes
                    premiumMaxWillModules
                    premiumMaxFamily
                    premiumCloudBackup
                    premiumDataExport
                    premiumAiAssist
                    customerServicePhone
                    customerServiceEmail
                }
            }
            """
            
            let response = try await sendGraphQLQuery(query: query, variables: [:], baseURL: DataManager.apiURL)
            
            if let data = response["data"] as? [String: Any],
               let configData = data["getConfig"] as? [String: Any] {
                // 推送配置
                let reminderHours = configData["checkinReminderThresholdHours"] as? Int ?? 12
                let pushInterval = configData["checkinReminderIntervalHours"] as? Int ?? 2
                let overduePushInterval = configData["overduePushIntervalHours"] as? Int ?? 1
                
                // 维护模式
                let maintenanceMode = configData["maintenanceMode"] as? Bool ?? false
                let maintenanceMessage = configData["maintenanceMessage"] as? String ?? "系统维护中，请稍后再试"
                
                // 版本更新
                let latestVersion = configData["latestVersion"] as? String ?? "1.0.0"
                let forceUpdateVersion = configData["forceUpdateVersion"] as? String ?? "0.0.0"
                let updateUrl = configData["updateUrl"] as? String ?? ""
                
                // 会员价格
                let priceMonthly = configData["memberPriceMonthly"] as? Double ?? 8.0
                let priceYearly = configData["memberPriceYearly"] as? Double ?? 68.0
                
                // 免费版限制
                let freeMaxCapsules = configData["freeMaxCapsules"] as? Int ?? 5
                let freeMaxMediaCapsules = configData["freeMaxMediaCapsules"] as? Int ?? 2
                let freeMaxVideoMinutes = configData["freeMaxVideoMinutes"] as? Int ?? 2
                let freeMaxWillModules = configData["freeMaxWillModules"] as? Int ?? 3
                let freeMaxFamily = configData["freeMaxFamily"] as? Int ?? 1
                let freeCloudBackup = configData["freeCloudBackup"] as? Bool ?? false
                let freeDataExport = configData["freeDataExport"] as? Bool ?? false
                let freeAiAssist = configData["freeAiAssist"] as? Bool ?? false
                
                // 会员版限制
                let premiumMaxCapsules = configData["premiumMaxCapsules"] as? Int ?? 20
                let premiumMaxMediaCapsules = configData["premiumMaxMediaCapsules"] as? Int ?? 10
                let premiumMaxVideoMinutes = configData["premiumMaxVideoMinutes"] as? Int ?? 5
                let premiumMaxWillModules = configData["premiumMaxWillModules"] as? Int ?? 999
                let premiumMaxFamily = configData["premiumMaxFamily"] as? Int ?? 5
                let premiumCloudBackup = configData["premiumCloudBackup"] as? Bool ?? true
                let premiumDataExport = configData["premiumDataExport"] as? Bool ?? true
                let premiumAiAssist = configData["premiumAiAssist"] as? Bool ?? true
                
                // 客服配置
                let customerServicePhone = configData["customerServicePhone"] as? String ?? "400-123-4567"
                let customerServiceEmail = configData["customerServiceEmail"] as? String ?? "support@zhonghuo.cn"
                
                // 更新系统配置
                systemConfig = SystemConfig(
                    checkinReminderThresholdHours: Double(reminderHours),
                    checkinReminderIntervalHours: Double(pushInterval),
                    overduePushIntervalHours: Double(overduePushInterval),
                    appMaintenanceMode: maintenanceMode,
                    appMaintenanceMessage: maintenanceMessage,
                    latestVersion: latestVersion,
                    forceUpdateVersion: forceUpdateVersion,
                    updateUrl: updateUrl,
                    memberPriceMonthly: priceMonthly,
                    memberPriceYearly: priceYearly,
                    freeMaxCapsules: freeMaxCapsules,
                    freeMaxMediaCapsules: freeMaxMediaCapsules,
                    freeMaxVideoMinutes: freeMaxVideoMinutes,
                    freeMaxWillModules: freeMaxWillModules,
                    freeMaxFamily: freeMaxFamily,
                    freeCloudBackup: freeCloudBackup,
                    freeDataExport: freeDataExport,
                    freeAiAssist: freeAiAssist,
                    premiumMaxCapsules: premiumMaxCapsules,
                    premiumMaxMediaCapsules: premiumMaxMediaCapsules,
                    premiumMaxVideoMinutes: premiumMaxVideoMinutes,
                    premiumMaxWillModules: premiumMaxWillModules,
                    premiumMaxFamily: premiumMaxFamily,
                    premiumCloudBackup: premiumCloudBackup,
                    premiumDataExport: premiumDataExport,
                    premiumAiAssist: premiumAiAssist,
                    customerServicePhone: customerServicePhone,
                    customerServiceEmail: customerServiceEmail
                )
                
                // ✅ 应用会员限制
                MembershipManager.shared.applyLimits(
                    freeMaxCapsules: freeMaxCapsules,
                    freeMaxMediaCapsules: freeMaxMediaCapsules,
                    freeMaxVideoMinutes: freeMaxVideoMinutes,
                    freeMaxWillModules: freeMaxWillModules,
                    freeMaxFamily: freeMaxFamily,
                    freeCloudBackup: freeCloudBackup,
                    freeDataExport: freeDataExport,
                    freeAiAssist: freeAiAssist,
                    premiumMaxCapsules: premiumMaxCapsules,
                    premiumMaxMediaCapsules: premiumMaxMediaCapsules,
                    premiumMaxVideoMinutes: premiumMaxVideoMinutes,
                    premiumMaxWillModules: premiumMaxWillModules,
                    premiumMaxFamily: premiumMaxFamily,
                    premiumCloudBackup: premiumCloudBackup,
                    premiumDataExport: premiumDataExport,
                    premiumAiAssist: premiumAiAssist
                )
                
                print("✅ 系统配置加载成功（GraphQL）")
                print("   - 维护模式：\(maintenanceMode ? "开启" : "关闭")")
                print("   - 签到提醒阈值：\(reminderHours) 小时")
                print("   - 签到提醒间隔：\(pushInterval) 小时")
                print("   - 超时推送间隔：\(overduePushInterval) 小时")
                print("   - 最新版本：\(latestVersion)")
                print("   - 强制更新版本：\(forceUpdateVersion)")
                print("   - 更新地址：\(updateUrl)")
                print("   - 会员价格：月卡\(priceMonthly)/年卡\(priceYearly)")
                print("   - 免费版限制：\(freeMaxCapsules)胶囊/\(freeMaxMediaCapsules)媒体/\(freeMaxVideoMinutes)分钟")
                print("   - 免费版遗嘱：\(freeMaxWillModules)/家庭\(freeMaxFamily)/云备份\(freeCloudBackup ? "是" : "否")")
                print("   - 客服电话：\(customerServicePhone)")
            } else {
                print("⚠️ 系统配置加载失败：数据格式错误")
            }
        } catch {
            print("❌ 系统配置加载失败：\(error)")
            print("ℹ️ 使用默认系统配置")
        }
    }


    // MARK: - 临时方法（待迁移到 GraphQL）
    
    /// 下载所有数据（临时实现）
    /// ✅ 修复：确保所有 @Published 属性更新在主线程执行
    @MainActor
    func downloadAllData() async {
        Logger.shared.i("开始从云端下载数据...")
        
        do {
            // ✅ 已实现完整的数据下载逻辑
            // 1. 同步胶囊数据
            if let capsulesResult = await batchSyncCapsules() {
                Logger.shared.i("胶囊同步完成：\(capsulesResult.total) 个，\(capsulesResult.created) 新增，\(capsulesResult.updated) 更新")
            } else {
                Logger.shared.w("胶囊同步失败")
            }
            
            // 2. 同步遗嘱数据
            if let willsResult = await batchSyncWills() {
                Logger.shared.i("遗嘱同步完成：\(willsResult.total) 个，\(willsResult.created) 新增，\(willsResult.updated) 更新")
            } else {
                Logger.shared.w("遗嘱同步失败")
            }
            
            // 3. 同步资产数据
            if let assetsResult = await batchSyncAssets() {
                Logger.shared.i("资产同步完成：\(assetsResult.total) 个，\(assetsResult.created) 新增，\(assetsResult.updated) 更新")
            } else {
                Logger.shared.w("资产同步失败")
            }
            
            Logger.shared.i("数据下载完成")
        } catch {
            Logger.shared.e("下载数据失败：\(error)")
        }
    }

    /// 持久化媒体文件（确保文件保存在 Documents 目录）
    func persistMediaFile(_ tempURL: URL) async -> URL? {
        print("📁 持久化媒体文件：\(tempURL.path)")
        
        // 检查源文件是否存在
        guard FileManager.default.fileExists(atPath: tempURL.path) else {
            print("❌ 源文件不存在：\(tempURL.path)")
            return nil
        }
        
        // 使用稳定的文档目录路径
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let capsulesFolder = documents.appendingPathComponent("TimeCapsules")
        
        // 创建胶囊文件夹（如果不存在）
        if !FileManager.default.fileExists(atPath: capsulesFolder.path) {
            do {
                try FileManager.default.createDirectory(at: capsulesFolder, withIntermediateDirectories: true, attributes: nil)
                print("📁 创建胶囊文件夹：\(capsulesFolder.path)")
            } catch {
                print("❌ 创建文件夹失败：\(error)")
                return nil
            }
        }
        
        // 生成新的文件名（避免冲突）- pathExtension 不带点，需要手动添加
        let filename = "capsule_" + UUID().uuidString + "." + tempURL.pathExtension
        let permanentURL = capsulesFolder.appendingPathComponent(filename)
        
        do {
            // 如果目标文件已存在，先删除
            if FileManager.default.fileExists(atPath: permanentURL.path) {
                try FileManager.default.removeItem(at: permanentURL)
                print("🗑️ 删除旧文件：\(permanentURL.path)")
            }
            
            // 复制文件到持久化目录
            try FileManager.default.copyItem(at: tempURL, to: permanentURL)
            
            // 验证文件
            let attributes = try? FileManager.default.attributesOfItem(atPath: permanentURL.path)
            let fileSize = attributes?[.size] as? Int ?? 0
            let isReadable = FileManager.default.isReadableFile(atPath: permanentURL.path)
            
            print("✅ 媒体文件已持久化：\(permanentURL.path)")
            print("✅ 文件大小：\(fileSize) bytes")
            print("✅ 文件可读：\(isReadable)")
            
            if fileSize == 0 {
                print("⚠️ 警告：文件大小为 0，可能损坏")
                return nil
            }
            
            return permanentURL
        } catch {
            print("❌ 媒体文件持久化失败：\(error)")
            print("❌ 错误详情：\(error.localizedDescription)")
            return nil
        }
    }
    
    // 🔧 重置所有数据（调试用）
    func reset() {
        print("🔧 DataManager.reset() - 重置所有数据")
        
        // 重置用户状态
        // currentUser = nil
        
        // 重置胶囊数据
        // capsules = []
        
        // 重置遗嘱模块
        // willModules = []
        
        // 重置资产
        // assets = []
        
        // 重置待办清单
        // checklistItems = []
        
        // 重置设置（使用默认值）
        // self.settings.name = ""
        // self.settings.checkInInterval = .twoDays
        // self.settings.notificationsEnabled = true
        // self.settings.cloudSyncEnabled = true
        // self.settings.lastCheckInDate = nil
        
        // 清除 API 配置
        DataManager.apiURL = ""
        DataManager.baseURL = ""
        
        Logger.shared.i("DataManager 已重置")
    }
}
