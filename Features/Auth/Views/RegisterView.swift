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
    @StateObject private var captchaService = AppCaptchaService(purpose: "register")
    
    @State private var name = ""
    @State private var account = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var captchaInput = ""
    @State private var selectedSecurityQuestion = Self.securityQuestions.first ?? ""
    @State private var securityAnswer = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""

    private static let securityQuestions = [
        "我的第一所学校名称是？",
        "我最喜欢的城市是？",
        "我母亲的姓氏是？",
        "我最喜欢的电影是？",
        "我童年最好的朋友名字是？"
    ]
    private var securityQuestions: [String] { Self.securityQuestions }
    
    // MARK: - 辅助方法
    
    /// 验证账号格式
    private func isValidAccount(_ account: String) -> Bool {
        let pattern = "^[^\\s]{4,30}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        let result = predicate.evaluate(with: account)
        print("🔍 账号验证：\(account) -> \(result)")
        return result
    }

    /// 验证手机号格式
    private func isValidPhone(_ phone: String) -> Bool {
        guard !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return true }
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
        print("🔍 密码验证：长度已检查")
        return result
    }

    private func clearError() {
        if showingError {
            showingError = false
            errorMessage = ""
        }
    }
    
    // MARK: - 注册逻辑
    
    private func register() async {
        print("🔵🔵🔵 register() 函数被调用！！！")
        print("🔍 当前状态：验证中")
        print("🔍 验证结果：已检查")
        
        await MainActor.run {
            isLoading = true
            print("⚙️ isLoading 已设置为 true")
        }
        
        do {
            // 验证输入
            let trimmedAccount = account.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)

            guard isValidAccount(trimmedAccount) else {
                print("❌ 账号验证失败")
                throw NSError(domain: "账号格式错误", code: -1)
            }

            guard isValidPhone(trimmedPhone) else {
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

            guard !captchaInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("❌ 图形验证码为空")
                throw NSError(domain: "请输入图形验证码", code: -1)
            }

            guard !securityAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("❌ 密保答案为空")
                throw NSError(domain: "请输入密保答案", code: -1)
            }
            
            print("✅ 所有验证通过，开始注册请求...")
            
            // 调用注册 API
            let mutation = """
            mutation($account: String!, $name: String!, $phone: String, $password: String!, $captcha: String!, $captchaPurpose: String!, $securityQuestion: String!, $securityAnswer: String!) {
                register(account: $account, name: $name, phone: $phone, password: $password, captcha: $captcha, captchaPurpose: $captchaPurpose, securityQuestion: $securityQuestion, securityAnswer: $securityAnswer) {
                    success
                    token
                    user {
                        id
                        account
                        name
                        phone
                    }
                }
            }
            """
            
            let variables: [String: Any] = [
                "account": trimmedAccount,
                "name": name,
                "phone": trimmedPhone.isEmpty ? NSNull() : trimmedPhone,
                "password": password,
                "captcha": captchaInput.trimmingCharacters(in: .whitespacesAndNewlines),
                "captchaPurpose": "register",
                "securityQuestion": selectedSecurityQuestion,
                "securityAnswer": securityAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
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
        let rawBaseURL = UserDefaults.standard.string(forKey: "lastUsedBaseURL") ?? "8.136.41.211:3395"
        let baseURL = NetworkUtils.normalizeBaseURL(rawBaseURL)
        print("🌐 注册请求 URL: \(baseURL)/api/graphql.php")
        print("📦 请求数据：account=\(account), name=\(name), phone=\(phone)")
        
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
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
            let message = errors[0]["message"] as? String ?? "GraphQL Error"
            throw NSError(domain: message, code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = bodyErrorMessage(from: data, statusCode: httpResponse.statusCode, context: "注册")
            throw NSError(domain: message, code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
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
        // 先检查是否有错误
        if let errors = response["errors"] as? [[String: Any]], !errors.isEmpty {
            let message = errors[0]["message"] as? String ?? "注册失败"
            print("❌ 注册失败：\(message)")
            await MainActor.run {
                errorMessage = message
                showingError = true
            }
            return
        }
        
        // 检查响应数据
        guard let data = response["data"] as? [String: Any],
              let registerData = data["register"] as? [String: Any],
              let success = registerData["success"] as? Bool,
              success else {
            let message = authMessage(from: response, fallback: "注册失败，请稍后重试")
            print("❌ 注册失败")
            await MainActor.run {
                errorMessage = message
                showingError = true
            }
            return
        }
        
        print("✅ 注册成功")
        
        // 保存 Token
        if let token = registerData["token"] as? String {
            KeychainManager.shared.saveToken(token)
        }

        if let user = registerData["user"] as? [String: Any] {
            if let userId = user["id"] as? String {
                KeychainManager.shared.saveUserId(userId)
            }
            if let account = user["account"] as? String, !account.isEmpty {
                KeychainManager.shared.saveUserAccount(account)
            }
            if let phone = user["phone"] as? String {
                KeychainManager.shared.saveUserPhone(phone)
            }
        }
        
        // 加载用户数据
        let userManager = UserManager.shared
        userManager.loadUser()

        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
        
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
        DispatchQueue.main.async {
            // ✅ 优先使用错误码进行精确匹配
            if errorMsg.contains("PHONE_EXISTS:") {
                self.errorMessage = "该手机号已注册，请直接登录"
            } else if errorMsg.contains("ACCOUNT_EXISTS:") {
                self.errorMessage = "该账号已注册，请直接登录"
            } else if errorMsg.contains("账号格式") {
                self.errorMessage = "账号格式错误，请输入 4-30 位非空白字符"
            } else if errorMsg.contains("已注册") || errorMsg.contains("已经存在") {
                self.errorMessage = "账号已注册，请登录"
            } else if errorMsg.contains("手机号") || errorMsg.contains("手机号格式") {
                self.errorMessage = "手机号格式错误"
            } else if errorMsg.contains("密码") && errorMsg.contains("不一致") {
                self.errorMessage = "两次输入的密码不一致"
            } else if errorMsg.contains("密码") {
                self.errorMessage = "密码至少 8 位，包含字母和数字"
            } else if errorMsg.contains("验证码") {
                self.errorMessage = "图形验证码错误或已过期，请刷新后重试"
                self.captchaInput = ""
                Task { await self.captchaService.loadCaptcha() }
            } else if errorMsg.contains("密保") {
                self.errorMessage = "密保问题或答案错误"
            } else if errorMsg.contains("网络") || errorMsg.contains("network") || errorMsg.contains("timed out") {
                self.errorMessage = "网络连接失败，请检查网络"
            } else {
                self.errorMessage = "注册失败，请稍后重试"
            }
            self.showingError = true
        }
    }

    private func authMessage(from response: [String: Any], fallback: String) -> String {
        if let errors = response["errors"] as? [[String: Any]], let first = errors.first {
            return first["message"] as? String ?? fallback
        }

        if let data = response["data"] as? [String: Any],
           let registerData = data["register"] as? [String: Any],
           let message = registerData["message"] as? String,
           !message.isEmpty {
            return message
        }

        return fallback
    }

    private func bodyErrorMessage(from data: Data, statusCode: Int, context: String) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let errors = json["errors"] as? [[String: Any]], let first = errors.first {
                return first["message"] as? String ?? "\(context)失败，请稍后重试"
            }
            if let message = json["message"] as? String, !message.isEmpty {
                return message
            }
        }

        if let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty {
            return text
        }

        switch statusCode {
        case 401: return "当前账号无权限操作"
        case 403: return "当前账号无权限操作"
        case 500: return "\(context)失败，请稍后重试"
        case 503: return "服务器暂不可用，请稍后重试"
        default: return "服务器返回 \(statusCode)"
        }
    }
    
    // MARK: - 视图
    
    var body: some View {
        NavigationView {
            if #available(iOS 16.0, *) {
                ScrollView {
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
                    
                    // 注册表单
                    VStack(spacing: 20) {
                        TextField("姓名", text: $name)
                            .textFieldStyle(CustomTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(size: 18, weight: .medium))
                        
                        TextField("账号（4-30 位）", text: $account)
                            .textFieldStyle(CustomTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(size: 18, weight: .medium))
                            .onChange(of: account) { _ in self.clearError() }
                        
                        TextField("手机号（选填）", text: $phone)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.phonePad)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(size: 18, weight: .medium))
                            .onChange(of: phone) { _ in self.clearError() }
                        Text("如果你不想使用手机号，可以只填写账号。")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 12) {
                            TextField("验证码", text: $captchaInput)
                                .textFieldStyle(CustomTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 18, weight: .medium))
                            
                            Button(action: {
                                Task {
                                    await captchaService.loadCaptcha()
                                    captchaInput = ""
                                }
                            }) {
                                Group {
                                    if let image = captchaService.image {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 120, height: 44)
                                            .cornerRadius(8)
                                    } else if captchaService.isLoading {
                                        ProgressView()
                                            .frame(width: 120, height: 44)
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray5))
                                            .frame(width: 120, height: 44)
                                            .overlay(Text("点击刷新").font(.system(size: 13)).foregroundColor(.secondary))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        SecureField("设置密码（8 位以上）", text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                            .font(.system(size: 18, weight: .medium))
                        
                        SecureField("确认密码", text: $confirmPassword)
                            .textFieldStyle(CustomTextFieldStyle())
                            .font(.system(size: 18, weight: .medium))

                        VStack(alignment: .leading, spacing: 10) {
                            Text("找回密码唯一方式")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)

                            Text("注册时必须选择并牢记密保问题与答案。以后忘记密码，只能通过它找回。")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)

                            Picker("密保问题", selection: $selectedSecurityQuestion) {
                                ForEach(securityQuestions, id: \.self) { question in
                                    Text(question).tag(question)
                                }
                            }
                            .pickerStyle(.menu)

                            TextField("密保答案", text: $securityAnswer)
                                .textFieldStyle(CustomTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 18, weight: .medium))
                        }
                        .padding(.top, 4)
                        
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
                        .contentShape(Rectangle())
                        .disabled(false)
                        .opacity(isLoading ? 0.5 : 1)
                    }
                    .padding(.horizontal, 24)
                    
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
                    .padding(.bottom, 40)
                }
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
                .alert(isPresented: $showingError) {
                    Alert(
                        title: Text("错误"),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("确定"))
                    )
                }
                .background(Color("BackgroundColor"))
                .navigationBarTitleDisplayMode(.inline)
                .task {
                    if captchaService.image == nil {
                        await captchaService.loadCaptcha()
                    }
                }
            } else {
                ScrollView {
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
                        
                        // 注册表单
                        VStack(spacing: 20) {
                            TextField("姓名", text: $name)
                                .textFieldStyle(CustomTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 18, weight: .medium))
                            
                            TextField("账号（4-30 位）", text: $account)
                                .textFieldStyle(CustomTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 18, weight: .medium))
                                .onChange(of: account) { _ in self.clearError() }
                            
                            TextField("手机号（选填）", text: $phone)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.phonePad)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 18, weight: .medium))
                                .onChange(of: phone) { _ in self.clearError() }
                            Text("如果你不想使用手机号，可以只填写账号。")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 12) {
                                TextField("验证码", text: $captchaInput)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .font(.system(size: 18, weight: .medium))
                                
                                Button(action: {
                                    Task {
                                        await captchaService.loadCaptcha()
                                        captchaInput = ""
                                    }
                                }) {
                                    Group {
                                        if let image = captchaService.image {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 120, height: 44)
                                                .cornerRadius(8)
                                        } else if captchaService.isLoading {
                                            ProgressView()
                                                .frame(width: 120, height: 44)
                                        } else {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(.systemGray5))
                                                .frame(width: 120, height: 44)
                                                .overlay(Text("点击刷新").font(.system(size: 13)).foregroundColor(.secondary))
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }

                            SecureField("设置密码（8 位以上）", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                                .font(.system(size: 18, weight: .medium))
                            
                            SecureField("确认密码", text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                                .font(.system(size: 18, weight: .medium))

                            VStack(alignment: .leading, spacing: 10) {
                                Text("找回密码唯一方式")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)

                                Text("注册时必须选择并牢记密保问题与答案。以后忘记密码，只能通过它找回。")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)

                                Picker("密保问题", selection: $selectedSecurityQuestion) {
                                    ForEach(securityQuestions, id: \.self) { question in
                                        Text(question).tag(question)
                                    }
                                }
                                .pickerStyle(.menu)

                                TextField("密保答案", text: $securityAnswer)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .font(.system(size: 18, weight: .medium))
                            }
                            .padding(.top, 4)
                            
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
                            .contentShape(Rectangle())
                            .disabled(false)
                            .opacity(isLoading ? 0.5 : 1)
                        }
                        .padding(.horizontal, 24)
                        
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
                        .padding(.bottom, 40)
                    }
                    .frame(maxWidth: .infinity)
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
                .task {
                    if captchaService.image == nil {
                        await captchaService.loadCaptcha()
                    }
                }
            }
        }
    }
}

#Preview {
    RegisterView(isPresented: .constant(true))
}
