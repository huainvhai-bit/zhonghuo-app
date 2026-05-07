//
//  RegisterView.swift
//  安心助手
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
    @ObservedObject private var languageManager = AppLanguageManager.shared
    
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

    private static var securityQuestions: [String] {
        [
            L10n.text("我的第一所学校名称是？", en: "What was the name of my first school?", ja: "最初の学校の名前は？", ko: "내 첫 번째 학교 이름은?"),
            L10n.text("我最喜欢的城市是？", en: "What is my favorite city?", ja: "一番好きな都市は？", ko: "내가 가장 좋아하는 도시는?"),
            L10n.text("我母亲的姓氏是？", en: "What is my mother's maiden name?", ja: "母の旧姓は？", ko: "어머니의 성은?"),
            L10n.text("我最喜欢的电影是？", en: "What is my favorite movie?", ja: "一番好きな映画は？", ko: "내가 가장 좋아하는 영화는?"),
            L10n.text("我童年最好的朋友名字是？", en: "What is the name of my childhood best friend?", ja: "子どもの頃の親友の名前は？", ko: "어릴 때 가장 친했던 친구의 이름은?")
        ]
    }
    private var securityQuestions: [String] { Self.securityQuestions }

    private func captchaFrameWidth(for availableWidth: CGFloat) -> CGFloat {
        let preferred = availableWidth * 0.38
        return max(150, min(preferred, 240))
    }
    
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
                throw NSError(domain: L10n.text("账号格式错误，请输入 4-30 位非空白字符", en: "Invalid account format. Use 4-30 non-space characters.", ja: "アカウント形式が正しくありません。4〜30文字の空白以外を入力してください。", ko: "계정 형식이 올바르지 않습니다. 공백이 없는 4~30자를 입력하세요."), code: -1)
            }

            guard isValidPhone(trimmedPhone) else {
                print("❌ 手机号验证失败")
                throw NSError(domain: L10n.text("手机号格式错误", en: "Invalid phone format.", ja: "電話番号の形式が正しくありません。", ko: "휴대폰 번호 형식이 올바르지 않습니다."), code: -1)
            }
            
            guard isValidPassword(password) else {
                print("❌ 密码验证失败")
                throw NSError(domain: L10n.text("密码至少 8 位，包含字母和数字", en: "Password must be at least 8 characters and include letters and numbers.", ja: "パスワードは8文字以上で、英字と数字を含めてください。", ko: "비밀번호는 8자 이상이며 문자와 숫자를 포함해야 합니다."), code: -1)
            }
            
            guard password == confirmPassword else {
                print("❌ 两次密码不一致")
                throw NSError(domain: L10n.text("两次输入的密码不一致", en: "The two passwords do not match.", ja: "2つのパスワードが一致しません。", ko: "두 비밀번호가 일치하지 않습니다."), code: -1)
            }

            guard !captchaInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("❌ 图形验证码为空")
                throw NSError(domain: L10n.text("请输入图形验证码", en: "Please enter the captcha.", ja: "画像認証を入力してください。", ko: "이미지 인증을 입력하세요."), code: -1)
            }

            guard !securityAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("❌ 密保答案为空")
                throw NSError(domain: L10n.text("请输入密保答案", en: "Please enter the security answer.", ja: "秘密の答えを入力してください。", ko: "보안 답변을 입력하세요."), code: -1)
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
        let rawBaseURL = UserDefaults.standard.string(forKey: "lastUsedBaseURL") ?? "zhonghuo.zhonghuo.xyz"
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
            let message = authMessage(from: response, fallback: L10n.text("注册失败，请稍后重试", en: "Registration failed. Please try again later.", ja: "登録に失敗しました。後でもう一度お試しください。", ko: "등록에 실패했습니다. 잠시 후 다시 시도하세요."))
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
            if errorMsg.contains("SQLSTATE") || errorMsg.contains("Unknown column") || errorMsg.contains("doesn’t have a default value") || errorMsg.contains("doesn't have a default value") {
                self.errorMessage = errorMsg
            } else if errorMsg.contains("ACCOUNT_BANNED:") || errorMsg.contains("IP_BANNED_LOGIN:") || errorMsg.contains("IP_BANNED_REGISTER:") {
                self.errorMessage = BackendSecurityPolicy.userFacingMessage(for: errorMsg)
            } else if errorMsg.contains("PHONE_EXISTS:") {
                self.errorMessage = L10n.text("该手机号已注册，请直接登录", en: "This phone number is already registered. Please sign in.", ja: "この電話番号はすでに登録されています。ログインしてください。", ko: "이미 등록된 전화번호입니다. 로그인하세요.")
            } else if errorMsg.contains("ACCOUNT_EXISTS:") {
                self.errorMessage = L10n.text("该账号已注册，请直接登录", en: "This account is already registered. Please sign in.", ja: "このアカウントはすでに登録されています。ログインしてください。", ko: "이미 등록된 계정입니다. 로그인하세요.")
            } else if errorMsg.contains("账号格式") {
                self.errorMessage = L10n.text("账号格式错误，请输入 4-30 位非空白字符", en: "Invalid account format. Use 4-30 non-space characters.", ja: "アカウント形式が正しくありません。4〜30文字の空白以外を入力してください。", ko: "계정 형식이 올바르지 않습니다. 공백이 없는 4~30자를 입력하세요.")
            } else if errorMsg.contains("已注册") || errorMsg.contains("已经存在") {
                self.errorMessage = L10n.text("账号已注册，请登录", en: "This account is already registered. Please sign in.", ja: "このアカウントはすでに登録されています。ログインしてください。", ko: "이미 등록된 계정입니다. 로그인하세요.")
            } else if errorMsg.contains("手机号") || errorMsg.contains("手机号格式") {
                self.errorMessage = L10n.text("手机号格式错误", en: "Invalid phone format.", ja: "電話番号の形式が正しくありません。", ko: "휴대폰 번호 형식이 올바르지 않습니다.")
            } else if errorMsg.contains("密码") && errorMsg.contains("不一致") {
                self.errorMessage = L10n.text("两次输入的密码不一致", en: "The two passwords do not match.", ja: "2つのパスワードが一致しません。", ko: "두 비밀번호가 일치하지 않습니다.")
            } else if errorMsg.contains("密码") {
                self.errorMessage = L10n.text("密码至少 8 位，包含字母和数字", en: "Password must be at least 8 characters and include letters and numbers.", ja: "パスワードは8文字以上で、英字と数字を含めてください。", ko: "비밀번호는 8자 이상이며 문자와 숫자를 포함해야 합니다.")
            } else if errorMsg.contains("验证码") {
                self.errorMessage = L10n.text("图形验证码错误或已过期，请刷新后重试", en: "Captcha is invalid or expired. Please refresh and try again.", ja: "画像認証が正しくないか期限切れです。更新して再度お試しください。", ko: "이미지 인증이 잘못되었거나 만료되었습니다. 새로고침 후 다시 시도하세요.")
                self.captchaInput = ""
                Task { await self.captchaService.loadCaptcha() }
            } else if errorMsg.contains("密保") {
                self.errorMessage = L10n.text("密保问题或答案错误", en: "Security question or answer is incorrect.", ja: "秘密の質問または答えが正しくありません。", ko: "보안 질문 또는 답변이 올바르지 않습니다.")
            } else if errorMsg.contains("网络") || errorMsg.contains("network") || errorMsg.contains("timed out") {
                self.errorMessage = L10n.text("网络连接失败，请检查网络", en: "Network connection failed. Please check your connection.", ja: "ネットワーク接続に失敗しました。接続を確認してください。", ko: "네트워크 연결에 실패했습니다. 연결을 확인하세요.")
            } else if !errorMsg.isEmpty {
                self.errorMessage = errorMsg
            } else {
                self.errorMessage = L10n.text("注册失败，请稍后重试", en: "Registration failed. Please try again later.", ja: "登録に失敗しました。後でもう一度お試しください。", ko: "등록에 실패했습니다. 잠시 후 다시 시도하세요.")
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
                        
                        Text(L10n.string(.appName))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(hex: "AF52DE"))
                        
                        Text(L10n.string(.registerTitle))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    
                    // 注册表单
                    VStack(spacing: 20) {
                        TextField(L10n.string(.registerName), text: $name)
                            .textFieldStyle(CustomTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(size: 18, weight: .medium))
                        
                        TextField(L10n.string(.registerAccount), text: $account)
                            .textFieldStyle(CustomTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(size: 18, weight: .medium))
                            .onChange(of: account) { _ in self.clearError() }
                        
                        TextField(L10n.string(.registerPhoneOptional), text: $phone)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.phonePad)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(size: 18, weight: .medium))
                            .onChange(of: phone) { _ in self.clearError() }
                        Text(L10n.string(.registerPhoneHelp))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        GeometryReader { proxy in
                            HStack(spacing: 12) {
                                TextField(L10n.string(.registerCaptcha), text: $captchaInput)
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
                                                .frame(width: captchaFrameWidth(for: proxy.size.width), height: 56)
                                                .cornerRadius(10)
                                        } else if captchaService.isLoading {
                                            ProgressView()
                                                .frame(width: captchaFrameWidth(for: proxy.size.width), height: 56)
                                        } else {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(.systemGray5))
                                                .frame(width: captchaFrameWidth(for: proxy.size.width), height: 56)
                                                .overlay(Text(L10n.string(.captchaRefresh)).font(.system(size: 15, weight: .medium)).foregroundColor(.secondary))
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(height: 56)

                        SecureField(L10n.string(.registerPassword), text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                            .font(.system(size: 18, weight: .medium))
                        
                        SecureField(L10n.string(.registerConfirmPassword), text: $confirmPassword)
                            .textFieldStyle(CustomTextFieldStyle())
                            .font(.system(size: 18, weight: .medium))

                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.string(.securityQuestionTitle))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)

                            Text(L10n.string(.securityQuestionHelp))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)

                            Picker(L10n.string(.securityQuestionPicker), selection: $selectedSecurityQuestion) {
                                ForEach(securityQuestions, id: \.self) { question in
                                    Text(question).tag(question)
                                }
                            }
                            .pickerStyle(.menu)

                            TextField(L10n.string(.securityAnswer), text: $securityAnswer)
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
                            Text(L10n.string(.registerButton))
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
                        Text(L10n.string(.alreadyHaveAccount))
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                        
                        Button(action: { isPresented = false }) {
                            Text(L10n.string(.loginNow))
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
                        title: Text(L10n.string(.error)),
                        message: Text(errorMessage),
                        dismissButton: .default(Text(L10n.string(.confirm)))
                    )
                }
                .background(Color("BackgroundColor"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        languageMenu
                    }
                }
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
                            
                            Text(L10n.string(.appName))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(hex: "AF52DE"))
                            
                            Text(L10n.string(.registerTitle))
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 40)
                        
                        // 注册表单
                        VStack(spacing: 20) {
                            TextField(L10n.string(.registerName), text: $name)
                                .textFieldStyle(CustomTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 18, weight: .medium))
                            
                            TextField(L10n.string(.registerAccount), text: $account)
                                .textFieldStyle(CustomTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 18, weight: .medium))
                                .onChange(of: account) { _ in self.clearError() }
                            
                            TextField(L10n.string(.registerPhoneOptional), text: $phone)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.phonePad)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 18, weight: .medium))
                                .onChange(of: phone) { _ in self.clearError() }
                            Text(L10n.string(.registerPhoneHelp))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            GeometryReader { proxy in
                                HStack(spacing: 12) {
                                    TextField(L10n.string(.registerCaptcha), text: $captchaInput)
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
                                                    .frame(width: captchaFrameWidth(for: proxy.size.width), height: 56)
                                                    .cornerRadius(10)
                                            } else if captchaService.isLoading {
                                                ProgressView()
                                                    .frame(width: captchaFrameWidth(for: proxy.size.width), height: 56)
                                            } else {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color(.systemGray5))
                                                    .frame(width: captchaFrameWidth(for: proxy.size.width), height: 56)
                                                    .overlay(Text(L10n.string(.captchaRefresh)).font(.system(size: 15, weight: .medium)).foregroundColor(.secondary))
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(height: 56)

                            SecureField(L10n.string(.registerPassword), text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                                .font(.system(size: 18, weight: .medium))
                            
                            SecureField(L10n.string(.registerConfirmPassword), text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                                .font(.system(size: 18, weight: .medium))

                            VStack(alignment: .leading, spacing: 10) {
                                Text(L10n.string(.securityQuestionTitle))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)

                                Text(L10n.string(.securityQuestionHelp))
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)

                                Picker(L10n.string(.securityQuestionPicker), selection: $selectedSecurityQuestion) {
                                    ForEach(securityQuestions, id: \.self) { question in
                                        Text(question).tag(question)
                                    }
                                }
                                .pickerStyle(.menu)

                                TextField(L10n.string(.securityAnswer), text: $securityAnswer)
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
                                Text(L10n.string(.registerButton))
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
                            Text(L10n.string(.alreadyHaveAccount))
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                            
                            Button(action: { isPresented = false }) {
                                Text(L10n.string(.loginNow))
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
                        title: Text(L10n.string(.error)),
                        message: Text(errorMessage),
                        dismissButton: .default(Text(L10n.string(.confirm)))
                    )
                }
                .background(Color("BackgroundColor"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        languageMenu
                    }
                }
                .task {
                    if captchaService.image == nil {
                        await captchaService.loadCaptcha()
                    }
                }
            }
        }
        .stackNavigationStyle()
    }

    private var languageMenu: some View {
        Menu {
            ForEach(AppLanguageManager.Language.allCases, id: \.self) { language in
                Button(language.displayName) {
                    languageManager.setLanguage(language)
                }
            }
        } label: {
            Image(systemName: "globe")
                .font(.system(size: 16, weight: .semibold))
        }
    }
}

#Preview {
    RegisterView(isPresented: .constant(true))
}
