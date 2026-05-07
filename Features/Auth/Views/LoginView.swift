//
//  LoginView.swift
//  安心助手
//
//  登录界面
//  职责：手机号 + 密码/验证码 登录 UI
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LoginViewModel()
    @StateObject private var captchaService = AppCaptchaService(purpose: "login")
    @ObservedObject private var languageManager = AppLanguageManager.shared
    @State private var isRegistering = false
    @State private var showingResetPassword = false

    private func captchaFrameWidth(for availableWidth: CGFloat) -> CGFloat {
        let preferred = availableWidth * 0.38
        return max(150, min(preferred, 240))
    }
    
    // MARK: - 视图
    
    var body: some View {
        NavigationView {
            if #available(iOS 16.0, *) {
                ScrollView {
                    content
                }
                .scrollDismissesKeyboard(.interactively)
                .background(Color(.systemBackground))
                .navigationBarTitleDisplayMode(.inline)
                .onTapGesture {
                    hideKeyboard()
                }
            } else {
                ScrollView {
                    content
                }
                .background(Color(.systemBackground))
                .navigationBarTitleDisplayMode(.inline)
                .onTapGesture {
                    hideKeyboard()
                }
            }
        }
        .stackNavigationStyle()
        .fullScreenCover(isPresented: $isRegistering) {
            RegisterView(isPresented: $isRegistering)
        }
        .sheet(isPresented: $showingResetPassword) {
            ResetPasswordView(isPresented: $showingResetPassword)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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
        .task {
            if captchaService.image == nil {
                await captchaService.loadCaptcha()
            }
        }
    }

    private var content: some View {
        VStack(spacing: 30) {
                // Logo
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "AF52DE"))
                        
                        Text(L10n.string(.appName))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(hex: "AF52DE"))
                        
                        Text(L10n.string(.appTagline))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 60)
                    
                    // 登录表单
                    VStack(spacing: 20) {
                        TextField(L10n.string(.identifierPlaceholder), text: $viewModel.identifier)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.default)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(size: 18, weight: .medium))
                            .onChange(of: viewModel.identifier) { _ in viewModel.clearError() }
                            .onTapGesture { viewModel.clearError() }
                        
                        SecureField(L10n.string(.passwordPlaceholder), text: $viewModel.password)
                            .textFieldStyle(CustomTextFieldStyle())
                            .font(.system(size: 18, weight: .medium))
                            .onChange(of: viewModel.password) { _ in viewModel.clearError() }

                        GeometryReader { proxy in
                            HStack(spacing: 12) {
                                TextField(L10n.string(.captchaPlaceholder), text: $viewModel.captchaInput)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .font(.system(size: 18, weight: .medium))
                                    .onChange(of: viewModel.captchaInput) { _ in viewModel.clearError() }

                                Button {
                                    Task {
                                        await captchaService.loadCaptcha()
                                        viewModel.captchaInput = ""
                                    }
                                } label: {
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

                        Button(action: {
                            Task {
                                let success = await viewModel.submitLogin()
                                if success {
                                    dismiss()
                                }
                            }
                        }) {
                            Text(L10n.string(.loginButton))
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
                            title: Text(L10n.string(.error)),
                            message: Text(viewModel.errorMessage),
                            dismissButton: .default(Text(L10n.string(.confirm)))
                        )
                    }
                    .onChange(of: viewModel.errorMessage, perform: { newValue in
                        if newValue.contains("图形验证码") {
                            Task {
                                await captchaService.loadCaptcha()
                                viewModel.captchaInput = ""
                            }
                        }
                    })

                    HStack {
                        Spacer()
                        Button {
                            showingResetPassword = true
                        } label: {
                        Text(L10n.string(.forgotPassword))
                                .foregroundColor(Color(hex: "AF52DE"))
                                .font(.system(size: 16))
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // 切换到注册
                    HStack {
                        Text(L10n.string(.noAccount))
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                        
                        Button {
                            print("🔵🔵🔵 LoginView: 点击立即注册")
                            isRegistering = true 
                            print("🔵 isRegistering = \(isRegistering)")
                        } label: {
                            Text(L10n.string(.registerNow))
                                .foregroundColor(Color(hex: "AF52DE"))
                                .font(.system(size: 16, weight: .bold))
                        }
                        .contentShape(Rectangle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: --controls

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    LoginView()
}
