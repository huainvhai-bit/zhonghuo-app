//
//  Settings/AboutSettingsView.swift
//  终活
//
//  关于设置视图
//  职责：检查更新、关于我们等
//

import SwiftUI
import UIKit

struct AboutSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingUpdateAlert = false
    @State private var showingStatusAlert = false
    @State private var statusAlertMessage = ""
    @State private var checkingUpdate = false
    @ObservedObject private var dataManager = DataManager.shared

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
                            if checkingUpdate {
                                ProgressView()
                            }
                            Text(L10n.string(.checkUpdate))
                                .foregroundColor(Color(hex: "6366F1"))
                            Spacer()
                        }
                    }
                    .disabled(checkingUpdate)
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
                    Link(L10n.string(.privacyPolicy), destination: OfficialDocumentLinks.privacy) {
                        HStack {
                            Text(L10n.string(.privacyPolicy))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                    Link(L10n.string(.termsOfService), destination: OfficialDocumentLinks.terms) {
                        HStack {
                            Text(L10n.string(.termsOfService))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }

                    if let mailURL = dataManager.systemConfig.customerServiceMailURL {
                        let emailText = dataManager.systemConfig.trimmedCustomerServiceEmail
                        Link(destination: mailURL) {
                            HStack {
                                Text(L10n.string(.customerEmail))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(emailText)
                                    .foregroundColor(Color(hex: "6366F1"))
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                    } else {
                        HStack {
                            Text(L10n.string(.customerEmail))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(L10n.text(
                                "暂未配置（后台填写后自动显示）",
                                en: "Not configured",
                                ja: "未設定",
                                ko: "미설정"
                            ))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer(minLength: 24)
                Text(L10n.text(
                    "© 2026 \(L10n.string(.appName)). All rights reserved.",
                    en: "© 2026 \(L10n.string(.appName)). All rights reserved.",
                    ja: "© 2026 \(L10n.string(.appName)). All rights reserved.",
                    ko: "© 2026 \(L10n.string(.appName)). All rights reserved."
                ))
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
            Button(L10n.string(.later), role: .cancel) {}
            Button(L10n.string(.updateNow)) {
                let urlStr = dataManager.systemConfig.updateUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                if let url = URL(string: urlStr), !urlStr.isEmpty {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            let latest = AppVersion.normalize(dataManager.systemConfig.latestVersion)
            let emptyUrl = dataManager.systemConfig.updateUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            Text(emptyUrl
                ? L10n.text(
                    "发现新版本 v\(latest)\n\n当前未配置更新地址，请稍后再试",
                    en: "New version v\(latest) found.\n\nNo update URL is configured yet. Please try again later.",
                    ja: "新しいバージョン v\(latest) が見つかりました。\n\n更新URLがまだ設定されていません。後でもう一度お試しください。",
                    ko: "새 버전 v\(latest)를 찾았습니다.\n\n업데이트 URL이 아직 설정되지 않았습니다. 잠시 후 다시 시도하세요."
                )
                : L10n.text(
                    "发现新版本 v\(latest)\n\nBug 修复和性能优化",
                    en: "New version v\(latest) found.\n\nBug fixes and performance improvements.",
                    ja: "新しいバージョン v\(latest) が見つかりました。\n\n不具合修正とパフォーマンス改善です。",
                    ko: "새 버전 v\(latest)를 찾았습니다.\n\n버그 수정 및 성능 개선이 포함되어 있습니다."
                ))
        }
        .alert(L10n.string(.prompt), isPresented: $showingStatusAlert) {
            Button(L10n.string(.confirm), role: .cancel) {}
        } message: {
            Text(statusAlertMessage)
        }
    }

    private func checkUpdate() {
        Task {
            checkingUpdate = true
            defer { checkingUpdate = false }
            await dataManager.loadSystemConfig()
            ForceUpdateGate.shared.refresh(from: dataManager.systemConfig)

            let latest = AppVersion.normalize(dataManager.systemConfig.latestVersion)
            let current = AppVersion.marketing

            await MainActor.run {
                if ForceUpdateGate.shared.blocksInteraction {
                    statusAlertMessage = L10n.text(
                        "当前版本已低于运营最低要求，请先从应用商店更新应用。",
                        en: "Your version is below the minimum required. Please update from the App Store first.",
                        ja: "現在のバージョンは運用の最低要件を下回っています。先に App Store からアップデートしてください。",
                        ko: "현재 버전이 운영 최소 요구보다 낮습니다. 먼저 App Store에서 업데이트해 주세요."
                    )
                    showingStatusAlert = true
                    return
                }

                guard !latest.isEmpty else {
                    statusAlertMessage = L10n.text(
                        "无法获取服务器版本信息，请稍后重试。",
                        en: "Could not read the latest version. Please try again later.",
                        ja: "サーバーのバージョン情報が取得できません。しばらくしてからお試しください。",
                        ko: "서버 버전 정보를 가져오지 못했습니다. 잠시 후 다시 시도하세요."
                    )
                    showingStatusAlert = true
                    return
                }

                if AppVersion.versionsEqual(current, latest) || AppVersion.isNewer(current, than: latest) {
                    statusAlertMessage = L10n.text(
                        "当前已是最新版本",
                        en: "You're on the latest version.",
                        ja: "お使いのバージョンは最新です。",
                        ko: "이미 최신 버전입니다."
                    )
                    showingStatusAlert = true
                    return
                }

                showingUpdateAlert = true
            }
        }
    }
}

#Preview {
    AboutSettingsView()
}
