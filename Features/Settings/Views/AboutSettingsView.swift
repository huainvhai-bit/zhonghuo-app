//
//  Settings/AboutSettingsView.swift
//  终活
//
//  关于设置视图
//  职责：检查更新、关于我们等
//

import SwiftUI

struct AboutSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingUpdateAlert = false
    @State private var checkingUpdate = false
    @ObservedObject private var dataManager = DataManager.shared
    @ObservedObject private var languageManager = AppLanguageManager.shared
    
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "F59E0B"))
                    Text(L10n.string(.appName))
                        .font(.system(size: 28, weight: .bold))
                    Text(L10n.string(.appTagline))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 16) {
                    Button(action: checkUpdate) {
                        HStack {
                            Spacer()
                            Text(L10n.string(.checkUpdate))
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
                        Text(L10n.string(.currentVersion))
                            .foregroundColor(.secondary)
                        Spacer()
                    Text("v\(appVersion)")
                            .foregroundColor(.secondary)
                    }
                    .font(.body)
                }

                VStack(spacing: 12) {
                    if let url = URL(string: "https://zhonghuo.zhonghuo.xyz") {
                            Link(destination: url) {
                                HStack {
                                Text(L10n.string(.officialSite))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                    }
                    if let url = URL(string: "https://zhonghuo.zhonghuo.xyz/privacy") {
                            Link(destination: url) {
                                HStack {
                                Text(L10n.string(.privacyPolicy))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                    }
                    if let url = URL(string: "https://zhonghuo.zhonghuo.xyz/terms") {
                            Link(destination: url) {
                                HStack {
                                Text(L10n.string(.termsOfService))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                    }

                    HStack {
                        Text(L10n.string(.customerEmail))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(dataManager.systemConfig.customerServiceEmail)
                            .foregroundColor(Color(hex: "6366F1"))
                    }

                    HStack {
                        Text(L10n.string(.customerPhone))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(dataManager.systemConfig.customerServicePhone)
                            .foregroundColor(Color(hex: "6366F1"))
                    }
                }

                Spacer(minLength: 24)
            Text(L10n.text("© 2026 \(L10n.string(.appName)). All rights reserved.", en: "© 2026 \(L10n.string(.appName)). All rights reserved.", ja: "© 2026 \(L10n.string(.appName)). All rights reserved.", ko: "© 2026 \(L10n.string(.appName)). All rights reserved."))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(L10n.string(.back))
                    }
                }
            }
            ToolbarItem(placement: .principal) {
                Text(L10n.string(.about))
                    .font(.system(size: 18, weight: .bold))
            }
        }
        .task {
            await dataManager.loadSystemConfig()
        }
        .alert(L10n.string(.checkUpdate), isPresented: $showingUpdateAlert) {
            Button(L10n.string(.later), role: .cancel) { }
            Button(L10n.string(.updateNow)) {
                if let url = URL(string: dataManager.systemConfig.updateUrl), !dataManager.systemConfig.updateUrl.isEmpty {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(dataManager.systemConfig.updateUrl.isEmpty
                 ? L10n.text("发现新版本 v\(dataManager.systemConfig.latestVersion)\n\n当前未配置更新地址，请稍后再试", en: "New version v\(dataManager.systemConfig.latestVersion) found.\n\nNo update URL is configured yet. Please try again later.", ja: "新しいバージョン v\(dataManager.systemConfig.latestVersion) が見つかりました。\n\n更新URLがまだ設定されていません。後でもう一度お試しください。", ko: "새 버전 v\(dataManager.systemConfig.latestVersion)를 찾았습니다.\n\n업데이트 URL이 아직 설정되지 않았습니다. 잠시 후 다시 시도하세요.")
                 : L10n.text("发现新版本 v\(dataManager.systemConfig.latestVersion)\n\nBug 修复和性能优化", en: "New version v\(dataManager.systemConfig.latestVersion) found.\n\nBug fixes and performance improvements.", ja: "新しいバージョン v\(dataManager.systemConfig.latestVersion) が見つかりました。\n\n不具合修正とパフォーマンス改善です。", ko: "새 버전 v\(dataManager.systemConfig.latestVersion)를 찾았습니다.\n\n버그 수정 및 성능 개선이 포함되어 있습니다."))
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
