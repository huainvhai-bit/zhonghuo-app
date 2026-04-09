//
//  ContentView.swift
//  终活
//
//  主界面 - 4 个 Tab
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var dataManager = DataManager.shared
    @ObservedObject private var userManager = UserManager.shared
    @State private var selectedTab = 0
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    @AppStorage("customServerURL") private var customServerURL = ""  // 空表示自动获取
    @State private var showingEmergencyContactAlert = false
    @AppStorage("hasShownEmergencyContactAlert") private var hasShownEmergencyContactAlert = false
    @State private var showingFamilyGuard = false  // 👨‍👩‍👧‍👦 家人守护
    @State private var forceLogout = false  // 强制退出登录
    @State private var isCheckingAuth = true  // 🔴 添加加载状态
    @State private var refreshTrigger = false  // 🔴 触发刷新的标记
    @State private var showingLogoutAlert = false  // 🔴 显示退出登录提示
    @State private var logoutReason = ""  // 🔴 退出登录原因
    @State private var showingUpdateAlert = false  // 📱 版本更新提示
    @State private var updateVersion = ""  // 📱 更新版本号
    @State private var updateUrl = ""  // 📱 更新地址
    @State private var isForceUpdate = false  // 📱 是否强制更新
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            // ✅ 先检查是否首次启动（引导页面）
            if isFirstLaunch {
                OnboardingView(isFirstLaunch: $isFirstLaunch)
            } else {
                // 🔴 等待登录状态检查完成
                if isCheckingAuth {
                    // 显示加载界面
                    LoadingView()
                } else if forceLogout || !userManager.isLoggedIn || userManager.currentUser == nil {
                    LoginView()
                } else {
                    mainTabView
                }
            }
        }
        .alert("版本更新", isPresented: $showingUpdateAlert) {
            Button("立即更新") {
                if !updateUrl.isEmpty, let url = URL(string: updateUrl) {
                    UIApplication.shared.open(url)
                }
            }
            if !isForceUpdate {
                Button("稍后再说", role: .cancel) {
                    showingUpdateAlert = false
                }
            }
        } message: {
            Text("发现新版本 \(updateVersion)，是否立即更新？")
        }
        .onAppear {
            // 🔴 关键修复：等待 UserManager 完成加载后再检查登录状态
            Task {
                await checkLoginStatus()
            }
            
            // 📝 设置全局错误处理器
            ErrorHandler.shared.showErrorAlert = { title, message in
                // 在主线程显示错误提示
                DispatchQueue.main.async {
                    // 可以扩展为显示全局错误弹窗
                    print("🔔 全局错误提示：\(title) - \(message ?? "")")
                }
            }
            
            // 监听强制退出登录通知
            NotificationCenter.default.addObserver(forName: NSNotification.Name("ForceLogout"), object: nil, queue: .main) { _ in
                print("🔴 收到强制退出登录通知")
                forceLogout = true
                isCheckingAuth = false
            }
            
            // 🔴 监听用户登录成功通知
            NotificationCenter.default.addObserver(forName: NSNotification.Name("UserDidLogin"), object: nil, queue: .main) { _ in
                print("🔔 收到用户登录通知，重新检查状态...")
                Task {
                    await checkLoginStatus()
                }
            }
            
            // 🔴 禁用退出登录提示（不再弹窗打扰用户）
            // NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowLogoutAlert"), object: nil, queue: .main) { notification in
            //     if let reason = notification.userInfo?["reason"] as? String {
            //         logoutReason = reason
            //         showingLogoutAlert = true
            //     }
            // }
            
            // 📱 监听版本更新提示
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                let showing = UserDefaults.standard.bool(forKey: "showingUpdateAlert")
                if showing && !showingUpdateAlert {
                    updateVersion = UserDefaults.standard.string(forKey: "pendingUpdateVersion") ?? ""
                    updateUrl = UserDefaults.standard.string(forKey: "pendingUpdateUrl") ?? ""
                    let forceVersion = UserDefaults.standard.string(forKey: "pendingForceUpdateVersion") ?? ""
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                    
                    // 判断是否强制更新
                    isForceUpdate = isVersionNewerOrEqual(forceVersion, than: currentVersion)
                    
                    showingUpdateAlert = true
                    
                    // 清除标记
                    UserDefaults.standard.set(false, forKey: "showingUpdateAlert")
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            // ✅ 从后台进入前台时，自动签到 + 刷新用户数据
            if newPhase == .active && userManager.isLoggedIn && userManager.currentUser != nil {
                print("🔵 App 从后台进入前台，触发自动签到...")
                
                // 📢 通知所有页面场景已激活（刷新倒计时）
                NotificationCenter.default.post(name: NSNotification.Name("SceneDidBecomeActive"), object: nil)
                
                // 🎯 执行自动签到
                Task {
                    await self.userManager.performAutoSignIn()
                }
                
                // 📥 从本地重新加载用户数据
                _ = UserManager.shared.currentUser
            } else if newPhase == .background {
                // 🌙 App 进入后台，保存当前状态
                print("🌙 App 进入后台，倒计时继续（本地通知）")
            }
        }
        .alert("账号验证失败", isPresented: $showingLogoutAlert) {
            Button("确定", role: .destructive) {}
        } message: {
            Text(logoutReason)
        }
        .alert("紧急联系人提醒", isPresented: $showingEmergencyContactAlert) {
            Button("稍后设置", role: .cancel) {}
            Button("立即设置") {
                selectedTab = 3  // 跳转到家人守护
            }
        } message: {
            Text("为了您的安全，请至少设置 2 位紧急联系人。添加家人守护会自动同步到紧急联系人。")
        }
        .sheet(isPresented: $showingFamilyGuard) {
            FamilyGuardView()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenFamilyGuard"))) { _ in
            showingFamilyGuard = true
        }
    }
    
    private func checkEmergencyContacts() {
        // 只有紧急联系人数量少于 2 人时才提醒，且只提示一次
        if let user = userManager.currentUser,
           user.emergencyContacts.count < 2,
           !hasShownEmergencyContactAlert {
            showingEmergencyContactAlert = true
            hasShownEmergencyContactAlert = true
        }
    }
    
    // 🔴 检查登录状态的函数（可重复调用）
    private func checkLoginStatus() async {
        print("🔍 开始检查登录状态...")
        
        // 🔴 重置 forceLogout，避免历史状态影响
        self.forceLogout = false
        
        // 加载用户（同步）
        self.userManager.loadUser()
        
        // 🔴 等待异步加载完成（最多 3 秒）
        var waitCount = 0
        while self.userManager.currentUser == nil && waitCount < 30 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
            waitCount += 1
        }
        
        // 🔴 确保 isLoggedIn 和 currentUser 都有效
        let isLoggedIn = self.userManager.isLoggedIn && self.userManager.currentUser != nil
        print("🔍 登录状态检查：")
        print("   - isLoggedIn: \(self.userManager.isLoggedIn)")
        print("   - currentUser: \(self.userManager.currentUser?.name ?? "nil")")
        
        // 🔴 新增：验证后端 Token 是否有效（仅在网络请求失败且返回 401 时退出）
        if isLoggedIn {
            let validationResult = await validateToken()
            if validationResult == .unauthorized {
                // 只有明确 401 时才退出登录
                print("❌ Token 验证失败（401），后端可能没有此账号，执行退出登录")
                await self.userManager.logout()
                await MainActor.run {
                    self.isCheckingAuth = false
                    self.refreshTrigger.toggle()
                }
                return
            } else if validationResult == .networkError || validationResult == .serverError {
                // 网络错误/服务器错误时，保持登录状态（使用本地数据）
                print("⚠️ 网络/服务器错误，保持登录状态（使用本地缓存）")
                // 🔴 重置 forceLogout，避免误判
                self.forceLogout = false
            } else {
                print("✅ Token 验证成功")
                // 🔴 重置 forceLogout，确保登录状态正常
                self.forceLogout = false
            }
        }
        
        // 🔴 关键：立即更新状态，避免白屏
        await MainActor.run {
            self.isCheckingAuth = false
            self.refreshTrigger.toggle()
            
            print("   - isCheckingAuth: \(self.isCheckingAuth)")
            print("   - forceLogout: \(self.forceLogout)")
            print("   - userManager.isLoggedIn: \(self.userManager.isLoggedIn)")
            print("   - userManager.currentUser: \(self.userManager.currentUser?.name ?? "nil")")
            print("   - 判断条件：forceLogout=\(self.forceLogout) || !isLoggedIn=\(!self.userManager.isLoggedIn) || currentUser==nil=\(self.userManager.currentUser == nil)")
            
            // 🔴 禁用自动签到（避免重复触发和卡顿）
            // ✅ 用户已登录时，执行自动签到（只在这里触发一次）
            // if isLoggedIn {
            //     print("✅ 用户已登录，执行自动签到...")
            //     Task {
            //         await self.userManager.performAutoSignIn()
            //         self.checkEmergencyContacts()
            //     }
            // } else {
            //     print("⚠️ 用户未登录，显示登录界面")
            // }
            
            if isLoggedIn {
                print("✅ 用户已登录，跳过自动签到")
                self.checkEmergencyContacts()
            } else {
                print("⚠️ 用户未登录，显示登录界面")
            }
        }
    }
    
    /// Token 验证结果
    enum ValidateTokenResult {
        case success      // Token 有效
        case unauthorized // 401/404 - Token 无效或用户不存在（需要退出登录）
        case networkError // 网络错误（保持登录）
        case serverError  // 服务器错误（保持登录）
    }
    
    /// 验证后端 Token 是否有效（GraphQL）
    /// ✅ 2026-03-27 永久方案：超时 + 错误处理 + 日志
    /// 🔧 修复：更清晰地区分网络错误和服务器错误
    private func validateToken() async -> ValidateTokenResult {
        guard let token = KeychainManager.shared.getToken(), !token.isEmpty else {
            print("⚠️ validateToken: No token found")
            return .unauthorized
        }
        
        guard !DataManager.apiURL.isEmpty else {
            print("⚠️ validateToken: API URL is empty")
            return .networkError
        }
        
        // ✅ 使用带超时的 URLSession（5 秒请求超时，15 秒资源超时）
        var config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 15
        let session = URLSession(configuration: config)
        
        do {
            // 使用 GraphQL validateUser query
            let query = """
            query {
                validateUser(userId: "") {
                    success
                    message
                    data { id name phone }
                }
            }
            """
            
            var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/api/graphql.php")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = ["query": query]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            print("🔍 validateToken: Sending request to \(DataManager.apiURL)/api/graphql.php")
            
            let (data, response) = try await session.data(for: request)
            
            print("🔍 validateToken: Response received, status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    // 🔧 修复：解析响应体，区分成功和服务器错误
                    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        print("❌ validateToken: Failed to parse JSON response (server error)")
                        return .serverError
                    }
                    
                    // GraphQL 响应格式：{"data": {"validateUser": {"success": true, ...}}}
                    if let dataObj = json["data"] as? [String: Any],
                       let validateUser = dataObj["validateUser"] as? [String: Any],
                       let success = validateUser["success"] as? Bool {
                        print("✅ validateToken: success=\(success)")
                        return success ? .success : .unauthorized
                    } else if let errors = json["errors"] as? [[String: Any]] {
                        // GraphQL 返回错误，检查是否是认证错误
                        print("❌ validateToken: GraphQL errors: \(errors)")
                        return .unauthorized
                    } else {
                        print("❌ validateToken: Invalid response format (server error)")
                        return .serverError
                    }
                case 401:
                    // 🔧 修复：明确 401 为认证失败
                    print("❌ validateToken: Token invalid (401 Unauthorized)")
                    return .unauthorized
                case 404:
                    // 🔧 修复：明确 404 为用户不存在
                    print("❌ validateToken: User not found (404 Not Found)")
                    return .unauthorized
                case 500, 502, 503, 504:
                    // 🔧 修复：明确 5xx 为服务器错误，保持登录
                    print("⚠️ validateToken: Server error (\(httpResponse.statusCode)), keeping login")
                    return .serverError
                case 400, 403, 405, 408, 429:
                    // 🔧 修复：其他客户端错误，保持登录（可能是临时问题）
                    print("⚠️ validateToken: Client error (\(httpResponse.statusCode)), keeping login")
                    return .networkError
                default:
                    // 🔧 修复：未知状态码，保持登录
                    print("⚠️ validateToken: Unknown status (\(httpResponse.statusCode)), keeping login")
                    return .serverError
                }
            } else {
                // 🔧 修复：没有 HTTP 响应，可能是网络问题
                print("⚠️ validateToken: No HTTP response received")
                return .networkError
            }
        } catch let urlError as URLError {
            // 🔧 修复：明确区分网络错误类型
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                print("⚠️ validateToken: No network connection, keeping login")
            case .timedOut:
                print("⚠️ validateToken: Request timed out, keeping login")
            case .cannotFindHost, .cannotConnectToHost:
                print("⚠️ validateToken: Cannot reach server, keeping login")
            default:
                print("⚠️ validateToken: Network error (\(urlError.code)): \(urlError.localizedDescription), keeping login")
            }
            return .networkError
        } catch let decodingError as DecodingError {
            // 🔧 修复：JSON 解析错误，可能是服务器返回格式错误
            print("⚠️ validateToken: JSON decoding error: \(decodingError.localizedDescription), keeping login")
            return .serverError
        } catch {
            // 🔧 修复：其他未知错误，保持登录
            print("⚠️ validateToken: Unknown error: \(type(of: error)) - \(error.localizedDescription), keeping login")
            return .networkError
        }
    }
    
    private func writeLogToFile(_ message: String) {
        let fileManager = FileManager.default
        let docsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let logFile = docsPath.appendingPathComponent("checkin_log.txt")
        
        var content = ""
        if fileManager.fileExists(atPath: logFile.path) {
            content = (try? String(contentsOf: logFile)) ?? ""
        }
        
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        content += "\n[\(timestamp)] \(message)"
        
        try? content.write(to: logFile, atomically: true, encoding: .utf8)
    }
    
    private func autoSignIn() {
        let logMsg = "🔵 autoSignIn() 自动签到 - 每次打开 App 触发"
        writeLogToFile(logMsg)
        print(logMsg)
        
        // 确保用户数据已加载
        if userManager.currentUser == nil {
            print("🔄 用户数据未加载，先加载用户...")
            userManager.loadUser()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                userManager.performAutoSignIn()
            }
        } else {
            let logMsg2 = "✅ 用户数据已存在，执行自动签到"
            writeLogToFile(logMsg2)
            print(logMsg2)
            
            userManager.performAutoSignIn()
        }
    }
    
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            // 🚀 懒加载：使用 NavigationView 包装，延迟视图创建（iOS 15 兼容）
            NavigationView {
                HomeStatusView()
                    .navigationBarHidden(true)
            }
            .tabItem {
                Label("首页", systemImage: "house.fill")
            }
            .tag(0)
            
            NavigationView {
                CapsuleList(dataManager: dataManager)
                    .navigationBarHidden(true)
            }
            .tabItem {
                Label("时光胶囊", systemImage: "clock.fill")
            }
            .tag(1)
            
            NavigationView {
                WillAssetsView()
                    .navigationBarHidden(true)
            }
            .tabItem {
                Label("嘱托与资产", systemImage: "doc.text.fill")
            }
            .tag(2)
            
            NavigationView {
                FamilyGuardView()
                    .navigationBarHidden(true)
            }
            .tabItem {
                Label("家人守护", systemImage: "person.2.fill")
            }
            .tag(3)
            
            NavigationView {
                SettingsView()
                    .navigationBarHidden(true)
            }
            .tabItem {
                Label("我的", systemImage: "person.fill")
            }
            .tag(4)
        }
        .tint(Color(hex: "6366F1"))
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// 🔴 加载视图 - 等待登录状态检查
struct LoadingView: View {
    @State private var opacity = 0.5
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("正在加载...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "F5F5F7"))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                opacity = 1.0
            }
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - 版本比较辅助函数
extension ContentView {
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
    
    private func isVersionNewerOrEqual(_ v1: String, than v2: String) -> Bool {
        if v1 == v2 {
            return true
        }
        return isVersionNewer(v1, than: v2)
    }
}
