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
                    // 🔴 增加 currentUser 检查，确保用户数据也存在
                    AuthView()
                } else {
                    mainTabView
                }
            }
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
            
            // 🔴 监听退出登录提示
            NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowLogoutAlert"), object: nil, queue: .main) { notification in
                if let reason = notification.userInfo?["reason"] as? String {
                    logoutReason = reason
                    showingLogoutAlert = true
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            // ✅ 从后台进入前台时，自动签到 + 刷新用户数据
            if newPhase == .active && userManager.isLoggedIn && userManager.currentUser != nil {
                print("🔵 App 从后台进入前台，触发自动签到...")
                Task {
                    await self.userManager.performAutoSignIn()
                }
                // 从本地重新加载用户数据
                _ = UserManager.shared.currentUser
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
        
        // 加载用户（同步）
        self.userManager.loadUser()
        
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
            } else {
                print("✅ Token 验证成功")
            }
        }
        
        // 🔴 关键：立即更新状态，避免白屏
        await MainActor.run {
            self.isCheckingAuth = false
            self.refreshTrigger.toggle()
            
            print("   - isCheckingAuth: \(self.isCheckingAuth)")
            
            // ✅ 用户已登录时，执行自动签到（只在这里触发一次）
            if isLoggedIn {
                print("✅ 用户已登录，执行自动签到...")
                Task {
                    await self.userManager.performAutoSignIn()
                    self.checkEmergencyContacts()
                }
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
    private func validateToken() async -> ValidateTokenResult {
        guard let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty else {
            return .unauthorized
        }
        
        guard !DataManager.apiURL.isEmpty else {
            return .networkError
        }
        
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
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    // GraphQL 响应格式：{"data": {"validateUser": {"success": true, ...}}}
                    if let dataObj = json?["data"] as? [String: Any],
                       let validateUser = dataObj["validateUser"] as? [String: Any],
                       let success = validateUser["success"] as? Bool {
                        return success ? .success : .unauthorized
                    }
                    return .serverError
                case 401:
                    print("❌ Token 无效（401）")
                    return .unauthorized
                case 404:
                    print("❌ 用户不存在（404）")
                    return .unauthorized
                case 500, 502, 503:
                    print("⚠️ 服务器错误（\(httpResponse.statusCode)），保持登录状态")
                    return .serverError
                default:
                    print("⚠️ 未知状态码（\(httpResponse.statusCode)），保持登录状态")
                    return .serverError
                }
            }
        } catch let urlError as URLError {
            // 网络错误（无网络、超时等）
            print("⚠️ 网络错误：\(urlError.localizedDescription)，保持登录状态")
            return .networkError
        } catch {
            // 其他错误
            print("⚠️ 未知错误：\(error)，保持登录状态")
            return .networkError
        }
        
        // 默认保持登录
        return .networkError
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
        ZStack {
            Color(hex: "F5F5F7")
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                HomeStatusView()
                    .tabItem {
                        Label("首页", systemImage: "house")
                    }
                    .tag(0)
                
                TimeCapsuleView()
                    .tabItem {
                        Label("时光胶囊", systemImage: "hourglass")
                    }
                    .tag(1)
                
                WillAssetsView()
                    .tabItem {
                        Label("嘱托与资产", systemImage: "signature")
                    }
                    .tag(2)
                
                FamilyGuardView()
                    .tabItem {
                        Label("家人守护", systemImage: "heart")
                    }
                    .tag(3)
                
                SettingsView()
                    .tabItem {
                        Label("我的", systemImage: "gear")
                    }
                    .tag(4)
            }
            .tint(Color(hex: "6366F1"))
            
        }
        .onAppear {
            // 设置 Tab 栏样式
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            
            // 设置选中项颜色（紫色）
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(hex: "6366F1")
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(hex: "6366F1")]
            
            // 未选中项颜色（灰色）
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
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
