//
//  ContentView.swift
//  终活
//
//  主界面 - 4 个 Tab
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var userManager = UserManager.shared
    @State private var selectedTab = 0
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    @AppStorage("customServerURL") private var customServerURL = ""  // 空表示自动获取
    @State private var showingEmergencyContactAlert = false
    @AppStorage("hasShownEmergencyContactAlert") private var hasShownEmergencyContactAlert = false
    @State private var showingFamilyGuard = false  // 👨‍👩‍👧‍👦 家人守护
    @State private var forceLogout = false  // 强制退出登录
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            // ✅ 先检查是否首次启动（引导页面）
            if isFirstLaunch {
                OnboardingView(isFirstLaunch: $isFirstLaunch)
            } else {
                // 再检查登录状态（只依赖 UserManager，不使用 UserDefaults 双重检查）
                if forceLogout || !userManager.isLoggedIn {
                    AuthView()
                } else {
                    mainTabView
                }
            }
        }
        .onAppear {
            // 🔴 登录前不执行任何操作！
            // 所有 API 调用必须在用户成功登录后才执行
            
            // 监听强制退出登录通知
            NotificationCenter.default.addObserver(forName: NSNotification.Name("ForceLogout"), object: nil, queue: .main) { _ in
                forceLogout = true
            }
            
            // ✅ 用户已登录时，执行自动签到（只在这里触发一次）
            if userManager.isLoggedIn && userManager.currentUser != nil {
                Task {
                    await userManager.performAutoSignIn()
                    checkEmergencyContacts()
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            // ✅ 从后台进入前台时，刷新用户数据（不再重复签到）
            if newPhase == .active && userManager.isLoggedIn && userManager.currentUser != nil {
                // 从本地重新加载用户数据
                _ = UserManager.shared.currentUser
            }
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
        let logMsg = "🔵 autoSignIn() 自动签到"
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
                        Image(systemName: "house.fill")
                        Text("首页")
                    }
                    .tag(0)
                
                TimeCapsuleView()
                    .tabItem {
                        Image(systemName: "capsule.fill")
                        Text("时光胶囊")
                    }
                    .tag(1)
                
                WillAssetsView()
                    .tabItem {
                        Image(systemName: "doc.text.fill")
                        Text("嘱托与资产")
                    }
                    .tag(2)
                
                FamilyGuardView()
                    .tabItem {
                        Image(systemName: "person.2.fill")
                        Text("家人守护")
                    }
                    .tag(3)
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("我的")
                    }
                    .tag(4)
            }
            .accentColor(Color(hex: "AF52DE"))
            
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

#Preview {
    ContentView()
}
