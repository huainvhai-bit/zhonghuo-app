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
    @ObservedObject var languageManager = AppLanguageManager.shared
    @AppStorage("silentModeEnabled") private var silentModeEnabled = false
    @AppStorage("isFamilyMode") private var isFamilyMode = false
    @State private var showingLogoutConfirm = false
    @State private var showingRestoreAlert = false
    @State private var showingRestoreConfirmAlert = false
    @State private var showingUpgradeForCloudBackup = false
    @State private var showingMembershipView = false
    @State private var showingAbout = false
    @State private var showingDeleteAccount = false
    @State private var restoreMessage = ""
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            List {
                if !AppConfig.isChinaReviewMode {
                    // 👨‍👩‍👧 关闭签到设置
                    Section(header: Text(L10n.string(.closeCheckIn))) {
                    Toggle(isOn: $isFamilyMode) {
                        SettingsRow(icon: "person.2.fill", iconColor: .green, title: L10n.string(.closeCheckIn), subtitle: L10n.string(.familyGuardHint))
                    }
                    .tint(Color(hex: "6366F1"))
                    .onChange(of: isFamilyMode) { newValue in
                        if newValue {
                            CountdownTimerManager.shared.stop()
                        } else {
                            CountdownTimerManager.shared.start { }
                        }
                        NotificationCenter.default.post(name: NSNotification.Name("FamilyModeChanged"), object: nil)
                        // 重新排程本人签到提醒：开启后会清空，关闭后会按当前签到记录重建
                        LifeCheckStatusManager.shared.requestNotificationRefresh(reason: "关闭签到设置切换")
                        // 同步到后端：让首页状态与服务端保持一致
                        Task {
                            await DataManager.shared.setFamilyMode(enabled: newValue)
                        }
                    }
                }
                    
                    Section(header: Text(L10n.string(.prompt))) {
                        Text(L10n.string(.familyGuardHint))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                // 🎨 主题设置
                Section(header: Text(L10n.string(.appearance))) {
                    NavigationLink(destination: ThemeSettingsView()) {
                        SettingsRow(icon: "paintbrush.fill", iconColor: .purple, title: L10n.string(.themeSettings), subtitle: themeDisplayName(themeManager.theme))
                    }
                }

                // 🌐 语言设置
                Section(header: Text(L10n.string(.languageSection))) {
                    NavigationLink(destination: LanguageSettingsView()) {
                        SettingsRow(icon: "globe", iconColor: .green, title: L10n.string(.languageSettings), subtitle: languageManager.language.displayName)
                    }
                }
                
                // ☁️ 云端恢复
                Section(header: Text(L10n.string(.appInfo))) {
                    Button(action: {
                        if MembershipManager.shared.canRestoreFromCloud() {
                            showingRestoreConfirmAlert = true
                        } else {
                            showingUpgradeForCloudBackup = true
                        }
                    }) {
                        SettingsRow(
                            icon: "icloud.and.arrow.down.fill",
                            iconColor: .cyan,
                            title: L10n.text("云端恢复数据", en: "Restore from Cloud", ja: "クラウドから復元", ko: "클라우드 복원"),
                            subtitle: L10n.text("从服务器恢复本地数据", en: "Restore local data from the server", ja: "サーバーからローカルデータを復元します", ko: "서버에서 로컬 데이터를 복원합니다")
                        )
                    }
                }
                
                // ℹ️ 关于
                Section(header: Text(L10n.string(.about))) {
                    Button(action: {
                        showingAbout = true
                    }) {
                        SettingsRow(icon: "info.circle.fill", iconColor: .gray, title: L10n.string(.about), subtitle: "v\(appVersion)")
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
                            Text(L10n.text("退出登录", en: "Sign Out", ja: "ログアウト", ko: "로그아웃"))
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }

                // ⚠️ 注销账号（位于设置最底部，独立分区，与"退出登录"明显区分）
                Section {
                    Button(action: { showingDeleteAccount = true }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .foregroundColor(.red)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.text("注销账号", en: "Delete Account", ja: "アカウント削除", ko: "계정 삭제"))
                                    .foregroundColor(.red)
                                Text(L10n.text(
                                    "永久删除账号及全部数据，操作不可撤销",
                                    en: "Permanently delete your account and all data. This cannot be undone.",
                                    ja: "アカウントとすべてのデータを完全に削除します。元に戻せません。",
                                    ko: "계정과 모든 데이터를 영구히 삭제합니다. 되돌릴 수 없습니다."
                                ))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle(L10n.string(.settingsTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(L10n.string(.done)) {
                    dismiss()
                }
            }
        }
        .alert(L10n.text("确认退出", en: "Sign out?", ja: "ログアウトしますか？", ko: "로그아웃하시겠습니까?"), isPresented: $showingLogoutConfirm) {
            Button(L10n.string(.cancel), role: .cancel) {}
            Button(L10n.text("退出登录", en: "Sign Out", ja: "ログアウト", ko: "로그아웃"), role: .destructive) {
                logout()
            }
        } message: {
            Text(L10n.text("确定要退出登录吗？退出后需要重新登录才能使用 App。", en: "Are you sure you want to sign out? You will need to sign in again to use the app.", ja: "本当にログアウトしますか？続けて使うには再度ログインが必要です。", ko: "정말 로그아웃하시겠습니까? 앱을 계속 사용하려면 다시 로그인해야 합니다."))
        }
        .alert(L10n.text("云端恢复", en: "Cloud Restore", ja: "クラウド復元", ko: "클라우드 복원"), isPresented: $showingRestoreAlert) {
            Button(L10n.string(.confirm), role: .cancel) {}
        } message: {
            Text(restoreMessage)
        }
        .alert(L10n.text("确认恢复", en: "Restore now?", ja: "今すぐ復元しますか？", ko: "지금 복원하시겠습니까?"), isPresented: $showingRestoreConfirmAlert) {
            Button(L10n.string(.cancel), role: .cancel) {}
            Button(L10n.text("确定恢复", en: "Restore", ja: "復元", ko: "복원")) {
                restoreFromCloud()
            }
        } message: {
            Text(L10n.text("确定要从云端恢复数据吗？这将覆盖本地数据。", en: "Restore data from the cloud? This will overwrite local data.", ja: "クラウドからデータを復元しますか？ローカルデータは上書きされます。", ko: "클라우드에서 데이터를 복원하시겠습니까? 로컬 데이터가 덮어써집니다."))
        }
        .sheet(isPresented: $showingUpgradeForCloudBackup) {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                    UpgradePromptView(
                        feature: L10n.text("云端恢复数据", en: "Cloud Restore", ja: "クラウド復元", ko: "클라우드 복원"),
                        statusText: L10n.text("当前功能仅会员可用", en: "This feature is for members only", ja: "この機能は会員限定です", ko: "이 기능은 멤버십 전용입니다"),
                        currentLimit: L10n.text("免费版不可使用", en: "Unavailable on free plan", ja: "無料プランでは利用できません", ko: "무료 플랜에서는 사용할 수 없습니다"),
                        targetLimit: L10n.text("会员版可从云端恢复数据", en: "Premium can restore data from cloud", ja: "会員プランではクラウドから復元できます", ko: "멤버십에서는 클라우드에서 복원할 수 있습니다"),
                        onUpgrade: {
                            showingUpgradeForCloudBackup = false
                            showingMembershipView = true
                    },
                    onCancel: {
                        showingUpgradeForCloudBackup = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingMembershipView) {
            NavigationView {
                MembershipView()
            }
        }
        .sheet(isPresented: $showingAbout) {
            NavigationView {
                AboutSettingsView()
            }
        }
        .sheet(isPresented: $showingDeleteAccount) {
            DeleteAccountView()
        }
    }
    
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    private func themeDisplayName(_ theme: ThemeManager.Theme) -> String {
        switch theme {
        case .auto: return L10n.string(.followSystem)
        case .light: return L10n.string(.lightMode)
        case .dark: return L10n.string(.darkMode)
        }
    }
    
    private func restoreFromCloud() {
        Task {
            do {
                if let result = await dataManager.batchSyncCapsules() {
                    restoreMessage = "成功从云端恢复 \(result.total) 条留言"
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

// MARK: - 主题设置
struct ThemeSettingsView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var languageManager = AppLanguageManager.shared
    
    private func themeDisplayName(_ theme: ThemeManager.Theme) -> String {
        switch theme {
        case .auto: return L10n.string(.followSystem)
        case .light: return L10n.string(.lightMode)
        case .dark: return L10n.string(.darkMode)
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            List {
                Section(header: Text(L10n.string(.themeSettings))) {
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
                
                Section(header: Text(L10n.text("说明", en: "Info", ja: "説明", ko: "설명"))) {
                    Text(L10n.text("主题设置会影响 App 的整体外观颜色。选择您喜欢的颜色方案。", en: "Theme settings affect the app's overall appearance. Choose the color scheme you like.", ja: "テーマ設定はアプリ全体の外観に影響します。お好みの配色を選んでください。", ko: "테마 설정은 앱 전체 외관 색상에 영향을 줍니다. 원하는 색 구성표를 선택하세요."))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle(L10n.string(.themeSettings))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LanguageSettingsView: View {
    @ObservedObject var languageManager = AppLanguageManager.shared

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            List {
                Section(header: Text(L10n.string(.selectLanguage))) {
                    ForEach(AppLanguageManager.Language.allCases, id: \.self) { language in
                        Button {
                            languageManager.setLanguage(language)
                        } label: {
                            HStack {
                                Text(language.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if languageManager.language == language {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "6366F1"))
                                }
                            }
                        }
                    }
                }

                Section(header: Text(L10n.text("说明", en: "Info", ja: "説明", ko: "설명"))) {
                    Text(L10n.text("切换语言后，登录、注册、设置、关于和底部 Tab 会立即跟随显示。日期格式也会按所选语言变化。", en: "After switching languages, login, registration, settings, about, and the tab bar will update immediately. Date formats will also follow the selected language.", ja: "言語を切り替えると、ログイン、登録、設定、情報、下部タブがすぐに更新されます。日付形式も選択した言語に合わせて変わります。", ko: "언어를 전환하면 로그인, 등록, 설정, 정보, 하단 탭이 즉시 변경됩니다. 날짜 형식도 선택한 언어에 맞게 바뀝니다."))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle(L10n.string(.languageSettings))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SettingsDetailView()
    }
}
