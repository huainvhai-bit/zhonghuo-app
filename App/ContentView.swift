//
//  ContentView.swift
//  终活
//
//  主界面 - 4 个 Tab
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    private let dataManager = DataManager.shared
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    @AppStorage("customServerURL") private var customServerURL = ""
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            if viewModel.isMaintenanceMode {
                MaintenanceView(message: viewModel.maintenanceMessage)
            } else if isFirstLaunch {
                OnboardingView(isFirstLaunch: $isFirstLaunch)
            } else {
                if viewModel.isCheckingAuth {
                    // 显示加载界面
                    LoadingView()
                } else if viewModel.forceLogout || !viewModel.hasPersistentSession {
                    LoginView()
                } else {
                    mainTabView
                }
            }
        }
        .alert("版本更新", isPresented: $viewModel.showingUpdateAlert) {
            Button("立即更新") {
                viewModel.openUpdateURL()
            }
            if !viewModel.isForceUpdate {
                Button("稍后再说", role: .cancel) {
                    viewModel.showingUpdateAlert = false
                }
            }
        } message: {
            Text("发现新版本 \(viewModel.updateVersion)，是否立即更新？")
        }
        .onAppear {
            viewModel.start()
            // 📝 设置全局错误处理器
            ErrorHandler.shared.showErrorAlert = { title, message in
                DispatchQueue.main.async {
                    print("🔔 全局错误提示：\(title) - \(message ?? "")")
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            viewModel.handleScenePhaseChange(newPhase)
        }
        .sheet(isPresented: $viewModel.showingFamilyGuard) {
            FamilyGuardView()
        }
    }
    
    private var mainTabView: some View {
        TabView(selection: $viewModel.selectedTab) {
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
            
            SettingsView()
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
// 🔧 维护模式视图
struct MaintenanceView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 维护图标
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            // 标题
            Text("系统维护中")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            // 维护信息
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // 底部信息
            Text("请稍后再试")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "F5F5F7"))
    }
}

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
