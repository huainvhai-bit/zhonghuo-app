//
//  Settings/AboutSettingsView.swift
//  终活
//
//  关于设置视图
//  职责：检查更新、关于我们等
//

import SwiftUI

struct AboutSettingsView: View {
    @State private var showingUpdateAlert = false
    @State private var checkingUpdate = false
    @ObservedObject private var dataManager = DataManager.shared
    
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo
                    VStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text("终活")
                            .font(.system(size: 28, weight: .bold))
                        Text("让生命更有温度")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    // 版本信息
                    VStack(spacing: 16) {
                        Button(action: checkUpdate) {
                            HStack {
                                Spacer()
                                Text("检查更新")
                                    .foregroundColor(Color(hex: "6366F1"))
                                Spacer()
                            }
                        }
                        .frame(height: 44)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        }
                        
                        HStack {
                            Text("当前版本")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("v\(appVersion)")
                                .foregroundColor(.secondary)
                        }
                        .font(.body)
                    }
                    
                    // 联系方式
                    VStack(spacing: 12) {
                        if let url = URL(string: "https://zhonghuo.cn") {
                            Link(destination: url) {
                                HStack {
                                    Text("官方网站")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                            }
                        }
                        if let url = URL(string: "https://zhonghuo.cn/privacy") {
                            Link(destination: url) {
                                HStack {
                                    Text("隐私政策")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                            }
                        }
                        if let url = URL(string: "https://zhonghuo.cn/terms") {
                            Link(destination: url) {
                                HStack {
                                    Text("服务条款")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                            }
                        }
                        
                        HStack {
                            Text("客服邮箱")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(dataManager.systemConfig.customerServiceEmail)
                                .foregroundColor(Color(hex: "6366F1"))
                        }
                        
                        HStack {
                            Text("客服电话")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(dataManager.systemConfig.customerServicePhone)
                                .foregroundColor(Color(hex: "6366F1"))
                        }
                    }
                    
                    Spacer()
                    Text("© 2026 终活 App. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "6366F1"))
                        Text("关于")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
            }
            .alert("检查更新", isPresented: $showingUpdateAlert) {
                Button("稍后更新", role: .cancel) { }
                Button("立即更新") {
                    if let url = URL(string: dataManager.systemConfig.updateUrl.isEmpty ? "https://apps.apple.com/app/终活/id123456789" : dataManager.systemConfig.updateUrl) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: { 
                Text("发现新版本 v\(dataManager.systemConfig.latestVersion)\n\nBug 修复和性能优化") 
            }
        }
    }
    
    private func checkUpdate() {
        Task {
            await dataManager.loadSystemConfig()
            await MainActor.run {
                showingUpdateAlert = true
            }
        }
    }
}

#Preview {
    AboutSettingsView()
}
