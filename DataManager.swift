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
    }
    
    func deleteWitness(_ witness: Witness) {
        witnesses.removeAll { $0.id == witness.id }
    }
    
    func updateWitness(_ witness: Witness) {
        if let index = witnesses.firstIndex(where: { $0.id == witness.id }) {
            witnesses[index] = witness
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
        }
    }
    
    func deleteWillModule(_ module: WillModule) {
        willModules.removeAll { $0.id == module.id }
        saveWillModulesToFile()
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
    }
    
    func updateCapsule(_ capsule: TimeCapsule) {
        if let index = capsules.firstIndex(where: { $0.id == capsule.id }) {
            capsules[index] = capsule
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
        guard !DataManager.apiURL.isEmpty else { return nil }
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/capsules.php?action=batch_sync")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 转换为后端格式
        let capsulesData = capsules.map { capsule in
            var data: [String: Any] = [
                "id": capsule.id,
                "title": capsule.title,
                "content": capsule.content,
                "type": capsule.type.rawValue,
                "send_date": ISO8601DateFormatter().string(from: capsule.sendDate),
                "is_sent": capsule.isSent
            ]
            if !capsule.mediaURL.isEmpty {
                data["media_url"] = capsule.mediaURL
            }
            return data
        }
        
        let body: [String: Any] = ["capsules": capsulesData]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let data = result?["data"] as? [String: Any] {
                    let total = data["total"] as? Int ?? 0
                    let created = data["created"] as? Int ?? 0
                    let updated = data["updated"] as? Int ?? 0
                    print("✅ 胶囊同步成功：总计 \(total), 新增 \(created), 更新 \(updated)")
                    return (total, created, updated)
                }
            }
        } catch {
            print("❌ 胶囊同步失败：\(error)")
        }
        return nil
    }
}
