//
//  RealTimeSyncManager.swift
//  终活 - 实时双向同步管理器
//
//  功能:
//  1. 网络状态监控
//  2. App 进入前台自动同步
//  3. 本地数据变更自动同步
//  4. 离线使用，联网后自动同步
//

import Foundation
import Combine
import Network

@MainActor
class RealTimeSyncManager: ObservableObject {
    static let shared = RealTimeSyncManager()
    
    // MARK: - Published Properties
    @Published var isOnline: Bool = false
    @Published var isSyncing: Bool = false
    @Published var lastSyncTime: Date?
    @Published var syncStatus: SyncStatus = .idle
    @Published var pendingSyncCount: Int = 0
    
    // MARK: - Network Monitor
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // MARK: - Sync Queue
    private var syncQueue: [SyncTask] = []
    private var isProcessingQueue: Bool = false
    
    // MARK: - Debounce Timers
    private var syncDebounceTimers: [String: Timer] = [:]
    private let debounceInterval: TimeInterval = 2.0 // 2 秒防抖
    
    // MARK: - Sync Status
    enum SyncStatus: String {
        case idle = "空闲"
        case syncing = "同步中..."
        case success = "同步成功"
        case failed = "同步失败"
        case waiting = "等待网络"
    }
    
    // MARK: - Sync Task
    struct SyncTask: Equatable {
        let id: String
        let type: SyncType
        let timestamp: Date
        
        enum SyncType {
            case capsule
            case will
            case emergencyContact
            case witness
            case location
            case checkin
            case full
        }
    }
    
    // MARK: - Initialization
    private init() {
        startNetworkMonitoring()
        loadPendingSyncCount()
        
        // 监听本地数据变更通知
        setupLocalChangeNotifications()
    }
    
    // MARK: - Network Monitoring
    
    /// 启动网络监控
    func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.handleNetworkPathUpdate(path)
            }
        }
        monitor.start(queue: queue)
        
        print("🌐 网络监控已启动")
    }
    
    /// 处理网络状态变化
    private func handleNetworkPathUpdate(_ path: NWPath) {
        let wasOnline = isOnline
        isOnline = path.status == .satisfied
        
        if isOnline != wasOnline {
            print("🌐 网络状态变化：\(isOnline ? "在线" : "离线")")
            
            if isOnline {
                syncStatus = .success
                // 网络恢复，立即同步
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 延迟 0.5 秒
                    await processSyncQueue()
                }
            } else {
                syncStatus = .waiting
            }
        }
    }
    
    // MARK: - Local Change Notifications
    
    /// 设置本地数据变更监听
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
    
    // MARK: - Sync Scheduling
    
    /// 调度同步任务（带防抖）
    private func scheduleSync(type: SyncTask.SyncType, debounce: Bool = true) {
        let taskId = UUID().uuidString
        let task = SyncTask(id: taskId, type: type, timestamp: Date())
        
        if debounce {
            // 取消之前的定时器
            let timerKey = type.rawValue
            syncDebounceTimers[timerKey]?.invalidate()
            
            // 创建新定时器
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
    
    /// 添加到同步队列
    private func addToSyncQueue(_ task: SyncTask) {
        // 去重：如果队列中已有相同类型的任务，跳过
        if syncQueue.contains(where: { $0.type == task.type }) {
            print("⏭️ 跳过重复的同步任务：\(task.type)")
            return
        }
        
        syncQueue.append(task)
        pendingSyncCount = syncQueue.count
        print("📋 同步队列：\(pendingSyncCount) 个任务")
        
        // 立即处理队列
        Task {
            await processSyncQueue()
        }
    }
    
    /// 处理同步队列
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
                // 失败的任务不重新加入队列，避免死循环
            }
        }
        
        isSyncing = false
        isProcessingQueue = false
        lastSyncTime = Date()
        syncStatus = .success
        
        print("🎉 所有同步任务完成")
    }
    
    /// 执行单个同步任务
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
    
    // MARK: - Sync Operations
    
    /// 同步所有数据
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
    
    /// 同步胶囊
    private func syncCapsules() async throws {
        print("📦 同步胶囊数据")
        await DataManager.shared.uploadAllCapsules()
        try? await DataManager.shared.downloadCapsules()
    }
    
    /// 同步遗嘱
    private func syncWills() async throws {
        print("📝 同步遗嘱数据")
        await DataManager.shared.uploadAllWills()
        try? await DataManager.shared.downloadWills()
    }
    
    /// 同步紧急联系人
    private func syncEmergencyContacts() async throws {
        print("👥 同步紧急联系人")
        await DataManager.shared.uploadAllEmergencyContacts()
        try? await DataManager.shared.downloadEmergencyContacts()
    }
    
    /// 同步见证人
    private func syncWitnesses() async throws {
        print("👤 同步见证人")
        await DataManager.shared.uploadAllWitnesses()
        try? await DataManager.shared.downloadWitnesses()
    }
    
    /// 同步位置
    private func syncLocations() async throws {
        // 位置数据只在有网络时自动上传
    }
    
    /// 同步签到
    private func syncCheckIns() async throws {
        // 签到数据在签到时已上传
    }
    
    // MARK: - Manual Sync
    
    /// 手动触发同步
    func triggerSync(type: SyncTask.SyncType = .full) async {
        print("🔵 手动触发同步：\(type)")
        scheduleSync(type: type, debounce: false)
    }
    
    /// 立即同步（不防抖）
    func syncNow() async {
        await triggerSync(type: .full)
    }
    
    // MARK: - Helper Methods
    
    private func loadPendingSyncCount() {
        pendingSyncCount = syncQueue.count
    }
    
    // MARK: - App Lifecycle
    
    /// App 进入前台时调用
    func appDidBecomeActive() {
        print("🟢 App 进入前台，触发同步")
        Task {
            await syncNow()
        }
    }
    
    /// 用户登录成功后调用
    func userDidLogin() {
        print("🔵 用户登录成功，触发全量同步")
        Task {
            await syncNow()
        }
    }
    
    /// 网络恢复时调用
    func networkDidRecover() {
        print("🌐 网络恢复，触发同步")
        Task {
            await syncNow()
        }
    }
}

// MARK: - 通知发送扩展

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
