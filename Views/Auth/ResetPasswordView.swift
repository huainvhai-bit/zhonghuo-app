//
//  ResetPasswordView.swift
//  终活
//
//  重置密码界面
//  职责：手机号 + 验证码 + 新密码 重置密码 UI
//

import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    
    @State private var phone = ""
    @State private var verifyCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var countdown = 0
    @State private var timer: Timer?
    @State private var isSuccess = false
    @State private var codeSent = false
    
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
    
    // MARK: - 重置密码逻辑
    
    private func resetPassword() async {
        isLoading = true
        
        do {
            // 验证输入
            guard isValidPhone(phone) else {
                throw NSError(domain: "手机号格式错误", code: -1)
            }
            
            guard newPassword.count >= 6 else {
                throw NSError(domain: "密码至少 6 位", code: -1)
            }
            
            guard newPassword == confirmPassword else {
                throw NSError(domain: "两次输入的密码不一致", code: -1)
            }
            
            guard verifyCode.count == 6 else {
                throw NSError(domain: "请输入 6 位验证码", code: -1)
            }
            
            // 调用重置密码 API
            let mutation = """
            mutation($phone: String!, $verifyCode: String!, $newPassword: String!) {
                resetPassword(phone: $phone, verifyCode: $verifyCode, newPassword: $newPassword) {
                    success
                    message
                }
            }
            """
            
            let variables: [String: Any] = [
                "phone": phone,
                "verifyCode": verifyCode,
                "newPassword": newPassword
            ]
            
            let response = try await graphqlAuthRequest(mutation: mutation, variables: variables)
            await handleResetSuccess(response)
        } catch {
            handleResetError(error)
        }
        
        await MainActor.run { isLoading = false }
    }
    
    /// GraphQL Auth 请求
    private func graphqlAuthRequest(mutation: String, variables: [String: Any]) async throws -> [String: Any] {
        let rawBaseURL = UserDefaults.standard.string(forKey: "lastUsedBaseURL") ?? "api.zhonghuo.app"
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
    
    /// 处理重置成功
    private func handleResetSuccess(_ response: [String: Any]) async {
        guard let data = response["data"] as? [String: Any],
              let resetData = data["resetPassword"] as? [String: Any],
              let success = resetData["success"] as? Bool,
              success else {
            print("❌ 重置密码失败")
            return
        }
        
        print("✅ 密码重置成功")
        
        // 显示成功提示
        await MainActor.run {
            isSuccess = true
            
            // 1 秒后关闭弹窗
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isPresented = false
            }
        }
        
        print("🟢 新密码已保存")
    }
    
    /// 处理重置错误
    private func handleResetError(_ error: Error) {
        print("❌ 重置密码失败：\(error.localizedDescription)")
        
        let errorMsg = error.localizedDescription
        if errorMsg.contains("验证码") || errorMsg.contains("错误") {
            errorMessage = "验证码错误或已过期，请重新获取"
        } else if errorMsg.contains("手机号") {
            errorMessage = "手机号格式错误"
        } else if errorMsg.contains("密码") {
            errorMessage = "密码至少 6 位"
        } else if errorMsg.contains("不一致") {
            errorMessage = "两次输入的密码不一致"
        } else {
            errorMessage = "重置密码失败，请稍后重试"
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
                    
                    Text("重置密码")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // 重置密码表单
                VStack(spacing: 20) {
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
                    
                    SecureField("新密码（6 位以上）", text: $newPassword)
                        .textFieldStyle(CustomTextFieldStyle())
                        .font(.system(size: 18, weight: .medium))
                    
                    SecureField("确认新密码", text: $confirmPassword)
                        .textFieldStyle(CustomTextFieldStyle())
                        .font(.system(size: 18, weight: .medium))
                    
                    Button(action: { Task { await resetPassword() } }) {
                        Text("重置密码")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(hex: "AF52DE"))
                            .cornerRadius(12)
                    }
                    .disabled(false)  // 🔓 临时解除限制
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
                
                Spacer()
                
                // 返回登录
                HStack {
                    Button(action: { isPresented = false }) {
                        Text("返回登录")
                            .foregroundColor(Color(hex: "AF52DE"))
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
            .background(Color("BackgroundColor"))
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                timer?.invalidate()
            }
            .onTapGesture {
                hideKeyboard()
            }
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
        isLoading = true
        errorMessage = ""
        
        do {
            let mutation = """
            mutation($phone: String!) {
                sendResetPasswordCode(phone: $phone) {
                    success
                    message
                }
            }
            """
            
            let variables: [String: Any] = ["phone": phone]
            _ = try await graphqlAuthRequest(mutation: mutation, variables: variables)
            
            await MainActor.run {
                codeSent = true
                startTimer()
            }
            
            print("✅ 验证码已发送到 \(phone)")
        } catch {
            await MainActor.run {
                errorMessage = "发送验证码失败：\(error.localizedDescription)"
                showingError = true
            }
            print("❌ 发送验证码失败：\(error)")
        }
        
        await MainActor.run { isLoading = false }
    }
}

#Preview {
    ResetPasswordView(isPresented: .constant(true))
}
