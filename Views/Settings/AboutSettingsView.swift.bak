//
//  Settings/AboutSettingsView.swift
//  �终活
//
//  关于设置视图
//  职责：检查更新、关于我们等
//

import SwiftUI

struct AboutSettingsView: View {
    @State private var showingUpdateAlert = false
    @State private var checkingUpdate = false
    
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
                                    .foregroundColor(.blue)
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
                        
                        HStack {
                            Text("应用 ID")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("com.zhonghuo.app")
                                .foregroundColor(.secondary)
                        }
                        .font(.body)
                    }
                    
                    // 联系方式
                    VStack(spacing: 12) {
                        if let url = URL(string: "https://zhonghuo.cn") {
                            Link("官方网站", destination: url)
                        }
                        if let url = URL(string: "https://zhonghuo.cn/privacy") {
                            Link("隐私政策", destination: url)
                        }
                        if let url = URL(string: "https://zhonghuo.cn/terms") {
                            Link("服务条款", destination: url)
                        }
                        
                        HStack {
                            Text("客服邮箱")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("support@zhonghuo.cn")
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("客服电话")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("400-123-4567")
                                .foregroundColor(.blue)
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
            .alert("检查更新", isPresented: $showingUpdateAlert) {
                Button("稍后更新", role: .cancel) { }
                Button("立即更新") {
                    if let url = URL(string: "https://apps.apple.com/app/终活/id123456789") {
                        UIApplication.shared.open(url)
                    }
                }
            } message: { Text("发现新版本 v1.0.1\n\nBug 修复和性能优化") }
        }
    }
    
    private func checkUpdate() {
        Task {
            await MainActor.run {
                showingUpdateAlert = true
            }
        }
    }
}

#Preview {
    AboutSettingsView()
}
