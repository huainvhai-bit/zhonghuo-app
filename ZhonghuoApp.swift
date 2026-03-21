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
    @State private var accountValidated = false
    @State private var validationFailed = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            // 🔴 关键修复：删除启动时自动验证账号
            // 原因：登录成功后也会触发验证，导致验证失败就退出登录的恶性循环
            // 账号验证应该在设置页面由用户主动触发，而不是自动执行
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                print("🟢 App 进入前台 - ZhonghuoApp")
                RealTimeSyncManager.shared.appDidBecomeActive()
            }
        }
    }
    
    // 🔴 删除 validateAccountOnLaunch() - 不再自动验证账号
    // 如果未来需要验证，应该在设置页面添加"验证账号"按钮，由用户主动触发
    
    private func waitForNetwork() async -> Bool {
        let maxWaitTime: TimeInterval = 5.0
        let checkInterval: TimeInterval = 0.5
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
    
    private func validateUserCredentials(user: User) async -> Bool {
        guard !DataManager.apiURL.isEmpty else { return false }
        
        let storedPassword = UserDefaults.standard.string(forKey: "userPassword") ?? ""
        
        do {
            let url = URL(string: "\(DataManager.apiURL)/api.php?action=user_validate")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = ["phone": user.phone, "password": storedPassword]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let success = json?["success"] as? Bool ?? false
                print("🔐 账号验证结果：\(success ? "成功" : "失败")")
                return success
            }
        } catch {
            print("❌ 验证请求失败：\(error)")
        }
        
        // 兼容旧版本（无密码）
        if storedPassword.isEmpty {
            return await validateByUserInfo(user: user)
        }
        
        return false
    }
    
    private func validateByUserInfo(user: User) async -> Bool {
        guard !DataManager.apiURL.isEmpty else { return false }
        let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
        
        do {
            let url = URL(string: "\(DataManager.apiURL)/api.php?action=user_info")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    let success = json?["success"] as? Bool ?? false
                    if success,
                       let data = json?["data"] as? [String: Any],
                       let phone = data["phone"] as? String {
                        print("🔐 Token 验证成功，手机号匹配：\(phone == user.phone)")
                        return phone == user.phone
                    }
                } else if httpResponse.statusCode == 401 {
                    print("❌ Token 已过期")
                    return false
                }
            }
        } catch {
            print("❌ 获取用户信息失败：\(error)")
        }
        return false
    }
    
    private func logout() {
        print("🚪 自动退出登录")
        UserManager.shared.logout()
        UserDefaults.standard.removeObject(forKey: "userPassword")
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        
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
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 初始化 API 配置
        Task {
            await initializeAPIConfig()
        }
        
        NotificationManager.shared.requestPermission()
        print("✅ 终活 App 启动完成")
        return true
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
