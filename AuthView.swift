//
//  AuthView.swift
//  终活
//
//  用户注册和登录界面
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var userManager: UserManager
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
                    .disabled(isLoading || (isRegistering ? (phone.isEmpty || name.isEmpty || password.isEmpty || verifyCode.isEmpty) : (loginType == "password" ? (phone.isEmpty || password.isEmpty) : (phone.isEmpty || verifyCode.isEmpty))))
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
            .alert("提示", isPresented: $showingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingResetPassword) {
                ResetPasswordView()
            }
            .onAppear {
                timer?.invalidate()
                timer = nil
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
        
        // 执行登录/注册
        isLoading = true
        if isRegistering {
            Task {
                await register()
                isLoading = false
            }
        } else {
            Task {
                await login()
                isLoading = false
            }
        }
    }
    
    // MARK: - API 请求
    
    private func apiRequest(action: String, body: [String: Any]) async throws -> [String: Any] {
        try await DataManager.shared.checkAPIReady()
        guard !DataManager.apiURL.isEmpty else {
            throw NSError(domain: "API 未初始化", code: -1)
        }
        
        let urlString = "\(DataManager.apiURL)/users.php"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "URL 无效", code: -1)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        let session = URLSession(configuration: config)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "响应类型错误", code: -1)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            let responseString = String(data: data, encoding: .utf8) ?? "无法解析"
            throw NSError(domain: "HTTP 错误：\(httpResponse.statusCode) - \(responseString)", code: httpResponse.statusCode)
        }
        
        // 使用 JSONSerialization 解析（更灵活，不要求严格类型匹配）
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "JSON 解析失败", code: -1)
        }
        
        return json
    }
    
    private func register() async {
        do {
            let body: [String: Any] = [
                "action": "register",
                "name": name,
                "phone": phone,
                "password": password
            ]
            
            let json = try await apiRequest(action: "register", body: body)
            
            let success = json["success"] as? Bool ?? false
            
            if success {
                await handleAuthSuccess(json)
                errorMessage = "注册成功！"
                showingError = true
            } else {
                errorMessage = json["error"] as? String ?? "注册失败"
                showingError = true
            }
        } catch {
            errorMessage = "注册失败：\(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func login() async {
        do {
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
            
            let json = try await apiRequest(action: "login", body: body)
            
            let success = json["success"] as? Bool ?? false
            
            if success {
                await handleAuthSuccess(json)
                errorMessage = "登录成功！"
                showingError = true
            } else {
                errorMessage = json["error"] as? String ?? "登录失败"
                showingError = true
            }
        } catch {
            errorMessage = "登录失败：\(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func handleAuthSuccess(_ json: [String: Any]) async {
        guard let data = json["data"] as? [String: Any] else { return }
        
        let token = data["token"] as? String ?? ""
        let userId = data["user_id"] as? String ?? ""
        
        // 保存 token
        UserDefaults.standard.set(token, forKey: "userToken")
        UserDefaults.standard.set(userId, forKey: "userId")
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        
        // 更新 UserManager
        userManager.isLoggedIn = true
        
        // 创建用户数据
        if let userDict = data["user"] as? [String: Any] {
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
            
            // 处理签到间隔（可能是 String 或 Int）
            if let intervalValue = userDict["check_in_interval"] {
                let hours: Int
                if let intVal = intervalValue as? Int {
                    hours = intVal
                } else if let strVal = intervalValue as? String, let intVal = Int(strVal) {
                    hours = intVal
                } else {
                    hours = 48
                }
                
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
            }
            
            userManager.currentUser = user
            _ = userManager.saveUser(user)
        }
    }
}

// MARK: - ResetPasswordView

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
            .alert("提示", isPresented: $showingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
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
