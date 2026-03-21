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
                    // 🔴 关键修复：延迟验证，避免登录成功后立即触发
                    // 仅在 App 冷启动时验证（距离上次验证超过 5 分钟）
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 延迟 2 秒
                        await validateAccountOnLaunch()
                    }
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                print("🟢 App 进入前台 - ZhonghuoApp")
                RealTimeSyncManager.shared.appDidBecomeActive()
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
                print("❌ 账号验证失败：\(result.reason)")
                // 🔴 关键修复 4: 仅在不允许本地使用时才退出登录
                if result.shouldLogout {
                    print("🚪 账号异常，需要退出登录")
                    await logout(reason: result.reason)
                } else {
                    print("⚠️ 账号异常，但允许本地使用")
                }
            }
        }
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
        guard !DataManager.apiURL.isEmpty else { return false }
        do {
            let url = URL(string: "\(DataManager.apiURL)/api/check-config.php")!
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return (200...299).contains(httpResponse.statusCode)
            }
        } catch {
            print("⚠️ 网络检查失败：\(error)")
        }
        return false
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
        
        let storedPassword = UserDefaults.standard.string(forKey: "userPassword") ?? ""
        
        do {
            // 优先使用密码验证（更准确）
            if !storedPassword.isEmpty {
                let url = URL(string: "\(DataManager.apiURL)/api.php?action=user_validate")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = ["phone": user.phone, "password": storedPassword]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        let success = json?["success"] as? Bool ?? false
                        if success {
                            return ValidationResult(isValid: true, shouldLogout: false, reason: "")
                        } else {
                            // 密码错误 → 需要退出
                            let code = json?["code"] as? String ?? ""
                            let shouldLogout = (code == "INVALID_PASSWORD")
                            let reason = json?["message"] as? String ?? "密码错误"
                            return ValidationResult(isValid: false, shouldLogout: shouldLogout, reason: reason)
                        }
                        
                    case 401:
                        // Token 无效 → 需要退出
                        return ValidationResult(isValid: false, shouldLogout: true, reason: "登录已过期")
                        
                    case 404, 500:
                        // 服务器错误 → 不退出，允许本地使用
                        return ValidationResult(isValid: false, shouldLogout: false, reason: "验证服务不可用")
                        
                    default:
                        return ValidationResult(isValid: false, shouldLogout: false, reason: "网络错误")
                    }
                }
            } else {
                // 兼容旧版本：使用 Token 验证
                let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
                let url = URL(string: "\(DataManager.apiURL)/api.php?action=user_info")!
                var request = URLRequest(url: url)
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        let success = json?["success"] as? Bool ?? false
                        if success,
                           let data = json?["data"] as? [String: Any],
                           let phone = data["phone"] as? String,
                           phone == user.phone {
                            return ValidationResult(isValid: true, shouldLogout: false, reason: "")
                        } else {
                            // 账号不存在 → 需要退出
                            return ValidationResult(isValid: false, shouldLogout: true, reason: "账号不存在")
                        }
                        
                    case 401:
                        // Token 无效 → 需要退出
                        return ValidationResult(isValid: false, shouldLogout: true, reason: "登录已过期")
                        
                    case 404, 500:
                        // 服务器错误 → 不退出，允许本地使用
                        return ValidationResult(isValid: false, shouldLogout: false, reason: "验证服务不可用")
                        
                    default:
                        return ValidationResult(isValid: false, shouldLogout: false, reason: "网络错误")
                    }
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

// MARK: - 响应模型
struct ValidateResponse: Codable {
    let success: Bool
    let message: String?
}

struct UserInfoResponse: Codable {
    let status: String
    let data: UserInfoData?
    let message: String?
}

struct UserInfoData: Codable {
    let id: String
    let name: String
    let phone: String
    let avatar: String?
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
        // 初始化 API 配置
        Task {
            await initializeAPIConfig()
        }
        
        // 请求通知权限
        NotificationManager.shared.requestPermission()
        
        // 设置通知代理
        UNUserNotificationCenter.current().delegate = self
        
        // 设置签到提醒通知
        setupCheckInReminder()
        
        // 启动后台检查任务
        startBackgroundCheckTask()
        
        print("✅ 终活 App 启动完成")
        return true
    }
    
    /// 设置签到提醒通知
    private func setupCheckInReminder() {
        LifeCheckStatusManager.shared.scheduleBackgroundCheck()
    }
    
    /// 启动后台检查任务（定期检查超时）
    private func startBackgroundCheckTask() {
        // 使用 BGTaskScheduler 安排后台检查
        // 注意：iOS 后台任务有时间限制，系统会决定何时执行
        
        // 注册后台任务（在 Info.plist 中配置）
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.zhonghuo.app.check", using: nil) { task in
                self.handleBackgroundCheck(task: task as! BGAppRefreshTask)
            }
        }
        
        // 安排后台检查
        scheduleBackgroundCheckTask()
    }
    
    /// 安排后台检查任务
    private func scheduleBackgroundCheckTask() {
        if #available(iOS 13.0, *) {
            let request = BGAppRefreshTaskRequest(identifier: "com.zhonghuo.app.check")
            request.earliestBeginDate = Date().addingTimeInterval(60 * 60) // 1 小时后
            
            do {
                try BGTaskScheduler.shared.submit(request)
                print("📅 后台检查任务已安排")
            } catch {
                print("❌ 安排后台任务失败：\(error)")
            }
        }
    }
    
    /// 处理后台检查任务
    private func handleBackgroundCheck(task: BGAppRefreshTask) {
        print("🔍 执行后台检查任务...")
        
        // 设置任务过期处理
        task.expirationHandler = {
            print("⏰ 后台任务时间到")
            task.setTaskCompleted(success: false)
        }
        
        // 后台任务只负责重新安排通知，不检查超时
        // 因为用户打开 App 会自动签到，说明用户安全
        scheduleBackgroundCheckTask()
        
        task.setTaskCompleted(success: true)
        print("✅ 后台检查任务完成")
    }
    
    // MARK: - 通知代理
    
    /// 收到通知时的处理（App 在后台）
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 收到通知：\(notification.request.identifier)")
        
        // 显示通知（横幅 + 声音）
        // 用户点击通知打开 App 后会自动签到，不需要检查超时
        completionHandler([.banner, .sound])
    }
    
    /// 用户点击通知时的处理
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("👆 用户点击通知：\(response.actionIdentifier)")
        
        // 用户打开 App 后会自动签到，不需要检查超时
        completionHandler()
    }
    
    private func initializeAPIConfig() async {
        // 尝试从 UserDefaults 读取已保存的 API URL
        if let savedURL = UserDefaults.standard.string(forKey: "apiURL"), !savedURL.isEmpty {
            DataManager.apiURL = savedURL
            print("🔵 API URL 已从缓存加载：\(DataManager.apiURL)")
            return
        }
        
        // 从服务器获取配置
        let baseURL = "http://8.136.41.211:3395"
        do {
            try await DataManager.shared.fetchServerConfig(from: baseURL)
            print("🔵 API URL 已从服务器获取：\(DataManager.apiURL)")
        } catch {
            print("❌ 获取 API 配置失败：\(error)")
            // 使用默认值
            DataManager.apiURL = baseURL
        }
    }
}
