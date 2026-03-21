//
//  AuthView.swift
//  终活
//
//  用户注册和登录界面
//

import SwiftUI

struct AuthView: View {
    // 🔴 关键修复：直接使用 shared 单例，而不是 @StateObject
    private var userManager: UserManager { UserManager.shared }
    
    @State private var name = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var verifyCode = ""
    @State private var loginType: String = "password" // "password" or "verify_code"
    @State private var isRegistering = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var countdown = 0
    @State private var timer: Timer?
    @State private var showingResetPassword = false
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss  // 🔴 添加 dismiss 用于登录后关闭登录页
    
    // ✅ 计算属性：表单是否有效
    private var isFormValid: Bool {
        if isRegistering {
            return !phone.isEmpty && !name.isEmpty && !password.isEmpty && password.count >= 6
        } else {
            if loginType == "password" {
                return !phone.isEmpty && !password.isEmpty
            } else {
                return !phone.isEmpty && !verifyCode.isEmpty
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Logo
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "AF52DE"))
                    
                    Text("终活")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: "AF52DE"))
                    
                    Text("让生命更有尊严，让告别更有温度")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // 表单
                VStack(spacing: 20) {
                    if isRegistering {
                        TextField("姓名", text: $name)
                            .textFieldStyle(CustomTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(size: 18, weight: .medium))  // ✅ 加大字号，方便老年人
                    }
                    
                    // 手机号输入
                    TextField("手机号码", text: $phone)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.phonePad)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(size: 18, weight: .medium))  // ✅ 加大字号，方便老年人
                    
                    if isRegistering {
                        // 注册时：密码输入框
                        SecureField("设置密码（6 位以上）", text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                            .font(.system(size: 18, weight: .medium))  // ✅ 加大字号
                        
                        // 验证码输入框
                        TextField("验证码", text: $verifyCode)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                            .font(.system(size: 18, weight: .medium))  // ✅ 加大字号
                            .onChange(of: verifyCode) { newValue in
                                if newValue.count > 6 {
                                    verifyCode = String(newValue.prefix(6))
                                }
                            }
                        
                        // 获取验证码按钮
                        Button(action: sendVerifyCode) {
                            HStack {
                                Image(systemName: "message.fill")
                                Text(countdown > 0 ? "\(countdown) 秒后重新获取" : "获取验证码")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(countdown > 0 ? .gray : Color(hex: "AF52DE"))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(countdown > 0 ? Color.gray.opacity(0.1) : Color(hex: "AF52DE").opacity(0.1))
                            .cornerRadius(12)
                        }
                        .disabled(countdown > 0 || phone.isEmpty)
                    } else {
                        // 登录时：切换登录方式
                        Picker("登录方式", selection: $loginType) {
                            Text("密码登录").tag("password")
                            Text("验证码登录").tag("verify_code")
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        if loginType == "password" {
                            // 密码登录
                            SecureField("密码", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                                .font(.system(size: 18, weight: .medium))  // ✅ 加大字号
                            
                            // 找回密码
                            Button(action: { showingResetPassword = true }) {
                                HStack {
                                    Spacer()
                                    Text("忘记密码？")
                                        .font(.system(size: 16))  // ✅ 加大字号
                                        .foregroundColor(Color(hex: "AF52DE"))
                                }
                            }
                        } else {
                            // 验证码登录
                            TextField("验证码", text: $verifyCode)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.numberPad)
                                .font(.system(size: 18, weight: .medium))  // ✅ 加大字号
                                .onChange(of: verifyCode) { newValue in
                                    if newValue.count > 6 {
                                        verifyCode = String(newValue.prefix(6))
                                    }
                                }
                            
                            Button(action: sendVerifyCode) {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text(countdown > 0 ? "\(countdown) 秒后重新获取" : "获取验证码")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(countdown > 0 ? .gray : Color(hex: "AF52DE"))
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(countdown > 0 ? Color.gray.opacity(0.1) : Color(hex: "AF52DE").opacity(0.1))
                                .cornerRadius(12)
                            }
                            .disabled(countdown > 0 || phone.isEmpty)
                        }
                    }
                    
                    // 注册/登录按钮
                    Button(action: handleSubmit) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isRegistering ? "注册" : "登录")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isLoading ? Color.gray : Color(hex: "AF52DE"))
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || !isFormValid)
                }
                .padding(.horizontal, 30)
                
                // 切换注册/登录
                HStack {
                    Text(isRegistering ? "已有账号？" : "没有账号？")
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        withAnimation {
                            isRegistering.toggle()
                            verifyCode = ""
                            countdown = 0
                            timer?.invalidate()
                            timer = nil
                        }
                    }) {
                        Text(isRegistering ? "去登录" : "去注册")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "AF52DE"))
                    }
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert(isPresented: $showingError) {
                Alert(
                    title: Text(""),  // 空标题，更简洁
                    message: Text(errorMessage),
                    dismissButton: .default(Text("好的"))
                )
            }
            .sheet(isPresented: $showingResetPassword) {
                ResetPasswordView()
            }
            .onAppear {
                timer?.invalidate()
                timer = nil
                // 🔴 登录前不初始化 API，等到登录时再初始化
            }
        }
    }
    
    // MARK: - Actions
    
    private func sendVerifyCode() {
        guard !phone.isEmpty else {
            errorMessage = "请输入手机号"
            showingError = true
            return
        }
        
        // 验证手机号格式
        let phoneRegex = "^1[3-9]\\d{9}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        if !phoneTest.evaluate(with: phone) {
            errorMessage = "请输入正确的手机号"
            showingError = true
            return
        }
        
        countdown = 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            countdown -= 1
            if countdown <= 0 {
                timer.invalidate()
            }
        }
        
        // 显示测试验证码提示
        errorMessage = "开发环境：验证码固定为 123456"
        showingError = true
    }
    
    private func handleSubmit() {
        print("🔴 ====== handleSubmit 被调用 ======")
        print("   isRegistering: \(isRegistering)")
        print("   loginType: \(loginType)")
        print("   phone: \(phone)")
        print("   password: \(password)")
        print("   verifyCode: \(verifyCode)")
        print("   isLoading: \(isLoading)")
        
        // 验证输入
        if isRegistering {
            if name.isEmpty {
                errorMessage = "请输入姓名"
                showingError = true
                return
            }
            if phone.isEmpty {
                errorMessage = "请输入手机号"
                showingError = true
                return
            }
            if password.isEmpty || password.count < 6 {
                errorMessage = "密码至少 6 位"
                showingError = true
                return
            }
            if verifyCode.isEmpty {
                errorMessage = "请输入验证码"
                showingError = true
                return
            }
        } else {
            if phone.isEmpty {
                errorMessage = "请输入手机号"
                showingError = true
                return
            }
            if loginType == "password" {
                if password.isEmpty {
                    errorMessage = "请输入密码"
                    showingError = true
                    return
                }
            } else {
                if verifyCode.isEmpty {
                    errorMessage = "请输入验证码"
                    showingError = true
                    return
                }
            }
        }
        
        print("✅ 验证通过，开始执行登录/注册")
        
        // 执行登录/注册
        isLoading = true
        print("🟡 isLoading = true")
        
        Task {
            if isRegistering {
                await register()
            } else {
                await login()
            }
            await MainActor.run {
                isLoading = false
                print("🟢 isLoading = false")
            }
        }
    }
    
    // MARK: - API 请求
    
    private func apiRequest(action: String, body: [String: Any]) async throws -> [String: Any] {
        try await DataManager.shared.checkAPIReady()
        
        print("🔍 ====== API 请求调试 ======")
        print("   action: \(action)")
        print("   DataManager.baseURL: \(DataManager.baseURL)")
        print("   DataManager.apiURL: \(DataManager.apiURL)")
        print("   请求 URL: \(DataManager.apiURL)/api.php?action=\(action)")
        print("   请求 Body: \(body)")
        
        guard !DataManager.apiURL.isEmpty else {
            print("❌ API 未初始化")
            throw NSError(domain: "API 未初始化", code: -1)
        }
        
        let urlString = "\(DataManager.apiURL)/api.php?action=\(action)"
        guard let url = URL(string: urlString) else {
            print("❌ URL 无效：\(urlString)")
            throw NSError(domain: "URL 无效", code: -1)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📤 发送请求...")
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        let session = URLSession(configuration: config)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ 响应类型错误：\(type(of: response))")
            throw NSError(domain: "响应类型错误", code: -1)
        }
        
        print("📥 收到响应:")
        print("   状态码：\(httpResponse.statusCode)")
        print("   URL: \(httpResponse.url?.absoluteString ?? "nil")")
        
        // 即使 HTTP 状态码不是 2xx，也尝试解析 JSON 获取错误信息
        let responseString = String(data: data, encoding: .utf8) ?? "无法解析"
        print("📥 响应内容：\(responseString.prefix(200))")
        
        // 尝试解析 JSON（即使是错误响应）
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // 成功解析 JSON，返回给调用者处理错误
            return json
        }
        
        // 无法解析 JSON，抛出原始错误
        if !(200...299).contains(httpResponse.statusCode) {
            print("❌ HTTP 错误：\(httpResponse.statusCode)")
            throw NSError(domain: "HTTP 错误：\(httpResponse.statusCode)", code: httpResponse.statusCode)
        }
        
        print("✅ 请求成功")
        
        // 使用 JSONSerialization 解析（更灵活，不要求严格类型匹配）
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "JSON 解析失败", code: -1)
        }
        
        return json
    }
    
    private func register() async {
        // ✅ 验证手机号长度（必须 11 位）
        if phone.count != 11 {
            errorMessage = "手机号必须是 11 位"
            showingError = true
            return
        }
        
        do {
            // 🔵 注册时才初始化 API
            DataManager.shared.initializeAPIConfig()
            print("🔵 注册请求 - API 已初始化")
            
            let body: [String: Any] = [
                "action": "register",
                "name": name,
                "phone": phone,
                "password": password
            ]
            
            let json = try await apiRequest(action: "register", body: body)
            
            let success = json["success"] as? Bool ?? false
            
            if success {
                print("✅ 注册成功，处理用户数据...")
                // 🔴 先处理用户数据（在主线程更新状态）
                await handleAuthSuccess(json)
                
                // 🔴 关键修复：延迟后在主线程显示提示，给 UI 切换的时间
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 秒延迟
                
                await MainActor.run {
                    print("🟢 注册成功，显示提示")
                    // 显示成功提示
                    errorMessage = "✅ 注册成功！"
                    showingError = true
                    // 延迟后隐藏键盘
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.hideKeyboard()
                    }
                }
            } else {
                // 根据错误码显示友好提示（不显示错误编码）
                let errorCode = json["code"] as? String ?? ""
                
                switch errorCode {
                case "PHONE_EXISTS":
                    errorMessage = "该手机号已注册，请直接登录"
                case "INVALID_NAME":
                    errorMessage = "姓名不能为空"
                case "INVALID_PHONE":
                    errorMessage = "手机号格式不正确"
                case "INVALID_PASSWORD":
                    errorMessage = "密码至少 6 位"
                default:
                    errorMessage = json["error"] as? String ?? "注册失败"
                }
                showingError = true
            }
        } catch {
            errorMessage = "❌ 注册失败：\(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func login() async {
        print("🔵 ====== login() 开始执行 ======")
        
        do {
            // 🔵 登录时才初始化 API
            DataManager.shared.initializeAPIConfig()
            print("🔵 登录请求 - API 已初始化")
            
            var body: [String: Any] = [
                "action": "login",
                "phone": phone,
                "login_type": loginType
            ]
            
            if loginType == "password" {
                body["password"] = password
            } else {
                body["verify_code"] = verifyCode
            }
            
            print("📤 准备发送登录请求...")
            let json = try await apiRequest(action: "login", body: body)
            
            print("📥 收到响应：\(json)")
            let success = json["success"] as? Bool ?? false
            print("🔍 success: \(success)")
            
            if success {
                print("✅ 登录成功，处理用户数据...")
                // 🔴 先处理用户数据（在主线程更新状态）
                await handleAuthSuccess(json)
                
                // 🔴 关键修复：确保 UserManager 状态已更新
                await MainActor.run {
                    print("🟢 登录状态已更新：")
                    print("   - isLoggedIn: \(userManager.isLoggedIn)")
                    print("   - currentUser: \(userManager.currentUser?.name ?? "nil")")
                    print("   - currentUser?.id: \(userManager.currentUser?.id ?? "nil")")
                }
                
                // 🔴 延迟后显示成功提示并触发 UI 切换
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 秒延迟
                
                await MainActor.run {
                    print("🟢 准备显示成功提示...")
                    
                    // 🔴 关键修复：先触发 ContentView 重新检查，再显示提示
                    // 这样提示消失时 UI 已经切换了
                    print("🔔 立即触发 ContentView 重新检查登录状态...")
                    NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
                    
                    // 显示成功提示
                    errorMessage = "✅ 登录成功！"
                    showingError = true
                    
                    // 延迟后隐藏键盘
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.hideKeyboard()
                    }
                }
            } else {
                print("❌ 登录失败，处理错误...")
                // 根据错误码显示友好提示（不显示错误编码）
                let errorCode = json["code"] as? String ?? ""
                print("   errorCode: \(errorCode)")
                
                switch errorCode {
                case "USER_NOT_FOUND":
                    errorMessage = "账号不存在，请先注册"
                case "INVALID_PASSWORD":
                    errorMessage = "密码错误"
                case "INVALID_VERIFY_CODE", "INVALID_CODE":
                    errorMessage = "验证码错误或已过期"
                case "INVALID_PHONE":
                    errorMessage = "手机号格式不正确"
                default:
                    errorMessage = json["error"] as? String ?? "登录失败"
                }
                print("❌ 显示错误：\(errorMessage)")
                showingError = true
            }
        } catch {
            print("❌ 登录异常：\(error)")
            errorMessage = "❌ 登录失败：\(error.localizedDescription)"
            print("❌ 显示错误：\(errorMessage)")
            showingError = true
        }
    }
    
    private func handleAuthSuccess(_ json: [String: Any]) async {
        print("🔵 登录成功，开始处理用户数据...")
        
        guard let data = json["data"] as? [String: Any] else {
            print("❌ 错误：data 为空")
            return
        }
        
        let token = data["token"] as? String ?? ""
        let userId = data["user_id"] as? String ?? ""
        
        print("🔑 Token: \(token.prefix(20))...")
        print("👤 User ID: \(userId)")
        
        // 保存 token
        UserDefaults.standard.set(token, forKey: "userToken")
        UserDefaults.standard.set(userId, forKey: "userId")
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        
        // 保存密码（用于后续启动时验证）
        if loginType == "password" && !password.isEmpty {
            UserDefaults.standard.set(password, forKey: "userPassword")
            print("✅ 密码已保存（用于启动验证）")
        }
        
        print("✅ Token 已保存")
        
        // 🔴 关键修复：在主线程更新 UserManager，确保 UI 刷新
        await MainActor.run {
            userManager.isLoggedIn = true
            print("✅ UserManager.isLoggedIn = true (主线程)")
        }
        
        // 创建用户数据
        if let userDict = data["user"] as? [String: Any] {
            print("📝 用户数据：\(userDict)")
            
            let name = userDict["name"] as? String ?? "用户"
            let phone = userDict["phone"] as? String ?? self.phone
            
            var user = User(
                id: userDict["id"] as? String ?? userId,
                name: name,
                phone: phone,
                createdAt: Date(),
                emergencyContacts: [],
                checkInInterval: .twoDays,
                notificationsEnabled: true,
                cloudSyncEnabled: false
            )
            print("✅ User 对象已创建：\(user.name)")
            
            // 处理签到间隔（可能是 String 或 Int）
            if let intervalValue = userDict["check_in_interval"] {
                print("📊 签到间隔原始值：\(intervalValue) (类型：\(type(of: intervalValue)))")
                
                let hours: Int
                if let intVal = intervalValue as? Int {
                    hours = intVal
                } else if let strVal = intervalValue as? String, let intVal = Int(strVal) {
                    hours = intVal
                } else {
                    hours = 48
                }
                
                print("⏰ 签到间隔：\(hours) 小时")
                
                switch hours {
                case 24: user.checkInInterval = .oneDay
                case 48: user.checkInInterval = .twoDays
                case 72: user.checkInInterval = .threeDays
                case 96: user.checkInInterval = .fourDays
                case 120: user.checkInInterval = .fiveDays
                case 144: user.checkInInterval = .sixDays
                case 168: user.checkInInterval = .sevenDays
                default: user.checkInInterval = .twoDays
                }
                userManager.checkInInterval = user.checkInInterval
                print("✅ 签到间隔已设置：\(user.checkInInterval)")
            }
            
            print("💾 准备保存用户数据...")
            print("   用户 ID: \(user.id)")
            print("   用户姓名：\(user.name)")
            print("   用户文件路径：\(userManager.userFileURL.path)")
            
            // 🔴 在主线程设置 currentUser，确保 UI 刷新
            await MainActor.run {
                userManager.currentUser = user
                print("✅ UserManager.currentUser 已设置 (主线程)")
            }
            
            let success = userManager.saveUser(user)
            print("✅ 用户数据已保存：\(success)")
            
            // 验证文件是否存在
            if userManager.userFileExists {
                print("✅ 用户文件已创建：\(userManager.userFileURL.path)")
            } else {
                print("❌ 用户文件创建失败！")
            }
            
            // 🎯 登录成功后立即执行自动签到（重置倒计时）
            print("⏰ 登录成功，执行自动签到...")
            await userManager.performAutoSignIn()
            
            // 🆕 登录后智能同步数据（双向同步：云端→本地，本地→云端）
            print("🔄 登录后智能同步数据...")
            Task {
                // 第一步：从云端下载数据（新设备或获取其他设备的数据）
                print("📥 1. 从云端下载数据...")
                await DataManager.shared.downloadAllData()
                
                // 第二步：上传本地新数据到云端
                print("📤 2. 上传本地新数据到云端...")
                
                // 上传位置
                print("📍 上传位置...")
                userManager.uploadLocation()
                
                // 同步胶囊
                print("📦 同步胶囊...")
                if let result = await DataManager.shared.batchSyncCapsules() {
                    print("✅ 胶囊同步完成：\(result)")
                }
                
                // 同步遗嘱
                print("📝 同步遗嘱...")
                if let result = await DataManager.shared.batchSyncWills() {
                    print("✅ 遗嘱同步完成：\(result)")
                }
                
                // 同步紧急联系人
                print("👥 同步紧急联系人...")
                if let result = await DataManager.shared.batchSyncEmergencyContacts() {
                    print("✅ 紧急联系人同步完成：\(result)")
                }
                
                // 同步见证人
                print("👤 同步见证人...")
                if let result = await DataManager.shared.batchSyncWitnesses() {
                    print("✅ 见证人同步完成：\(result)")
                }
                
                print("🎉 登录同步完成！")
                print("📊 本地和云端数据已保持一致")
            }
            
            print("🎉 登录流程完成！")
        } else {
            print("❌ 错误：user 数据为空")
        }
    }
}

// MARK: - ResetPasswordView

// MARK: - Helper Extensions

extension AuthView {
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ResetPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var phone = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("找回密码") {
                    TextField("手机号", text: $phone)
                        .keyboardType(.phonePad)
                    
                    SecureField("新密码", text: $newPassword)
                    
                    SecureField("确认密码", text: $confirmPassword)
                    
                    Button("重置密码") {
                        Task {
                            await resetPassword()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(phone.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                }
            }
            .navigationTitle("找回密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showingError) {
                Alert(
                    title: Text(""),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("好的"))
                )
            }
        }
    }
    
    private func resetPassword() async {
        // TODO: 实现重置密码 API
        errorMessage = "功能开发中..."
        showingError = true
    }
}

#Preview {
    AuthView()
        .environmentObject(UserManager.shared)
}

// MARK: - 自定义输入框样式（适合老年人）
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(14)  // ✅ 增加内边距
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)  // ✅ 加深边框
            )
            .foregroundColor(Color.black.opacity(0.9))  // ✅ 加深文字颜色
            .font(.system(size: 18, weight: .medium))  // ✅ 加大字号
    }
}
