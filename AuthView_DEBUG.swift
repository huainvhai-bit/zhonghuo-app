//
//  AuthView.swift - 调试增强版
//  终活
//
//  添加详细的网络调试信息
//

import SwiftUI

struct AuthView: View {
    @StateObject private var userManager = UserManager.shared
    @State private var name = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var verifyCode = ""
    @State private var isRegistering = true
    @State private var loginType: String = "password"
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var countdown = 0
    @State private var timer: Timer?
    
    // 调试信息
    @State private var debugInfo = ""
    
    struct SMSResponse: Codable {
        let success: Bool
        let message: String?
        let code: String?
        let error: String?
    }
    
    struct AuthResponse: Codable {
        let success: Bool
        let message: String?
        let error: String?
        let data: AuthData?
        
        struct AuthData: Codable {
            let token: String
            let user_id: String
            let user: UserData?
        }
        
        struct UserData: Codable {
            let id: String
            let name: String
            let phone: String
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
                }
                .padding(.top, 60)
                
                Spacer()
                
                // 调试信息
                if !debugInfo.isEmpty {
                    Text(debugInfo)
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                // 表单
                VStack(spacing: 20) {
                    TextField("手机号码", text: $phone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                    
                    if loginType == "password" {
                        SecureField("密码", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        TextField("验证码", text: $verifyCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    Button(action: handleSubmit) {
                        Text("登录")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "AF52DE"))
                            .cornerRadius(12)
                    }
                    .disabled(phone.isEmpty || (loginType == "password" ? password.isEmpty : verifyCode.isEmpty))
                }
                .padding(.horizontal, 30)
                
                // 切换登录方式
                Picker("登录方式", selection: $loginType) {
                    Text("密码登录").tag("password")
                    Text("验证码登录").tag("verify_code")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .background(Color(hex: "F6F6F8"))
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await testNetworkConnection()
                }
            }
            .alert("提示", isPresented: $showingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - 网络测试
    private func testNetworkConnection() async {
        debugInfo = "🔄 测试网络连接..."
        
        let baseURL = "http://8.136.41.211:3395"
        let apiURL = "\(baseURL)/api"
        
        debugInfo += "\n📍 Base URL: \(baseURL)"
        debugInfo += "\n📍 API URL: \(apiURL)"
        
        // 测试 1: config.php
        do {
            let configURL = URL(string: "\(apiURL)/config.php")!
            debugInfo += "\n📡 请求：\(configURL.absoluteString)"
            
            let (data, response) = try await URLSession.shared.data(from: configURL)
            
            if let httpResponse = response as? HTTPURLResponse {
                debugInfo += "\n✅ HTTP 状态码：\(httpResponse.statusCode)"
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    debugInfo += "\n✅ 响应：成功"
                }
            }
        } catch {
            debugInfo += "\n❌ 错误：\(error.localizedDescription)"
            debugInfo += "\n\n可能原因:"
            debugInfo += "\n1. 模拟器无法访问外网"
            debugInfo += "\n2. 防火墙阻止连接"
            debugInfo += "\n3. 服务器地址错误"
        }
        
        // 测试 2: 登录 API
        do {
            let loginURL = URL(string: "\(apiURL)/users.php")!
            debugInfo += "\n\n📡 测试登录 API: \(loginURL.absoluteString)"
            
            var request = URLRequest(url: loginURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "action": "login",
                "phone": "13233323334",
                "password": "test123456",
                "login_type": "password"
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                debugInfo += "\n✅ 登录 API 状态码：\(httpResponse.statusCode)"
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let success = json["success"] as? Bool, success {
                        debugInfo += "\n✅ 登录测试：成功"
                        debugInfo += "\n\n🎉 所有测试通过！"
                        debugInfo += "\n如果登录仍然失败，请检查:"
                        debugInfo += "\n1. 输入的手机号和密码"
                        debugInfo += "\n2. 用户是否已注册"
                    } else {
                        debugInfo += "\n⚠️ 登录测试：失败"
                        if let error = json["error"] as? String {
                            debugInfo += "\n错误：\(error)"
                        }
                    }
                }
            }
        } catch {
            debugInfo += "\n❌ 登录 API 错误：\(error.localizedDescription)"
        }
    }
    
    // MARK: - 提交处理
    private func handleSubmit() {
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
        
        Task {
            await loginWithAPI()
        }
    }
    
    // MARK: - API 登录
    private func loginWithAPI() async {
        print("🔵 开始登录...")
        print("  手机号：\(phone)")
        print("  登录方式：\(loginType)")
        
        let baseURL = "http://8.136.41.211:3395"
        let apiURL = "\(baseURL)/api"
        
        do {
            let urlString = "\(apiURL)/users.php"
            guard let url = URL(string: urlString) else {
                throw NSError(domain: "InvalidURL", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL 无效"])
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
            
            print("📡 发送请求到：\(url)")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "InvalidResponse", code: -1, userInfo: [NSLocalizedDescriptionKey: "响应类型错误"])
            }
            
            print("📥 收到响应：\(httpResponse.statusCode)")
            
            // 处理错误响应
            if httpResponse.statusCode >= 400 {
                if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let errorMsg = errorJSON["error"] as? String ?? "未知错误"
                    throw NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
                }
                throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP 错误：\(httpResponse.statusCode)"])
            }
            
            let result = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            await MainActor.run {
                if result.success, let data = result.data {
                    UserDefaults.standard.set(data.token, forKey: "userToken")
                    UserDefaults.standard.set(data.user_id, forKey: "userId")
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    userManager.isLoggedIn = true
                    errorMessage = "登录成功！"
                } else {
                    errorMessage = result.error ?? "登录失败"
                }
                showingError = true
            }
            
        } catch {
            print("❌ 登录失败：\(error)")
            await MainActor.run {
                var errorMsg = error.localizedDescription
                
                if error._domain == "InvalidURL" {
                    errorMsg = "服务器地址无效"
                } else if error._domain == "ServerError" {
                    errorMsg = "服务器错误：\(errorMsg)"
                } else if error._domain == "HTTPError" {
                    errorMsg = "网络错误：\(errorMsg)"
                } else {
                    errorMsg = "登录失败：\(errorMsg)\n\n请检查:\n1. 网络连接\n2. 服务器状态\n3. 账号密码是否正确"
                }
                
                errorMessage = errorMsg
                showingError = true
            }
        }
    }
}

#Preview {
    AuthView()
}
