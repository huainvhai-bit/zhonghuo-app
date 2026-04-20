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
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var userManager = UserManager.shared
    @ObservedObject var deviceMonitor = DeviceMonitor.shared  // 🔋 设备监控
    @ObservedObject var membershipManager = MembershipManager.shared  // 👑 会员管理
    @State private var showingEditProfile = false
    @State private var showingMembershipView = false  // 👑 会员页面
    @State private var showingLocationAlert = false
    @AppStorage("customServerURL") private var customServerURL = ""  // 空表示自动获取
    @State private var tempServerURL = ""
    @AppStorage("silentModeEnabled") private var silentModeEnabled = false  // 🤫 静默模式
    @ObservedObject var themeManager = ThemeManager.shared  // 🎨 主题管理
    @State private var showingLogoutConfirm = false  // 退出登录确认
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showingUpdateAlert = false  // ✅ 修复 #7: 检查更新弹窗
    
    // ✅ 修复 #7: 版本号
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            NavigationView {
                List {
                // 用户信息卡片
                Section {
                    userInfoCard
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                // 统计信息
                Section {
                    statsCard
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                // 签到间隔
                Section(header: Text("设置")) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(Color(hex: "6366F1"))
                            .frame(width: 30)
                        
                        Text("签到间隔")
                            .font(.system(size: 16))
                        
                        Spacer()
                        
                        Menu {
                            ForEach(CheckInInterval.allCases, id: \.self) { interval in
                                Button(interval.rawValue) {
                                    print("🔵 点击签到间隔：\(interval.rawValue)")
                                    print("   - 当前 userId: \(KeychainManager.shared.getUserId() ?? "nil")")
                                    print("   - 当前 currentUser: \(userManager.currentUser?.name ?? "nil")")
                                    print("   - 当前 checkInInterval: \(userManager.checkInInterval.rawValue)")
                                    print("   - 当前 user.checkInInterval: \(userManager.currentUser?.checkInInterval.rawValue ?? "nil")")
                                    Task { @MainActor in
                                        try? await Task.checkCancellation()
                                        await updateCheckInInterval(interval)
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(userManager.checkInInterval.rawValue)
                                    .foregroundColor(.indigo)
                                
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // 🔔 通知设置
                Section(header: Text("通知设置")) {
                    // 🤫 静默模式
                    Toggle(isOn: $silentModeEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: silentModeEnabled ? "bell.slash.fill" : "bell.fill")
                                    .foregroundColor(silentModeEnabled ? .orange : .green)
                                    .frame(width: 24)
                                
                                Text("静默模式")
                                    .font(.system(size: 16))
                            }
                            
                            Text(silentModeEnabled ? "已关闭所有签到通知" : "开启后不再推送任何签到通知")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.orange)
                    .onChange(of: silentModeEnabled) { isEnabled in
                        // 当静默模式切换时，立即取消所有已安排的签到提醒
                        if isEnabled {
                            NotificationManager.shared.cancelAllCheckInReminders()
                            print("🤫 静默模式已开启，已取消所有签到提醒")
                        }
                    }
                }
                
                // 🔋 设备信息
                Section(header: Text("设备信息")) {
                    VStack(spacing: 12) {
                        // 今日步数
                        HStack {
                            Image(systemName: "figure.walk")
                                .foregroundColor(Color(hex: "34C759"))
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("今日步数")
                                    .font(.system(size: 14))
                                Text("\(deviceMonitor.stepCount, specifier: "%d") 步")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            // 刷新动画
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(deviceMonitor.isMonitoring ? 360 : 0))
                        }
                        
                        Divider()
                        
                        // 电量信息
                        HStack {
                            Image(systemName: deviceMonitor.batteryIcon)
                                .foregroundColor(deviceMonitor.batteryColor)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("设备电量")
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
                        
                        // 最后更新
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            
                            Text("最后更新：\(deviceMonitor.lastUpdateTime, formatter: timeFormatter)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("我的")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsDetailView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                // 设置紫色导航栏背景（与首页一致）
                setupNavigationBar()
                
                // 启动设备监控
                startDeviceMonitoring()
                
                // 检查定位权限
                checkLocationPermission()
                
                // 上传设备信息到服务器
                Task { @MainActor in
                    try? await Task.checkCancellation()
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 秒后上传
                    await deviceMonitor.uploadDeviceInfo()
                }
            }
            .onDisappear {
                // 停止监控
                stopDeviceMonitoring()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileModal(dataManager: dataManager, userManager: userManager)
            }
            .sheet(isPresented: $showingMembershipView) {
                MembershipView()
            }
            .alert("定位权限", isPresented: $showingLocationAlert) {
                Button("稍后", role: .cancel) {}
                Button("去设置") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("为了您的安全，建议开启\"始终允许\"定位权限，这样即使不打开 App 也能获取位置信息。")
            }
            .confirmationDialog("确认退出", isPresented: $showingLogoutConfirm) {
                Button(LocalizedStringKey("退出登录"), role: .destructive) {
                    logout()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("确定要退出登录吗？退出后需要重新登录才能使用 App。")
            }
            }
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
            Text("我的数据")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                StatItemView(
                    icon: "capsule.fill",
                    color: Color(hex: "AF52DE"),
                    count: capsulesCount,
                    label: "胶囊"
                )
                
                StatItemView(
                    icon: "doc.text.fill",
                    color: Color(hex: "FF2D55"),
                    count: willsCount,
                    label: "嘱托"
                )
                
                StatItemView(
                    icon: "person.2.fill",
                    color: Color(hex: "007AFF"),
                    count: familyCount,
                    label: "家人"
                )
                
                StatItemView(
                    icon: "calendar.badge.checkmark",
                    color: Color(hex: "34C759"),
                    count: checkinCount,
                    label: "签到"
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
                        Text(userManager.currentUser?.name ?? "用户")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        if membershipManager.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "FFD700"))
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Label(userManager.currentUser?.phone ?? "未设置", systemImage: "phone.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("ID: \(userManager.currentUser?.id.prefix(8) ?? "未知")")
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
                        Text("开通会员")
                            .font(.system(size: 18, weight: .bold))
                        Spacer()
                        Text("限时特惠 >")
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
                    Text("会员有效")
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
    
    private var locationStatusText: String {
        switch userManager.locationAuthStatus {
        case .authorizedAlways:
            return "后台定位已开启"
        case .authorizedWhenInUse:
            return "仅使用期间允许"
        case .denied:
            return "已拒绝"
        default:
            return "未设置"
        }
    }
    
    // MARK: - 退出登录
    private func logout() {
        print("🔴 退出登录")
        
        // 清除所有用户数据
        userManager.logout()
        
        // 清除 UserDefaults
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.synchronize()
        
        print("✅ 退出登录完成")
        print("   userManager.isLoggedIn: \(userManager.isLoggedIn)")
        print("   UserDefaults.isLoggedIn: \(UserDefaults.standard.bool(forKey: "isLoggedIn"))")
    }
    
    // MARK: - 更新签到间隔
    private func updateCheckInInterval(_ interval: CheckInInterval) async {
        print("🔵 开始更新签到间隔：\(interval.rawValue)")
        print("   - Keychain userId: \(KeychainManager.shared.getUserId() ?? "nil")")
        print("   - userManager.currentUser: \(userManager.currentUser?.name ?? "nil")")
        print("   - userManager.isLoggedIn: \(userManager.isLoggedIn)")
        
        // 检查用户是否登录
        guard let userId = KeychainManager.shared.getUserId(),
              let _ = userManager.currentUser else {
            print("❌ 用户未登录")
            await MainActor.run {
                errorMessage = "请先登录"
                showingError = true
            }
            return
        }
        
        do {
            // 1. 本地更新
            userManager.checkInInterval = interval
            userManager.currentUser?.checkInInterval = interval
            DataManager.shared.settings.checkInInterval = interval
            
            // 2. 保存到本地文件
            let saveResult = userManager.updateCheckInInterval(interval)
            if case .failure(let error) = saveResult {
                print("❌ 本地保存失败：\(error)")
            }
            
            // 3. 同步到服务器
            try await syncCheckInIntervalToServer(userId: userId, interval: interval)
            
            print("✅ 签到间隔更新成功：\(interval.rawValue)")
            
        } catch {
            print("❌ 签到间隔更新失败：\(error)")
            await MainActor.run {
                errorMessage = "更新失败：\(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    private func syncCheckInIntervalToServer(userId: String, interval: CheckInInterval) async throws {
        // ✅ 使用 GraphQL API 更新签到间隔
        let mutation = """
        mutation($checkInIntervalHours: Int!) {
            updateCheckInInterval(checkInIntervalHours: $checkInIntervalHours) {
                success
                message
            }
        }
        """
        
        let variables: [String: Any] = [
            "checkInIntervalHours": interval.hours
        ]
        
        let response = try await DataManager.shared.sendGraphQLQuery(query: mutation, variables: variables, baseURL: DataManager.apiURL)
        
        if let data = response["data"] as? [String: Any],
           let updateData = data["updateCheckInInterval"] as? [String: Any],
           let success = updateData["success"] as? Bool, success {
            print("✅ GraphQL 签到间隔更新成功")
        } else {
            print("⚠️ GraphQL 签到间隔更新失败")
            throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "更新失败"])
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
                Section(header: Text("头像")) {
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
                        Picker("性别", selection: $gender) {
                            ForEach(User.Gender.allCases, id: \.self) { g in
                                Text(g.rawValue).tag(g)
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
                
                Section(header: Text("姓名")) {
                    TextField("请输入姓名", text: $name)
                }
                
                Section(header: Text("手机号")) {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        Text(phone)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
                
                Section(header: Text("身份信息")) {
                    // 性别选择
                    Picker("性别", selection: $gender) {
                        ForEach(User.Gender.allCases, id: \.self) { g in
                            Text(g.rawValue).tag(g)
                        }
                    }
                    
                    TextField("民族", text: $ethnicity)
                    
                    DatePicker("出生日期", selection: $birthday, displayedComponents: .date)
                    
                    TextField("身份证号码", text: $idCard)
                        .textInputAutocapitalization(.characters)
                    
                    TextField("住址", text: $address)
                        .lineLimit(2)
                }
                
                Section {
                    Button(action: {
                        print("🔵 开始保存用户信息...")
                        print("   userManager.isLoggedIn (保存前): \(userManager.isLoggedIn)")
                        print("   currentUser: \(userManager.currentUser?.name ?? "nil")")
                        
                        if !name.isEmpty {
                            if var user = userManager.currentUser {
                                user.name = name
                                // phone 不可修改
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
                        Text("保存")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                if let user = userManager.currentUser {
                    name = user.name
                    phone = user.phone
                    ethnicity = user.ethnicity ?? ""
                    birthday = user.birthday ?? Date()
                    idCard = user.idCard ?? ""
                    address = user.address ?? ""
                    gender = user.gender ?? .male
                    selectedAvatar = user.avatar ?? "male_1"
                    print("🔵 编辑资料：name=\(name), phone=\(phone), gender=\(gender.rawValue), avatar=\(selectedAvatar)")
                }
            }
        }
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
                Section(header: Text("服务器地址")) {
                    TextField("自动获取（推荐）", text: $tempURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    Text("留空表示自动从后端获取，深度绑定当前服务器地址")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("修改后需要重启 App 生效")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("测试连接")) {
                    HStack {
                        Text("状态")
                        Spacer()
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("测试中...")
                                .foregroundColor(.secondary)
                        } else if !testResult.isEmpty {
                            Text(testResult)
                                .foregroundColor(testResult == "成功" ? .green : .red)
                        } else {
                            Text("未测试")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: testConnection) {
                        HStack {
                            Spacer()
                            Text("测试连接")
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
                            Text("保存并重启")
                            Spacer()
                        }
                    }
                    .disabled(tempURL.isEmpty)
                }
            }
            .navigationTitle("服务器配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                tempURL = customServerURL
            }
        }
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
                        smsIsDevelopment
                    }
                }
                """
                
                let variables: [String: Any] = [:]
                let response = try await DataManager.shared.sendGraphQLQuery(query: query, variables: variables, baseURL: tempURL)
                
                await MainActor.run {
                    isTesting = false
                    if let data = response["data"] as? [String: Any],
                       data["getConfig"] != nil {
                        testResult = "成功 (GraphQL)"
                    } else {
                        testResult = "失败"
                    }
                }
            } catch {
                await MainActor.run {
                    isTesting = false
                    testResult = "失败：\(error.localizedDescription)"
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
                Text("终活")
                    .font(.system(size: 28, weight: .bold))
                Text("让生命更有温度")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            VStack(spacing: 16) {
                HStack {
                    Text("当前版本")
                    Spacer()
                    Text("v\(appVersion)")
                        .foregroundColor(.secondary)
                }
                Button(action: checkUpdate) {
                    HStack {
                        Text(LocalizedStringKey("检查更新")).accessibilityLabel("检查应用更新")
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
                Section(header: Text("应用信息")) {
                    if let url = URL(string: "https://zhonghuo.cn") {
                        Link("官方网站", destination: url)
                    }
                    if let url = URL(string: "https://zhonghuo.cn/privacy") {
                        Link("隐私政策", destination: url)
                    }
                    if let url = URL(string: "https://zhonghuo.cn/terms") {
                        Link("服务条款", destination: url)
                    }
                    
                    // ⚖️ 法律声明
                    NavigationLink(destination: LegalDisclosureView()) {
                        HStack {
                            Image(systemName: "scale")
                            Text("电子遗嘱效力说明")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section(header: Text("联系我们")) {
                    HStack {
                        Text("客服邮箱")
                        Spacer()
                        Text("support@zhonghuo.cn").foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
            Text("© 2026 终活 App. All rights reserved.")
                .font(.caption).foregroundColor(.secondary).padding(.bottom, 20)
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
        .alert(LocalizedStringKey("检查更新"), isPresented: $showingUpdateAlert) {
            Button("稍后更新", role: .cancel) { }
            Button("立即更新") {
                if let url = URL(string: "https://apps.apple.com/app/终活/id123456789") {
                    UIApplication.shared.open(url)
                }
            }
        } message: { Text("发现新版本 v1.0.1\\n\\nBug 修复和性能优化") }
    }
    
    private func checkUpdate() {
        showingUpdateAlert = true
    }
    
    func startDeviceMonitoring() {
        deviceMonitor.startMonitoring()
        print("🔋 设备监控已启动")
    }
    
    func stopDeviceMonitoring() {
        deviceMonitor.stopMonitoring()
        print("🔋 设备监控已停止")
    }
    
    /// 检查定位权限并在需要时提示用户
    private func checkLocationPermission() {
        let status = userManager.locationAuthStatus
        
        // 如果已经确定过权限，不再提示
        guard status == .notDetermined || status == .denied else {
            return
        }
        
        // 如果是被拒绝，显示提示让用户去设置
        if status == .denied {
            showingLocationAlert = true
            return
        }
        
        // 请求定位权限
        userManager.requestLocationPermission()
    }
    
    // 设置紫色导航栏背景（与首页一致）
    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "6366F1")
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

#Preview {
    SettingsView()
}
