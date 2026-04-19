//
//  SettingsDetailView.swift
//  终活
//
//  设置详情页面
//

import SwiftUI

struct SettingsDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var userManager = UserManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @AppStorage("silentModeEnabled") private var silentModeEnabled = false
    @AppStorage("isFamilyMode") private var isFamilyMode = false
    @State private var showingLogoutConfirm = false
    @State private var showingRestoreAlert = false
    @State private var showingRestoreConfirmAlert = false
    @State private var restoreMessage = ""
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F7")
                .ignoresSafeArea()
            
            List {
                // 📍 定位服务
                Section(header: Text("位置服务")) {
                    NavigationLink(destination: LocationSettingsView()) {
                        SettingsRow(icon: "location.fill", iconColor: .blue, title: "定位服务", subtitle: "签到时获取位置")
                    }
                }
                
                // 👨‍👩‍👧 家人守护模式
                Section(header: Text("家人守护")) {
                    Toggle(isOn: $isFamilyMode) {
                        SettingsRow(icon: "person.2.fill", iconColor: .green, title: "我是家人", subtitle: "停止签到倒计时")
                    }
                    .tint(Color(hex: "6366F1"))
                }
                
                Section(header: Text("说明")) {
                    Text("开启「我是家人」后，您将不需要进行安全签到。此设备作为守护者使用，负责查看家人的安全状态，不再进行自我签到倒计时。")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                // 🎨 主题设置
                Section(header: Text("外观")) {
                    NavigationLink(destination: ThemeSettingsView()) {
                        SettingsRow(icon: "paintbrush.fill", iconColor: .purple, title: "主题设置", subtitle: themeManager.theme.rawValue)
                    }
                }
                
                // ☁️ 云端恢复
                Section(header: Text("数据")) {
                    Button(action: {
                        showingRestoreConfirmAlert = true
                    }) {
                        SettingsRow(icon: "icloud.and.arrow.down.fill", iconColor: .cyan, title: "云端恢复数据", subtitle: "从服务器恢复本地数据")
                    }
                }
                
                // ℹ️ 关于
                Section(header: Text("关于")) {
                    NavigationLink(destination: AboutSettingsView()) {
                        SettingsRow(icon: "info.circle.fill", iconColor: .gray, title: "关于", subtitle: "版本 \(appVersion)")
                    }
                }
                
                // 🚪 退出登录
                Section {
                    Button(action: {
                        showingLogoutConfirm = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                                .frame(width: 28)
                            Text("退出登录")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
        .confirmationDialog("确认退出", isPresented: $showingLogoutConfirm) {
            Button("退出登录", role: .destructive) {
                logout()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要退出登录吗？退出后需要重新登录才能使用 App。")
        }
        .alert("云端恢复", isPresented: $showingRestoreAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(restoreMessage)
        }
        .alert("确认恢复", isPresented: $showingRestoreConfirmAlert) {
            Button("取消", role: .cancel) {}
            Button("确定恢复") {
                restoreFromCloud()
            }
        } message: {
            Text("确定要从云端恢复数据吗？这将覆盖本地数据。")
        }
    }
    
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    
    private func restoreFromCloud() {
        Task {
            do {
                if let result = await dataManager.batchSyncCapsules() {
                    restoreMessage = "成功从云端恢复 \(result.total) 个胶囊"
                } else {
                    restoreMessage = "云端恢复失败，请检查网络连接"
                }
                showingRestoreAlert = true
            }
        }
    }
    
    private func logout() {
        userManager.logout()
        dismiss()
    }
}

// MARK: - 设置行组件
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 定位服务设置
struct LocationSettingsView: View {
    @AppStorage("locationEnabled") private var locationEnabled = true
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F7")
                .ignoresSafeArea()
            
            List {
                Section(header: Text("定位权限")) {
                    Toggle("启用定位服务", isOn: $locationEnabled)
                        .tint(Color(hex: "6366F1"))
                }
                
                Section(header: Text("说明")) {
                    Text("定位服务用于在签到时记录您的位置信息，证明您的人身安全。如果您不启用定位，将无法使用签到功能的位置记录。")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("定位服务")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 主题设置
struct ThemeSettingsView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    
    private func themeDisplayName(_ theme: ThemeManager.Theme) -> String {
        switch theme {
        case .auto: return "跟随系统"
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F7")
                .ignoresSafeArea()
            
            List {
                Section(header: Text("选择主题")) {
                    ForEach(ThemeManager.Theme.allCases, id: \.self) { theme in
                        Button(action: {
                            themeManager.setTheme(theme)
                        }) {
                            HStack {
                                Text(themeDisplayName(theme))
                                    .foregroundColor(.primary)
                                Spacer()
                                if themeManager.theme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "6366F1"))
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("说明")) {
                    Text("主题设置会影响 App 的整体外观颜色。选择您喜欢的颜色方案。")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("主题设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SettingsDetailView()
    }
}
