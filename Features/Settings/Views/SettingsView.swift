//
//  SettingsView.swift
//  终活
//
//  设置页面 - 个人信息、家人守护、通知
//

import SwiftUI

// MARK: - Stat Item View
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

struct SettingsView: View {
    private let timeFormatter = ChineseDateFormatter.dateTimeFormatter
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var userManager = UserManager.shared
    @ObservedObject var deviceMonitor = DeviceMonitor.shared  // 🔋 设备监控
    @ObservedObject var membershipManager = MembershipManager.shared  // 👑 会员管理
    @ObservedObject private var languageManager = AppLanguageManager.shared
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingEditProfile = false
    @State private var showingMembershipView = false  // 👑 会员页面
    @AppStorage("customServerURL") private var customServerURL = ""  // 空表示自动获取
    @State private var tempServerURL = ""
    @AppStorage("silentModeEnabled") private var silentModeEnabled = false  // 🤫 静默模式
    @ObservedObject var themeManager = ThemeManager.shared  // 🎨 主题管理
    
    // ✅ 修复 #7: 版本号
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                settingsList
            }
            .navigationTitle(L10n.string(.tabMe))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { settingsToolbar }
            .onAppear {
                viewModel.onAppear()
            }
            .onDisappear {
                viewModel.onDisappear()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileModal(dataManager: dataManager, userManager: userManager)
            }
            .sheet(isPresented: $showingMembershipView) {
                MembershipView()
            }
            .alert(L10n.string(.locationPermission), isPresented: $viewModel.showingLocationAlert) {
                Button(L10n.string(.later), role: .cancel) {}
                Button(L10n.string(.goSettings)) {
                    viewModel.openAppSettings()
                }
            } message: {
                Text(L10n.string(.locationAlwaysHint))
            }
            .alert(L10n.string(.prompt), isPresented: $viewModel.showingError) {
                Button(L10n.string(.confirm), role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .stackNavigationStyle()
    }

    @ViewBuilder
    private var settingsList: some View {
        List {
            settingsProfileSection
            settingsStatsSection
            settingsIntervalSection
            settingsNotificationSection
            settingsDeviceSection
        }
    }

    @ToolbarContentBuilder
    private var settingsToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(L10n.string(.tabMe))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink(destination: SettingsDetailView()) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.indigo)
                    .frame(width: 34, height: 34)
                    .background(Color.indigo.opacity(0.12))
                    .clipShape(Circle())
            }
        }
    }

    private var settingsProfileSection: some View {
        Section {
            userInfoCard
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }

    private var settingsStatsSection: some View {
        Section {
            statsCard
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }

    private var settingsIntervalSection: some View {
        Section(header: Text(L10n.string(.settingsTitle))) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Color(hex: "6366F1"))
                    .frame(width: 30)

                Text(L10n.string(.signInInterval))
                    .font(.system(size: 16))

                Spacer()

                Menu {
                    ForEach(CheckInInterval.allCases, id: \.self) { interval in
                        Button(interval.rawValue) {
                            Task { await viewModel.updateCheckInInterval(interval) }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.selectedCheckInInterval.rawValue)
                            .foregroundColor(.indigo)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var settingsNotificationSection: some View {
        Section(header: Text(L10n.string(.notificationSettings))) {
            Toggle(isOn: $silentModeEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: silentModeEnabled ? "bell.slash.fill" : "bell.fill")
                            .foregroundColor(silentModeEnabled ? .orange : .green)
                            .frame(width: 24)

                        Text(L10n.string(.silentMode))
                            .font(.system(size: 16))
                    }

                    Text(silentModeEnabled ? L10n.string(.notificationsMuted) : L10n.string(.notificationsMuteHelp))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .tint(.orange)
            .onChange(of: silentModeEnabled) { isEnabled in
                if isEnabled {
                    NotificationManager.shared.cancelAllCheckInReminders()
                    UserDefaults.standard.removeObject(forKey: "checkinNotificationScheduleSignature")
                    print("🤫 静默模式已开启，已取消所有签到提醒")
                }
            }
        }
    }

    private var settingsDeviceSection: some View {
        Section(header: Text(L10n.string(.deviceInfo))) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(Color(hex: "34C759"))
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.string(.todaySteps))
                            .font(.system(size: 14))
                        Text("\(deviceMonitor.stepCount, specifier: "%d") \(L10n.string(.steps))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(deviceMonitor.isMonitoring ? 360 : 0))
                }

                Divider()

                HStack {
                    Image(systemName: deviceMonitor.batteryIcon)
                        .foregroundColor(deviceMonitor.batteryColor)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.string(.deviceBattery))
                            .font(.system(size: 14))
                        Text(deviceMonitor.batteryLevelText)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Text(deviceMonitor.batteryStateText)
                        .font(.system(size: 13))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(deviceMonitor.batteryStateColor)
                        .cornerRadius(8)
                }

                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))

                    Text("\(L10n.string(.updateTime))：\(deviceMonitor.lastUpdateTime, formatter: timeFormatter)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 用户信息卡片
    @ViewBuilder
    private var statsCard: some View {
        // ✅ 从本地 DataManager 获取数据（不依赖云端）
        let capsulesCount = DataManager.shared.capsules.count
        let willsCount = DataManager.shared.willModules.count
        let familyCount = DataManager.shared.familyMembers.count  // ✅ 家人
        let checkinCount = userManager.currentUser?.checkinCount ?? 0
        
        VStack(spacing: 12) {
                    Text(L10n.string(.tabMe))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                StatItemView(
                    icon: "capsule.fill",
                    color: Color(hex: "AF52DE"),
                    count: capsulesCount,
                    label: L10n.string(.tabCapsule)
                )
                
                StatItemView(
                    icon: "doc.text.fill",
                    color: Color(hex: "FF2D55"),
                    count: willsCount,
                    label: L10n.string(.tabWills)
                )
                
                StatItemView(
                    icon: "person.2.fill",
                    color: Color(hex: "007AFF"),
                    count: familyCount,
                    label: L10n.string(.tabFamily)
                )
                
                StatItemView(
                    icon: "calendar.badge.checkmark",
                    color: Color(hex: "34C759"),
                    count: checkinCount,
                    label: L10n.string(.tabHome)
                )
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color(hex: "F8F9FF")]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .shadow(color: Color(hex: "6366F1").opacity(0.15), radius: 12, x: 0, y: 6)
    }
    
    private var userInfoCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // 头像 - 唯一可点击编辑的地方
                Button(action: { showingEditProfile = true }) {
                    ZStack {
                        Circle()
                            .fill(userAvatarGradient())
                            .frame(width: 70, height: 70)

                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)

                        // 编辑指示器
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "pencil")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: "6366F1"))
                            )
                            .offset(x: 25, y: 25)
                    }
                }
                .buttonStyle(PlainButtonStyle())  // 移除按钮默认样式
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(displayUserName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        if membershipManager.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "FFD700"))
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Label(displayUserPhone, systemImage: "phone.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("ID: \(displayUserId)")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
            }
            
            if !membershipManager.isPremium {
                // 开通会员按钮 - 放大并独占一行
                Button(action: { showingMembershipView = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 22, weight: .bold))
                        Text(L10n.string(.openMembership))
                            .font(.system(size: 18, weight: .bold))
                        Spacer()
                        Text(L10n.string(.limitedOffer))
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(25)
                }
                .buttonStyle(PlainButtonStyle())  // 移除按钮默认样式
            } else {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                    Text(L10n.string(.membershipValid))
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.8))
                .cornerRadius(20)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color(hex: "6366F1").opacity(0.4), radius: 16, x: 0, y: 8)
    }
    
    /// 返回用户头像对应的渐变色
    private func userAvatarGradient() -> LinearGradient {
        let avatar = userManager.currentUser?.avatar ?? "male_1"
        let colors: [Color]
        
        if avatar.hasPrefix("male") {
            switch avatar {
            case "male_1": colors = [Color(hex: "3B82F6"), Color(hex: "1E40AF")]
            case "male_2": colors = [Color(hex: "6366F1"), Color(hex: "4338CA")]
            case "male_3": colors = [Color(hex: "10B981"), Color(hex: "059669")]
            case "male_4": colors = [Color(hex: "F59E0B"), Color(hex: "D97706")]
            case "male_5": colors = [Color(hex: "EF4444"), Color(hex: "DC2626")]
            default: colors = [Color(hex: "6366F1"), Color(hex: "8B5CF6")]
            }
        } else {
            switch avatar {
            case "female_1": colors = [Color(hex: "EC4899"), Color(hex: "DB2777")]
            case "female_2": colors = [Color(hex: "F472B6"), Color(hex: "C026D3")]
            case "female_3": colors = [Color(hex: "FB7185"), Color(hex: "E11D48")]
            case "female_4": colors = [Color(hex: "FBBF24"), Color(hex: "F59E0B")]
            case "female_5": colors = [Color(hex: "34D399"), Color(hex: "10B981")]
            default: colors = [Color(hex: "EC4899"), Color(hex: "DB2777")]
            }
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var displayUserName: String {
        if let name = userManager.currentUser?.name, !name.isEmpty {
            return name
        }
        if !dataManager.settings.name.isEmpty {
            return dataManager.settings.name
        }
        return L10n.string(.user)
    }

    private var displayUserPhone: String {
        if let phone = userManager.currentUser?.phone, !phone.isEmpty {
            return phone
        }
        if let phone = KeychainManager.shared.getUserPhone(), !phone.isEmpty {
            return phone
        }
        return L10n.string(.unboundPhone)
    }

    private var displayUserId: String {
        if let userId = userManager.currentUser?.id, !userId.isEmpty {
            return String(userId.prefix(8))
        }
        if let userId = KeychainManager.shared.getUserId(), !userId.isEmpty {
            return String(userId.prefix(8))
        }
        return L10n.string(.unknown)
    }
    
    private var locationStatusText: String {
        switch userManager.locationAuthStatus {
        case .authorizedAlways:
            return L10n.string(.backgroundLocationOn)
        case .authorizedWhenInUse:
            return L10n.string(.whenInUseOnly)
        case .denied:
            return L10n.string(.denied)
        default:
            return L10n.string(.notSet)
        }
    }
    
    struct ServerResponse: Codable {
        let success: Bool
        let message: String?
        let error: String?
    }
}

// MARK: - 编辑个人信息弹窗
struct EditProfileModal: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var userManager: UserManager
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var ethnicity = ""
    @State private var birthday = Date()
    @State private var idCard = ""
    @State private var address = ""
    @State private var gender: User.Gender = .male
    @State private var selectedAvatar = "male_1"
    @State private var showingProfileError = false
    @State private var profileErrorMessage = ""
    @State private var isPhoneLocked = false
    
    // 默认头像列表
    private let maleAvatars = ["male_1", "male_2", "male_3", "male_4", "male_5"]
    private let femaleAvatars = ["female_1", "female_2", "female_3", "female_4", "female_5"]
    
    private var currentAvatars: [String] {
        gender == .male ? maleAvatars : femaleAvatars
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 头像选择区域
                Section(header: Text(L10n.string(.avatar))) {
                    VStack(spacing: 16) {
                        // 当前选中头像显示
                        ZStack {
                            Circle()
                                .fill(avatarGradient(for: selectedAvatar))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: avatarSymbol(for: selectedAvatar))
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 8)
                        
                        // 性别选择
                        Picker(L10n.string(.gender), selection: $gender) {
                            ForEach(User.Gender.allCases, id: \.self) { g in
                                Text(g == .male ? L10n.string(.maleGender) : L10n.string(.femaleGender)).tag(g)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 40)
                        .onChange(of: gender) { newGender in
                            // 切换性别时自动选择该性别的第一个头像
                            selectedAvatar = newGender == .male ? "male_1" : "female_1"
                        }
                        
                        // 头像网格选择
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(currentAvatars, id: \.self) { avatar in
                                Button(action: {
                                    selectedAvatar = avatar
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(avatarGradient(for: avatar))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: avatarSymbol(for: avatar))
                                            .font(.system(size: 22))
                                            .foregroundColor(.white)
                                    }
                                    .overlay(
                                        Circle()
                                            .stroke(selectedAvatar == avatar ? Color(hex: "6366F1") : Color.clear, lineWidth: 3)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                }
                
                Section(header: Text(L10n.string(.name))) {
                    TextField(L10n.string(.name), text: $name)
                }
                
                Section(header: Text(L10n.string(.phone))) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            TextField(L10n.string(.phone), text: $phone)
                                .disabled(isPhoneLocked)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }

                        Text(isPhoneLocked ? L10n.string(.phoneBoundLocked) : L10n.string(.phoneBindingHint))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text(L10n.string(.identityInfo))) {
                    // 性别选择
                    Picker(L10n.string(.gender), selection: $gender) {
                        ForEach(User.Gender.allCases, id: \.self) { g in
                            Text(g == .male ? L10n.string(.maleGender) : L10n.string(.femaleGender)).tag(g)
                        }
                    }
                    
                    TextField(L10n.string(.ethnicity), text: $ethnicity)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        DatePicker(L10n.string(.birthdayLabel), selection: $birthday, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "zh_CN"))

                        Text("\(L10n.string(.birthdayPreview))：\(AppLocalization.dateString(for: birthday))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    
                    TextField(L10n.string(.idCard), text: $idCard)
                        .textInputAutocapitalization(.characters)
                    
                    TextField(L10n.string(.address), text: $address)
                        .lineLimit(2)
                }
                
                Section {
                    Button(action: {
                        print("🔵 开始保存用户信息...")
                        print("   userManager.isLoggedIn (保存前): \(userManager.isLoggedIn)")
                        print("   currentUser: \(userManager.currentUser?.name ?? "nil")")
                        
                        if !name.isEmpty {
                            if var user = userManager.currentUser {
                                let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmedPhone.isEmpty && !isValidPhone(trimmedPhone) {
                                    print("❌ 手机号格式不正确：\(trimmedPhone)")
                                    profileErrorMessage = L10n.string(.phoneFormatError)
                                    showingProfileError = true
                                    return
                                }
                                let currentBoundPhone = !user.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? user.phone.trimmingCharacters(in: .whitespacesAndNewlines)
                                    : (KeychainManager.shared.getUserPhone() ?? "")
                                if !currentBoundPhone.isEmpty {
                                    if trimmedPhone != currentBoundPhone {
                                        print("❌ 手机号已绑定，不可再次修改")
                                        profileErrorMessage = L10n.string(.phoneBoundLocked)
                                        showingProfileError = true
                                        return
                                    }
                                } else if trimmedPhone.isEmpty {
                                    print("❌ 首次绑定手机号不能为空")
                                    profileErrorMessage = L10n.string(.firstBindPhoneRequired)
                                    showingProfileError = true
                                    return
                                }
                                user.name = name
                                user.phone = currentBoundPhone.isEmpty ? trimmedPhone : currentBoundPhone
                                user.ethnicity = ethnicity
                                user.birthday = birthday
                                user.idCard = idCard
                                user.address = address
                                user.gender = gender
                                user.avatar = selectedAvatar
                                
                                // 先更新 currentUser，再保存
                                userManager.currentUser = user
                                let saveSuccess = userManager.saveUser(user)
                                
                                print("   saveUser 返回：\(saveSuccess)")
                                print("   userManager.isLoggedIn (保存后): \(userManager.isLoggedIn)")
                                
                                if saveSuccess {
                                    // 确保登录状态保持
                                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                                    UserDefaults.standard.set(user.id, forKey: "userId")
                                    print("✅ 用户信息已保存，登录状态保持")
                                    dismiss()
                                } else {
                                    print("❌ 保存用户失败")
                                }
                            }
                        }
                    }) {
                    Text(L10n.string(.saveProfile))
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle(L10n.string(.editProfile))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.string(.cancel)) { dismiss() }
                }
            }
            .alert(L10n.string(.prompt), isPresented: $showingProfileError) {
                Button(L10n.string(.confirm), role: .cancel) { }
            } message: {
                Text(profileErrorMessage)
            }
            .onAppear {
                if userManager.currentUser == nil {
                    userManager.loadUser()
                }

                if let user = userManager.currentUser {
                    let savedPhone = KeychainManager.shared.getUserPhone() ?? ""
                    let existingPhone = !user.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? user.phone.trimmingCharacters(in: .whitespacesAndNewlines)
                        : savedPhone.trimmingCharacters(in: .whitespacesAndNewlines)
                    name = user.name
                    phone = existingPhone
                    ethnicity = user.ethnicity ?? ""
                    birthday = user.birthday ?? Date()
                    idCard = user.idCard ?? ""
                    address = user.address ?? ""
                    gender = user.gender ?? .male
                    selectedAvatar = user.avatar ?? "male_1"
                    isPhoneLocked = !existingPhone.isEmpty
                    print("🔵 编辑资料：name=\(name), phone=\(phone), gender=\(gender.rawValue), avatar=\(selectedAvatar)")
                }
            }
        }
        .stackNavigationStyle()
    }

    private func isValidPhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: phone)
    }
    
    // 根据头像名称返回渐变色
    private func avatarGradient(for avatar: String) -> LinearGradient {
        let colors: [Color]
        if avatar.hasPrefix("male") {
            switch avatar {
            case "male_1": colors = [Color(hex: "3B82F6"), Color(hex: "1E40AF")]  // 蓝色
            case "male_2": colors = [Color(hex: "6366F1"), Color(hex: "4338CA")]  // 紫色
            case "male_3": colors = [Color(hex: "10B981"), Color(hex: "059669")]  // 绿色
            case "male_4": colors = [Color(hex: "F59E0B"), Color(hex: "D97706")]  // 橙色
            case "male_5": colors = [Color(hex: "EF4444"), Color(hex: "DC2626")]  // 红色
            default: colors = [Color(hex: "6366F1"), Color(hex: "8B5CF6")]
            }
        } else {
            switch avatar {
            case "female_1": colors = [Color(hex: "EC4899"), Color(hex: "DB2777")]  // 粉色
            case "female_2": colors = [Color(hex: "F472B6"), Color(hex: "C026D3")]  // 紫红
            case "female_3": colors = [Color(hex: "FB7185"), Color(hex: "E11D48")]  // 玫红
            case "female_4": colors = [Color(hex: "FBBF24"), Color(hex: "F59E0B")]  // 金色
            case "female_5": colors = [Color(hex: "34D399"), Color(hex: "10B981")]  // 翠绿
            default: colors = [Color(hex: "EC4899"), Color(hex: "DB2777")]
            }
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    // 根据头像名称返回 SF Symbol（每个头像使用不同的图标样式）
    private func avatarSymbol(for avatar: String) -> String {
        switch avatar {
        case "male_1": return "person.fill"                    // 标准男性
        case "male_2": return "person.circle.fill"              // 圆形男性
        case "male_3": return "figure.stand"                   // 站立的男性
        case "male_4": return "person.fill.viewfinder"         // 搜索中的男性
        case "male_5": return "person.badge.plus"               // 带加号的男性
        case "female_1": return "person.fill"                   // 标准女性
        case "female_2": return "person.circle.fill"             // 圆形女性
        case "female_3": return "figure.stand"                  // 站立的女性
        case "female_4": return "person.fill.viewfinder"        // 搜索中的女性
        case "female_5": return "person.badge.plus"             // 带加号的女性
        default: return "person.fill"
        }
    }
}

// MARK: - 服务器配置弹窗
struct ServerConfigModal: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("customServerURL") private var customServerURL = ""
    @State private var tempURL = ""
    @State private var isTesting = false
    @State private var testResult = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(L10n.string(.serverAddress))) {
                    TextField(L10n.string(.automaticFetchRecommended), text: $tempURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    Text(L10n.string(.leaveBlankAuto))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(L10n.string(.restartRequired))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text(L10n.string(.testConnection))) {
                    HStack {
                        Text(L10n.string(.status))
                        Spacer()
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(L10n.string(.testing))
                                .foregroundColor(.secondary)
                        } else if !testResult.isEmpty {
                            Text(testResult)
                                .foregroundColor(testResult.contains(L10n.string(.testSuccess)) ? .green : .red)
                        } else {
                            Text(L10n.string(.notTested))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: testConnection) {
                        HStack {
                            Spacer()
                            Text(L10n.string(.testConnection))
                            Spacer()
                        }
                    }
                    .disabled(isTesting || tempURL.isEmpty)
                }
                
                Section {
                    Button(action: {
                        customServerURL = tempURL
                        DataManager.baseURL = tempURL
                        DataManager.apiURL = "\(tempURL)/api"
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text(L10n.string(.saveAndRestart))
                            Spacer()
                        }
                    }
                    .disabled(tempURL.isEmpty)
                }
            }
            .navigationTitle(L10n.string(.serverConfig))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.string(.cancel)) { dismiss() }
                }
            }
            .onAppear {
                tempURL = customServerURL
            }
        }
        .stackNavigationStyle()
    }
    
    private func testConnection() {
        isTesting = true
        testResult = ""
        
        Task {
            do {
                let query = """
                query {
                    getConfig {
                        checkinIntervalHours
                        notificationReminderThresholdHours
                        notificationPushIntervalHours
                    }
                }
                """
                
                let variables: [String: Any] = [:]
                let response = try await DataManager.shared.sendGraphQLQuery(query: query, variables: variables, baseURL: tempURL)
                
                await MainActor.run {
                    isTesting = false
                    if let data = response["data"] as? [String: Any],
                       data["getConfig"] != nil {
                        testResult = L10n.string(.testSuccess) + " (GraphQL)"
                    } else {
                        testResult = L10n.string(.testFailed)
                    }
                }
            } catch {
                await MainActor.run {
                    isTesting = false
                    testResult = "\(L10n.string(.testFailed))：\(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    
    /// 格式化更新时间
    private func formatUpdateTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 视图生命周期

extension SettingsView {
    // ✅ 修复 #7: 关于页面
    private var aboutView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "F59E0B"))
                Text(L10n.string(.appName))
                    .font(.system(size: 28, weight: .bold))
                Text(L10n.string(.appTagline))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            VStack(spacing: 16) {
                HStack {
                    Text(L10n.string(.currentVersionTitle))
                    Spacer()
                    Text(L10n.string(.currentVersionValue).replacingOccurrences(of: "%@", with: appVersion))
                        .foregroundColor(.secondary)
                }
                Button(action: {
                    Task { await viewModel.checkUpdate() }
                }) {
                    HStack {
                        Text(L10n.string(.checkUpdate)).accessibilityLabel(L10n.string(.checkUpdate))
                        Spacer()
                        Image(systemName: "arrow.clockwise").foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            List {
                Section(header: Text(L10n.string(.appInformation))) {
                    if let url = URL(string: "https://zhonghuo.zhonghuo.xyz") {
                        Link(L10n.string(.officialSite), destination: url)
                    }
                    if let url = URL(string: "https://zhonghuo.zhonghuo.xyz/privacy") {
                        Link(L10n.string(.privacyPolicy), destination: url)
                    }
                    if let url = URL(string: "https://zhonghuo.zhonghuo.xyz/terms") {
                        Link(L10n.string(.termsOfService), destination: url)
                    }
                    
                    // ⚖️ 法律声明
                    NavigationLink(destination: LegalDisclosureView()) {
                        HStack {
                            Image(systemName: "scale")
                            Text(L10n.string(.legalDisclosure))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section(header: Text(L10n.string(.contactUs))) {
                    HStack {
                        Text(L10n.string(.contactEmail))
                        Spacer()
                        Text("support@zhonghuo.cn").foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
            Text(L10n.string(.appCopyright))
                .font(.caption).foregroundColor(.secondary).padding(.bottom, 20)
        }
        .navigationTitle(L10n.string(.about))
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.string(.checkUpdate), isPresented: $viewModel.showingUpdateAlert) {
            Button(L10n.string(.later), role: .cancel) { }
            Button(L10n.string(.updateNow)) {
                viewModel.openUpdateURL()
            }
        } message: {
            Text(L10n.text(
                "\(L10n.string(.newVersionFound)) v\(viewModel.latestVersion.isEmpty ? dataManager.systemConfig.latestVersion : viewModel.latestVersion)\n\nBug 修复和性能优化",
                en: "New version v\(viewModel.latestVersion.isEmpty ? dataManager.systemConfig.latestVersion : viewModel.latestVersion) found.\n\nBug fixes and performance improvements.",
                ja: "新しいバージョン v\(viewModel.latestVersion.isEmpty ? dataManager.systemConfig.latestVersion : viewModel.latestVersion) が見つかりました。\n\n不具合修正と性能改善。",
                ko: "새 버전 v\(viewModel.latestVersion.isEmpty ? dataManager.systemConfig.latestVersion : viewModel.latestVersion)를 찾았습니다.\n\n버그 수정 및 성능 개선."
            ))
        }
    }
}

#Preview {
    SettingsView()
}
