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
    @State private var verifyCode = ""
    @State private var isRegistering = true
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var countdown = 0
    @State private var timer: Timer?
    
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
        
        struct AuthData: Codable {
            let token: String
            let user_id: String
            let is_new: Bool
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
                    
                    // 验证码区域
                    if countdown > 0 || verifyCode.isEmpty == false {
                        // 验证码输入框 + 重新获取按钮
                        HStack {
                            TextField("验证码", text: $verifyCode)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .onChange(of: verifyCode) { newValue in
                                    if newValue.count > 6 {
                                        verifyCode = String(newValue.prefix(6))
                                    }
                                }
                            
                            Button(action: sendVerifyCode) {
                                Text(countdown > 0 ? "\(countdown)秒" : "重新获取")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(countdown > 0 ? .gray : Color(hex: "AF52DE"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(countdown > 0 ? Color.gray.opacity(0.1) : Color(hex: "AF52DE").opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .disabled(countdown > 0 || phone.isEmpty)
                        }
                    } else {
                        // 获取验证码按钮
                        Button(action: sendVerifyCode) {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("获取验证码")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "AF52DE"))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "AF52DE").opacity(0.1))
                            .cornerRadius(12)
                        }
                        .disabled(phone.isEmpty)
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
                    .disabled(isRegistering ? (phone.isEmpty || name.isEmpty || verifyCode.isEmpty) : (phone.isEmpty || verifyCode.isEmpty))
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
                // 确保 API 已就绪
                try await DataManager.shared.checkAPIReady()
                
                guard !DataManager.apiURL.isEmpty else {
                    throw NSError(domain: "API URL not initialized", code: -1)
                }
                
                let url = URL(string: "\(DataManager.apiURL)/sms.php")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "phone": phone,
                    "action": isRegistering ? "register" : "login"
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw NSError(domain: "Server error", code: -1)
                }
                
                let result = try JSONDecoder().decode(SMSResponse.self, from: data)
                
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
            
            if verifyCode.isEmpty {
                errorMessage = "请输入验证码"
                showingError = true
                return
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
            
            // 检查是否是验证码错误（后端返回特定错误码）
            if httpResponse.statusCode == 400 || httpResponse.statusCode == 500 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("  响应内容：\(responseString)")
                    // 尝试解析错误信息
                    if let errorData = try? JSONDecoder().decode(AuthResponse.self, from: data) {
                        if errorData.error?.contains("验证码") == true {
                            await MainActor.run {
                                errorMessage = "验证码错误或已过期"
                                showingError = true
                                countdown = 0 // 允许重新获取
                            }
                            return
                        }
                    }
                }
                throw NSError(domain: "Server error", code: httpResponse.statusCode)
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
        print("  verify_code: \(verifyCode)")
        
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
                "action": "login",
                "phone": phone,
                "verify_code": verifyCode
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("📡 发送请求...")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 响应不是 HTTPURLResponse")
                throw NSError(domain: "Invalid response type", code: -1)
            }
            
            print("  HTTP 状态码：\(httpResponse.statusCode)")
            
            // 检查验证码错误
            if httpResponse.statusCode == 400 || httpResponse.statusCode == 500 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("  响应内容：\(responseString)")
                    if let errorData = try? JSONDecoder().decode(AuthResponse.self, from: data) {
                        if errorData.error?.contains("验证码") == true {
                            await MainActor.run {
                                errorMessage = "验证码错误或已过期"
                                showingError = true
                                countdown = 0 // 允许重新获取
                            }
                            return
                        }
                    }
                }
                throw NSError(domain: "Server error", code: httpResponse.statusCode)
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
                    
                    errorMessage = "登录成功！"
                    showingError = true
                } else {
                    errorMessage = result.error ?? "登录失败"
                    showingError = true
                }
            }
            
        } catch {
            print("❌ 登录失败：\(error)")
            
            await MainActor.run {
                if error._domain == "Server error" {
                    errorMessage = "服务器错误，请稍后重试"
                } else {
                    errorMessage = "网络错误：\(error.localizedDescription)"
                }
                showingError = true
            }
        }
    }
}

#Preview {
    AuthView()
}
