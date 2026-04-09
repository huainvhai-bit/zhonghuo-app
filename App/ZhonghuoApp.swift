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
    @State private var accountValidated = false
    @State private var validationFailed = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // 🔴 禁用启动时账号验证（避免弹窗打扰用户）
                    // Task {
                    //     await validateAccountOnLaunch()
                    // }
                    Task {
                        await checkVersionUpdate()  // 只检查版本更新
                    }
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                print("🟢 App 进入前台 - ZhonghuoApp")
                RealTimeSyncManager.shared.appDidBecomeActive()
                
                // 🔴 禁用自动签到（避免重复触发和卡顿）
                // 🔵 自动签到已迁移到 HomeStatusView 处理（避免重复签到）
                // HomeStatusView 的 onAppear 和 scenePhase 变化会自动触发签到
            }
        }
    }
    
    /// 启动时验证账号（仅在冷启动时）
    private func validateAccountOnLaunch() async {
        // 🔴 关键修复 1: 仅在已登录状态下验证
        guard UserManager.shared.isLoggedIn else {
            print("⚠️ 用户未登录，跳过账号验证")
            return
        }
        
        // 🔴 关键修复 2: 检查上次验证时间，避免频繁验证（5 分钟内不重复验证）
        let lastValidationTime = UserDefaults.standard.double(forKey: "lastAccountValidationTime")
        let now = Date().timeIntervalSince1970
        if now - lastValidationTime < 300 { // 5 分钟
            print("⏰ 距离上次验证仅 \(Int(now - lastValidationTime)) 秒，跳过验证")
            return
        }
        
        // 🔵 版本检查更新（每次启动时检查）
        await checkVersionUpdate()
        
        // 🔴 关键修复 3: 验证失败不立即退出登录，而是标记状态
        if let user = UserManager.shared.currentUser {
            print("🔐 开始验证账号：\(user.name) (\(user.phone))")
            
            // 等待网络（最多 3 秒）
            let networkAvailable = await waitForNetwork(timeout: 3)
            if !networkAvailable {
                print("⚠️ 网络不可用，跳过验证")
                return
            }
            
            // 验证账号（不自动退出登录）
            let result = await validateUserCredentials(user: user)
            
            if result.isValid {
                print("✅ 账号验证成功")
                UserDefaults.standard.set(now, forKey: "lastAccountValidationTime")
            } else {
                // 🔴 关键修复 4: 完全禁用验证失败的弹窗和退出登录
                // 只记录日志，不打扰用户
                print("⚠️ 账号验证失败：\(result.reason) - 静默处理，不影响使用")
                // 不再调用 logout()，允许用户继续使用本地数据
            }
        }
    }
    
    /// 检查版本更新
    @MainActor
    private func checkVersionUpdate() async {
        // 等待网络
        _ = await waitForNetwork(timeout: 5.0)
        
        guard !DataManager.apiURL.isEmpty else {
            print("⚠️ API URL 未设置，跳过版本检查")
            return
        }
        
        do {
            // 加载系统配置（包含版本信息）
            await DataManager.shared.loadSystemConfig()
            
            let config = DataManager.shared.systemConfig
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            
            print("📱 版本检查：当前=\(currentVersion), 最新=\(config.latestVersion)")
            
            // 判断是否需要更新
            if isVersionNewer(config.latestVersion, than: currentVersion) {
                let forceUpdate = isVersionNewerOrEqual(config.forceUpdateVersion, than: currentVersion)
                
                print("📢 发现新版本：\(config.latestVersion), 强制更新=\(forceUpdate)")
                
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
    // ✅ 修复：使用 DataManager 统一方法，避免重复代码
    private func isNetworkAvailable() async -> Bool {
        return await DataManager.shared.checkNetworkConnectivity()
    }
    
    /// 验证结果
    struct ValidationResult {
        let isValid: Bool
        let shouldLogout: Bool  // 是否应该退出登录
        let reason: String      // 失败原因
    }
    
    /// 验证用户账号（返回详细的验证结果）
    private func validateUserCredentials(user: User) async -> ValidationResult {
        guard !DataManager.apiURL.isEmpty else {
            return ValidationResult(isValid: false, shouldLogout: false, reason: "API 地址未配置")
        }
        
        // ✅ 安全修复：不再使用密码验证，仅使用 Token 验证
        do {
            let token = KeychainManager.shared.getToken() ?? ""
            let query = """
            query {
                user {
                    id
                    name
                    phone
                    status
                }
            }
            """
            
            let url = URL(string: "\(DataManager.apiURL)/api/graphql.php")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query])
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    // ✅ 宽松验证：只要 200 响应且有用户数据，就认为验证成功
                    if let data = json?["data"] as? [String: Any],
                       let userId = data["id"] as? String {
                        print("✅ 验证成功：用户 ID=\(userId)")
                        return ValidationResult(isValid: true, shouldLogout: false, reason: "")
                    } else {
                        // 无用户数据 → 静默失败，不退出
                        print("⚠️ 验证响应无用户数据，静默失败")
                        return ValidationResult(isValid: false, shouldLogout: false, reason: "")
                    }
                    
                case 401:
                    // Token 无效 → 静默失败，不退出
                    print("⚠️ Token 无效，静默失败")
                    return ValidationResult(isValid: false, shouldLogout: false, reason: "")
                    
                case 404, 500:
                    // 服务器错误 → 不退出，允许本地使用
                    return ValidationResult(isValid: false, shouldLogout: false, reason: "")
                    
                default:
                    return ValidationResult(isValid: false, shouldLogout: false, reason: "")
                }
            }
        } catch {
            print("❌ 验证请求失败：\(error)")
            return ValidationResult(isValid: false, shouldLogout: false, reason: "网络异常")
        }
        
        return ValidationResult(isValid: false, shouldLogout: false, reason: "未知错误")
    }
    
    /// 退出登录（带原因）
    private func logout(reason: String) async {
        print("🚪 执行自动退出登录：\(reason)")
        
        // 显示提示
        await MainActor.run {
            // 可以通过通知让 ContentView 显示提示
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowLogoutAlert"),
                object: nil,
                userInfo: ["reason": reason]
            )
        }
        
        // 延迟后退出登录（让用户看到提示）
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 秒
        await UserManager.shared.logout()
        
        // 发送强制退出通知
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(name: NSNotification.Name("ForceLogout"), object: nil)
        }
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
            print("🌐 网络状态变化：\(isOnline ? "在线" : "离线")")
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
        print("📝 检测到数据变更，准备同步")
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
            do { try await executeSyncTask(task) } catch { print("❌ 同步失败：\(task.type)") }
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
            print("⏭️ 跳过全量同步（5 分钟内已同步）")
            return
        }
        print("🔄 全量同步")
        lastFullSyncTime = Date()
    }
    
    func appDidBecomeActive() {
        // 不自动触发同步，避免频繁请求
        // print("🟢 App 进入前台，触发同步")  // 删除日志
    }
    
    func syncNow() async { await triggerSync(type: .full) }
    
    func triggerSync(type: SyncTask.SyncType = .full) async {
        scheduleSync(type: type, debounce: false)
    }
    
    func userDidLogin() {
        print("🔵 用户登录成功，触发全量同步")
        Task { await syncNow() }
    }
    
    func networkDidRecover() {
        print("🌐 网络恢复，触发同步")
        Task { await syncNow() }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 🔴 关键：同步设置默认 API URL（在后台任务注册前）
        // 使用 NetworkUtils 自动转换为正确的协议（本地 IP 强制使用 HTTP）
        let defaultURL = "8.136.41.211:3395"
        let normalizedURL = NetworkUtils.normalizeBaseURL(defaultURL)
        DataManager.apiURL = normalizedURL
        DataManager.baseURL = normalizedURL
        UserDefaults.standard.set(normalizedURL, forKey: "apiURL")
        print("🔵 API URL 已设置：\(DataManager.apiURL)")
        
        // 异步更新配置（从服务器获取最新配置）
        Task {
            await initializeAPIConfig()
        }
        
        // 请求通知权限
        NotificationManager.shared.requestPermission()
        
        // 设置通知代理
        UNUserNotificationCenter.current().delegate = self
        
        // 从后端加载通知配置
        Task {
            await LifeCheckStatusManager.shared.loadNotificationConfig()
        }
        
        // 🔴 临时禁用后台任务（修复白屏问题）
        // startBackgroundTasks()
        // setupCheckInNotifications()
        print("⚠️ 后台任务已临时禁用")
        
        print("✅ 终活 App 启动完成")
        return true
    }
    
    /// 设置签到提醒通知
    private func setupCheckInNotifications() {
        LifeCheckStatusManager.shared.scheduleCheckInNotifications()
    }
    
    // ✅ 后台任务注册（在 didFinishLaunchingWithOptions 之后立即注册）
    private func startBackgroundTasks() {
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.zhonghuo.app.sms_notify", using: nil) { task in
                self.handleBackgroundSmsTask(task: task as! BGAppRefreshTask)
            }
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.zhonghuo.app.refresh_notifications", using: nil) { task in
                self.handleNotificationRefresh(task: task as! BGAppRefreshTask)
            }
            print("✅ 后台任务已注册")
        }
    }
    
    private func handleBackgroundSmsTask(task: BGAppRefreshTask) {
        LifeCheckStatusManager.shared.handleBackgroundSmsTask(task: task)
    }
    
    private func handleNotificationRefresh(task: BGAppRefreshTask) {
        print("🔄 刷新通知...")
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        LifeCheckStatusManager.shared.scheduleCheckInNotifications()
        task.setTaskCompleted(success: true)
    }
    
    // MARK: - 通知代理
    
    /// 收到通知时的处理（App 在后台）
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 收到通知：\(notification.request.identifier)")
        
        // 如果是超时通知，且 App 在后台运行，尝试发送短信
        if notification.request.identifier.contains("checkin_overdue") {
            // App 在后台，可以尝试发送短信
            print("📱 超时通知触发，准备发送短信...")
            Task {
                await LifeCheckStatusManager.shared.notifyGuardians()
            }
        }
        
        // 显示通知（横幅 + 声音）
        completionHandler([.banner, .sound])
    }
    
    /// 用户点击通知时的处理
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("👆 用户点击通知：\(response.actionIdentifier)")
        
        // 用户打开 App 后会自动签到
        completionHandler()
    }
    
    private func initializeAPIConfig() async {
        // 🔴 关键：立即设置默认值（同步，确保在异步操作前就设置好）
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
                print("🔵 API URL 已从缓存加载：\(DataManager.apiURL)")
                return
            }
            
            // 从服务器获取配置（超时 3 秒）
            let baseURL = "8.136.41.211:3395"
            try await withTimeout(seconds: 3) {
                try await DataManager.shared.fetchServerConfig(from: baseURL)
            }
            print("🔵 API URL 已从服务器获取：\(DataManager.apiURL)")
        } catch {
            print("❌ 获取 API 配置失败：\(error) - 使用默认值")
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
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
