//
//  ZhonghuoApp.swift
//  终活 App 入口
//

import SwiftUI
import Network

@main
struct ZhonghuoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                print("🟢 App 进入前台 - ZhonghuoApp")
                // 触发实时同步
                RealTimeSyncManager.shared.appDidBecomeActive()
            }
        }
    }
}

// MARK: - RealTimeSyncManager (内联版本，避免 Xcode 项目问题)
@MainActor
class RealTimeSyncManager: ObservableObject {
    static let shared = RealTimeSyncManager()
    
    @Published var isOnline: Bool = false
    @Published var isSyncing: Bool = false
    @Published var lastSyncTime: Date?
    @Published var syncStatus: SyncStatus = .idle
    @Published var pendingSyncCount: Int = 0
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var syncQueue: [SyncTask] = []
    private var isProcessingQueue: Bool = false
    private var syncDebounceTimers: [String: Timer] = [:]
    private let debounceInterval: TimeInterval = 2.0
    
    enum SyncStatus: String {
        case idle = "空闲"
        case syncing = "同步中..."
        case success = "同步成功"
        case failed = "同步失败"
        case waiting = "等待网络"
    }
    
    struct SyncTask: Equatable {
        let id: String
        let type: SyncType
        let timestamp: Date
        
        enum SyncType: String, Equatable {
            case capsule
            case will
            case emergencyContact
            case witness
            case location
            case checkin
            case full
        }
    }
    
    private init() {
        startNetworkMonitoring()
        setupLocalChangeNotifications()
    }
    
    func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.handleNetworkPathUpdate(path)
            }
        }
        monitor.start(queue: queue)
        print("🌐 网络监控已启动")
    }
    
    private func handleNetworkPathUpdate(_ path: NWPath) {
        let wasOnline = isOnline
        isOnline = path.status == .satisfied
        
        if isOnline != wasOnline {
            print("🌐 网络状态变化：\(isOnline ? "在线" : "离线")")
            if isOnline {
                syncStatus = .success
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await processSyncQueue()
                }
            } else {
                syncStatus = .waiting
            }
        }
    }
    
    private func setupLocalChangeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataChange(_:)),
            name: NSNotification.Name("DataChanged"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCapsuleChanged(_:)),
            name: NSNotification.Name("CapsuleChanged"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWillChanged(_:)),
            name: NSNotification.Name("WillChanged"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContactChanged(_:)),
            name: NSNotification.Name("EmergencyContactChanged"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWitnessChanged(_:)),
            name: NSNotification.Name("WitnessChanged"),
            object: nil
        )
    }
    
    @objc private func handleDataChange(_ notification: Notification) {
        print("📝 检测到数据变更，准备同步")
        scheduleSync(type: .full)
    }
    
    @objc private func handleCapsuleChanged(_ notification: Notification) {
        print("📦 胶囊数据变更")
        scheduleSync(type: .capsule)
    }
    
    @objc private func handleWillChanged(_ notification: Notification) {
        print("📝 遗嘱数据变更")
        scheduleSync(type: .will)
    }
    
    @objc private func handleContactChanged(_ notification: Notification) {
        print("👥 紧急联系人变更")
        scheduleSync(type: .emergencyContact)
    }
    
    @objc private func handleWitnessChanged(_ notification: Notification) {
        print("👤 见证人变更")
        scheduleSync(type: .witness)
    }
    
    private func scheduleSync(type: SyncTask.SyncType, debounce: Bool = true) {
        let taskId = UUID().uuidString
        let task = SyncTask(id: taskId, type: type, timestamp: Date())
        
        if debounce {
            let timerKey = type.rawValue
            syncDebounceTimers[timerKey]?.invalidate()
            
            let timer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.addToSyncQueue(task)
                }
            }
            syncDebounceTimers[timerKey] = timer
        } else {
            addToSyncQueue(task)
        }
    }
    
    private func addToSyncQueue(_ task: SyncTask) {
        if syncQueue.contains(where: { $0.type == task.type }) {
            print("⏭️ 跳过重复的同步任务：\(task.type)")
            return
        }
        
        syncQueue.append(task)
        pendingSyncCount = syncQueue.count
        print("📋 同步队列：\(pendingSyncCount) 个任务")
        
        Task {
            await processSyncQueue()
        }
    }
    
    private func processSyncQueue() async {
        guard !isProcessingQueue else { return }
        guard isOnline else {
            syncStatus = .waiting
            print("⏸️ 网络离线，等待网络恢复")
            return
        }
        
        isProcessingQueue = true
        isSyncing = true
        syncStatus = .syncing
        
        print("🚀 开始处理同步队列，共 \(syncQueue.count) 个任务")
        
        while !syncQueue.isEmpty {
            let task = syncQueue.removeFirst()
            pendingSyncCount = syncQueue.count
            
            do {
                try await executeSyncTask(task)
                print("✅ 同步任务完成：\(task.type)")
            } catch {
                print("❌ 同步任务失败：\(task.type), 错误：\(error)")
            }
        }
        
        isSyncing = false
        isProcessingQueue = false
        lastSyncTime = Date()
        syncStatus = .success
        
        print("🎉 所有同步任务完成")
    }
    
    private func executeSyncTask(_ task: SyncTask) async throws {
        switch task.type {
        case .capsule:
            try await syncCapsules()
        case .will:
            try await syncWills()
        case .emergencyContact:
            try await syncEmergencyContacts()
        case .witness:
            try await syncWitnesses()
        case .location:
            try await syncLocations()
        case .checkin:
            try await syncCheckIns()
        case .full:
            try await syncAllData()
        }
    }
    
    func syncAllData() async throws {
        print("🔄 开始全量同步")
        async let capsules = syncCapsules()
        async let wills = syncWills()
        async let contacts = syncEmergencyContacts()
        async let witnesses = syncWitnesses()
        
        try await capsules
        try await wills
        try await contacts
        try await witnesses
        print("✅ 全量同步完成")
    }
    
    private func syncCapsules() async throws {
        print("📦 同步胶囊数据")
        _ = await DataManager.shared.batchSyncCapsules()
        try? await DataManager.shared.downloadCapsules()
    }
    
    private func syncWills() async throws {
        print("📝 同步遗嘱数据")
        _ = await DataManager.shared.batchSyncWills()
        try? await DataManager.shared.downloadWills()
    }
    
    private func syncEmergencyContacts() async throws {
        print("👥 同步紧急联系人")
        _ = await DataManager.shared.batchSyncEmergencyContacts()
        try? await DataManager.shared.downloadEmergencyContacts()
    }
    
    private func syncWitnesses() async throws {
        print("👤 同步见证人")
        _ = await DataManager.shared.batchSyncWitnesses()
        try? await DataManager.shared.downloadWitnesses()
    }
    
    private func syncLocations() async throws {}
    private func syncCheckIns() async throws {}
    
    func triggerSync(type: SyncTask.SyncType = .full) async {
        print("🔵 手动触发同步：\(type)")
        scheduleSync(type: type, debounce: false)
    }
    
    func syncNow() async {
        await triggerSync(type: .full)
    }
    
    func appDidBecomeActive() {
        print("🟢 App 进入前台，触发同步")
        Task {
            await syncNow()
        }
    }
    
    func userDidLogin() {
        print("🔵 用户登录成功，触发全量同步")
        Task {
            await syncNow()
        }
    }
    
    func networkDidRecover() {
        print("🌐 网络恢复，触发同步")
        Task {
            await syncNow()
        }
    }
}

// MARK: - NotificationCenter Extensions
extension NotificationCenter {
    func postDataChanged() {
        post(name: NSNotification.Name("DataChanged"), object: nil)
    }
    
    func postCapsuleChanged() {
        post(name: NSNotification.Name("CapsuleChanged"), object: nil)
    }
    
    func postWillChanged() {
        post(name: NSNotification.Name("WillChanged"), object: nil)
    }
    
    func postContactChanged() {
        post(name: NSNotification.Name("EmergencyContactChanged"), object: nil)
    }
    
    func postWitnessChanged() {
        post(name: NSNotification.Name("WitnessChanged"), object: nil)
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        NotificationManager.shared.requestPermission()
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor(Color(hex: "6366F1"))
        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 18)
        ]
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 17)
        ]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().tintColor = .white
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let docsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
            print("🔵 ====== 用户状态 ======")
            print("📁 文档路径：\(docsPath)")
            print("👤 登录状态：\(UserManager.shared.isLoggedIn)")
            print("⏰ 签到间隔：\(UserManager.shared.checkInInterval.rawValue)")
            if let user = UserManager.shared.currentUser {
                print("📝 用户：\(user.name), 签到间隔：\(user.checkInInterval.rawValue)")
            }
            
            let userFileURL = URL(fileURLWithPath: docsPath).appendingPathComponent("user.json")
            let exists = FileManager.default.fileExists(atPath: userFileURL.path)
            print("📄 user.json 存在：\(exists)")
            
            if exists {
                do {
                    let data = try Data(contentsOf: userFileURL)
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("📄 user.json 内容：\(json)")
                    }
                } catch {
                    print("❌ 读取 user.json 失败：\(error)")
                }
            }
        }
        
        print("✅ 终活 App 启动完成")
        return true
    }
}
