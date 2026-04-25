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
    @ObservedObject private var languageManager = AppLanguageManager.shared
    
    @State private var identifier = ""
    @State private var selectedSecurityQuestion = Self.securityQuestions.first ?? ""
    @State private var securityAnswer = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSuccess = false
    
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
    
    // MARK: - 辅助方法
    
    /// 验证账号或手机号
    private func isValidIdentifier(_ identifier: String) -> Bool {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let pattern = "^[^\\s]{4,30}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: trimmed)
    }
    
    // MARK: - 重置密码逻辑
    
    private func resetPassword() async {
        isLoading = true
        
        do {
            // 验证输入
            let trimmedIdentifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
            guard isValidIdentifier(trimmedIdentifier) else {
                throw NSError(domain: L10n.text("账号或手机号格式错误", en: "Invalid account or phone format.", ja: "アカウントまたは電話番号の形式が正しくありません。", ko: "계정 또는 전화번호 형식이 올바르지 않습니다."), code: -1)
            }
            
            guard newPassword.count >= 6 else {
                throw NSError(domain: L10n.text("密码至少 6 位", en: "Password must be at least 6 characters.", ja: "パスワードは6文字以上で入力してください。", ko: "비밀번호는 6자 이상이어야 합니다."), code: -1)
            }
            
            guard newPassword == confirmPassword else {
                throw NSError(domain: L10n.text("两次输入的密码不一致", en: "The two passwords do not match.", ja: "2つのパスワードが一致しません。", ko: "두 비밀번호가 일치하지 않습니다."), code: -1)
            }
            
            guard !securityAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw NSError(domain: L10n.text("请输入密保答案", en: "Please enter the security answer.", ja: "秘密の答えを入力してください。", ko: "보안 답변을 입력하세요."), code: -1)
            }
            
            // 调用重置密码 API
            let mutation = """
            mutation($identifier: String!, $newPassword: String!, $securityQuestion: String!, $securityAnswer: String!) {
                resetPassword(identifier: $identifier, newPassword: $newPassword, securityQuestion: $securityQuestion, securityAnswer: $securityAnswer) {
                    success
                    message
                }
            }
            """
            
            let variables: [String: Any] = [
                "identifier": trimmedIdentifier,
                "newPassword": newPassword,
                "securityQuestion": selectedSecurityQuestion,
                "securityAnswer": securityAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
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
        let rawBaseURL = UserDefaults.standard.string(forKey: "lastUsedBaseURL") ?? "8.136.41.211:3395"
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
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
            let message = errors[0]["message"] as? String ?? "GraphQL Error"
            throw NSError(domain: message, code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = bodyErrorMessage(from: data, statusCode: httpResponse.statusCode, context: "重置密码")
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
    
    /// 处理重置成功
    private func handleResetSuccess(_ response: [String: Any]) async {
        guard let data = response["data"] as? [String: Any],
              let resetData = data["resetPassword"] as? [String: Any],
              let success = resetData["success"] as? Bool,
              success else {
            let message = authMessage(from: response, fallback: L10n.text("重置密码失败，请稍后重试", en: "Password reset failed. Please try again later.", ja: "パスワードの再設定に失敗しました。後でもう一度お試しください。", ko: "비밀번호 재설정에 실패했습니다. 잠시 후 다시 시도하세요."))
            print("❌ 重置密码失败")
            await MainActor.run {
                errorMessage = message
                showingError = true
            }
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
        DispatchQueue.main.async {
            if errorMsg.contains("SQLSTATE") || errorMsg.contains("Unknown column") || errorMsg.contains("doesn't have a default value") || errorMsg.contains("cannot be null") {
                self.errorMessage = errorMsg
            } else if errorMsg.contains("ACCOUNT_NOT_FOUND:") || errorMsg.contains("不存在") {
                self.errorMessage = L10n.text("账号不存在，请先注册", en: "Account not found. Please register first.", ja: "アカウントが見つかりません。先に登録してください。", ko: "계정을 찾을 수 없습니다. 먼저 등록하세요.")
            } else if errorMsg.contains("密保") || errorMsg.contains("答案") {
                self.errorMessage = L10n.text("密保问题或答案错误", en: "Security question or answer is incorrect.", ja: "秘密の質問または答えが正しくありません。", ko: "보안 질문 또는 답변이 올바르지 않습니다.")
            } else if errorMsg.contains("账号") || errorMsg.contains("手机号") {
                self.errorMessage = L10n.text("账号或手机号格式错误", en: "Invalid account or phone format.", ja: "アカウントまたは電話番号の形式が正しくありません。", ko: "계정 또는 전화번호 형식이 올바르지 않습니다.")
            } else if errorMsg.contains("密码") {
                self.errorMessage = L10n.text("密码至少 6 位", en: "Password must be at least 6 characters.", ja: "パスワードは6文字以上で入力してください。", ko: "비밀번호는 6자 이상이어야 합니다.")
            } else if errorMsg.contains("不一致") {
                self.errorMessage = L10n.text("两次输入的密码不一致", en: "The two passwords do not match.", ja: "2つのパスワードが一致しません。", ko: "두 비밀번호가 일치하지 않습니다.")
            } else if errorMsg.contains("网络") || errorMsg.contains("network") || errorMsg.contains("timed out") {
                self.errorMessage = L10n.text("网络连接失败，请检查网络", en: "Network connection failed. Please check your connection.", ja: "ネットワーク接続に失敗しました。接続を確認してください。", ko: "네트워크 연결에 실패했습니다. 연결을 확인하세요.")
            } else if !errorMsg.isEmpty {
                self.errorMessage = errorMsg
            } else {
                self.errorMessage = L10n.text("重置密码失败，请稍后重试", en: "Password reset failed. Please try again later.", ja: "パスワードの再設定に失敗しました。後でもう一度お試しください。", ko: "비밀번호 재설정에 실패했습니다. 잠시 후 다시 시도하세요.")
            }
            self.showingError = true
        }
    }

    private func authMessage(from response: [String: Any], fallback: String) -> String {
        if let errors = response["errors"] as? [[String: Any]], let first = errors.first {
            return first["message"] as? String ?? fallback
        }

        if let data = response["data"] as? [String: Any],
           let resetData = data["resetPassword"] as? [String: Any],
           let message = resetData["message"] as? String,
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
                        
                        Text(L10n.string(.resetSubtitle))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    
                    // 重置密码表单
                    VStack(spacing: 20) {
                        TextField(L10n.string(.identifierPlaceholder), text: $identifier)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.default)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(size: 18, weight: .medium))

                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.string(.resetSecurityTitle))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)

                            Text(L10n.string(.resetSecurityHelp))
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
                        
                        SecureField(L10n.string(.registerPassword), text: $newPassword)
                            .textFieldStyle(CustomTextFieldStyle())
                            .font(.system(size: 18, weight: .medium))
                        
                        SecureField(L10n.string(.registerConfirmPassword), text: $confirmPassword)
                            .textFieldStyle(CustomTextFieldStyle())
                            .font(.system(size: 18, weight: .medium))
                        
                        Button(action: { Task { await resetPassword() } }) {
                            Text(L10n.string(.resetPasswordButton))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(hex: "AF52DE"))
                                .cornerRadius(12)
                        }
                        .disabled(isLoading)
                        .opacity(isLoading ? 0.5 : 1)
                    }
                    .padding(.horizontal, 24)
                    .alert(isPresented: $showingError) {
                        Alert(
                            title: Text(L10n.string(.error)),
                            message: Text(errorMessage),
                            dismissButton: .default(Text(L10n.string(.confirm)))
                        )
                    }
                    
                    // 返回登录
                    HStack {
                        Button(action: { isPresented = false }) {
                            Text(L10n.string(.returnLogin))
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
                .background(Color("BackgroundColor"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        languageMenu
                    }
                }
                .onDisappear {
                    isLoading = false
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
                            
                            Text(L10n.string(.resetSubtitle))
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 40)
                        
                        // 重置密码表单
                        VStack(spacing: 20) {
                            TextField(L10n.string(.identifierPlaceholder), text: $identifier)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.default)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 18, weight: .medium))

                            VStack(alignment: .leading, spacing: 10) {
                                Text(L10n.string(.resetSecurityTitle))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)

                                Text(L10n.string(.resetSecurityHelp))
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
                            
                            SecureField(L10n.string(.registerPassword), text: $newPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                                .font(.system(size: 18, weight: .medium))
                            
                            SecureField(L10n.string(.registerConfirmPassword), text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                                .font(.system(size: 18, weight: .medium))
                            
                            Button(action: { Task { await resetPassword() } }) {
                                Text(L10n.string(.resetPasswordButton))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color(hex: "AF52DE"))
                                    .cornerRadius(12)
                            }
                            .disabled(isLoading)
                            .opacity(isLoading ? 0.5 : 1)
                        }
                        .padding(.horizontal, 24)
                        .alert(isPresented: $showingError) {
                            Alert(
                                title: Text(L10n.string(.error)),
                                message: Text(errorMessage),
                                dismissButton: .default(Text(L10n.string(.confirm)))
                            )
                        }
                        
                        // 返回登录
                        HStack {
                            Button(action: { isPresented = false }) {
                                Text(L10n.string(.returnLogin))
                                    .foregroundColor(Color(hex: "AF52DE"))
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .frame(maxWidth: .infinity)
                }
                .background(Color("BackgroundColor"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        languageMenu
                    }
                }
                .onDisappear {
                    isLoading = false
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
    ResetPasswordView(isPresented: .constant(true))
}
