//
//  AuthView.swift
//  终活
//
//  用户注册和登录界面
//

import SwiftUI

struct AuthView: View {
    @StateObject private var userManager = UserManager.shared
    @State private var name = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var verifyCode = ""
    @State private var isRegistering = true
    @State private var loginType: String = "password" // "password" or "verify_code"
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var countdown = 0
    @State private var timer: Timer?
    @State private var showingResetPassword = false
    
    // MARK: - 短信验证码响应模型
    struct SMSResponse: Codable {
        let success: Bool
        let message: String?
        let code: String?
        let error: String?
        let expiresIn: Int?
        let debug: String?
    }
    
    // MARK: - 注册/登录 API 响应模型
    struct AuthResponse: Codable {
        let success: Bool
        let message: String?
        let error: String?
        let data: AuthData?
        let code: String?  // 错误码
        
        struct AuthData: Codable {
            let token: String
            let user_id: String
            let is_new: Bool?  // 登录时可能不返回
            let user: UserData?
        }
        
        struct UserData: Codable {
            let id: String
            let name: String
            let phone: String
            let check_in_interval: Int?
            let last_check_in_date: String?
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
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    // 手机号输入
                    TextField("手机号码", text: $phone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if isRegistering {
                        // 注册时：密码输入框
                        SecureField("设置密码（6 位以上）", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        // 验证码输入框
                        TextField("验证码", text: $verifyCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
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
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            // 找回密码
                            Button(action: { showingResetPassword = true }) {
                                HStack {
                                    Spacer()
                                    Text("忘记密码？")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "AF52DE"))
                                }
                            }
                        } else {
                            // 验证码登录
                            TextField("验证码", text: $verifyCode)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
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
                        Text(isRegistering ? "注册" : "登录")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "AF52DE"))
                            .cornerRadius(12)
                    }
                    .disabled(isRegistering ? (phone.isEmpty || name.isEmpty || password.isEmpty || verifyCode.isEmpty) : (loginType == "password" ? (phone.isEmpty || password.isEmpty) : (phone.isEmpty || verifyCode.isEmpty)))
                }
                .padding(.horizontal, 30)
                
                // 切换注册/登录
                HStack {
                    Text(isRegistering ? "已有账号？" : "没有账号？")
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        withAnimation {
                            isRegistering.toggle()
                            // 切换时重置状态
                            verifyCode = ""
                            countdown = 0
                            timer?.invalidate()
                            timer = nil
                        }
                    }) {
                        Text(isRegistering ? "立即登录" : "立即注册")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "AF52DE"))
                    }
                }
                .padding(.bottom, 30)
                
                Spacer()
                
                // 使用说明
                VStack(spacing: 8) {
                    Text("注册即代表同意")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 4) {
                        Button("使用说明") {
                            print("📖 使用说明")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "AF52DE"))
                        
                        Text("和")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Button("隐私政策") {
                            print("🔒 隐私政策")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "AF52DE"))
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(hex: "F6F6F8"))
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                // 初始化 API 配置（必须在获取验证码之前）
                print("🟢 AuthView onAppear - 初始化 API 配置")
                DataManager.shared.initializeAPIConfig()
            }
            .alert("提示", isPresented: $showingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - 发送验证码
    private func sendVerifyCode() {
        guard !phone.isEmpty else { return }
        
        // 检查是否正在倒计时
        if countdown > 0 {
            return
        }
        
        // 开始倒计时
        countdown = 60
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            countdown -= 1
            if countdown <= 0 {
                timer?.invalidate()
                timer = nil
            }
        }
        
        // 调用后端 API 发送验证码
        Task {
            do {
                print("🔵 开始获取验证码...")
                print("   DataManager.baseURL: \(DataManager.baseURL)")
                print("   DataManager.apiURL: \(DataManager.apiURL)")
                print("   isBackendOnline: \(DataManager.shared.isBackendOnline)")
                
                // 确保 API 已就绪
                try await DataManager.shared.checkAPIReady()
                
                guard !DataManager.apiURL.isEmpty else {
                    print("❌ API URL 未初始化")
                    throw NSError(domain: "API URL not initialized", code: -1)
                }
                
                let url = URL(string: "\(DataManager.apiURL)/sms.php")!
                print("🌐 请求 URL: \(url)")
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "phone": phone,
                    "action": isRegistering ? "register" : "login"
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                print("📡 发送请求...")
                let (data, response) = try await URLSession.shared.data(for: request)
                
                print("📥 收到响应")
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    print("❌ HTTP 错误：\(statusCode)")
                    throw NSError(domain: "Server error", code: statusCode)
                }
                
                let result = try JSONDecoder().decode(SMSResponse.self, from: data)
                print("✅ JSON 解析成功：success=\(result.success)")
                
                await MainActor.run {
                    if result.success {
                        // 根据后端返回决定是否显示验证码
                        // 后端在测试模式下会返回 code，生产模式不返回
                        if let code = result.code {
                            errorMessage = "验证码：\(code)（测试模式）"
                            showingError = true
                        } else {
                            errorMessage = "验证码已发送到手机"
                            showingError = true
                        }
                    } else {
                        errorMessage = result.error ?? "发送失败"
                        showingError = true
                        countdown = 0 // 重置倒计时允许重试
                    }
                }
            } catch {
                print("❌ 错误：\(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = "网络错误：\(error.localizedDescription)"
                    showingError = true
                    countdown = 0 // 重置倒计时允许重试
                }
            }
        }
    }
    
    // MARK: - 提交处理
    private func handleSubmit() {
        if isRegistering {
            // 验证输入
            if phone.isEmpty {
                errorMessage = "请输入手机号"
                showingError = true
                return
            }
            
            if name.isEmpty {
                errorMessage = "请输入姓名"
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
            
            // 调用后端 API 注册
            Task {
                await registerWithAPI()
            }
        } else {
            // 登录
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
            
            // 调用后端 API 登录
            Task {
                await loginWithAPI()
            }
        }
    }
    
    // MARK: - API 注册
    private func registerWithAPI() async {
        print("🔵 开始注册流程...")
        print("  name: \(name)")
        print("  phone: \(phone)")
        print("  verify_code: \(verifyCode)")
        print("  DataManager.baseURL: \(DataManager.baseURL)")
        print("  DataManager.apiURL: \(DataManager.apiURL)")
        print("  DataManager.isBackendOnline: \(DataManager.shared.isBackendOnline)")
        
        // 测试网络连通性
        do {
            let testURL = URL(string: "\(DataManager.baseURL)/api/config.php")!
            let (testData, testResponse) = try await URLSession.shared.data(from: testURL)
            print("✅ 网络连通性测试成功")
            print("  响应：\(testResponse)")
        } catch {
            print("❌ 网络连通性测试失败：\(error)")
        }
        
        do {
            // 等待 API 初始化完成
            try await DataManager.shared.checkAPIReady()
            print("✅ API 已就绪")
            
            guard !DataManager.apiURL.isEmpty else {
                print("❌ API URL 为空")
                throw NSError(domain: "API URL not initialized", code: -1)
            }
            
            let urlString = "\(DataManager.apiURL)/users.php"
            print("🌐 请求 URL: \(urlString)")
            
            guard let url = URL(string: urlString) else {
                print("❌ URL 无效")
                throw NSError(domain: "Invalid URL", code: -1)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "action": "register",
                "name": name,
                "phone": phone,
                "password": password,
                "verify_code": verifyCode
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                print("✅ 请求体已序列化")
            } catch {
                print("❌ JSON 序列化失败：\(error)")
                throw error
            }
            
            print("📡 发送请求...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("📥 收到响应")
            print("  响应类型：\(type(of: response))")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 响应不是 HTTPURLResponse")
                throw NSError(domain: "Invalid response type", code: -1)
            }
            
            print("  HTTP 状态码：\(httpResponse.statusCode)")
            
            // 检查验证码错误（HTTP 400/500）
            if httpResponse.statusCode == 400 || httpResponse.statusCode == 500 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("  响应内容：\(responseString)")
                    
                    // 尝试解析错误信息
                    if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let errorCode = errorJSON["code"] as? String ?? ""
                        let errorMsg = errorJSON["error"] as? String ?? ""
                        print("  错误码：\(errorCode)")
                        print("  错误信息：\(errorMsg)")
                        
                        // 根据错误码判断
                        if errorCode == "INVALID_CODE" || errorMsg.contains("验证码") {
                            await MainActor.run {
                                errorMessage = "验证码错误或已过期"
                                showingError = true
                                countdown = 0 // 允许重新获取
                            }
                            return
                        } else if errorMsg.contains("手机号") {
                            await MainActor.run {
                                errorMessage = "手机号格式不正确"
                                showingError = true
                            }
                            return
                        } else if errorMsg.contains("用户名") || errorMsg.contains("姓名") {
                            await MainActor.run {
                                errorMessage = "用户名不能为空"
                                showingError = true
                            }
                            return
                        }
                    }
                }
                
                // 其他服务器错误
                await MainActor.run {
                    errorMessage = "服务器错误，请稍后重试"
                    showingError = true
                }
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ HTTP 错误：\(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("  响应内容：\(responseString)")
                }
                throw NSError(domain: "Server error", code: httpResponse.statusCode)
            }
            
            do {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                print("✅ JSON 解析成功")
                print("  success: \(result.success)")
                print("  message: \(result.message ?? "nil")")
                print("  error: \(result.error ?? "nil")")
                
                await MainActor.run {
                    if result.success, let data = result.data {
                        // 保存 token 到 UserDefaults
                        UserDefaults.standard.set(data.token, forKey: "userToken")
                        UserDefaults.standard.set(data.user_id, forKey: "userId")
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        
                        // 更新 UserManager 状态
                        userManager.isLoggedIn = true
                        
                        errorMessage = "注册成功！"
                        showingError = true
                        // 不需要手动跳转，ContentView 会监听 isLoggedIn 变化
                    } else {
                        errorMessage = result.error ?? "注册失败"
                        showingError = true
                    }
                }
            } catch {
                print("❌ JSON 解析失败：\(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("  原始响应：\(responseString)")
                }
                throw error
            }
            
        } catch {
            print("❌ 注册失败：\(error)")
            print("  错误域：\(error._domain)")
            print("  错误码：\(error._code)")
            print("  错误描述：\(error.localizedDescription)")
            
            await MainActor.run {
                // 根据错误类型显示更详细的信息
                if error._domain == "API URL not initialized" {
                    errorMessage = "API 未初始化，请检查网络设置"
                } else if error._domain == "Invalid URL" {
                    errorMessage = "服务器地址无效"
                } else if error._domain == "Server error" {
                    errorMessage = "服务器错误，请稍后重试"
                } else {
                    errorMessage = "网络错误：\(error.localizedDescription)"
                }
                showingError = true
            }
        }
    }
    
    // MARK: - API 登录
    private func loginWithAPI() async {
        print("🔵 开始登录流程...")
        print("  phone: \(phone)")
        print("  loginType: \(loginType)")
        print("  password: \(loginType == "password" ? "******" : "N/A")")
        print("  verify_code: \(loginType == "verify_code" ? verifyCode : "N/A")")
        
        do {
            // 等待 API 初始化完成
            try await DataManager.shared.checkAPIReady()
            print("✅ API 已就绪")
            
            guard !DataManager.apiURL.isEmpty else {
                print("❌ API URL 为空")
                throw NSError(domain: "API URL not initialized", code: -1)
            }
            
            let urlString = "\(DataManager.apiURL)/users.php"
            print("🌐 请求 URL: \(urlString)")
            
            guard let url = URL(string: urlString) else {
                print("❌ URL 无效")
                throw NSError(domain: "Invalid URL", code: -1)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
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
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("📡 发送请求...")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 响应不是 HTTPURLResponse")
                await MainActor.run {
                    errorMessage = "网络响应异常，请检查网络连接"
                    showingError = true
                }
                throw NSError(domain: "Invalid response type", code: -1)
            }
            
            print("  HTTP 状态码：\(httpResponse.statusCode)")
            
            // 检查 404 错误（服务器找不到文件）
            if httpResponse.statusCode == 404 {
                print("❌ 404 错误 - 服务器找不到 API 文件")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("  响应内容：\(responseString)")
                }
                await MainActor.run {
                    errorMessage = "服务器配置错误（404），请联系管理员"
                    showingError = true
                }
                return
            }
            
            // 检查验证码错误（HTTP 400/500）
            if httpResponse.statusCode == 400 || httpResponse.statusCode == 500 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("  响应内容：\(responseString)")
                    
                    // 尝试解析错误信息
                    if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let errorCode = errorJSON["code"] as? String ?? ""
                        let errorMsg = errorJSON["error"] as? String ?? ""
                        print("  错误码：\(errorCode)")
                        print("  错误信息：\(errorMsg)")
                        
                        // 根据错误码判断
                        if errorCode == "INVALID_CODE" || errorMsg.contains("验证码") {
                            await MainActor.run {
                                errorMessage = "验证码错误或已过期"
                                showingError = true
                                countdown = 0 // 允许重新获取
                            }
                            return
                        } else if errorMsg.contains("手机号") {
                            await MainActor.run {
                                errorMessage = "手机号格式不正确"
                                showingError = true
                            }
                            return
                        }
                    }
                }
                
                // 其他服务器错误
                await MainActor.run {
                    errorMessage = "服务器错误，请稍后重试"
                    showingError = true
                }
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ HTTP 错误：\(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("  响应内容：\(responseString)")
                }
                throw NSError(domain: "Server error", code: httpResponse.statusCode)
            }
            
            let result = try JSONDecoder().decode(AuthResponse.self, from: data)
            print("✅ JSON 解析成功")
            print("  success: \(result.success)")
            print("  message: \(result.message ?? "nil")")
            
            await MainActor.run {
                if result.success, let data = result.data {
                    // 保存 token 到 UserDefaults
                    UserDefaults.standard.set(data.token, forKey: "userToken")
                    UserDefaults.standard.set(data.user_id, forKey: "userId")
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    
                    // 更新 UserManager 状态
                    userManager.isLoggedIn = true
                    
                    // 🔵 关键修复：创建或更新用户数据
                    if let userData = data.user {
                        var user = User(
                            id: userData.id,
                            name: userData.name,
                            phone: userData.phone,
                            createdAt: Date(),
                            emergencyContacts: [],
                            checkInInterval: .twoDays,
                            notificationsEnabled: true,
                            cloudSyncEnabled: false
                        )
                        // 更新签到间隔（后端返回的是小时数）
                        if let hours = userData.check_in_interval {
                            let interval: CheckInInterval
                            switch hours {
                            case 24: interval = .oneDay
                            case 48: interval = .twoDays
                            case 72: interval = .threeDays
                            case 96: interval = .fourDays
                            case 120: interval = .fiveDays
                            case 144: interval = .sixDays
                            case 168: interval = .sevenDays
                            default: interval = .twoDays
                            }
                            user.checkInInterval = interval
                            userManager.checkInInterval = interval
                        }
                        userManager.currentUser = user
                        _ = userManager.saveUser(user)
                        print("✅ 用户数据已加载：\(user.name)")
                    } else {
                        // 如果后端没有返回用户详细信息，创建基本用户
                        var user = User(
                            id: data.user_id,
                            name: "用户",
                            phone: phone,
                            createdAt: Date(),
                            emergencyContacts: [],
                            checkInInterval: .twoDays,
                            notificationsEnabled: true,
                            cloudSyncEnabled: false
                        )
                        userManager.currentUser = user
                        _ = userManager.saveUser(user)
                        print("✅ 创建基本用户数据")
                    }
                    
                    errorMessage = "登录成功！"
                    showingError = true
                } else {
                    errorMessage = result.error ?? "登录失败"
                    showingError = true
                }
            }
            
        } catch {
            print("❌ 登录失败：\(error)")
            print("  错误域：\(error._domain)")
            print("  错误码：\(error._code)")
            print("  错误描述：\(error.localizedDescription)")
            
            await MainActor.run {
                if error._domain == "Server error" {
                    errorMessage = "服务器错误，请稍后重试"
                } else if error._domain == "API URL not initialized" {
                    errorMessage = "API 未初始化，请检查网络设置"
                } else if error._domain == "Invalid URL" {
                    errorMessage = "服务器地址无效"
                } else {
                    errorMessage = "网络错误：\(error.localizedDescription)"
                }
                showingError = true
            }
        }
    }
    
    // MARK: - 找回密码
    private func resetPasswordWithAPI() async {
        print("🔵 开始密码重置流程...")
        print("  phone: \(phone)")
        print("  verify_code: \(verifyCode)")
        
        do {
            try await DataManager.shared.checkAPIReady()
            guard !DataManager.apiURL.isEmpty else {
                throw NSError(domain: "API URL not initialized", code: -1)
            }
            
            let urlString = "\(DataManager.apiURL)/users.php"
            guard let url = URL(string: urlString) else {
                throw NSError(domain: "Invalid URL", code: -1)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "action": "reset_password",
                "phone": phone,
                "verify_code": verifyCode,
                "new_password": password
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "Invalid response type", code: -1)
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                await MainActor.run {
                    showingResetPassword = false
                    errorMessage = "密码重置成功，请登录"
                    showingError = true
                    loginType = "password"
                }
            } else {
                throw NSError(domain: "Server error", code: httpResponse.statusCode)
            }
            
        } catch {
            print("❌ 密码重置失败：\(error)")
            await MainActor.run {
                errorMessage = "密码重置失败：\(error.localizedDescription)"
                showingError = true
            }
        }
    }
}

// MARK: - 找回密码弹窗
struct ResetPasswordModal: View {
    @Environment(\.dismiss) var dismiss
    @State private var phone = ""
    @State private var verifyCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var countdown = 0
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("找回密码")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top)
                
                Text("通过手机号和验证码重置密码")
                    .foregroundColor(.secondary)
                
                TextField("手机号", text: $phone)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.phonePad)
                
                HStack {
                    TextField("验证码", text: $verifyCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    Button(action: sendVerifyCode) {
                        Text(countdown > 0 ? "\(countdown) 秒" : "获取验证码")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .disabled(countdown > 0 || phone.isEmpty)
                }
                
                SecureField("新密码", text: $newPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("确认密码", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: resetPassword) {
                    Text("重置密码")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "AF52DE"))
                        .cornerRadius(12)
                }
                .disabled(phone.isEmpty || verifyCode.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword)
                
                Spacer()
            }
            .padding(30)
            .navigationTitle("找回密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func sendVerifyCode() {
        guard !phone.isEmpty else { return }
        countdown = 60
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            countdown -= 1
            if countdown <= 0 {
                timer.invalidate()
            }
        }
    }
    
    private func resetPassword() {
        if newPassword != confirmPassword {
            errorMessage = "两次输入的密码不一致"
            showingError = true
            return
        }
        
        if newPassword.count < 6 {
            errorMessage = "密码至少 6 位"
            showingError = true
            return
        }
        
        // TODO: 调用 API
        print("重置密码：phone=\(phone), new_password=\(newPassword)")
    }
}

#Preview {
    AuthView()
}
