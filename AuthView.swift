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
    @State private var showingVerifyCode = false
    @State private var countdown = 0
    @State private var timer: Timer?
    @State private var sentCode = ""
    
    // MARK: - 短信验证码响应模型
    struct SMSResponse: Codable {
        let success: Bool
        let message: String?
        let code: String?
        let error: String?
        let expiresIn: Int?
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
                    
                    // 验证码输入（获取验证码后显示）
                    if showingVerifyCode {
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
                                Text(countdown > 0 ? "\(countdown)秒" : "获取验证码")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(countdown > 0 ? .gray : Color(hex: "AF52DE"))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(countdown > 0 ? Color.gray.opacity(0.1) : Color(hex: "AF52DE").opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .disabled(countdown > 0 || phone.isEmpty)
                        }
                    }
                    
                    Button(action: handleSubmit) {
                        HStack {
                            Image(systemName: isRegistering && !showingVerifyCode ? "arrow.right.circle.fill" : "checkmark.circle.fill")
                            Text(isRegistering && !showingVerifyCode ? "先获取验证码" : (isRegistering ? "注册" : "登录"))
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "AF52DE"))
                        .cornerRadius(12)
                    }
                    .disabled(isRegistering ? (phone.isEmpty || name.isEmpty || !showingVerifyCode || verifyCode.isEmpty) : phone.isEmpty)
                }
                .padding(.horizontal, 30)
                
                // 切换注册/登录
                HStack {
                    Text(isRegistering ? "已有账号？" : "没有账号？")
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        withAnimation {
                            isRegistering.toggle()
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
        
        // 开始倒计时（先开始，避免请求期间可重复点击）
        countdown = 60
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            countdown -= 1
            if countdown <= 0 {
                timer?.invalidate()
                timer = nil
            }
        }
        
        showingVerifyCode = true
        
        // 调用后端 API 发送验证码
        Task {
            do {
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
                        // 开发环境显示验证码（用于测试）
                        if let code = result.code {
                            errorMessage = "验证码：\(code)（开发环境）"
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
            // 验证验证码（开发环境可以跳过）
            if verifyCode.isEmpty {
                errorMessage = "请输入验证码"
                showingError = true
                return
            }
            
            // 调用后端 API 验证验证码并注册
            Task {
                await registerWithAPI()
            }
        } else {
            // 登录：也需要验证码
            if !showingVerifyCode {
                sendVerifyCode()
                errorMessage = "请先获取验证码"
                showingError = true
                return
            }
            
            // 验证验证码（开发环境可以跳过）
            if verifyCode.isEmpty {
                errorMessage = "请输入验证码"
                showingError = true
                return
            }
            
            // 调用后端 API 验证验证码并登录
            Task {
                await loginWithAPI()
            }
        }
    }
    
    // MARK: - API 注册
    private func registerWithAPI() async {
        do {
            let url = URL(string: "\(DataManager.apiURL)/users.php")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "action": "register",
                "name": name,
                "phone": phone,
                "verify_code": verifyCode
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NSError(domain: "Server error", code: -1)
            }
            
            let result = try JSONDecoder().decode(APIResponse.self, from: data)
            
            await MainActor.run {
                if result.success {
                    errorMessage = "注册成功！"
                    showingError = true
                } else {
                    errorMessage = result.error ?? "注册失败"
                    showingError = true
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "网络错误：\(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    // MARK: - API 登录
    private func loginWithAPI() async {
        do {
            let url = URL(string: "\(DataManager.apiURL)/users.php")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "action": "login",
                "phone": phone,
                "verify_code": verifyCode
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NSError(domain: "Server error", code: -1)
            }
            
            let result = try JSONDecoder().decode(APIResponse.self, from: data)
            
            await MainActor.run {
                if result.success {
                    errorMessage = "登录成功！"
                    showingError = true
                } else {
                    errorMessage = result.error ?? "登录失败"
                    showingError = true
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "网络错误：\(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    // MARK: - API 响应模型
    struct APIResponse: Codable {
        let success: Bool
        let message: String?
        let error: String?
    }
}

#Preview {
    AuthView()
}
