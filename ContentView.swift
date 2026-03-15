//
//  ContentView.swift
//  终活
//
//  主界面 - 4 个 Tab + 首页悬浮机器人
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedTab = 0
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    @State private var showingEmergencyContactAlert = false
    
    var body: some View {
        Group {
            if isFirstLaunch {
                OnboardingView(isFirstLaunch: $isFirstLaunch)
            } else {
                mainTabView
            }
        }
        .onAppear {
            checkEmergencyContacts()
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
        // TODO: 集成 UserManager 后启用
        // if userManager.needsEmergencyContactCheck {
        //     showingEmergencyContactAlert = true
        // }
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
            
            // 悬浮 AI 机器人 - 仅在首页显示
            if selectedTab == 0 {
                AIRobotView()
            }
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
