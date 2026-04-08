//
//  RegisterView.swift
//  终活
//
//  注册界面
//  职责：用户注册 UI
//

import SwiftUI

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var verifyCode = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var countdown = 0
    @State private var timer: Timer?
    
    // MARK: - 辅助方法
    
    /// 验证手机号格式
    private func isValidPhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        let result = predicate.evaluate(with: phone)
        print("🔍 手机号验证：\(phone) -> \(result)")
        return result
    }
    
    /// 验证密码
    private func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 else { 
            print("🔍 密码验证：长度不足 8 位")
            return false 
        }
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        let result = hasLetter && hasNumber
        print("🔍 密码验证：长度=\(password.count), 有字母=\(hasLetter), 有数字=\(hasNumber) -> \(result)")
        return result
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
    
    // MARK: - 注册逻辑
    
    private func register() async {
        print("🔵🔵🔵 register() 函数被调用！！！")
        print("🔍 当前状态：phone=\(phone), password 长度=\(password.count), confirmPassword=\(confirmPassword)")
        print("🔍 验证结果：isValidPhone=\(isValidPhone(phone)), isValidPassword=\(isValidPassword(password)), 密码匹配=\(password == confirmPassword)")
        
        await MainActor.run {
            isLoading = true
            print("⚙️ isLoading 已设置为 true")
        }
        
        do {
            // 验证输入
            guard isValidPhone(phone) else {
                print("❌ 手机号验证失败")
                throw NSError(domain: "手机号格式错误", code: -1)
            }
            
            guard isValidPassword(password) else {
                print("❌ 密码验证失败")
                throw NSError(domain: "密码至少 8 位，包含字母和数字", code: -1)
            }
            
            guard password == confirmPassword else {
                print("❌ 两次密码不一致")
                throw NSError(domain: "两次输入的密码不一致", code: -1)
            }
            
            guard !verifyCode.isEmpty else {
                print("❌ 验证码为空")
                throw NSError(domain: "请输入验证码", code: -1)
            }
            
            print("✅ 所有验证通过，开始注册请求...")
            
            // 调用注册 API
            let mutation = """
            mutation($name: String!, $phone: String!, $password: String!, $verifyCode: String!) {
                register(name: $name, phone: $phone, password: $password, verifyCode: $verifyCode) {
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
                "name": name,
                "phone": phone,
                "password": password,
                "verifyCode": verifyCode
            ]
            
            let response = try await graphqlAuthRequest(mutation: mutation, variables: variables)
            await handleRegisterSuccess(response)
        } catch {
            handleRegisterError(error)
        }
        
        await MainActor.run { isLoading = false }
    }
    
    /// GraphQL Auth 请求
    private func graphqlAuthRequest(mutation: String, variables: [String: Any]) async throws -> [String: Any] {
        let rawBaseURL = UserDefaults.standard.string(forKey: "lastUsedBaseURL") ?? "https://api.zhonghuo.app"
        let baseURL = NetworkUtils.normalizeBaseURL(rawBaseURL)
        print("🌐 注册请求 URL: \(baseURL)/api/graphql.php")
        print("📦 请求数据：name=\(name), phone=\(phone)")
        
        guard let url = URL(string: "\(baseURL)/api/graphql.php") else {
            print("❌ URL 无效：\(baseURL)/api/graphql.php")
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
        
        print("📤 发送请求...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📥 收到响应：statusCode=\((response as? HTTPURLResponse)?.statusCode ?? -1)")
        
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
    
    /// 处理注册成功
    private func handleRegisterSuccess(_ response: [String: Any]) async {
        guard let data = response["data"] as? [String: Any],
              let registerData = data["register"] as? [String: Any],
              let success = registerData["success"] as? Bool,
              success else {
            print("❌ 注册失败")
            return
        }
        
        print("✅ 注册成功")
        
        // 保存 Token
        if let token = registerData["token"] as? String {
            KeychainManager.shared.saveToken(token)
        }
        
        // 加载用户数据
        let userManager = UserManager.shared
        await userManager.loadUser()
        
        // 通知 HomeStatusView 刷新
        NotificationCenter.default.post(name: NSNotification.Name("CheckInDidComplete"), object: nil)
        
        // 自动关闭注册页面
        await MainActor.run {
            isPresented = false
        }
        
        print("🟢 注册状态已更新")
    }
    
    /// 处理注册错误
    private func handleRegisterError(_ error: Error) {
        print("❌ 注册失败：\(error.localizedDescription)")
        
        let errorMsg = error.localizedDescription
        if errorMsg.contains("已注册") || errorMsg.contains("已经存在") {
            errorMessage = "账号已注册，请登录"
        } else if errorMsg.contains("手机号") {
            errorMessage = "手机号格式错误"
        } else if errorMsg.contains("密码") {
            errorMessage = "密码至少 8 位，包含字母和数字"
        } else if errorMsg.contains("不一致") {
            errorMessage = "两次输入的密码不一致"
        } else {
            errorMessage = "注册失败，请稍后重试"
        }
        showingError = true
    }
    
    // MARK: - 视图
    
    var body: some View {
        VStack(spacing: 30) {
            // Logo
            VStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "AF52DE"))
                
                Text("终活")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(hex: "AF52DE"))
                
                Text("注册账号")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // 注册表单
            VStack(spacing: 20) {
                TextField("姓名", text: $name)
                    .textFieldStyle(CustomTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .font(.system(size: 18, weight: .medium))
                
                TextField("手机号码", text: $phone)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.phonePad)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .font(.system(size: 18, weight: .medium))
                
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
                
                SecureField("设置密码（8 位以上）", text: $password)
                    .textFieldStyle(CustomTextFieldStyle())
                    .font(.system(size: 18, weight: .medium))
                
                SecureField("确认密码", text: $confirmPassword)
                    .textFieldStyle(CustomTextFieldStyle())
                    .font(.system(size: 18, weight: .medium))
                
                Button(action: {
                    print("🔴🔴🔴 立即注册按钮被点击！！！")
                    Task { @MainActor in
                        print("🔴 Task 开始执行")
                        await register()
                        print("🔴 Task 执行完成")
                    }
                }, label: {
                    Text("立即注册")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "AF52DE"))
                        .cornerRadius(12)
                })
                .disabled(false)  // 强制不禁用
                .opacity(isLoading ? 0.5 : 1)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // 切换到登录
            HStack {
                Text("已经有账号？")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                
                Button(action: { isPresented = false }) {
                    Text("立即登录")
                        .foregroundColor(Color(hex: "AF52DE"))
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60)
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("错误"),
                message: Text(errorMessage),
                dismissButton: .default(Text("确定"))
            )
        }
        .background(Color("BackgroundColor"))
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            print("🎹 点击背景隐藏键盘")
            hideKeyboard()
        }
    }
    
    // MARK: --actions
    
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
    RegisterView(isPresented: .constant(true))
}
