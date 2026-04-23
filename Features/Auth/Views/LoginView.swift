//
//  LoginView.swift
//  终活
//
//  登录界面
//  职责：手机号 + 密码/验证码 登录 UI
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LoginViewModel()
    @State private var isRegistering = false
    @State private var showingResetPassword = false
    
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
                    TextField("手机号码", text: $viewModel.phone)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.phonePad)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(size: 18, weight: .medium))
                        .onChange(of: viewModel.phone) { _ in viewModel.clearError() }
                        .onTapGesture { viewModel.clearError() }
                    
                    SecureField("密码", text: $viewModel.password)
                        .textFieldStyle(CustomTextFieldStyle())
                        .font(.system(size: 18, weight: .medium))
                        .onChange(of: viewModel.password) { _ in viewModel.clearError() }
                    
                    Button(action: {
                        Task {
                            let success = await viewModel.submitLogin()
                            if success {
                                dismiss()
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
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading ? 0.5 : 1)
                }
                .padding(.horizontal, 24)
                .alert(isPresented: $viewModel.showingError) {
                    Alert(
                        title: Text("错误"),
                        message: Text(viewModel.errorMessage),
                        dismissButton: .default(Text("确定"))
                    )
                }

                HStack {
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
                        isRegistering = true 
                        print("🔵 isRegistering = \(isRegistering)")
                    }) {
                        Text("立即注册")
                            .foregroundColor(Color(hex: "AF52DE"))
                            .font(.system(size: 16, weight: .bold))
                    }
                    .contentShape(Rectangle())
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

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    LoginView()
}
