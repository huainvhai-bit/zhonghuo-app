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

/// 数据管理中心 - 全局单例
/// 
/// 功能模块：
/// - **API 配置**：动态获取服务器地址（`apiURL`）
/// - **用户数据**：`capsules`, `willModules`, `assets`, `witnesses`
/// - **系统配置**：签到间隔、通知配置等
/// - **数据同步**：GraphQL + REST API 混合架构
/// 
/// 使用方式：
/// ```swift
/// let manager = DataManager.shared
/// manager.capsules.append(newCapsule)
/// manager.saveCapsules()
/// ```
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // MARK: - API 地址（动态获取，初始值为空）
    static var baseURL: String = ""
    static var apiURL: String = ""
    
    // MARK: - 配置
    @Published var serverConfig: ServerConfig?
    @Published var smsConfig: ServerConfig.ServerConfigData.SMSConfig?
    @Published var isBackendOnline: Bool = false
    
    // MARK: - 用户数据
    @Published var currentUser: User?
    @Published var capsules: [TimeCapsule] = []
    @Published var willModules: [WillModule] = []
    @Published var assets: [Asset] = []
    @Published var witnesses: [Witness] = []
    @Published var checklistItems: [ChecklistItem] = []
    @Published var settings: UserSettings
    @Published var systemConfig: SystemConfig = SystemConfig()  // 系统配置
    
    // MARK: - API 配置管理
    
    /// 从服务器获取 API 配置（无条件相信后端返回的地址）
    // MARK: - API 配置管理
    
    /// 从服务器获取 API 配置（GraphQL）
    func fetchServerConfig(from baseURL: String) async throws {
        print("🌐 请求配置（GraphQL）：\(baseURL)")
        
        let query = """
        query {
            getConfig {
                checkinIntervalHours
                notificationReminderThresholdHours
                notificationPushIntervalHours
                smsIsDevelopment
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
            // 解析配置
            let checkinHours = configData["checkinIntervalHours"] as? Int ?? 48
            let reminderHours = configData["notificationReminderThresholdHours"] as? Int ?? 12
            let pushInterval = configData["notificationPushIntervalHours"] as? Int ?? 2
            let smsDev = configData["smsIsDevelopment"] as? Int ?? 1
            
            self.systemConfig = SystemConfig(
                checkinReminderThresholdHours: Double(reminderHours),
                checkinReminderIntervalHours: Double(pushInterval),
                minimumEmergencyContacts: 2
            )
            
            // 保存签到间隔到 UserSettings
            self.settings.checkInInterval = checkinHours == 24 ? .oneDay : .twoDays
            
            // 使用后端返回的地址（无条件相信）
            DataManager.baseURL = baseURL
            DataManager.apiURL = baseURL
            
            self.isBackendOnline = true
            
            // 保存地址供下次使用
            UserDefaults.standard.set(DataManager.baseURL, forKey: "lastUsedBaseURL")
            
            print("✅ 后端配置获取成功（GraphQL）")
            print("   Base URL: \(DataManager.baseURL)")
            print("   签到间隔：\(checkinHours) 小时")
            print("   提醒阈值：\(reminderHours) 小时")
            print("   推送间隔：\(pushInterval) 小时")
            print("   短信模式：\(smsDev == 1 ? "测试" : "生产")")
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
        
        let body: [String: Any] = [
            "query": query,
            "variables": variables
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Server error", code: -1)
        }
        
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
    
    /// 初始化 API 配置（同步版本 - 立即设置默认值）
    func initializeAPIConfig() {
        // 立即设置默认值，确保 API 立即可用
        DataManager.baseURL = "http://8.136.41.211:3395"
        DataManager.apiURL = "http://8.136.41.211:3395"  // 新架构：直接使用 baseURL
        self.isBackendOnline = true
        
        print("🔵 API 已初始化（默认地址）")
        print("   Base URL: \(DataManager.baseURL)")
        print("   API URL: \(DataManager.apiURL)")
        
        // 异步尝试获取最新配置
        Task {
            await refreshAPIConfig()
        }
    }
    
    /// 异步刷新 API 配置（后台静默更新）
    func refreshAPIConfig() async {
        // 尝试顺序：保存的地址 > 默认地址
        let candidates = [
            UserDefaults.standard.string(forKey: "lastUsedBaseURL") ?? "",
            "http://8.136.41.211:3395"
        ].filter { !$0.isEmpty }
        
        for baseURL in candidates {
            do {
                try await fetchServerConfig(from: baseURL)
                print("✅ 后端配置刷新成功：\(DataManager.baseURL)")
                return
            } catch {
                print("⚠️ 尝试地址失败：\(baseURL) - \(error.localizedDescription)")
                continue
            }
        }
        
        // 所有尝试都失败，保持默认值
        print("⚠️ 后端配置刷新失败，使用默认地址")
    }
    
    /// 检查 API 是否已初始化（立即可用）
    func checkAPIReady() async throws {
        // 如果已初始化，直接返回
        if !DataManager.apiURL.isEmpty && isBackendOnline {
            return
        }
        
        // 如果未初始化，使用默认地址
        if DataManager.apiURL.isEmpty {
            DataManager.baseURL = "http://8.136.41.211:3395"
            DataManager.apiURL = "http://8.136.41.211:3395"  // 新架构：直接使用 baseURL
            self.isBackendOnline = true
            print("⚠️ API 未初始化，使用默认地址：\(DataManager.apiURL)")
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
            emergencyContact: nil,
            emergencyContacts: [],
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
        
        self.lastCheckInDate = settings.lastCheckInDate
        loadAllData()
    }
    
    // MARK: - 网络检查
    
    /// 检查网络连通性
    func checkNetworkConnectivity() async -> Bool {
        guard let url = URL(string: "http://8.136.41.211:3395/api/check-config.php") else {
            return false
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            return (200...299).contains(httpResponse.statusCode)
        } catch {
            print("❌ 网络检查失败：\(error)")
            return false
        }
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
        witnesses = loadWitnessesFromFile()
        checklistItems = loadChecklistItemsFromFile()
    }
    
    // MARK: - 文件操作
    
    func saveSettingsToFile() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(settings) {
            try? data.write(to: fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("settings.json"))
        }
    }
    
    func loadSettingsFromFile() -> UserSettings? {
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("settings.json")
        if let data = try? Data(contentsOf: path) {
            return try? JSONDecoder().decode(UserSettings.self, from: data)
        }
        return nil
    }
    
    // 其他数据加载方法...
    func loadCapsulesFromFile() -> [TimeCapsule] {
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("capsules.json")
        if let data = try? Data(contentsOf: path) {
            return (try? JSONDecoder().decode([TimeCapsule].self, from: data)) ?? []
        }
        return []
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
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(capsules) {
            try? data.write(to: fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("capsules.json"))
        }
    }
    
    func saveWitnessesToFile() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(witnesses) {
            try? data.write(to: fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("witnesses.json"))
        }
    }
    
    func loadWitnessesFromFile() -> [Witness] {
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("witnesses.json")
        if let data = try? Data(contentsOf: path) {
            return (try? JSONDecoder().decode([Witness].self, from: data)) ?? []
        }
        return []
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
        
        let hours = settings.checkInInterval.hours
        let interval: TimeInterval = hours * 3600
        return now.timeIntervalSince(lastCheckIn) >= interval
    }
    
    var nextCheckInTime: Date? {
        guard let lastCheckIn = lastCheckInDate else { return nil }
        let hours = Int(settings.checkInInterval.hours)
        return Calendar.current.date(byAdding: .hour, value: hours, to: lastCheckIn)
    }
    
    func performCheckIn() {
        lastCheckInDate = Date()
        settings.lastCheckInDate = lastCheckInDate
        saveSettingsToFile()
    }
    
    // MARK: - 用户管理
    
    func saveUser(_ user: User) {
        currentUser = user
        settings.name = user.name
        saveSettingsToFile()
    }
    
    func logout() {
        currentUser = nil
        lastCheckInDate = nil
        settings.lastCheckInDate = nil
        saveSettingsToFile()
    }
    
    // MARK: - 密码重置
    
    /// 发送重置密码验证码
    func sendResetPasswordCode(phone: String) async throws -> Bool {
        guard !Self.apiURL.isEmpty else {
            print("❌ API URL 未设置")
            return false
        }
        
        let url = URL(string: "\(Self.apiURL)/api/users.php?action=send_reset_code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "phone": phone
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           (200...299).contains(httpResponse.statusCode) {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let success = json?["success"] as? Bool ?? false
            print("📱 发送验证码结果：\(success ? "成功" : "失败")")
            return success
        }
        
        return false
    }
    
    /// 重置密码（带验证码验证）
    func resetPasswordWithCode(phone: String, verifyCode: String, newPassword: String) async throws -> Bool {
        guard !Self.apiURL.isEmpty else {
            print("❌ API URL 未设置")
            return false
        }
        
        let url = URL(string: "\(Self.apiURL)/api/users.php?action=reset_password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "phone": phone,
            "verify_code": verifyCode,
            "new_password": newPassword
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           (200...299).contains(httpResponse.statusCode) {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let success = json?["success"] as? Bool ?? false
            print("🔐 重置密码结果：\(success ? "成功" : "失败")")
            return success
        }
        
        return false
    }
    
    // MARK: - 短信通知
    
    /// 发送短信通知（阿里云/腾讯云）
    func sendSmsNotification(phone: String, message: String) async throws -> Bool {
        guard !Self.apiURL.isEmpty else {
            print("❌ API URL 未设置")
            return false
        }
        
        // 调用后端 API，由后端调用短信服务商
        let url = URL(string: "\(Self.apiURL)/api/sms.php?action=send_sms")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "phone": phone,
            "message": message
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           (200...299).contains(httpResponse.statusCode) {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let success = json?["success"] as? Bool ?? false
            print("📱 发送短信结果：\(success ? "成功" : "失败")")
            return success
        }
        
        return false
    }
    
    /// 通知监护人（用户超时未签到）
    func notifyGuardian(guardianPhone: String, userName: String, hoursOverdue: Double) async throws -> Bool {
        let message = "【终活】您的家人\(userName)已超时\(Int(hoursOverdue))小时未签到，可能存在安全风险，请及时联系确认。"
        return try await sendSmsNotification(phone: guardianPhone, message: message)
    }
    
    /// 获取通知配置
    func fetchNotificationConfig() async -> NotificationConfig? {
        guard !Self.apiURL.isEmpty else { return nil }
        
        let url = URL(string: "\(Self.apiURL)/api/notification_config.php?action=get")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let success = json?["success"] as? Bool, success,
                   let data = json?["data"] as? [String: Any] {
                    
                    let config = NotificationConfig(
                        checkInInterval: data["checkInInterval"] as? Int ?? 48,
                        firstReminderHours: data["firstReminderHours"] as? Int ?? 12,
                        reminderInterval: data["reminderInterval"] as? Int ?? 2,
                        overduePushInterval: data["overduePushInterval"] as? Int ?? 1,
                        enableSmsNotification: data["enableSmsNotification"] as? Bool ?? true
                    )
                    
                    print("✅ 获取通知配置成功：间隔=\(config.checkInInterval)h, 首次=\(config.firstReminderHours)h, 重复=\(config.reminderInterval)h")
                    return config
                }
            }
        } catch {
            print("❌ 获取通知配置失败：\(error)")
        }
        
        // 返回默认配置
        return NotificationConfig()
    }
    
    // MARK: - 见证人管理
    func addWitness(_ witness: Witness) {
        witnesses.append(witness)
        saveWitnessesToFile()
        print("👥 见证人已添加到本地，准备同步到服务器...")
        
        // 发送数据变更通知（触发实时同步）
        NotificationCenter.default.post(name: NSNotification.Name("WitnessChanged"), object: nil)
        
        // 异步同步到服务器
        Task {
            if let result = await batchSyncWitnesses() {
                print("✅ 见证人同步成功：总计 \(result.total) 个，创建 \(result.created) 个，更新 \(result.updated) 个")
            } else {
                print("⚠️ 见证人同步失败（可能无网络或未登录）")
            }
        }
    }
    
    func deleteWitness(_ witness: Witness) {
        witnesses.removeAll { $0.id == witness.id }
        saveWitnessesToFile()
        print("👥 见证人已删除，准备同步到服务器...")
        
        // 发送数据变更通知（触发实时同步）
        NotificationCenter.default.post(name: NSNotification.Name("WitnessChanged"), object: nil)
        
        // 异步同步到服务器
        Task {
            if let result = await batchSyncWitnesses() {
                print("✅ 见证人同步成功：总计 \(result.total) 个，创建 \(result.created) 个，更新 \(result.updated) 个")
            } else {
                print("⚠️ 见证人同步失败（可能无网络或未登录）")
            }
        }
    }
    
    func updateWitness(_ witness: Witness) {
        if let index = witnesses.firstIndex(where: { $0.id == witness.id }) {
            witnesses[index] = witness
            saveWitnessesToFile()
            print("👥 见证人已更新到本地，准备同步到服务器...")
            
            // 发送数据变更通知（触发实时同步）
            NotificationCenter.default.post(name: NSNotification.Name("WitnessChanged"), object: nil)
            
            // 异步同步到服务器
            Task {
                if let result = await batchSyncWitnesses() {
                    print("✅ 见证人同步成功：总计 \(result.total) 个，创建 \(result.created) 个，更新 \(result.updated) 个")
                } else {
                    print("⚠️ 见证人同步失败（可能无网络或未登录）")
                }
            }
        }
    }
    
    func getWitnessProgress() -> Double {
        guard !witnesses.isEmpty else { return 0 }
        let confirmed = witnesses.filter { $0.isConfirmed }.count
        return Double(confirmed) / Double(witnesses.count)
    }
    
    func getWitnessProgressString() -> String {
        let total = witnesses.count
        let confirmed = witnesses.filter { $0.isConfirmed }.count
        return "\(confirmed)/\(total)"
    }
    
    // MARK: - 资产管理
    func addAsset(_ asset: Asset) {
        assets.append(asset)
        saveAssetsToFile()
    }
    
    func deleteAsset(_ asset: Asset) {
        assets.removeAll { $0.id == asset.id }
        saveAssetsToFile()
    }
    
    func deleteAssets(at offsets: IndexSet) {
        assets.remove(atOffsets: offsets)
        saveAssetsToFile()
    }
    
    func updateAsset(_ asset: Asset) {
        if let index = assets.firstIndex(where: { $0.id == asset.id }) {
            assets[index] = asset
            saveAssetsToFile()
            // TODO: 同步到服务器
            Task {
                await syncAssetToServer(asset)
            }
        }
    }
    
    // MARK: - 服务器同步
    
    /// 同步资产到服务器
    func syncAssetToServer(_ asset: Asset) async {
        guard !DataManager.apiURL.isEmpty else { return }
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/api/will.php?action=update_asset")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "id": asset.id,
            "type": asset.type.rawValue,
            "name": asset.name,
            "institution": asset.institution,
            "balance": asset.balance,
            "account_number": asset.accountNumber,
            "details": asset.details
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                print("✅ 资产已同步到服务器：\(asset.name)")
            }
        } catch {
            print("❌ 资产同步失败：\(error)")
        }
    }
    
    func updateWillModule(_ module: WillModule) {
        if let index = willModules.firstIndex(where: { $0.id == module.id }) {
            willModules[index] = module
            saveWillModulesToFile()
            print("📜 遗嘱模块已更新到本地，准备同步到服务器...")
            print("📊 当前 willModules.count: \(willModules.count)")
            print("📊 当前模块内容：\(module.title) - 完成：\(module.isCompleted)")
            
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
    }
    
    func deleteWillModule(_ module: WillModule) {
        willModules.removeAll { $0.id == module.id }
        saveWillModulesToFile()
        print("📜 遗嘱模块已从本地删除，准备同步到服务器...")
        
        // 发送数据变更通知（触发实时同步）
        NotificationCenter.default.post(name: NSNotification.Name("WillChanged"), object: nil)
        
        // 异步同步删除到服务器
        Task {
            if let result = await batchSyncWills() {
                print("✅ 遗嘱删除同步成功")
            } else {
                print("⚠️ 遗嘱删除同步失败")
            }
        }
        // TODO: 同步删除到服务器
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
        capsules.removeAll { $0.id == capsule.id }
    }
    
    func addCapsule(_ capsule: TimeCapsule) {
        capsules.append(capsule)
        saveCapsulesToFile()
        print("📦 胶囊已添加到本地，准备同步到服务器...")
        
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
    func syncCheckInStatus() async -> (isSafe: Bool, hoursRemaining: Double, autoCheckInPerformed: Bool)? {
        guard !DataManager.apiURL.isEmpty else { return nil }
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/api/checkin.php?action=checkin_sync")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                let result = try JSONDecoder().decode(ServerCheckInResponse.self, from: data)
                print("✅ 签到同步成功：剩余 \(result.data.hoursRemaining) 小时，自动签到=\(result.data.autoCheckInPerformed)")
                return (result.data.isSafe, result.data.hoursRemaining, result.data.autoCheckInPerformed)
            }
        } catch {
            print("❌ 签到同步失败：\(error)")
        }
        return nil
    }
    
    /// 批量同步遗嘱模块到服务器
    func batchSyncWillModules() async -> (total: Int, created: Int, updated: Int)? {
        guard !DataManager.apiURL.isEmpty else { return nil }
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/api/will.php?action=batch_sync")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 转换为后端格式
        let modulesData = willModules.map { module in
            [
                "id": module.id,
                "type": module.type,
                "title": module.title,
                "subtitle": module.subtitle,
                "content": module.content,
                "is_completed": module.isCompleted,
                "template": module.template ?? ""
            ]
        }
        
        let body: [String: Any] = ["modules": modulesData]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let data = result?["data"] as? [String: Any] {
                    let total = data["total"] as? Int ?? 0
                    let created = data["created"] as? Int ?? 0
                    let updated = data["updated"] as? Int ?? 0
                    print("✅ 遗嘱同步成功：总计 \(total), 新增 \(created), 更新 \(updated)")
                    return (total, created, updated)
                }
            }
        } catch {
            print("❌ 遗嘱同步失败：\(error)")
        }
        return nil
    }
    
    /// 批量同步胶囊到服务器
    func batchSyncCapsules() async -> (total: Int, created: Int, updated: Int)? {
        print("📦 开始同步胶囊：共 \(capsules.count) 个")
        guard !capsules.isEmpty else { return (0, 0, 0) }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let inputs = capsules.map { capsule in
            CapsuleInput(
                id: capsule.id,
                title: capsule.title,
                type: capsule.type.rawValue == "文字" ? "text" : capsule.type.rawValue,
                content: capsule.content,
                openAt: formatter.string(from: capsule.sendDate)
            )
        }
        
        do {
            let result = try await APIManager.shared.batchSyncCapsules(inputs)
            print("✅ 胶囊同步成功：\(result.total) 创建\(result.created) 更新\(result.updated)")
            return (result.total, result.created, result.updated)
        } catch {
            print("❌ 胶囊同步失败：\(error)")
            return nil
        }
    }
    
    func batchSyncWills() async -> (total: Int, created: Int, updated: Int)? {
        print("📜 开始同步遗嘱：共 \(willModules.count) 个")
        guard !willModules.isEmpty else { return (0, 0, 0) }
        
        let inputs = willModules.map { will in
            WillInput(id: will.id, type: will.type.rawValue, title: will.title, content: will.content)
        }
        
        do {
            let result = try await APIManager.shared.batchSyncWills(inputs)
            print("✅ 遗嘱同步成功：\(result.total) 创建\(result.created) 更新\(result.updated)")
            return (result.total, result.created, result.updated)
        } catch {
            print("❌ 遗嘱同步失败：\(error)")
            return nil
        }
    }
    
    func batchSyncEmergencyContacts() async -> (total: Int, created: Int, updated: Int)? {
        print("📞 紧急联系人同步：暂无本地数据")
        return (0, 0, 0)
        // TODO: 添加紧急联系人数据源后实现同步
    }
    
    func batchSyncWitnesses() async -> (total: Int, created: Int, updated: Int)? {
        print("👥 开始同步见证人：共 \(witnesses.count) 个")
        guard !witnesses.isEmpty else { return (0, 0, 0) }
        
        let inputs = witnesses.map { witness in
            WitnessInput(
                id: witness.id,
                name: witness.name,
                phone: witness.phone,
                relationship: witness.relationship,
                status: nil
            )
        }
        
        do {
            let result = try await APIManager.shared.batchSyncWitnesses(inputs)
            print("✅ 见证人同步成功：\(result.total) 创建\(result.created) 更新\(result.updated)")
            return (result.total, result.created, result.updated)
        } catch {
            print("❌ 见证人同步失败：\(error)")
            return nil
        }
    }
    
    func uploadMediaToServer(_ fileURL: URL, type: TimeCapsule.CapsuleType) async -> String? {
        print("☁️ ====== uploadMediaToServer 开始 ======")
        
        guard !DataManager.apiURL.isEmpty else {
            print("⚠️ 上传失败：API URL 为空")
            return nil
        }
        
        let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
        if token.isEmpty {
            print("⚠️ 上传失败：无 token")
            return nil
        }
        
        // 创建上传请求
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/api/upload.php?action=upload")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // 构建 multipart/form-data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加文件
        do {
            let fileData = try Data(contentsOf: fileURL)
            let filename = fileURL.lastPathComponent
            let mimetype = type == .audio ? "audio/mp4" : "video/mp4"
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
            
            // 添加类型参数
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"type\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(type == .audio ? "audio" : "video")\r\n".data(using: .utf8)!)
            
            // 添加 token
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"token\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(token)\r\n".data(using: .utf8)!)
            
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            let fileSizeMB = String(format: "%.2f", Double(fileData.count) / 1024 / 1024)
            print("📤 上传文件：\(filename) (\(fileSizeMB) MB)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 上传响应状态码：\(httpResponse.statusCode)")
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 上传响应：\(jsonString)")
                
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let result = json["status"] as? String, result == "success",
                   let fileURL = json["url"] as? String {
                    print("✅ 上传成功：\(fileURL)")
                    return fileURL
                }
            }
            
        } catch {
            print("❌ 上传失败：\(error)")
        }
        
        return nil
    }
    
    // MARK: - 系统配置
    
    /// 加载系统配置（后端可配置）
    func loadSystemConfig() async {
        print("⚙️ ====== loadSystemConfig 开始 ======")
        
        guard !DataManager.apiURL.isEmpty else {
            print("⚠️ 系统配置加载失败：API URL 为空")
            return
        }
        
        do {
            let url = URL(string: "\(DataManager.apiURL)/api/config_get.php")!
            print("📡 请求系统配置：\(url)")
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 系统配置响应状态码：\(httpResponse.statusCode)")
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 系统配置响应：\(jsonString)")
                
                let result = try JSONDecoder().decode(ConfigResponse.self, from: data)
                
                if result.status == "success" {
                    systemConfig = result.data
                    print("✅ 系统配置加载成功")
                    print("   - 签到提醒阈值：\(systemConfig.checkinReminderThresholdHours) 小时")
                    print("   - 签到提醒间隔：\(systemConfig.checkinReminderIntervalHours) 小时")
                    print("   - 离线超时阈值：\(systemConfig.offlineTimeoutHours) 小时")
                    print("   - 签到间隔：\(systemConfig.checkinIntervalHours) 小时")
                } else {
                    print("⚠️ 系统配置加载失败：\(result.message ?? "未知错误")")
                }
            }
        } catch {
            print("❌ 系统配置加载失败：\(error)")
            // 使用默认配置
            print("ℹ️ 使用默认系统配置")
        }
    }


    // MARK: - 临时方法（待迁移到 GraphQL）
    
    /// 下载所有数据（临时实现）
    func downloadAllData() async {
        print("📥 开始从云端下载数据...")
        
        do {
            let apiManager = APIManager.shared
            let result = try await apiManager.fetchUserData()
            
            // 从字典中解析数据
            await MainActor.run {
                // 解析胶囊数据
                if let capsulesArray = result["capsules"] as? [[String: Any]] {
                    capsules = capsulesArray.compactMap { dict -> TimeCapsule? in
                        guard let id = dict["id"] as? String,
                              let title = dict["title"] as? String,
                              let type = dict["type"] as? String else { return nil }
                        return TimeCapsule(
                            id: id,
                            title: title,
                            content: dict["content"] as? String ?? "",
                            type: TimeCapsule.CapsuleType(rawValue: type) ?? .text,
                            sendDate: Date(),
                            isSent: false,
                            createdAt: Date()
                        )
                    }
                }
                
                // 解析遗嘱数据
                if let willsArray = result["wills"] as? [[String: Any]] {
                    willModules = willsArray.compactMap { dict -> WillModule? in
                        guard let id = dict["id"] as? String,
                              let typeStr = dict["type"] as? String,
                              let title = dict["title"] as? String else { return nil }
                        return WillModule(
                            id: id,
                            type: WillModule.WillType(rawValue: typeStr) ?? .property,
                            title: title,
                            subtitle: "",
                            content: dict["content"] as? String ?? "",
                            isCompleted: false
                        )
                    }
                }
            }
            
            print("✅ 数据下载成功")
        } catch {
            print("❌ 数据下载失败：\(error)")
        }
    }
    
    /// 持久化媒体文件（临时实现）
    func persistMediaFile(_ tempURL: URL) async -> URL? {
        // 移动到 Documents 目录
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let permanentURL = documents.appendingPathComponent(tempURL.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: permanentURL.path) {
                try FileManager.default.removeItem(at: permanentURL)
            }
            try FileManager.default.copyItem(at: tempURL, to: permanentURL)
            print("✅ 媒体文件已持久化：\(permanentURL.path)")
            return permanentURL
        } catch {
            print("❌ 媒体文件持久化失败：\(error)")
            return tempURL
        }
    }
    
}
