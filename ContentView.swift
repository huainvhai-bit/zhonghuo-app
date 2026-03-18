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
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            // 双重检查：userManager.isLoggedIn 或 UserDefaults
            let isActuallyLoggedIn = userManager.isLoggedIn || UserDefaults.standard.bool(forKey: "isLoggedIn")
            
            if !isActuallyLoggedIn {
                AuthView()
            } else if isFirstLaunch {
                OnboardingView(isFirstLaunch: $isFirstLaunch)
            } else {
                mainTabView
            }
        }
        .onAppear {
            print("🟢 ====== ContentView onAppear ======")
            print("   userManager.isLoggedIn: \(userManager.isLoggedIn)")
            print("   UserDefaults isLoggedIn: \(UserDefaults.standard.bool(forKey: "isLoggedIn"))")
            print("   currentUser: \(userManager.currentUser?.name ?? "nil")")
            
            // 确保 API 配置已初始化（立即可用）
            DataManager.shared.initializeAPIConfig()
            
            // 强制同步登录状态
            if UserDefaults.standard.bool(forKey: "isLoggedIn") {
                userManager.isLoggedIn = true
                print("✅ 从 UserDefaults 恢复登录状态")
            }
            
            // 如果没有 currentUser 但有 isLoggedIn，尝试重新加载
            if userManager.isLoggedIn && userManager.currentUser == nil {
                userManager.loadUser()
                print("🔄 重新加载用户数据")
            }
            
            checkEmergencyContacts()
            
            // 🎯 每次打开 App 自动签到（延迟 0.5 秒确保用户数据加载）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("⏰ 延迟执行自动签到...")
                autoCheckIn()
            }
            
            // 如果用户自定义了服务器地址，使用自定义地址（用于特殊场景）
            if !customServerURL.isEmpty {
                DataManager.baseURL = customServerURL
                DataManager.apiURL = "\(customServerURL)/api"
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            print("🟡 ====== scenePhase 变化：\(oldPhase) → \(newPhase) ======")
            
            if newPhase == .active {
                print("🟢 App 进入前台状态")
                // 🎯 从后台进入前台时也自动签到
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    autoCheckIn()
                }
            }
        }
        .alert("紧急联系人提醒", isPresented: $showingEmergencyContactAlert) {
            Button("稍后设置", role: .cancel) {}
            Button("立即设置") {
                selectedTab = 3
            }
        } message: {
            Text("为了您的安全，请至少设置 2 位紧急联系人。")
        }
    }
    
    private func checkEmergencyContacts() {
        // 只有紧急联系人数量少于 2 人时才提醒
        if let user = userManager.currentUser,
           user.emergencyContacts.count < 2 {
            showingEmergencyContactAlert = true
        }
    }
    
    private func autoCheckIn() {
        print("🔵 autoCheckIn() 被调用")
        print("   isLoggedIn: \(userManager.isLoggedIn)")
        print("   currentUser: \(userManager.currentUser?.name ?? "nil")")
        
        // 确保用户数据已加载
        if userManager.currentUser == nil {
            print("🔄 用户数据未加载，先加载用户...")
            userManager.loadUser()
            // 延迟 0.5 秒再执行签到
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("⏰ 延迟执行自动签到...")
                userManager.performAutoCheckIn()
            }
        } else {
            print("✅ 用户数据已存在，直接执行签到")
            userManager.performAutoCheckIn()
        }
    }
    
    private var mainTabView: some View {
        ZStack {
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
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("我的")
                    }
                    .tag(3)
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
