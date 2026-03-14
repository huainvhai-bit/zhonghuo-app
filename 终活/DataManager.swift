//
//  DataManager.swift
//  终活
//
//  数据管理 - 增删改查 + 持久化
//

import Foundation

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var capsules: [TimeCapsule] = []
    @Published var willModules: [WillModule] = []
    @Published var assets: [Asset] = []
    @Published var witnesses: [Witness] = []
    @Published var checklistItems: [ChecklistItem] = []
    @Published var settings: UserSettings
    
    private let fileManager = FileManager.default
    private var documentsPath: String {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].path
    }
    
    init() {
        // 加载设置
        self.settings = loadSettings()
        
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
        capsules.removeAll { $0.id == id }
        saveCapsules()
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
    func addWitness(name: String, role: String, phone: String, order: Int) {
        let witness = Witness(
            id: UUID().uuidString,
            name: name,
            role: role,
            phone: phone,
            isConfirmed: false,
            order: order
        )
        witnesses.append(witness)
        witnesses.sort { $0.order < $1.order }
        saveWitnesses()
    }
    
    func deleteWitness(id: String) {
        witnesses.removeAll { $0.id == id }
        saveWitnesses()
    }
    
    func updateWitness(_ witness: Witness) {
        if let index = witnesses.firstIndex(where: { $0.id == witness.id }) {
            witnesses[index] = witness
            saveWitnesses()
        }
    }
    
    func confirmWitness(id: String) {
        if let index = witnesses.firstIndex(where: { $0.id == id }) {
            witnesses[index].isConfirmed = true
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
    @Published var checkInInterval: Int = 48 // 48 小时
    
    func checkIn() {
        lastCheckInDate = Date()
        saveSettings()
    }
    
    func getCheckInStatus() -> (isSafe: Bool, hoursRemaining: Double) {
        guard let lastCheckIn = lastCheckInDate else {
            return (false, Double(checkInInterval))
        }
        
        let elapsed = Date().timeIntervalSince(lastCheckIn)
        let intervalSeconds = Double(checkInInterval) * 3600
        let remaining = intervalSeconds - elapsed
        
        if remaining > 0 {
            return (true, remaining / 3600)
        } else {
            return (false, 0)
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
    
    private func saveSettings() {
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
    
    private func loadSettings() -> UserSettings {
        loadData("settings.json") ?? UserSettings(
            name: "用户",
            emergencyContact: nil,
            checkInInterval: 48,
            notificationsEnabled: true,
            cloudSyncEnabled: true
        )
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
            Witness(id: UUID().uuidString, name: "李四", role: "律师", phone: "138****5678", isConfirmed: true, order: 1),
            Witness(id: UUID().uuidString, name: "王五", role: "朋友", phone: "139****9012", isConfirmed: false, order: 2)
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
