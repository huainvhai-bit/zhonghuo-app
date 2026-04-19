//
//  ZhonghuoApp.swift
//  终活 App 入口
//

import SwiftUI
import Network
import BackgroundTasks

@main
struct ZhonghuoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var themeManager = ThemeManager.shared  // 使用 @StateObject 监听主题变化
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeManager.preferredColorScheme)
                .onAppear {
                    Task {
                        await checkMaintenanceAndVersion()
                    }
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Logger.shared.d("App 进入前台")
                RealTimeSyncManager.shared.appDidBecomeActive()
                
                // ✅ 检查会员是否过期（基于本地缓存）
                MembershipManager.shared.checkExpiration()
            }
        }
    }
    
    /// 检查版本更新
    @MainActor
    private func checkMaintenanceAndVersion() async {
        // 等待网络
        _ = await waitForNetwork(timeout: 5.0)
        
        guard !DataManager.apiURL.isEmpty else {
            Logger.shared.w("API URL 未设置，跳过维护/版本检查")
            return
        }
        
        do {
            // 加载系统配置（包含维护模式和版本信息）
            await DataManager.shared.loadSystemConfig()
            
            let config = DataManager.shared.systemConfig
            
            
            // 版本检查
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            
            Logger.shared.d("版本检查：当前=\(currentVersion), 最新=\(config.latestVersion)")
            
            // 判断是否需要更新
            if isVersionNewer(config.latestVersion, than: currentVersion) {
                let forceUpdate = isVersionNewerOrEqual(config.forceUpdateVersion, than: currentVersion)
                
                Logger.shared.i("发现新版本：\(config.latestVersion), 强制更新=\(forceUpdate)")
                
                // 存储更新信息到 UserDefaults，供 ContentView 读取
                UserDefaults.standard.set(config.latestVersion, forKey: "pendingUpdateVersion")
                UserDefaults.standard.set(config.forceUpdateVersion, forKey: "pendingForceUpdateVersion")
                UserDefaults.standard.set(config.updateUrl, forKey: "pendingUpdateUrl")
                UserDefaults.standard.set(true, forKey: "showingUpdateAlert")
            }
        }
    }
    
    /// 比较版本号（v1 > v2 返回 true）
    private func isVersionNewer(_ v1: String, than v2: String) -> Bool {
        let v1Components = v1.split(separator: ".").compactMap { Int($0) }
        let v2Components = v2.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(v1Components.count, v2Components.count) {
            let v1Part = i < v1Components.count ? v1Components[i] : 0
            let v2Part = i < v2Components.count ? v2Components[i] : 0
            
            if v1Part > v2Part {
                return true
            } else if v1Part < v2Part {
                return false
            }
        }
        
        return false
    }
    
    /// 比较版本号（v1 >= v2 返回 true）
    private func isVersionNewerOrEqual(_ v1: String, than v2: String) -> Bool {
        if v1 == v2 {
            return true
        }
        return isVersionNewer(v1, than: v2)
    }
    
    /// 等待网络（可配置超时）
    private func waitForNetwork(timeout: TimeInterval = 3.0) async -> Bool {
        let maxWaitTime = timeout
        let checkInterval: TimeInterval = 0.3
        var waitedTime: TimeInterval = 0
        
        while waitedTime < maxWaitTime {
            if await isNetworkAvailable() {
                return true
            }
            try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
            waitedTime += checkInterval
        }
        return false
    }
    
    /// 检查网络是否可用
    private func isNetworkAvailable() async -> Bool {
        return await DataManager.shared.checkNetworkConnectivity()
    }
}

// MARK: - RealTimeSyncManager
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
            case capsule, will, emergencyContact, witness, location, checkin, full
        }
    }
    
    private init() {
        startNetworkMonitoring()
        setupLocalChangeNotifications()
    }
    
    func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in self?.handleNetworkPathUpdate(path) }
        }
        monitor.start(queue: queue)
    }
    
    private func handleNetworkPathUpdate(_ path: NWPath) {
        let wasOnline = isOnline
        isOnline = path.status == .satisfied
        if isOnline != wasOnline {
            Logger.shared.d("网络状态变化：\(isOnline ? "在线" : "离线")")
            if isOnline {
                syncStatus = .success
                Task { try? await Task.sleep(nanoseconds: 500_000_000); await processSyncQueue() }
            } else {
                syncStatus = .waiting
            }
        }
    }
    
    private func setupLocalChangeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleDataChange(_:)), name: NSNotification.Name("DataChanged"), object: nil)
    }
    
    @objc private func handleDataChange(_ notification: Notification) {
        Logger.shared.d("检测到数据变更，准备同步")
        scheduleSync(type: .full)
    }
    
    private func scheduleSync(type: SyncTask.SyncType, debounce: Bool = true) {
        let task = SyncTask(id: UUID().uuidString, type: type, timestamp: Date())
        if debounce {
            let timer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
                Task { @MainActor in self?.addToSyncQueue(task) }
            }
            syncDebounceTimers[type.rawValue] = timer
        } else {
            addToSyncQueue(task)
        }
    }
    
    private func addToSyncQueue(_ task: SyncTask) {
        if !syncQueue.contains(where: { $0.type == task.type }) {
            syncQueue.append(task)
            pendingSyncCount = syncQueue.count
            Task { await processSyncQueue() }
        }
    }
    
    private func processSyncQueue() async {
        guard !isProcessingQueue, isOnline else { return }
        isProcessingQueue = true
        isSyncing = true
        syncStatus = .syncing
        
        while !syncQueue.isEmpty {
            let task = syncQueue.removeFirst()
            pendingSyncCount = syncQueue.count
            do { try await executeSyncTask(task) } catch { Logger.shared.e("同步失败：\(task.type)") }
        }
        
        isSyncing = false
        isProcessingQueue = false
        lastSyncTime = Date()
        syncStatus = .success
    }
    
    private func executeSyncTask(_ task: SyncTask) async throws {
        switch task.type {
        case .full: try await syncAllData()
        default: break
        }
    }
    
    // 同步间隔控制（5 分钟内不重复全量同步）
    private var lastFullSyncTime: Date?
    private let syncInterval: TimeInterval = 300  // 5 分钟
    
    func shouldSync() -> Bool {
        guard let lastSync = lastFullSyncTime else { return true }
        return Date().timeIntervalSince(lastSync) > syncInterval
    }
    
    func syncAllData() async throws {
        guard shouldSync() else {
            Logger.shared.d("跳过全量同步（5 分钟内已同步）")
            return
        }
        Logger.shared.i("全量同步")
        lastFullSyncTime = Date()
    }
    
    func appDidBecomeActive() {
        // 不自动触发同步，避免频繁请求
    }
    
    func syncNow() async { await triggerSync(type: .full) }
    
    func triggerSync(type: SyncTask.SyncType = .full) async {
        scheduleSync(type: type, debounce: false)
    }
    
    func userDidLogin() {
        Logger.shared.d("用户登录成功，触发全量同步")
        Task { await syncNow() }
    }
    
    func networkDidRecover() {
        Logger.shared.d("网络恢复，触发同步")
        Task { await syncNow() }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 同步设置默认 API URL（在后台任务注册前）
        // 使用 NetworkUtils 自动转换为正确的协议（本地 IP 强制使用 HTTP）
        let defaultURL = "8.136.41.211:3395"
        let normalizedURL = NetworkUtils.normalizeBaseURL(defaultURL)
        DataManager.apiURL = normalizedURL
        DataManager.baseURL = normalizedURL
        UserDefaults.standard.set(normalizedURL, forKey: "apiURL")
        Logger.shared.d("API URL 已设置：\(DataManager.apiURL)")
        
        // 异步更新配置（从服务器获取最新配置）
        Task {
            await initializeAPIConfig()
        }
        
        // ========== JPush 极光推送初始化 ==========
        setupJPush()
        
        // 请求通知权限
        NotificationManager.shared.requestPermission()
        
        // 设置通知代理
        UNUserNotificationCenter.current().delegate = self
        
        // 从后端加载通知配置
        Task {
            await LifeCheckStatusManager.shared.loadNotificationConfig()
        }
        
        // ✅ 启用后台任务
        startBackgroundTasks()
        setupCheckInNotifications()
        Logger.shared.i("后台任务已启用")
        
        Logger.shared.i("终活 App 启动完成")
        return true
    }
    
    // MARK: - JPush 极光推送
    private func setupJPush() {
        // 初始化 JPush
        JPushManager.shared.setup()
        
        // 设置别名（用户 ID）- 在 setup 中已设置代理，无需单独调用
        // 如果需要重新设置别名，调用以下方法：
        // JPushManager.shared.setAlias(userId: userId)
        
        // 监听登录状态变化，登录后设置别名
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UserDidLogin"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let userId = notification.userInfo?["userId"] as? String {
                JPushManager.shared.setAlias(userId: userId)
            }
        }
        
        Logger.shared.i("JPush 极光推送初始化完成")
    }
    
    /// 设置签到提醒通知
    private func setupCheckInNotifications() {
        LifeCheckStatusManager.shared.scheduleCheckInNotifications()
    }
    
    // 后台任务注册（在 didFinishLaunchingWithOptions 之后立即注册）
    private func startBackgroundTasks() {
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.zhonghuo.app.sms_notify", using: nil) { task in
                guard let bgTask = task as? BGAppRefreshTask else {
                    task.setTaskCompleted(success: false)
                    return
                }
                self.handleBackgroundSmsTask(task: bgTask)
            }
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.zhonghuo.app.refresh_notifications", using: nil) { task in
                guard let bgTask = task as? BGAppRefreshTask else {
                    task.setTaskCompleted(success: false)
                    return
                }
                self.handleNotificationRefresh(task: bgTask)
            }
            Logger.shared.i("后台任务已注册")
        }
    }
    
    private func handleBackgroundSmsTask(task: BGAppRefreshTask) {
        LifeCheckStatusManager.shared.handleBackgroundSmsTask(task: task)
    }
    
    private func handleNotificationRefresh(task: BGAppRefreshTask) {
        Logger.shared.d("刷新通知...")
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        LifeCheckStatusManager.shared.scheduleCheckInNotifications()
        task.setTaskCompleted(success: true)
    }
    
    // MARK: - 通知代理
    
    /// 收到通知时的处理（App 在后台）
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        Logger.shared.d("收到通知：\(notification.request.identifier)")
        
        // 如果是超时通知，且 App 在后台运行，尝试发送短信
        if notification.request.identifier.contains("checkin_overdue") {
            // App 在后台，可以尝试发送短信
            Logger.shared.d("超时通知触发，准备发送短信...")
            Task {
                await LifeCheckStatusManager.shared.notifyGuardians()
            }
        }
        
        // 显示通知（横幅 + 声音）
        completionHandler([.banner, .sound])
    }
    
    /// 用户点击通知时的处理
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Logger.shared.d("用户点击通知：\(response.actionIdentifier)")
        
        // 用户打开 App 后会自动签到
        completionHandler()
    }
    
    private func initializeAPIConfig() async {
        // 关键：立即设置默认值（同步，确保在异步操作前就设置好）
        let defaultURL = "8.136.41.211:3395"
        let normalizedURL = NetworkUtils.normalizeBaseURL(defaultURL)
        await MainActor.run {
            DataManager.apiURL = normalizedURL
            DataManager.baseURL = normalizedURL
        }
        
        do {
            // 尝试从 UserDefaults 读取已保存的 API URL
            if let savedURL = UserDefaults.standard.string(forKey: "apiURL"), !savedURL.isEmpty {
                await MainActor.run {
                    // 使用 NetworkUtils 确保 URL 格式正确
                    let normalizedSavedURL = NetworkUtils.normalizeBaseURL(savedURL)
                    DataManager.apiURL = normalizedSavedURL
                    DataManager.baseURL = normalizedSavedURL
                }
                Logger.shared.d("API URL 已从缓存加载：\(DataManager.apiURL)")
                return
            }
            
            // 从服务器获取配置（超时 3 秒）
            let baseURL = "8.136.41.211:3395"
            try await withTimeout(seconds: 3) {
                try await DataManager.shared.fetchServerConfig(from: baseURL)
            }
            Logger.shared.d("API URL 已从服务器获取：\(DataManager.apiURL)")
        } catch {
            Logger.shared.e("获取 API 配置失败：\(error) - 使用默认值")
            // 默认值已设置，不需要额外处理
        }
    }
    
    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw URLError(.timedOut)
            }
            guard let result = try await group.next() else {
                throw URLError(.timedOut)
            }
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - APNs Token 处理
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // JPush 处理 Token
        JPushManager.shared.handleRemoteNotification(deviceToken: deviceToken)
        
        // 保存 Token 到服务器
        let tokenString = deviceToken.reduce("") { $0 + String(format: "%02x", $1) }
        Logger.shared.i("APNs Token: \(tokenString)")
        
        Task {
            await uploadDeviceToken(tokenString)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Logger.shared.e("注册推送失败：\(error.localizedDescription)")
    }
    
    private func uploadDeviceToken(_ token: String) async {
        guard !DataManager.apiURL.isEmpty else { return }
        
        do {
            let mutation = """
            mutation {
                updateDeviceToken(token: "\(token)") {
                    success
                    message
                }
            }
            """
            let _ = try await APIClient.shared.query(mutation)
            Logger.shared.i("设备 Token 上传成功")
        } catch {
            Logger.shared.e("设备 Token 上传失败：\(error)")
        }
    }
}
