//
//  DataManager.swift
//  终活
//
//  数据管理 - 增删改查 + 持久化
//

import Foundation

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // MARK: - 后端 API 配置（动态获取）
    // 默认配置（仅用于首次启动，之后从服务器动态获取）
    static var baseURL: String = ""  // 空值表示等待动态获取
    static var apiURL: String = ""
    
    // 从服务器动态获取的配置
    @Published var serverConfig: ServerConfig?
    @Published var isBackendOnline = false
    
    // 短信配置（从后端获取）
    @Published var smsConfig: SMSConfig?
    
    struct SMSConfig: Codable {
        let enabled: Bool
        let provider: String
        let isDevelopment: Bool
    }
    
    @Published var capsules: [TimeCapsule] = []
    @Published var willModules: [WillModule] = []
    @Published var assets: [Asset] = []
    @Published var witnesses: [WillWitness] = []
    @Published var checklistItems: [ChecklistItem] = []
    @Published var settings: UserSettings
    
    // MARK: - API 配置管理
    /// 从服务器获取 API 配置（深度绑定，自动适配服务器地址）
    func fetchServerConfig(fallbackBaseURL: String) async throws {
        // 先尝试使用 fallbackBaseURL 获取配置
        let configURL = "\(fallbackBaseURL)/api/config.php"
        guard let url = URL(string: configURL) else {
            throw NSError(domain: "Invalid URL", code: -1)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Server error", code: -1)
        }
        
        let config = try JSONDecoder().decode(ServerConfig.self, from: data)
        
        if config.success, let configData = config.data {
            DispatchQueue.main.async {
                self.serverConfig = ServerConfig(success: true, data: configData, error: nil)
                // 使用后端返回的动态地址（深度绑定）
                DataManager.baseURL = configData.endpoints.base
                DataManager.apiURL = configData.endpoints.api
                
                // 解析短信配置
                if let smsData = configData.sms {
                    self.smsConfig = try? JSONDecoder().decode(SMSConfig.self, from: JSONSerialization.data(withJSONObject: smsData))
                }
                
                self.isBackendOnline = true
                print("✅ 后端配置获取成功：\(DataManager.apiURL)")
                print("📱 短信模式：\(self.smsConfig?.isDevelopment ?? true ? "测试" : "生产")")
            }
        } else {
            throw NSError(domain: config.error ?? "Unknown error", code: -1)
        }
    }
    
    /// 初始化 API 配置（从 AppStorage 获取上次使用的地址，或尝试常见地址）
    func initializeAPIConfig() {
        Task {
            await initializeAPIConfigAsync()
        }
    }
    
    /// 异步初始化 API 配置
    func initializeAPIConfigAsync() async {
        // 尝试从 AppStorage 获取上次使用的服务器地址
        let savedBaseURL = UserDefaults.standard.string(forKey: "lastUsedBaseURL") ?? ""
        
        // 尝试顺序：保存的地址 > 常见地址
        let candidates = savedBaseURL.isEmpty
            ? ["http://8.136.41.211:3395", "http://localhost:3395", "http://127.0.0.1:3395"]
            : [savedBaseURL]
        
        for baseURL in candidates {
            do {
                try await fetchServerConfig(fallbackBaseURL: baseURL)
                // 成功后保存地址供下次使用
                UserDefaults.standard.set(DataManager.baseURL, forKey: "lastUsedBaseURL")
                print("✅ 使用地址：\(DataManager.baseURL)")
                return
            } catch {
                print("⚠️ 尝试地址失败：\(baseURL) - \(error)")
                continue
            }
        }
        
        // 所有尝试都失败
        await MainActor.run {
            self.isBackendOnline = false
            print("⚠️ 后端离线，使用本地模式")
        }
    }
    
    /// 检查 API 是否已初始化（用于注册/登录前检查）
    func checkAPIReady() async throws {
        // 如果已初始化，直接返回
        if !DataManager.apiURL.isEmpty && isBackendOnline {
            print("✅ API 已就绪：\(DataManager.apiURL)")
            return
        }
        
        // 如果后端离线，使用备用地址
        if !isBackendOnline {
            // 使用 UserDefaults 中保存的地址
            if let savedURL = UserDefaults.standard.string(forKey: "lastUsedBaseURL") {
                DataManager.baseURL = savedURL
                DataManager.apiURL = "\(savedURL)/api"
                print("⚠️ 使用备用地址：\(DataManager.apiURL)")
                return
            }
            // 使用默认地址
            DataManager.baseURL = "http://8.136.41.211:3395"
            DataManager.apiURL = "http://8.136.41.211:3395/api"
            print("⚠️ 使用默认地址：\(DataManager.apiURL)")
            return
        }
        
        // 等待初始化（最多 3 秒）
        var attempts = 0
        while DataManager.apiURL.isEmpty && attempts < 30 {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            attempts += 1
        }
        
        if DataManager.apiURL.isEmpty {
            // 超时后使用默认地址
            DataManager.baseURL = "http://8.136.41.211:3395"
            DataManager.apiURL = "http://8.136.41.211:3395/api"
            print("⚠️ 初始化超时，使用默认地址：\(DataManager.apiURL)")
            return
        }
    }
    
    private let fileManager = FileManager.default
    private var documentsPath: String {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].path
    }
    
    init() {
        // 先设置默认值
        self.settings = UserSettings(
            name: "用户",
            emergencyContact: nil,
            emergencyContacts: [],
            checkInInterval: .twoDays,
            notificationsEnabled: true,
            cloudSyncEnabled: true,
            lastCheckInDate: nil
        )
        
        // 初始化 API 配置（异步获取服务器配置）
        initializeAPIConfig()
        
        // 然后加载
        if let loaded = loadSettingsFromFile() {
            self.settings = loaded
        }
        
        // 从 settings 同步签到状态到 @Published 属性（用于 UI 观察）
        self.lastCheckInDate = settings.lastCheckInDate
        
        // 强制从 UserManager 加载（触发 UserManager 初始化）
        let userManager = UserManager.shared
        self.checkInInterval = userManager.checkInInterval
        print("✅ DataManager: 从 UserManager 加载签到间隔 \(self.checkInInterval.rawValue)")
        
        // 加载数据
        loadAllData()
        
        // 如果是第一次使用，初始化示例数据
        if capsules.isEmpty {
            initializeSampleData()
        }
    }
    
    // MARK: - 时光胶囊操作
    func addCapsule(title: String, content: String, type: TimeCapsule.CapsuleType, sendDate: Date) {
        let capsule = TimeCapsule(
            id: UUID().uuidString,
            title: title,
            content: content,
            type: type,
            sendDate: sendDate,
            isSent: false,
            createdAt: Date()
        )
        capsules.append(capsule)
        saveCapsules()
    }
    
    func deleteCapsule(id: String) {
        // 先删除对应的媒体文件（如果是音频或视频）
        if let capsule = capsules.first(where: { $0.id == id }) {
            if capsule.type == .audio || capsule.type == .video {
                deleteMediaFile(atPath: capsule.content)
            }
        }
        capsules.removeAll { $0.id == id }
        saveCapsules()
    }
    
    /// 删除媒体文件
    private func deleteMediaFile(atPath path: String) {
        // 尝试从绝对路径或 URL 字符串解析
        var fileURL: URL?
        
        if path.hasPrefix("file://") {
            fileURL = URL(string: path)
        } else if path.hasPrefix("/") {
            fileURL = URL(fileURLWithPath: path)
        } else {
            // 相对路径，构建完整路径
            let capsulesFolder = URL(fileURLWithPath: documentsPath).appendingPathComponent("TimeCapsules")
            fileURL = capsulesFolder.appendingPathComponent(path)
        }
        
        if let url = fileURL, fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
                print("🗑️ 已删除媒体文件：\(url.lastPathComponent)")
            } catch {
                print("❌ 删除媒体文件失败：\(error)")
            }
        }
    }
    
    func updateCapsule(_ capsule: TimeCapsule) {
        if let index = capsules.firstIndex(where: { $0.id == capsule.id }) {
            capsules[index] = capsule
            saveCapsules()
        }
    }
    
    func getFilteredCapsules(type: TimeCapsule.CapsuleType?) -> [TimeCapsule] {
        guard let type = type else { return capsules }
        return capsules.filter { $0.type == type }
    }
    
    // MARK: - 遗嘱模块操作
    func updateWillModule(_ module: WillModule) {
        if let index = willModules.firstIndex(where: { $0.id == module.id }) {
            willModules[index] = module
            saveWillModules()
        }
    }
    
    func getWillProgress() -> Double {
        guard !willModules.isEmpty else { return 0 }
        let completed = willModules.filter { $0.isCompleted }.count
        return Double(completed) / Double(willModules.count)
    }
    
    func getWitnessProgress() -> Double {
        guard !witnesses.isEmpty else { return 0 }
        let confirmed = witnesses.filter { $0.isConfirmed }.count
        return Double(confirmed) / Double(witnesses.count)
    }
    
    func getWitnessProgressString() -> String {
        let confirmed = witnesses.filter { $0.isConfirmed }.count
        return "\(confirmed)/\(witnesses.count)"
    }
    
    func getAssetProgress() -> Double {
        // 简单计算：有资产就算完成
        return assets.isEmpty ? 0 : 0.33
    }
    
    // MARK: - 资产操作
    func addAsset(type: Asset.AssetType, name: String, institution: String, balance: Double, accountNumber: String, details: [String: String]) {
        let asset = Asset(
            id: UUID().uuidString,
            type: type,
            name: name,
            institution: institution,
            balance: balance,
            accountNumber: accountNumber,
            details: details,
            createdAt: Date()
        )
        assets.append(asset)
        saveAssets()
    }
    
    func deleteAsset(id: String) {
        assets.removeAll { $0.id == id }
        saveAssets()
    }
    
    func updateAsset(_ asset: Asset) {
        if let index = assets.firstIndex(where: { $0.id == asset.id }) {
            assets[index] = asset
            saveAssets()
        }
    }
    
    func getTotalBalance() -> Double {
        assets.reduce(0) { $0 + $1.balance }
    }
    
    // MARK: - 见证人操作
    func addWitness(_ witness: WillWitness) {
        witnesses.append(witness)
        saveWitnesses()
    }
    
    func deleteWitness(_ witness: WillWitness) {
        witnesses.removeAll { $0.id == witness.id }
        saveWitnesses()
    }
    
    func updateWitness(_ witness: WillWitness) {
        if let index = witnesses.firstIndex(where: { $0.id == witness.id }) {
            witnesses[index] = witness
            saveWitnesses()
        }
    }
    
    // MARK: - 待办事项操作
    func toggleChecklistItem(id: String) {
        if let index = checklistItems.firstIndex(where: { $0.id == id }) {
            checklistItems[index].isCompleted.toggle()
            saveChecklistItems()
        }
    }
    
    func getChecklistProgress() -> Double {
        guard !checklistItems.isEmpty else { return 0 }
        let completed = checklistItems.filter { $0.isCompleted }.count
        return Double(completed) / Double(checklistItems.count)
    }
    
    // MARK: - 签到功能
    @Published var lastCheckInDate: Date?
    @Published var checkInInterval: CheckInInterval = .twoDays {
        didSet {
            // 同步到 UserManager（如果已登录）
            if UserManager.shared.isLoggedIn && checkInInterval != oldValue {
                _ = UserManager.shared.updateCheckInInterval(checkInInterval)
            }
        }
    }
    
    func checkIn() {
        let now = Date()
        lastCheckInDate = now
        settings.lastCheckInDate = now
        saveSettings()
        print("✅ 签到成功：\(now)")
    }
    
    func getCheckInStatus() -> (isSafe: Bool, hoursRemaining: Double) {
        // 如果没有签到过，自动进行首次签到
        if lastCheckInDate == nil {
            checkIn()
            print("✅ 首次使用，自动签到")
        }
        
        guard let lastCheckIn = lastCheckInDate else {
            return (false, 0)
        }
        
        let elapsed = Date().timeIntervalSince(lastCheckIn)
        let intervalSeconds = checkInInterval.hours * 3600
        let remaining = intervalSeconds - elapsed
        
        if remaining > 0 {
            return (true, remaining / 3600) // 安全期内
        } else {
            return (false, 0) // 需要签到
        }
    }
    
    // MARK: - 持久化
    private func saveCapsules() {
        saveData(capsules, filename: "capsules.json")
    }
    
    private func saveWillModules() {
        saveData(willModules, filename: "willModules.json")
    }
    
    private func saveAssets() {
        saveData(assets, filename: "assets.json")
    }
    
    private func saveWitnesses() {
        saveData(witnesses, filename: "witnesses.json")
    }
    
    private func saveChecklistItems() {
        saveData(checklistItems, filename: "checklistItems.json")
    }
    
    func saveSettings() {
        saveData(settings, filename: "settings.json")
    }
    
    private func saveData<T: Encodable>(_ data: T, filename: String) {
        let path = URL(fileURLWithPath: documentsPath).appendingPathComponent(filename)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let encoded = try encoder.encode(data)
            try encoded.write(to: path)
        } catch {
            print("保存失败 \(filename): \(error)")
        }
    }
    
    private func loadAllData() {
        capsules = loadData("capsules.json") ?? []
        willModules = loadData("willModules.json") ?? []
        assets = loadData("assets.json") ?? []
        witnesses = loadData("witnesses.json") ?? []
        checklistItems = loadData("checklistItems.json") ?? []
    }
    
    private func loadData<T: Decodable>(_ filename: String) -> T? {
        let path = URL(fileURLWithPath: documentsPath).appendingPathComponent(filename)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let data = try? Data(contentsOf: path) else { return nil }
        
        return try? decoder.decode(T.self, from: data)
    }
    
    private func loadSettingsFromFile() -> UserSettings? {
        loadData("settings.json")
    }
    
    // MARK: - 初始化示例数据
    private func initializeSampleData() {
        // 示例胶囊
        capsules = [
            TimeCapsule(id: UUID().uuidString, title: "给女儿的 18 岁生日", content: "亲爱的女儿...", type: .text, sendDate: Date().addingTimeInterval(365*24*3600), isSent: false, createdAt: Date()),
            TimeCapsule(id: UUID().uuidString, title: "结婚纪念日视频", content: "", type: .video, sendDate: Date().addingTimeInterval(60*24*3600), isSent: false, createdAt: Date()),
            TimeCapsule(id: UUID().uuidString, title: "给妻子的话", content: "", type: .audio, sendDate: Date().addingTimeInterval(-30*24*3600), isSent: true, createdAt: Date())
        ]
        
        // 示例遗嘱模块
        willModules = WillModule.WillType.allCases.map { type in
            WillModule(id: UUID().uuidString, type: type, title: type.rawValue, subtitle: "", content: "", isCompleted: type.rawValue == "财产分配" || type.rawValue == "继承人指定", template: nil)
        }
        
        // 示例资产
        assets = [
            Asset(id: UUID().uuidString, type: .bank, name: "工商银行储蓄卡", institution: "中国工商银行", balance: 158000, accountNumber: "···8888", details: ["开户行": "北京朝阳支行"], createdAt: Date()),
            Asset(id: UUID().uuidString, type: .stock, name: "股票账户", institution: "华泰证券", balance: 320000, accountNumber: "···1234", details: ["持仓": "贵州茅台、招商银行"], createdAt: Date()),
            Asset(id: UUID().uuidString, type: .insurance, name: "终身寿险", institution: "中国平安", balance: 80000, accountNumber: "P1234567890", details: ["受益人": "张三（儿子）"], createdAt: Date())
        ]
        
        // 示例见证人
        witnesses = [
            WillWitness(id: UUID().uuidString, name: "李四", relationship: "律师", phone: "138****5678", idNumber: "110101********1234", notes: "北京市某某律师事务所", isConfirmed: true, createdAt: Date(), confirmedAt: Date()),
            WillWitness(id: UUID().uuidString, name: "王五", relationship: "大学同学", phone: "139****9012", idNumber: "", notes: "", isConfirmed: false, createdAt: Date(), confirmedAt: nil)
        ]
        
        // 示例待办事项
        checklistItems = [
            ChecklistItem(id: UUID().uuidString, title: "整理银行账户信息", description: "列出所有银行卡和账号", category: .finance, isCompleted: true, tags: ["财务"]),
            ChecklistItem(id: UUID().uuidString, title: "更新保险受益人", description: "联系保险公司更新", category: .finance, isCompleted: false, tags: ["财务"]),
            ChecklistItem(id: UUID().uuidString, title: "整理数字账号", description: "邮箱、社交媒体等", category: .digital, isCompleted: true, tags: ["数字账号"]),
            ChecklistItem(id: UUID().uuidString, title: "写下想说的话", description: "给家人的留言", category: .wish, isCompleted: false, tags: ["愿望"])
        ]
        
        saveAllData()
    }
    
    private func saveAllData() {
        saveCapsules()
        saveWillModules()
        saveAssets()
        saveWitnesses()
        saveChecklistItems()
        saveSettings()
    }
}
