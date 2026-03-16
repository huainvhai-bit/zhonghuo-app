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
                        Text(isRegistering ? "注册" : "登录")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "AF52DE"))
                            .cornerRadius(12)
                    }
                    .disabled(isRegistering ? (phone.isEmpty || name.isEmpty || verifyCode.isEmpty) : phone.isEmpty)
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
        
        // 生成 6 位随机验证码
        sentCode = String(Int.random(in: 100000...999999))
        print("📱 验证码：\(sentCode)（测试用，实际应发送短信）")
        
        // 开始倒计时
        countdown = 60
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            countdown -= 1
            if countdown <= 0 {
                timer?.invalidate()
                timer = nil
            }
        }
        
        showingVerifyCode = true
        
        // 模拟发送短信
        errorMessage = "验证码：\(sentCode)（测试用）"
        showingError = true
    }
    
    // MARK: - 提交处理
    private func handleSubmit() {
        if isRegistering {
            // 验证验证码
            if verifyCode != sentCode {
                errorMessage = "验证码错误，请重新输入"
                showingError = true
                return
            }
            
            // 注册
            let result = userManager.register(name: name, phone: phone)
            switch result {
            case .success:
                print("✅ 注册成功")
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        } else {
            // 登录：也需要验证码
            if !showingVerifyCode {
                sendVerifyCode()
                errorMessage = "请先获取验证码"
                showingError = true
                return
            }
            
            // 验证验证码
            if verifyCode != sentCode {
                errorMessage = "验证码错误，请重新输入"
                showingError = true
                return
            }
            
            // 登录
            let result = userManager.login(phone: phone)
            switch result {
            case .success:
                print("✅ 登录成功")
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

#Preview {
    AuthView()
}
