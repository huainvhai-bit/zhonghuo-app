//
//  LoginView.swift
//  终活
//
//  登录界面
//  职责：手机号 + 密码/验证码 登录 UI
//

import SwiftUI
import os.log

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userManager = UserManager.shared
    
    @State private var phone = ""
    @State private var password = ""
    @State private var verifyCode = ""
    @State private var loginType: String = "password" // "password" or "verify_code"
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var countdown = 0
    @State private var timer: Timer?
    @State private var showPassword = false
    
    // MARK: - 辅助方法
    
    /// 验证手机号格式
    private func isValidPhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: phone)
    }
    
    /// 启动倒计时
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer?.invalidate()
            }
        }
    }
    
    // MARK: - 网络请求
    
    /// 发送登录请求（Password）
    private func loginWithPassword() async {
        isLoading = true
        
        do {
            let mutation = """
            mutation($phone: String!, $password: String!) {
                login(phone: $phone, password: $password) {
                    success
                    token
                    user {
                        id
                        name
                        phone
                    }
                }
            }
            """
            
            let variables: [String: Any] = [
                "phone": phone,
                "password": password
            ]
            
            let response = try await graphqlAuthRequest(mutation: mutation, variables: variables)
            await handleAuthSuccess(response)
        } catch {
            handleAuthError(error, context: "登录（密码）")
        }
        
        await MainActor.run { isLoading = false }
    }
    
    /// 发送登录请求（验证码）
    private func loginWithCode() async {
        isLoading = true
        
        do {
            let mutation = """
            mutation($phone: String!, $verifyCode: String!) {
                login(phone: $phone, verifyCode: $verifyCode) {
                    success
                    token
                    user {
                        id
                        name
                        phone
                    }
                }
            }
            """
            
            let variables: [String: Any] = [
                "phone": phone,
                "verifyCode": verifyCode
            ]
            
            let response = try await graphqlAuthRequest(mutation: mutation, variables: variables)
            await handleAuthSuccess(response)
        } catch {
            handleAuthError(error, context: "登录（验证码）")
        }
        
        await MainActor.run { isLoading = false }
    }
    
    /// GraphQL Auth 请求
    private func graphqlAuthRequest(mutation: String, variables: [String: Any]) async throws -> [String: Any] {
        let rawBaseURL = UserDefaults.standard.string(forKey: "lastUsedBaseURL") ?? "https://api.zhonghuo.app"
        let baseURL = NetworkUtils.normalizeBaseURL(rawBaseURL)
        guard let url = URL(string: "\(baseURL)/api/graphql.php") else {
            throw NSError(domain: "Invalid URL", code: -1)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "query": mutation,
            "variables": variables
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid Response", code: -1)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "HTTP Error", code: httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "JSON Parse Error", code: -1)
        }
        
        if let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
            let message = errors[0]["message"] as? String ?? "GraphQL Error"
            throw NSError(domain: message, code: -1)
        }
        
        return json
    }
    
    /// 处理登录成功
    private func handleAuthSuccess(_ response: [String: Any]) async {
        guard let data = response["data"] as? [String: Any],
              let loginData = data["login"] as? [String: Any],
              let success = loginData["success"] as? Bool,
              success else {
            print("❌ 登录失败")
            return
        }
        
        print("✅ 登录成功")
        
        // 保存 Token
        if let token = loginData["token"] as? String {
            KeychainManager.shared.saveToken(token)
        }
        
        // 保存用户 ID
        if let user = loginData["user"] as? [String: Any],
           let userId = user["id"] as? String {
            KeychainManager.shared.saveUserId(userId)
        }
        
        // 加载用户数据
        await userManager.loadUser()
        
        // 通知 HomeStatusView 刷新
        NotificationCenter.default.post(name: NSNotification.Name("CheckInDidComplete"), object: nil)
        
        print("🟢 登录状态已更新")
    }
    
    /// 处理登录错误
    private func handleAuthError(_ error: Error, context: String) {
        print("❌ \(context) 失败：\(error.localizedDescription)")
        
        let errorMsg = error.localizedDescription
        if errorMsg.contains("未注册") || errorMsg.contains("不存在") {
            errorMessage = "账号不存在，请先注册"
        } else if errorMsg.contains("密码") || errorMsg.contains("错误") {
            errorMessage = "密码错误，请重试"
        } else {
            errorMessage = "登录失败，请稍后重试"
        }
        showingError = true
    }
    
    // MARK: - 视图
    
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
                
                // 登录表单
                VStack(spacing: 20) {
                    TextField("手机号码", text: $phone)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.phonePad)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(size: 18, weight: .medium))
                    
                    if loginType == "password" {
                        SecureField("密码", text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                            .font(.system(size: 18, weight: .medium))
                    } else {
                        HStack {
                            TextField("验证码", text: $verifyCode)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.numberPad)
                                .font(.system(size: 18, weight: .medium))
                            
                            Button(action: requestVerifyCode) {
                                Text(countdown > 0 ? "\(countdown)s" : "获取验证码")
                                    .foregroundColor(countdown > 0 ? .gray : Color(hex: "AF52DE"))
                                    .font(.system(size: 16))
                            }
                            .disabled(countdown > 0 || phone.isEmpty)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            if loginType == "password" {
                                await loginWithPassword()
                            } else {
                                await loginWithCode()
                            }
                        }
                    }) {
                        Text("登录")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(hex: "AF52DE"))
                            .cornerRadius(12)
                    }
                    .disabled(!isValidPhone(phone) || (loginType == "password" && password.isEmpty))
                    .opacity(isLoading ? 0.5 : 1)
                }
                .padding(.horizontal, 24)
                .alert(isPresented: $showingError) {
                    Alert(
                        title: Text("错误"),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("确定"))
                    )
                }
                
                // 切换登录方式
                HStack {
                    Button(action: toggleLoginType) {
                        Text(loginType == "password" ? "使用验证码登录" : "使用密码登录")
                            .foregroundColor(Color(hex: "AF52DE"))
                            .font(.system(size: 16))
                    }
                    
                    Spacer()
                    
                    Button(action: { showingResetPassword = true }) {
                        Text("忘记密码？")
                            .foregroundColor(Color(hex: "AF52DE"))
                            .font(.system(size: 16))
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // 切换到注册
                HStack {
                    Text("还没有账号？")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                    
                    Button(action: { 
                        print("🔵🔵🔵 LoginView: 点击立即注册")
                        NSLog("🔵🔵🔵 LoginView: 点击立即注册")
                        os_log("🔵🔵🔵 LoginView: 点击立即注册", log: .default, type: .error)
                        isRegistering = true 
                        print("🔵 isRegistering 已设置为：\(isRegistering)")
                    }) {
                        Text("立即注册")
                            .foregroundColor(Color(hex: "AF52DE"))
                            .font(.system(size: 16, weight: .bold))
                    }
                    .contentShape(Rectangle())  // 🔴 确保整个区域可点击
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
            .background(Color("BackgroundColor"))
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                hideKeyboard()
            }
        }
        .fullScreenCover(isPresented: $isRegistering) {
            RegisterView(isPresented: $isRegistering)
        }
        .sheet(isPresented: $showingResetPassword) {
            ResetPasswordView(isPresented: $showingResetPassword)
        }
    }
    
    // MARK: --controls
    
    @State private var isRegistering = false
    @State private var showingResetPassword = false
    
    private func toggleLoginType() {
        loginType = loginType == "password" ? "verify_code" : "password"
        password = ""
        verifyCode = ""
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func requestVerifyCode() {
        guard isValidPhone(phone) else {
            errorMessage = "手机号格式错误"
            showingError = true
            return
        }
        
        countdown = 60
        startTimer()
        
        // 调用发送验证码 API
        Task {
            await sendVerifyCode()
        }
    }
    
    private func sendVerifyCode() async {
        // TODO: 实现发送验证码逻辑
        print("📤 发送验证码到 \(phone)")
    }
}

#Preview {
    LoginView()
}
