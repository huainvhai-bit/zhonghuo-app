//
//  AuthView.swift
//  终活
//
//  Created on 2026-03-18.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var name = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var verifyCode = ""
    @State private var loginType = "password" // password | verify_code
    @State private var isRegistering = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var countdown = 0
    @State private var isSendingCode = false
    
    var body: some View {
        NavigationView {
            Form {
                if isRegistering {
                    Section("注册信息") {
                        TextField("用户名", text: $name)
                        TextField("手机号", text: $phone)
                            .keyboardType(.phonePad)
                        SecureField("密码", text: $password)
                    }
                } else {
                    Section("登录信息") {
                        TextField("手机号", text: $phone)
                            .keyboardType(.phonePad)
                        
                        Picker("登录方式", selection: $loginType) {
                            Text("密码登录").tag("password")
                            Text("验证码登录").tag("verify_code")
                        }
                        
                        if loginType == "password" {
                            SecureField("密码", text: $password)
                        } else {
                            HStack {
                                TextField("验证码", text: $verifyCode)
                                    .keyboardType(.numberPad)
                                
                                Button(action: {
                                    Task {
                                        await sendVerifyCode()
                                    }
                                }) {
                                    if isSendingCode {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else if countdown > 0 {
                                        Text("\(countdown)秒")
                                            .foregroundColor(.gray)
                                    } else {
                                        Text("获取验证码")
                                    }
                                }
                                .disabled(isSendingCode || countdown > 0 || phone.isEmpty)
                            }
                        }
                    }
                }
                
                Section {
                    Button(isRegistering ? "注册" : "登录") {
                        Task {
                            if isRegistering {
                                await registerWithAPI()
                            } else {
                                await loginWithAPI()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button(isRegistering ? "已有账号？去登录" : "没有账号？去注册") {
                        isRegistering.toggle()
                        resetForm()
                    }
                }
            }
            .navigationTitle(isRegistering ? "注册" : "登录")
            .alert("提示", isPresented: $showingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                resetForm()
            }
        }
    }
    
    private func resetForm() {
        name = ""
        phone = ""
        password = ""
        verifyCode = ""
        countdown = 0
    }
    
    // MARK: - 发送验证码
    private func sendVerifyCode() async {
        guard !phone.isEmpty else {
            errorMessage = "请输入手机号"
            showingError = true
            return
        }
        
        isSendingCode = true
        
        do {
            try await DataManager.shared.checkAPIReady()
            guard !DataManager.apiURL.isEmpty else {
                throw NSError(domain: "API URL not initialized", code: -1)
            }
            
            let urlString = "\(DataManager.apiURL)/sms.php"
            guard let url = URL(string: urlString) else {
                throw NSError(domain: "Invalid URL", code: -1)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let body: [String: Any] = [
                "action": "send",
                "phone": phone,
                "type": isRegistering ? "register" : "login"
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 60
            let session = URLSession(configuration: config)
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "Invalid response type", code: -1)
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let responseString = String(data: data, encoding: .utf8) ?? "无法解析"
                throw NSError(domain: "HTTP Error \(httpResponse.statusCode): \(responseString)", code: httpResponse.statusCode)
            }
            
            let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let success = jsonResponse?["success"] as? Bool ?? false
            
            if success {
                countdown = 60
                errorMessage = "验证码已发送（测试：123456）"
                showingError = true
                
                // 倒计时
                while countdown > 0 {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    countdown -= 1
                }
            } else {
                errorMessage = jsonResponse?["error"] as? String ?? "发送失败"
                showingError = true
            }
            
        } catch {
            errorMessage = "发送失败：\(error.localizedDescription)"
            showingError = true
        }
        
        isSendingCode = false
    }
    
    // MARK: - 统一 API 请求处理
    private func authRequest(action: String, body: [String: Any]) async throws -> AuthResponse {
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
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        let session = URLSession(configuration: config)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid response type", code: -1)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            let responseString = String(data: data, encoding: .utf8) ?? "无法解析"
            throw NSError(domain: "HTTP Error \(httpResponse.statusCode): \(responseString)", code: httpResponse.statusCode)
        }
        
        // 使用 JSONSerialization 解析（更灵活）
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "Invalid JSON format", code: -1)
        }
        
        return AuthResponse(json: json)
    }
    
    // MARK: - 注册
    private func registerWithAPI() async {
        guard !name.isEmpty else {
            errorMessage = "请输入用户名"
            showingError = true
            return
        }
        
        guard !phone.isEmpty else {
            errorMessage = "请输入手机号"
            showingError = true
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "请输入密码"
            showingError = true
            return
        }
        
        do {
            let body: [String: Any] = [
                "action": "register",
                "name": name,
                "phone": phone,
                "password": password
            ]
            
            let result = try await authRequest(action: "register", body: body)
            
            if result.success {
                await handleAuthSuccess(result)
                errorMessage = "注册成功！"
                showingError = true
            } else {
                errorMessage = result.error ?? "注册失败"
                showingError = true
            }
        } catch {
            errorMessage = "注册失败：\(error.localizedDescription)"
            showingError = true
        }
    }
    
    // MARK: - 登录
    private func loginWithAPI() async {
        guard !phone.isEmpty else {
            errorMessage = "请输入手机号"
            showingError = true
            return
        }
        
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
            
            let result = try await authRequest(action: "login", body: body)
            
            if result.success {
                await handleAuthSuccess(result)
                errorMessage = "登录成功！"
                showingError = true
            } else {
                errorMessage = result.error ?? "登录失败"
                showingError = true
            }
        } catch {
            errorMessage = "登录失败：\(error.localizedDescription)"
            showingError = true
        }
    }
    
    // MARK: - 处理认证成功
    private func handleAuthSuccess(_ result: AuthResponse) async {
        guard let data = result.data else { return }
        
        // 保存 token
        UserDefaults.standard.set(data.token, forKey: "userToken")
        UserDefaults.standard.set(data.user_id, forKey: "userId")
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        
        // 更新 UserManager
        userManager.isLoggedIn = true
        
        // 创建用户数据
        if let userData = data.user {
            var user = User(
                id: userData.id ?? data.user_id,
                name: userData.name,
                phone: userData.phone,
                createdAt: Date(),
                emergencyContacts: [],
                checkInInterval: .twoDays,
                notificationsEnabled: true,
                cloudSyncEnabled: false
            )
            
            // 处理签到间隔（可能是 String 或 Int）
            if let intervalValue = userData.check_in_interval {
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

// MARK: - 统一的响应模型
struct AuthResponse {
    let success: Bool
    let message: String?
    let error: String?
    let data: AuthData?
    
    init(json: [String: Any]) {
        self.success = json["success"] as? Bool ?? false
        self.message = json["message"] as? String
        self.error = json["error"] as? String
        
        if let dataDict = json["data"] as? [String: Any] {
            self.data = AuthData(dict: dataDict)
        } else {
            self.data = nil
        }
    }
    
    struct AuthData {
        let token: String
        let user_id: String
        let is_new: Bool?
        let user: UserData?
        
        init(dict: [String: Any]) {
            self.token = dict["token"] as? String ?? ""
            self.user_id = dict["user_id"] as? String ?? ""
            self.is_new = dict["is_new"] as? Bool
            
            if let userDict = dict["user"] as? [String: Any] {
                self.user = UserData(dict: userDict)
            } else {
                self.user = nil
            }
        }
    }
    
    struct UserData {
        let id: String?
        let name: String
        let phone: String
        let check_in_interval: Any?  // 可能是 String 或 Int
        let last_check_in_date: String?
        
        init(dict: [String: Any]) {
            self.id = dict["id"] as? String
            self.name = dict["name"] as? String ?? ""
            self.phone = dict["phone"] as? String ?? ""
            self.check_in_interval = dict["check_in_interval"]  // Any? 兼容两种类型
            self.last_check_in_date = dict["last_check_in_date"] as? String
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(UserManager.shared)
}
