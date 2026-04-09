//
//  Settings/SettingsView.swift
//  终活
//
//  设置页面入口
//  职责：聚合所有设置模块
//

import SwiftUI
import Combine
import CloudKit

struct SettingsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var userManager = UserManager.shared
    @ObservedObject var deviceMonitor = DeviceMonitor.shared  // 🔋 设备监控
    @State private var showProfile = false
    @State private var showEmergencyContacts = false
    @State private var showNotifications = false
    @State private var showPrivacy = false
    @State private var showAbout = false
    @State private var showingFamilyGuard = false  // 👨‍👩‍👧‍👦 家人守护
    @State private var showingLogoutConfirm = false
    @State private var showingRestoreConfirm = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showingExportProgress = false
    @State private var exportSuccess = false
    
    var body: some View {
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
                    Button("个人资料") { showProfile = true }
                    Button("紧急联系人") { showEmergencyContacts = true }
                    Button("通知设置") { showNotifications = true }
                }
                
                Section(header: Text("隐私与安全")) {
                    Button("隐私政策") { showPrivacy = true }
                    Button("服务条款") { openTermsURL() }
                    Button(action: exportUserData) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("导出个人数据")
                        }
                    }
                    Button(action: { showingRestoreConfirm = true }) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.down")
                            Text("从云端恢复")
                        }
                    }
                    .foregroundColor(.blue)
                }
                
                Section(header: Text("关于")) {
                    Button("关于 App") { showAbout = true }
                }
                
                Section(header: Text("家人守护")) {
                    Button(action: { showingFamilyGuard = true }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("家人守护")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
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
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .navigationViewStyle(StackNavigationViewStyle())
            .alert("退出登录", isPresented: $showingLogoutConfirm) {
                Button("取消", role: .cancel) { }
                Button("退出", role: .destructive) {
                    Task { await logout() }
                }
            } message: {
                Text("确定要退出登录吗？")
            }
            .alert("从云端恢复", isPresented: $showingRestoreConfirm) {
                Button("取消", role: .cancel) { }
                Button("恢复", role: .destructive) {
                    Task { await restoreFromCloud() }
                }
            } message: {
                Text("⚠️ 云端数据将覆盖本地所有数据（胶囊、遗嘱、紧急联系人、见证人），确定要继续吗？")
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
            .sheet(isPresented: $showingFamilyGuard) {
                FamilyGuardView()
            }
            .onReceive(deviceMonitor.$batteryLevel) { level in
                deviceMonitor.batteryLevel = level
            }
            .onAppear {
            deviceMonitor.startMonitoring()
        }
        .onDisappear {
            deviceMonitor.stopMonitoring()
        }
    }
    
    private func openTermsURL() {
        if let url = URL(string: "https://zhonghuo.cn/terms") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
    
    private func exportUserData() {
        Task {
            showingExportProgress = true
            
            do {
                // 调用数据导出 API
                let data = try await DataManager.shared.downloadUserData(type: "all")
                print("✅ 导出数据：\(data)")
                
                // 将数据转换为 JSON
                let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                
                // 保存到临时文件
                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "终活数据_\(Date().formatted(.dateTime.year().month().day().hour().minute()))"
                let fileURL = tempDir.appendingPathComponent("\(fileName).json")
                try jsonData.write(to: fileURL)
                
                // 使用 UIActivityViewController 分享文件
                let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                
                // 获取窗口场景
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    // 如果是 iPad，需要设置 popover
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = rootVC.view
                        popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                        popover.permittedArrowDirections = []
                    }
                    
                    await MainActor.run {
                        rootVC.present(activityVC, animated: true)
                        showingExportProgress = false
                        exportSuccess = true
                    }
                }
            } catch {
                print("❌ 导出数据失败：\(error)")
                errorMessage = "导出失败：\(error.localizedDescription)"
                showingError = true
                showingExportProgress = false
            }
        }
    }
    
    /// 从云端恢复数据
    @MainActor
    private func restoreFromCloud() async {
        print("☁️ 开始从云端恢复数据...")
        
        do {
            try await DataManager.shared.restoreFromCloud()
            print("✅ 云端恢复成功")
            showingRestoreConfirm = false
        } catch {
            print("❌ 云端恢复失败：\(error)")
            errorMessage = "恢复失败：\(error.localizedDescription)"
            showingError = true
            showingRestoreConfirm = false
        }
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
