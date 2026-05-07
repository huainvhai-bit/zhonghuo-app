//
//  ContentView.swift
//  安心助手
//
//  主界面 - 4 个 Tab
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @ObservedObject private var languageManager = AppLanguageManager.shared
    @ObservedObject private var forceUpdateGate = ForceUpdateGate.shared
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
        .alert(L10n.string(.versionUpdate), isPresented: $viewModel.showingUpdateAlert) {
            Button(L10n.string(.updateNow)) {
                viewModel.openUpdateURL()
            }
            if !viewModel.isForceUpdate {
                Button(L10n.string(.later), role: .cancel) {
                    viewModel.showingUpdateAlert = false
                }
            }
        } message: {
            Text(L10n.text(
                "\(L10n.string(.newVersionFound)) \(viewModel.updateVersion)，是否立即更新？",
                en: "New version \(viewModel.updateVersion) found. Update now?",
                ja: "新しいバージョン \(viewModel.updateVersion) が見つかりました。今すぐ更新しますか？",
                ko: "새 버전 \(viewModel.updateVersion)을 찾았습니다. 지금 업데이트하시겠습니까?"
            ))
        }
        .alert(Text(viewModel.forcedLogoutAlertKind.alertTitle), isPresented: $viewModel.showingPolicyViolationAlert) {
            Button(L10n.string(.confirm), role: .cancel) {
                viewModel.showingPolicyViolationAlert = false
            }
        } message: {
            Text(viewModel.policyViolationMessage.isEmpty
                 ? BackendSecurityPolicy.userFacingMessage(for: "ACCOUNT_BANNED:")
                 : viewModel.policyViolationMessage)
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
        .overlay {
            if forceUpdateGate.blocksInteraction && !viewModel.isMaintenanceMode {
                ForceUpdateBlockingOverlay(
                    currentVersion: AppVersion.marketing,
                    minimumVersion: forceUpdateGate.minimumSupportedVersionDisplay,
                    latestVersion: forceUpdateGate.latestVersionDisplay,
                    updateUrlString: forceUpdateGate.updateUrl
                )
            }
        }
    }
    
    private var mainTabView: some View {
        Group {
            if AppConfig.isChinaReviewMode {
                chinaReviewTabView
            } else {
                fullFeatureTabView
            }
        }
        .tint(Color(hex: "6366F1"))
    }

    private var fullFeatureTabView: some View {
        TabView(selection: $viewModel.selectedTab) {
            // 🚀 懒加载：使用 NavigationView 包装，延迟视图创建（iOS 15 兼容）
            NavigationView {
                HomeStatusView()
                    .navigationBarHidden(true)
            }
            .stackNavigationStyle()
            .tabItem {
                Label(L10n.string(.tabHome), systemImage: "house.fill")
            }
            .tag(0)
            
            NavigationView {
                CapsuleList(dataManager: dataManager)
            }
            .stackNavigationStyle()
            .tabItem {
                Label(L10n.string(.tabCapsule), systemImage: "clock.fill")
            }
            .tag(1)
            
            NavigationView {
                WillAssetsView()
                    .navigationBarHidden(true)
            }
            .stackNavigationStyle()
            .tabItem {
                Label(L10n.string(.tabWills), systemImage: "doc.text.fill")
            }
            .tag(2)
            
            NavigationView {
                FamilyGuardView()
                    .navigationBarHidden(true)
            }
            .stackNavigationStyle()
            .tabItem {
                Label(L10n.string(.tabFamily), systemImage: "person.2.fill")
            }
            .tag(3)
            
            SettingsView()
            .tabItem {
                Label(L10n.string(.tabMe), systemImage: "person.fill")
            }
            .tag(4)
        }
    }

    private var chinaReviewTabView: some View {
        TabView(selection: $viewModel.selectedTab) {
            NavigationView {
                HomeStatusView()
                    .navigationBarHidden(true)
            }
            .stackNavigationStyle()
            .tabItem {
                Label(L10n.string(.tabHome), systemImage: "house.fill")
            }
            .tag(0)

            NavigationView {
                CapsuleList(dataManager: dataManager)
            }
            .stackNavigationStyle()
            .tabItem {
                Label(L10n.string(.tabCapsule), systemImage: "clock.fill")
            }
            .tag(1)

            SettingsView()
                .tabItem {
                    Label(L10n.string(.tabMe), systemImage: "person.fill")
                }
                .tag(2)
        }
    }
}

// 强制更新：不可关闭、不可穿透，直到升级到满足最低版本要求
private struct ForceUpdateBlockingOverlay: View {
    let currentVersion: String
    let minimumVersion: String
    let latestVersion: String
    let updateUrlString: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(hex: "6366F1"))

                Text(L10n.text(
                    "需要更新应用",
                    en: "Update required",
                    ja: "アップデートが必要です",
                    ko: "업데이트 필요"
                ))
                .font(.system(size: 20, weight: .bold))
                .multilineTextAlignment(.center)

                Text(L10n.text(
                    "当前版本（v\(currentVersion)）已低于运营要求的最低版本，请更新后再使用。",
                    en: "Your version (v\(currentVersion)) is below the minimum required. Please update to continue.",
                    ja: "現在のバージョン（v\(currentVersion)）は運用の最低要件を下回っています。アップデート後にご利用ください。",
                    ko: "현재 버전(v\(currentVersion))은 운영 최소 요구 버전보다 낮습니다. 업데이트 후 이용해 주세요."
                ))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

                if !minimumVersion.isEmpty {
                    Text(L10n.text(
                        "最低要求版本：v\(minimumVersion)",
                        en: "Minimum required: v\(minimumVersion)",
                        ja: "最低バージョン：v\(minimumVersion)",
                        ko: "최소 요구 버전: v\(minimumVersion)"
                    ))
                    .font(.system(size: 13, weight: .medium))
                }

                if !latestVersion.isEmpty {
                    Text(L10n.text(
                        "最新版本：v\(latestVersion)",
                        en: "Latest: v\(latestVersion)",
                        ja: "最新バージョン：v\(latestVersion)",
                        ko: "최신 버전: v\(latestVersion)"
                    ))
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Button(action: openUpdateUrl) {
                    Text(L10n.string(.updateNow))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "6366F1"))
                        .cornerRadius(12)
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal, 24)
        }
        .allowsHitTesting(true)
    }

    private func openUpdateUrl() {
        let s = updateUrlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty, let url = URL(string: s) else { return }
        UIApplication.shared.open(url)
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
            Text(L10n.string(.systemMaintenance))
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
            Text(L10n.string(.pleaseRetry))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct LoadingView: View {
    @State private var opacity = 0.5
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(L10n.string(.loading))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
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
