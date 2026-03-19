//
//  DataManager.swift
//  终活
//
//  Created on 2026-03-15.
//

import Foundation

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
    func fetchServerConfig(from baseURL: String) async throws {
        let configURL = "\(baseURL)/api/config.php"
        guard let url = URL(string: configURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的 URL: \(configURL)"])
        }
        
        print("🌐 请求配置：\(configURL)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid response", code: -1)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Server error", code: httpResponse.statusCode)
        }
        
        let config = try JSONDecoder().decode(ServerConfig.self, from: data)
        
        guard config.success, let configData = config.data else {
            throw NSError(domain: "Config error", code: -1, userInfo: [NSLocalizedDescriptionKey: config.error ?? "配置加载失败"])
        }
        
        await MainActor.run {
            self.serverConfig = config
            
            // 使用后端返回的地址（无条件相信）
            DataManager.baseURL = configData.endpoints.base
            DataManager.apiURL = configData.endpoints.api
            
            // 解析短信配置
            if let smsData = configData.sms {
                self.smsConfig = try? JSONDecoder().decode(ServerConfig.ServerConfigData.SMSConfig.self, from: JSONSerialization.data(withJSONObject: smsData))
            }
            
            self.isBackendOnline = true
            
            // 保存地址供下次使用
            UserDefaults.standard.set(DataManager.baseURL, forKey: "lastUsedBaseURL")
            
            print("✅ 后端配置获取成功")
            print("   Base URL: \(DataManager.baseURL)")
            print("   API URL: \(DataManager.apiURL)")
            print("   短信模式：\(self.smsConfig?.isDevelopment ?? true ? "测试" : "生产")")
            
            if let serverInfo = configData.serverInfo {
                print("   服务器信息：\(serverInfo)")
            }
        }
    }
    
    /// 初始化 API 配置（同步版本 - 立即设置默认值）
    func initializeAPIConfig() {
        // 立即设置默认值，确保 API 立即可用
        DataManager.baseURL = "http://8.136.41.211:3395"
        DataManager.apiURL = "http://8.136.41.211:3395/api"
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
            DataManager.apiURL = "http://8.136.41.211:3395/api"
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
    
    // MARK: - 见证人管理
    func addWitness(_ witness: Witness) {
        witnesses.append(witness)
        saveWitnessesToFile()
        print("👥 见证人已添加到本地，准备同步到服务器...")
        
        // 发送数据变更通知（触发实时同步）
        NotificationCenter.default.postWitnessChanged()
        
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
        NotificationCenter.default.postWitnessChanged()
        
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
            NotificationCenter.default.postWitnessChanged()
            
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
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/will.php?resource=asset&action=update")!)
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
            NotificationCenter.default.postWillChanged()
            
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
        NotificationCenter.default.postCapsuleChanged()
        
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
            NotificationCenter.default.postCapsuleChanged()
            
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
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/checkin.php?action=sync")!)
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
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/will.php?action=batch_sync")!)
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
        print("📦 ====== batchSyncCapsules 开始 ======")
        print("   - API URL: \(DataManager.apiURL)")
        
        let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
        print("   - Token: \(token.prefix(30))...")
        print("   - Token 长度：\(token.count)")
        print("   - 本地胶囊数：\(capsules.count)")
        
        // ✅ 检查 Token 是否有效
        if token.isEmpty {
            print("⚠️ 胶囊同步失败：无 token（用户未登录）")
            return nil
        }
        
        // ✅ 检查 Token 是否过期
        if isTokenExpired(token) {
            print("⚠️ 胶囊同步失败：Token 已过期，请重新登录")
            // 清除过期 Token
            UserDefaults.standard.removeObject(forKey: "userToken")
            UserDefaults.standard.removeObject(forKey: "isLoggedIn")
            return nil
        }
        
        guard !DataManager.apiURL.isEmpty else {
            print("⚠️ 胶囊同步失败：API URL 为空")
            return nil
        }
        
        guard !capsules.isEmpty else {
            print("ℹ️ 胶囊同步：无数据需要同步（capsules 数组为空）")
            return (0, 0, 0)
        }
        
        print("🔄 开始同步胶囊：共 \(capsules.count) 个")
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/capsules.php?action=batch_sync")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // 转换为后端格式（支持删除标记）
        let formatter = ISO8601DateFormatter()
        let capsulesData = capsules.map { capsule -> [String: Any] in
            var data: [String: Any] = [
                "id": capsule.id,
                "title": capsule.title,
                "content": capsule.content,
                "media_type": capsule.type.rawValue == "文字" ? "text" : capsule.type.rawValue,
                "open_at": formatter.string(from: capsule.sendDate),
                "is_opened": capsule.isSent ? 1 : 0
            ]
            if !capsule.mediaURL.isEmpty {
                data["media_url"] = capsule.mediaURL
            }
            // 如果有 deletedAt 字段，标记为删除
            if let deletedAt = capsule.deletedAt {
                data["deleted_at"] = formatter.string(from: deletedAt)
            }
            return data
        }
        
        let body: [String: Any] = ["capsules": capsulesData, "token": token]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("📤 胶囊同步请求：\(capsules.count) 个胶囊")
            print("🌐 请求 URL: \(request.url?.absoluteString ?? "nil")")
            print("📋 请求方法：\(request.httpMethod ?? "nil")")
            print("🔑 请求头 - Content-Type: \(request.value(forHTTPHeaderField: "Content-Type") ?? "nil")")
            print("🔑 请求头 - Authorization: \(request.value(forHTTPHeaderField: "Authorization")?.prefix(50) ?? "nil")...")
            
            if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                print("📦 请求体：\(bodyString.prefix(500))...")
            }
            
            print("⏳ 开始发送请求...")
            let (data, response) = try await URLSession.shared.data(for: request)
            print("✅ 请求完成，收到响应")
            
            // ✅ 验证响应
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 胶囊同步失败：响应不是 HTTPURLResponse")
                return nil
            }
            
            print("📡 胶囊同步响应状态码：\(httpResponse.statusCode)")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 胶囊同步响应：\(jsonString)")
            }
            
            // ✅ 处理不同状态码
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                print("❌ 胶囊同步失败：401 未授权（Token 无效或过期）")
                UserDefaults.standard.removeObject(forKey: "userToken")
                UserDefaults.standard.removeObject(forKey: "isLoggedIn")
                return nil
            case 403:
                print("❌ 胶囊同步失败：403 权限不足")
                return nil
            case 404:
                print("❌ 胶囊同步失败：404 API 不存在")
                return nil
            case 500...599:
                print("❌ 胶囊同步失败：\(httpResponse.statusCode) 服务器错误")
                return nil
            default:
                print("❌ 胶囊同步失败：未知状态码 \(httpResponse.statusCode)")
                return nil
            }
            
            // ✅ 解析响应
            guard let result = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ 胶囊同步失败：无法解析响应 JSON")
                return nil
            }
            
            if let success = result["success"] as? Bool, success {
                if let data = result["data"] as? [String: Any] {
                    let total = data["synced"] as? Int ?? data["total"] as? Int ?? 0
                    let created = data["created"] as? Int ?? 0
                    let updated = data["updated"] as? Int ?? 0
                    print("✅ 胶囊同步成功：总计 \(total), 新增 \(created), 更新 \(updated)")
                    return (total, created, updated)
                }
            } else {
                if let error = result["error"] as? [String: Any] {
                    let code = error["code"] as? String ?? "UNKNOWN"
                    let message = error["message"] as? String ?? "未知错误"
                    print("❌ 胶囊同步失败：[\(code)] \(message)")
                } else if let message = result["message"] as? String {
                    print("⚠️ 胶囊同步返回：\(message)")
                }
                return nil
            }
        } catch let urlError as URLError {
            print("❌ 胶囊同步失败：网络错误 - \(urlError.localizedDescription)")
            switch urlError.code {
            case .notConnectedToInternet:
                print("💡 建议：检查网络连接")
            case .timedOut:
                print("💡 建议：检查服务器是否响应")
            case .cannotFindHost:
                print("💡 建议：检查 API URL 是否正确")
            default:
                break
            }
            return nil
        } catch {
            print("❌ 胶囊同步失败：\(error)")
            print("📋 错误类型：\(type(of: error))")
        }
        return nil
    }
    
    // MARK: - 遗嘱同步到服务器
    
    /// 批量同步遗嘱到服务器
    func batchSyncWills() async -> (total: Int, created: Int, updated: Int)? {
        print("📜 ====== batchSyncWills 开始 ======")
        
        let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
        print("   - Token: \(token.prefix(30))...")
        
        // ✅ 检查 Token 是否有效
        if token.isEmpty {
            print("⚠️ 遗嘱同步失败：无 token（用户未登录）")
            return nil
        }
        
        // ✅ 检查 Token 是否过期
        if isTokenExpired(token) {
            print("⚠️ 遗嘱同步失败：Token 已过期，请重新登录")
            UserDefaults.standard.removeObject(forKey: "userToken")
            UserDefaults.standard.removeObject(forKey: "isLoggedIn")
            return nil
        }
        
        guard !DataManager.apiURL.isEmpty else {
            print("⚠️ 遗嘱同步失败：API URL 为空")
            return nil
        }
        
        guard !willModules.isEmpty else {
            print("ℹ️ 遗嘱同步：无数据需要同步")
            return (0, 0, 0)
        }
        
        print("🔄 开始同步遗嘱：共 \(willModules.count) 个模块")
        print("🌐 API URL: \(DataManager.apiURL)")
        print("🔑 Token 长度：\(token.count)")
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/will.php?action=batch_sync")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("📍 请求 URL: \(request.url?.absoluteString ?? "nil")")
        print("📋 Headers: Content-Type=\(request.value(forHTTPHeaderField: "Content-Type") ?? "nil"), Authorization=\(request.value(forHTTPHeaderField: "Authorization")?.prefix(30) ?? "nil")...")
        
        // 转换为后端格式
        let willsData = willModules.map { module in
            [
                "id": module.id,
                "type": module.type.rawValue,
                "title": module.title,
                "subtitle": module.subtitle,
                "content": module.content,
                "is_completed": module.isCompleted ? 1 : 0
            ] as [String : Any]
        }
        
        let body: [String: Any] = ["wills": willsData, "token": token]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let bodyString = String(data: request.httpBody!, encoding: .utf8) ?? "无法解析"
            print("📤 遗嘱同步请求：\(willModules.count) 个模块")
            print("📦 请求体：\(bodyString.prefix(200))...")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 遗嘱同步失败：响应不是 HTTPURLResponse")
                return nil
            }
            
            print("📡 遗嘱同步响应状态码：\(httpResponse.statusCode)")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 遗嘱同步响应：\(jsonString)")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                print("❌ 遗嘱同步失败：401 未授权（Token 无效或过期）")
                UserDefaults.standard.removeObject(forKey: "userToken")
                UserDefaults.standard.removeObject(forKey: "isLoggedIn")
                return nil
            case 403:
                print("❌ 遗嘱同步失败：403 权限不足")
                return nil
            case 404:
                print("❌ 遗嘱同步失败：404 API 不存在")
                return nil
            case 500...599:
                print("❌ 遗嘱同步失败：\(httpResponse.statusCode) 服务器错误")
                return nil
            default:
                print("❌ 遗嘱同步失败：未知状态码 \(httpResponse.statusCode)")
                return nil
            }
            
            guard let result = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ 遗嘱同步失败：无法解析响应 JSON")
                return nil
            }
            
            if let success = result["success"] as? Bool, success {
                if let data = result["data"] as? [String: Any] {
                    let total = data["synced"] as? Int ?? data["total"] as? Int ?? 0
                    let created = data["created"] as? Int ?? 0
                    let updated = data["updated"] as? Int ?? 0
                    print("✅ 遗嘱同步成功：总计 \(total), 新增 \(created), 更新 \(updated)")
                    return (total, created, updated)
                }
            } else {
                if let error = result["error"] as? [String: Any] {
                    let code = error["code"] as? String ?? "UNKNOWN"
                    let message = error["message"] as? String ?? "未知错误"
                    print("❌ 遗嘱同步失败：[\(code)] \(message)")
                } else if let message = result["message"] as? String {
                    print("⚠️ 遗嘱同步返回：\(message)")
                }
                return nil
            }
        } catch let urlError as URLError {
            print("❌ 遗嘱同步失败：网络错误 - \(urlError.localizedDescription)")
            return nil
        } catch {
            print("❌ 遗嘱同步失败：\(error)")
            print("📋 错误类型：\(type(of: error))")
        }
        return nil
    }
    
    // MARK: - 紧急联系人同步
    
    /// 批量同步紧急联系人到服务器
    func batchSyncEmergencyContacts() async -> (total: Int, created: Int, updated: Int)? {
        print("📞 ====== batchSyncEmergencyContacts 开始 ======")
        
        let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
        print("   - Token: \(token.prefix(30))...")
        
        // ✅ 检查 Token 是否有效
        if token.isEmpty {
            print("⚠️ 紧急联系人同步失败：无 token（用户未登录）")
            return nil
        }
        
        // ✅ 检查 Token 是否过期
        if isTokenExpired(token) {
            print("⚠️ 紧急联系人同步失败：Token 已过期，请重新登录")
            UserDefaults.standard.removeObject(forKey: "userToken")
            UserDefaults.standard.removeObject(forKey: "isLoggedIn")
            return nil
        }
        
        guard !DataManager.apiURL.isEmpty else {
            print("⚠️ 紧急联系人同步失败：API URL 为空")
            return nil
        }
        
        guard let user = currentUser, !user.emergencyContacts.isEmpty else {
            print("ℹ️ 紧急联系人同步：无数据需要同步")
            return (0, 0, 0)
        }
        
        print("🔄 开始同步紧急联系人：共 \(user.emergencyContacts.count) 个")
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/emergency_contacts.php?action=batch_sync")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let formatter = ISO8601DateFormatter()
        let contactsData = user.emergencyContacts.map { contact -> [String: Any] in
            var data: [String: Any] = [
                "id": contact.id,
                "name": contact.name,
                "relationship": contact.relationship,
                "phone": contact.phone
            ]
            // 如果有 deletedAt 字段，标记为删除
            if let deletedAt = contact.deletedAt {
                data["deleted_at"] = formatter.string(from: deletedAt)
            }
            return data
        }
        
        let body: [String: Any] = ["contacts": contactsData, "token": token]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("📤 紧急联系人同步请求：\(user.emergencyContacts.count) 个联系人")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 紧急联系人同步响应状态码：\(httpResponse.statusCode)")
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 紧急联系人同步响应：\(jsonString)")
            }
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let success = result?["success"] as? Bool, success {
                    if let data = result?["data"] as? [String: Any] {
                        let total = data["synced"] as? Int ?? 0
                        let created = data["created"] as? Int ?? 0
                        let updated = data["updated"] as? Int ?? 0
                        print("✅ 紧急联系人同步成功：总计 \(total), 新增 \(created), 更新 \(updated)")
                        
                        
                        return (total, created, updated)
                    }
                }
            }
        } catch {
            print("❌ 紧急联系人同步失败：\(error)")
            
        }
        return nil
    }
    
    // MARK: - 从服务器下载数据
    
    /// 从服务器下载所有数据（智能合并：本地 + 云端）
    func downloadAllData() async {
        print("📥 ====== 开始从服务器下载数据 ======")
        print("🎯 下载策略：智能合并本地和云端数据")
        
        guard let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty else {
            print("⚠️ 下载失败：无 token")
            return
        }
        
        guard !DataManager.apiURL.isEmpty else {
            print("⚠️ 下载失败：API URL 为空")
            return
        }
        
        await downloadCapsules()
        await downloadWills()
        await downloadEmergencyContacts()
        await downloadWitnesses()
        
        print("🎉 所有数据下载完成！")
        print("📊 本地数据已更新")
        print("📥 ====== 下载完成 ======")
    }
    
    /// 从服务器下载胶囊
    func downloadCapsules() async {
        print("📦 下载胶囊数据...")
        
        guard let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty else {
            print("⚠️ 胶囊下载失败：无 token")
            return
        }
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/capsules.php?action=list&token=\(token)")!)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let capsulesData = json["data"] as? [[String: Any]] {
                    
                    let formatter = ISO8601DateFormatter()
                    var downloaded: [TimeCapsule] = []
                    
                    for item in capsulesData {
                        guard let id = item["id"] as? String,
                              let title = item["title"] as? String,
                              let content = item["content"] as? String,
                              let openAtStr = item["open_at"] as? String,
                              let openAt = formatter.date(from: openAtStr) else {
                            continue
                        }
                        
                        let mediaType = item["media_type"] as? String ?? "text"
                        let mediaUrl = item["media_url"] as? String ?? ""
                        let isSent = (item["is_opened"] as? Int ?? 0) == 1
                        
                        let capsule = TimeCapsule(
                            id: id,
                            title: title,
                            content: content,
                            type: TimeCapsule.CapsuleType(rawValue: mediaType) ?? .text,
                            mediaURL: mediaUrl,
                            sendDate: openAt,
                            isSent: isSent,
                            createdAt: Date()
                        )
                        downloaded.append(capsule)
                    }
                    
                    await MainActor.run {
                        // 🎯 智能合并：本地 + 云端，去重
                        var mergedCapsules = self.capsules
                        for newCapsule in downloaded {
                            if let index = mergedCapsules.firstIndex(where: { $0.id == newCapsule.id }) {
                                // 本地已有，更新时间新的优先
                                if newCapsule.createdAt > mergedCapsules[index].createdAt {
                                    mergedCapsules[index] = newCapsule
                                    print("🔄 更新胶囊：\(newCapsule.title)")
                                }
                            } else {
                                // 本地没有，添加
                                mergedCapsules.append(newCapsule)
                                print("➕ 新增胶囊：\(newCapsule.title)")
                            }
                        }
                        self.capsules = mergedCapsules
                        saveCapsulesToFile()
                    }
                    
                    print("✅ 胶囊下载成功：\(downloaded.count) 个，合并后共 \(self.capsules.count) 个")
                }
            }
        } catch {
            print("❌ 胶囊下载失败：\(error)")
        }
    }
    
    /// 从服务器下载遗嘱
    func downloadWills() async {
        print("📝 下载遗嘱数据...")
        
        guard let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty else {
            print("⚠️ 遗嘱下载失败：无 token")
            return
        }
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/will.php?action=list&token=\(token)")!)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let willsData = json["data"] as? [[String: Any]] {
                    
                    var downloaded: [WillModule] = []
                    
                    for item in willsData {
                        guard let id = item["id"] as? String,
                              let typeStr = item["type"] as? String,
                              let title = item["title"] as? String else {
                            continue
                        }
                        
                        // 将字符串转换为 WillType 枚举
                        let willType = WillModule.WillType(rawValue: typeStr) ?? .otherInstructions
                        
                        let will = WillModule(
                            id: id,
                            type: willType,
                            title: title,
                            subtitle: item["subtitle"] as? String ?? "",
                            content: item["content"] as? String ?? "",
                            isCompleted: (item["is_completed"] as? Int ?? 0) == 1
                        )
                        downloaded.append(will)
                    }
                    
                    await MainActor.run {
                        // 🎯 智能合并：保留本地有但服务器没有的数据（可能还没同步）
                        var merged = downloaded
                        
                        // 添加本地有但服务器没有的模块
                        for localModule in willModules {
                            if !downloaded.contains(where: { $0.id == localModule.id }) {
                                merged.append(localModule)
                                print("📝 保留本地遗嘱模块（未同步到服务器）：\(localModule.title)")
                            }
                        }
                        
                        self.willModules = merged
                        saveWillModulesToFile()
                        print("✅ 遗嘱下载成功：服务器 \(downloaded.count) 个 + 本地 \(willModules.count - downloaded.count) 个 = 合并 \(merged.count) 个")
                    }
                }
            }
        } catch {
            print("❌ 遗嘱下载失败：\(error)")
        }
    }
    
    /// 从服务器下载紧急联系人
    func downloadEmergencyContacts() async {
        print("👥 下载紧急联系人...")
        
        guard let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty else {
            print("⚠️ 紧急联系人下载失败：无 token")
            return
        }
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/emergency_contacts.php?action=list&token=\(token)")!)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let contactsData = json["data"] as? [[String: Any]] {
                    
                    var downloaded: [User.EmergencyContact] = []
                    
                    for item in contactsData {
                        guard let id = item["id"] as? String,
                              let name = item["name"] as? String,
                              let phone = item["phone"] as? String else {
                            continue
                        }
                        
                        let contact = User.EmergencyContact(
                            id: id,
                            name: name,
                            phone: phone,
                            relationship: item["relationship"] as? String ?? ""
                        )
                        downloaded.append(contact)
                    }
                    
                    await MainActor.run {
                        // 🎯 智能合并：保留本地有但服务器没有的数据
                        var merged = downloaded
                        
                        if let user = UserManager.shared.currentUser {
                            for localContact in user.emergencyContacts {
                                if !downloaded.contains(where: { $0.id == localContact.id }) {
                                    merged.append(localContact)
                                    print("📞 保留本地紧急联系人（未同步到服务器）：\(localContact.name)")
                                }
                            }
                            
                            // 更新当前用户的紧急联系人
                            var updatedUser = user
                            updatedUser.emergencyContacts = merged
                            UserManager.shared.currentUser = updatedUser
                            _ = UserManager.shared.saveUser(updatedUser)
                            
                            print("✅ 紧急联系人下载成功：服务器 \(downloaded.count) 个 + 本地 \(user.emergencyContacts.count - downloaded.count) 个 = 合并 \(merged.count) 个")
                        }
                    }
                }
            }
        } catch {
            print("❌ 紧急联系人下载失败：\(error)")
        }
    }
    
    /// 从服务器下载见证人
    func downloadWitnesses() async {
        print("👤 下载见证人...")
        
        guard let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty else {
            print("⚠️ 见证人下载失败：无 token")
            return
        }
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/will.php?action=list_witnesses&token=\(token)")!)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let witnessesData = json["data"] as? [[String: Any]] {
                    
                    var downloaded: [Witness] = []
                    
                    for item in witnessesData {
                        guard let id = item["id"] as? String,
                              let name = item["name"] as? String else {
                            continue
                        }
                        
                        let witness = Witness(
                            id: id,
                            name: name,
                            role: item["relationship"] as? String ?? "",
                            phone: item["phone"] as? String ?? "",
                            isConfirmed: (item["is_confirmed"] as? Int ?? 0) == 1,
                            order: 0,
                            idNumber: item["id_number"] as? String ?? "",
                            notes: item["notes"] as? String ?? ""
                        )
                        downloaded.append(witness)
                    }
                    
                    await MainActor.run {
                        // 🎯 智能合并：保留本地有但服务器没有的数据
                        var merged = downloaded
                        
                        for localWitness in witnesses {
                            if !downloaded.contains(where: { $0.id == localWitness.id }) {
                                merged.append(localWitness)
                                print("👥 保留本地见证人（未同步到服务器）：\(localWitness.name)")
                            }
                        }
                        
                        self.witnesses = merged
                        saveWitnessesToFile()
                        print("✅ 见证人下载成功：服务器 \(downloaded.count) 个 + 本地 \(witnesses.count - downloaded.count) 个 = 合并 \(merged.count) 个")
                    }
                }
            }
        } catch {
            print("❌ 见证人下载失败：\(error)")
        }
    }
    
    // MARK: - 见证人同步
    
    /// 批量同步见证人到服务器
    func batchSyncWitnesses() async -> (total: Int, created: Int, updated: Int)? {
        print("👥 ====== batchSyncWitnesses 开始 ======")
        
        let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
        print("   - Token: \(token.prefix(30))...")
        
        // ✅ 检查 Token 是否有效
        if token.isEmpty {
            print("⚠️ 见证人同步失败：无 token（用户未登录）")
            return nil
        }
        
        // ✅ 检查 Token 是否过期
        if isTokenExpired(token) {
            print("⚠️ 见证人同步失败：Token 已过期，请重新登录")
            UserDefaults.standard.removeObject(forKey: "userToken")
            UserDefaults.standard.removeObject(forKey: "isLoggedIn")
            return nil
        }
        
        guard !DataManager.apiURL.isEmpty else {
            print("⚠️ 见证人同步失败：API URL 为空")
            return nil
        }
        
        guard !witnesses.isEmpty else {
            print("ℹ️ 见证人同步：无数据需要同步")
            return (0, 0, 0)
        }
        
        print("🔄 开始同步见证人：共 \(witnesses.count) 个")
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/will.php?action=sync_witnesses")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let formatter = ISO8601DateFormatter()
        let witnessesData = witnesses.map { witness -> [String: Any] in
            var data: [String: Any] = [
                "id": witness.id,
                "name": witness.name,
                "relationship": witness.relationship,
                "phone": witness.phone,
                "id_number": witness.idNumber ?? "",
                "notes": witness.notes ?? "",
                "is_confirmed": witness.isConfirmed ? 1 : 0
            ]
            // 如果有 deletedAt 字段，标记为删除
            if let deletedAt = witness.deletedAt {
                data["deleted_at"] = formatter.string(from: deletedAt)
            }
            return data
        }
        
        let body: [String: Any] = ["witnesses": witnessesData, "token": token]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("📤 见证人同步请求：\(witnesses.count) 个见证人")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 见证人同步响应状态码：\(httpResponse.statusCode)")
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 见证人同步响应：\(jsonString)")
            }
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let success = result?["success"] as? Bool, success {
                    if let data = result?["data"] as? [String: Any] {
                        let total = data["synced"] as? Int ?? 0
                        let created = data["created"] as? Int ?? 0
                        let updated = data["updated"] as? Int ?? 0
                        print("✅ 见证人同步成功：总计 \(total), 新增 \(created), 更新 \(updated)")
                        
                        
                        return (total, created, updated)
                    }
                }
            }
        } catch {
            print("❌ 见证人同步失败：\(error)")
            
        }
        return nil
    }
    
    // MARK: - 系统配置
    
    /// 加载系统配置（后端可配置）
    func loadSystemConfig() async {
        print("📥 加载系统配置...")
        
        guard let url = URL(string: "\(apiURL)/settings.php") else {
            print("⚠️ 配置加载失败：URL 无效")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("⚠️ 配置加载失败：HTTP 错误")
                return
            }
            
            let result = try JSONDecoder().decode(ConfigResponse.self, from: data)
            
            if result.status == "success" {
                systemConfig = result.data
                print("✅ 系统配置加载成功")
                print("   - 签到提醒阈值：\(systemConfig.checkinReminderThresholdHours) 小时")
                print("   - 签到提醒间隔：\(systemConfig.checkinReminderIntervalHours) 小时")
                print("   - 最少紧急联系人：\(systemConfig.minimumEmergencyContacts) 人")
            } else {
                print("⚠️ 配置加载失败：\(result.message ?? "未知错误")")
            }
        } catch {
            print("❌ 配置加载失败：\(error)")
            // 使用默认配置
            print("⚠️ 使用默认配置")
        }
    }
}
