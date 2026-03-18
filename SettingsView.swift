//
//  SettingsView.swift
//  终活
//
//  设置页面 - 个人信息、紧急联系人、通知
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var userManager = UserManager.shared
    @State private var showingEditProfile = false
    @State private var showingEmergencyContact = false
    @State private var showingLocationAlert = false
    @AppStorage("customServerURL") private var customServerURL = ""  // 空表示自动获取
    @State private var tempServerURL = ""
    
    var body: some View {
        NavigationView {
            List {
                // 用户信息卡片
                Section {
                    userInfoCard
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                // 定位权限
                Section(header: Text("安全")) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(Color(hex: "6366F1"))
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("定位服务")
                                .font(.system(size: 16))
                            
                            Text(locationStatusText)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if userManager.locationAuthStatus != .authorizedAlways {
                            Button(action: {
                                userManager.requestLocationPermission()
                                showingLocationAlert = true
                            }) {
                                Text("开启")
                                    .foregroundColor(Color(hex: "6366F1"))
                            }
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // 紧急联系人和见证人
                Section(header: Text("安全")) {
                    NavigationLink(destination: EmergencyContactsView()) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .foregroundColor(Color(hex: "FF3B30"))
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("紧急联系人")
                                    .font(.system(size: 16))
                                
                                Text("紧急联系人和见证人管理")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
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
                                    Task {
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
                
                // 关于
                Section(header: Text("关于")) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color(hex: "6366F1"))
                            .frame(width: 30)
                        
                        Text("关于终活")
                            .font(.system(size: 16))
                        
                        Spacer()
                        
                        Text("v2.0 ✅")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // 退出登录（放在最底部）
                Section {
                    Button(action: logout) {
                        HStack {
                            Spacer()
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("退出登录")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
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
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileModal(dataManager: dataManager, userManager: userManager)
            }
            .sheet(isPresented: $showingEmergencyContact) {
                EmergencyContactModal(dataManager: dataManager, userManager: userManager)
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
        }
    }
    
    // MARK: - 用户信息卡片
    @ViewBuilder
    private var userInfoCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(userManager.currentUser?.name ?? "用户")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
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
            
            HStack(spacing: 12) {
                Button(action: { showingEditProfile = true }) {
                    HStack {
                        Image(systemName: "pencil.circle.fill")
                        Text("编辑资料")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                }
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
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "isFirstLaunch")  // ✅ 重置首次启动标记
        UserDefaults.standard.synchronize()
        
        print("✅ 退出登录完成")
    }
    
    // MARK: - 更新签到间隔
    private func updateCheckInInterval(_ interval: CheckInInterval) async {
        print("🔵 开始更新签到间隔：\(interval.rawValue)")
        
        // 检查用户是否登录
        guard let userId = UserDefaults.standard.string(forKey: "userId"),
              let user = userManager.currentUser else {
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
        guard !DataManager.apiURL.isEmpty else {
            throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "API 未初始化"])
        }
        
        let url = URL(string: "\(DataManager.apiURL)/admin.php?action=update_checkin_interval")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加 token
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "user_id": userId,
            "check_in_interval": interval.hours
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Server", code: -1)
        }
        
        let result = try JSONDecoder().decode(ServerResponse.self, from: data)
        if !result.success {
            throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: result.error ?? "更新失败"])
        }
        
        print("✅ 服务器同步成功")
    }
    
    // MARK: - 错误提示
    @State private var showingError = false
    @State private var errorMessage = ""
    
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
    
    var body: some View {
        NavigationView {
            Form {
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
                    name = user.name ?? ""
                    phone = user.phone ?? ""
                    ethnicity = user.ethnicity ?? ""
                    birthday = user.birthday ?? Date()
                    idCard = user.idCard ?? ""
                    address = user.address ?? ""
                    print("🔵 编辑资料：name=\(name), phone=\(phone)")
                }
            }
        }
    }
}

// MARK: - 紧急联系人弹窗
struct EmergencyContactModal: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var userManager: UserManager
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var relationship = ""
    @State private var showingAddWitness = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("联系人信息")) {
                    TextField("姓名", text: $name)
                    TextField("手机号", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("关系", text: $relationship)
                }
                
                Section {
                    Button(action: {
                        if !name.isEmpty && !phone.isEmpty {
                            let witness = Witness(
                                id: UUID().uuidString,
                                name: name,
                                role: relationship,
                                phone: phone,
                                isConfirmed: false,
                                order: 0
                            )
                            dataManager.addWitness(witness)
                            
                            dataManager.settings.emergencyContact = UserSettings.EmergencyContact(
                                name: name,
                                phone: phone,
                                relationship: relationship
                            )
                            dataManager.saveSettingsToFile()
                            
                            // 同步到 UserManager 的 currentUser
                            if var user = userManager.currentUser {
                                user.emergencyContacts.append(User.EmergencyContact(
                                    id: witness.id,
                                    name: witness.name,
                                    phone: witness.phone,
                                    relationship: witness.role
                                ))
                                userManager.currentUser = user
                                userManager.saveUser(user)
                                
                                // 确保登录状态保持
                                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                            }
                            
                            print("✅ 紧急联系人已保存，登录状态保持")
                            dismiss()
                        }
                    }) {
                        Text("保存")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(name.isEmpty || phone.isEmpty)
                }
            }
            .navigationTitle("紧急联系人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
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
                let url = URL(string: "\(tempURL)/api/config.php")!
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw NSError(domain: "Server error", code: -1)
                }
                
                let config = try JSONDecoder().decode(ServerConfig.self, from: data)
                
                await MainActor.run {
                    isTesting = false
                    testResult = config.success ? "成功" : "失败"
                }
            } catch {
                await MainActor.run {
                    isTesting = false
                    testResult = "失败"
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
