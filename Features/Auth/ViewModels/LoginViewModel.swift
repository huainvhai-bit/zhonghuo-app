//
//  LoginViewModel.swift
//  终活
//
//  登录状态与请求逻辑
//

import Foundation
import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var phone = ""
    @Published var password = ""
    @Published var verifyCode = ""
    @Published var loginType: String = "password"
    @Published var isLoading = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var countdown = 0
    @Published var showPassword = false

    private var timer: Timer?
    private let userManager = UserManager.shared

    deinit {
        timer?.invalidate()
    }

    func clearError() {
        if showingError {
            showingError = false
            errorMessage = ""
        }
    }

    func toggleLoginType() {
        loginType = loginType == "password" ? "verify_code" : "password"
        password = ""
        verifyCode = ""
    }

    func requestVerifyCode() async {
        guard isValidPhone(phone) else {
            errorMessage = "手机号格式错误"
            showingError = true
            return
        }

        countdown = 60
        startTimer()

        do {
            let mutation = """
            mutation($phone: String!) {
                sendLoginCode(phone: $phone) {
                    success
                    code
                    message
                }
            }
            """
            let variables: [String: Any] = ["phone": phone]
            let response = try await graphqlAuthRequest(mutation: mutation, variables: variables)

            if let data = response["data"] as? [String: Any],
               let result = data["sendLoginCode"] as? [String: Any],
               let success = result["success"] as? Bool, success {
                let devCode = result["code"] as? String ?? ""
                if !devCode.isEmpty {
                    verifyCode = devCode
                }
            }
        } catch {
            handleAuthError(error, context: "发送验证码")
        }
    }

    func submitLogin() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            if loginType == "password" {
                return try await loginWithPassword()
            } else {
                return try await loginWithCode()
            }
        } catch {
            handleAuthError(error, context: "登录")
            return false
        }
    }

    private func loginWithPassword() async throws -> Bool {
        let mutation = """
        mutation($phone: String!, $password: String!) {
            login(phone: $phone, password: $password) {
                success
                token
                user {
                    id
                    name
                    phone
                }
            }
        }
        """

        let variables: [String: Any] = [
            "phone": phone,
            "password": password
        ]

        let response = try await graphqlAuthRequest(mutation: mutation, variables: variables)
        return await handleAuthSuccess(response)
    }

    private func loginWithCode() async throws -> Bool {
        let mutation = """
        mutation($phone: String!, $code: String!) {
            verifyCodeLogin(phone: $phone, code: $code) {
                success
                token
                user {
                    id
                    name
                    phone
                }
            }
        }
        """

        let variables: [String: Any] = [
            "phone": phone,
            "code": verifyCode
        ]

        let response = try await graphqlAuthRequest(mutation: mutation, variables: variables)
        return await handleAuthSuccess(response)
    }

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

    private func handleAuthSuccess(_ response: [String: Any]) async -> Bool {
        if let errors = response["errors"] as? [[String: Any]], !errors.isEmpty {
            let message = errors[0]["message"] as? String ?? "登录失败"
            errorMessage = message
            showingError = true
            return false
        }

        guard let data = response["data"] as? [String: Any],
              let loginData = data.values.first as? [String: Any],
              let success = loginData["success"] as? Bool,
              success else {
            errorMessage = "登录失败，请稍后重试"
            showingError = true
            return false
        }

        if let token = loginData["token"] as? String {
            KeychainManager.shared.saveToken(token)
        }

        if let user = loginData["user"] as? [String: Any],
           let userId = user["id"] as? String {
            KeychainManager.shared.saveUserId(userId)
        }

        userManager.loadUser()
        userManager.isLoggedIn = true

        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("CheckInDidComplete"), object: nil)
        return true
    }

    private func handleAuthError(_ error: Error, context: String) {
        let errorMsg = error.localizedDescription

        if errorMsg.contains("ACCOUNT_NOT_FOUND:") {
            errorMessage = "账号不存在，请先注册"
        } else if errorMsg.contains("PASSWORD_ERROR:") {
            errorMessage = "密码错误，请重试"
        } else if errorMsg.contains("CODE_ERROR:") {
            errorMessage = "验证码错误或已过期"
        } else if errorMsg.contains("PHONE_EXISTS:") {
            errorMessage = "该手机号已注册，请直接登录"
        } else if errorMsg.contains("未注册") || errorMsg.contains("不存在") {
            errorMessage = "账号不存在，请先注册"
        } else if errorMsg.contains("密码") || errorMsg.contains("PASSWORD") {
            errorMessage = "密码错误，请重试"
        } else if errorMsg.contains("网络") || errorMsg.contains("网络连接") {
            errorMessage = "网络连接失败，请检查网络"
        } else {
            errorMessage = errorMsg.isEmpty ? "\(context)失败，请稍后重试" : errorMsg
        }
        showingError = true
    }

    private func isValidPhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: phone)
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.countdown > 0 {
                    self.countdown -= 1
                } else {
                    self.timer?.invalidate()
                }
            }
        }
    }
}
