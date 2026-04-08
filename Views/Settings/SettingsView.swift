//
//  Settings/SettingsView.swift
//  终活
//
//  设置页面入口
//  职责：聚合所有设置模块
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var userManager = UserManager.shared
    @ObservedObject var deviceMonitor = DeviceMonitor.shared  // 🔋 设备监控
    @State private var showProfile = false
    @State private var showEmergencyContacts = false
    @State private var showNotifications = false
    @State private var showPrivacy = false
    @State private var showAbout = false
    @State private var showingLogoutConfirm = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            List {
                // 用户信息卡片
                Section {
                    UserInfoCard(user: userManager.currentUser)
                        .onTapGesture {
                            showProfile = true
                        }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                // 统计信息
                Section {
                    StatCardsView(user: userManager.currentUser)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                // 设置分类
                Section(header: Text("账户设置")) {
                    NavigationLink("个人资料", destination: ProfileSettingsView())
                    NavigationLink("紧急联系人", destination: EmergencyContactSettingsView())
                    NavigationLink("通知设置", destination: NotificationSettingsView())
                }
                
                Section(header: Text("隐私与安全")) {
                    NavigationLink("隐私政策", destination: PrivacySettingsView())
                    NavigationLink("服务条款", destination: TermsSettingsView())
                }
                
                Section(header: Text("关于")) {
                    NavigationLink("关于 App", destination: AboutSettingsView())
                }
                
                Section {
                    Button(role: .destructive) {
                        showingLogoutConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "ant.cpu")
                            Text("退出登录")
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .background(Color(hex: "F5F5F7"))
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .alert("退出登录", isPresented: $showingLogoutConfirm) {
                Button("取消", role: .cancel) { }
                Button("退出", role: .destructive) {
                    Task { await logout() }
                }
            } message: {
                Text("确定要退出登录吗？")
            }
            .sheet(isPresented: $showProfile) {
                ProfileSettingsView()
            }
            .sheet(isPresented: $showEmergencyContacts) {
                EmergencyContactSettingsView()
            }
            .sheet(isPresented: $showNotifications) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacySettingsView()
            }
            .sheet(isPresented: $showAbout) {
                AboutSettingsView()
            }
            .onReceive(deviceMonitor.$batteryLevel) { level in
                deviceMonitor.batteryLevel = level
            }
        }
        .onAppear {
            deviceMonitor.startMonitoring()
        }
        .onDisappear {
            deviceMonitor.stopMonitoring()
        }
    }
    
    private func logout() async {
        print("🔴 退出登录")
        
        // 清除所有用户数据
        userManager.logout()
        
        // 清除 UserDefaults
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.synchronize()
        
        print("✅ 退出登录完成")
    }
}

// MARK: - 统计卡片视图
struct StatCardsView: View {
    let user: User?
    
    var body: some View {
        HStack(spacing: 12) {
            StatItemView(icon: "person.fill", color: .blue, count: user?.emergencyContactsCount ?? 0, label: "联系人")
            StatItemView(icon: "heart.fill", color: .purple, count: user?.witnessesCount ?? 0, label: "见证人")
            StatItemView(icon: "sparkles", color: .orange, count: user?.capsulesCount ?? 0, label: "胶囊")
            StatItemView(icon: "document.fill", color: .green, count: user?.willModulesCount ?? 0, label: "遗嘱")
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 统计项视图
struct StatItemView: View {
    let icon: String
    let color: Color
    let count: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color.opacity(0.15), color.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            
            Text("\(count)")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.6)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 用户信息卡片
struct UserInfoCard: View {
    let user: User?
    
    var body: some View {
        HStack(spacing: 12) {
            if let user = user {
                Text(user.name.prefix(1).uppercased())
                    .font(.system(size: 32, weight: .bold))
                    .frame(width: 60, height: 60)
                    .background(Color(hex: "AF52DE"))
                    .foregroundColor(.white)
                    .cornerRadius(30)
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let user = user {
                    Text(user.name)
                        .font(.headline)
                    Text(user.phone)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("未登录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    SettingsView()
}
