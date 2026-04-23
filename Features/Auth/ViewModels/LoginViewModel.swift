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
    @Published var isLoading = false
    @Published var showingError = false
    @Published var errorMessage = ""
    private let userManager = UserManager.shared

    func clearError() {
        if showingError {
            showingError = false
            errorMessage = ""
        }
    }

    func submitLogin() async -> Bool {
        guard isValidPhone(phone) else {
            presentAuthError("手机号格式错误")
            return false
        }

        guard !password.isEmpty else {
            presentAuthError("请输入密码")
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            return try await loginWithPassword()
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
            let message: String
            switch httpResponse.statusCode {
            case 401:
                message = "登录已失效，请重新登录"
            case 403:
                message = "当前账号无权限操作"
            case 500:
                message = "服务器内部错误，请稍后重试"
            case 503:
                message = "服务器暂不可用，请稍后重试"
            default:
                message = "服务器返回 \(httpResponse.statusCode)"
            }
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

    private func handleAuthSuccess(_ response: [String: Any]) async -> Bool {
        let message = authMessage(from: response, fallback: "登录失败，请稍后重试")
        guard let data = response["data"] as? [String: Any] else {
            presentAuthError(message)
            return false
        }

        guard let loginData = data["login"] as? [String: Any] else {
            presentAuthError(message)
            return false
        }

        if let success = loginData["success"] as? Bool, !success {
            presentAuthError(message)
            return false
        }

        guard let success = loginData["success"] as? Bool, success else {
            presentAuthError(message)
            return false
        }

        guard let token = loginData["token"] as? String, !token.isEmpty else {
            presentAuthError("登录失败：服务器未返回有效凭证")
            return false
        }
        KeychainManager.shared.saveToken(token)

        guard let user = loginData["user"] as? [String: Any],
              let userId = user["id"] as? String,
              !userId.isEmpty else {
            KeychainManager.shared.clearAll()
            presentAuthError("账号不存在或已被删除，请重新注册")
            return false
        }

        KeychainManager.shared.saveUserId(userId)
        if let phone = user["phone"] as? String, !phone.isEmpty {
            KeychainManager.shared.saveUserPhone(phone)
        }

        userManager.loadUser()
        userManager.isLoggedIn = true

        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("CheckInDidComplete"), object: nil)
        return true
    }

    private func handleAuthError(_ error: Error, context: String) {
        let errorMsg = error.localizedDescription
        presentAuthError(mappedAuthMessage(from: errorMsg, context: context))
    }

    private func authMessage(from response: [String: Any], fallback: String) -> String {
        if let errors = response["errors"] as? [[String: Any]], let first = errors.first {
            return first["message"] as? String ?? fallback
        }

        if let data = response["data"] as? [String: Any] {
            if let result = data["login"] as? [String: Any] {
                if let message = result["message"] as? String, !message.isEmpty {
                    return message
                }
            }
        }

        return fallback
    }

    private func mappedAuthMessage(from rawMessage: String, context: String) -> String {
        if rawMessage.contains("ACCOUNT_NOT_FOUND:") {
            return "账号不存在，请先注册"
        } else if rawMessage.contains("PASSWORD_ERROR:") {
            return "密码错误，请重试"
        } else if rawMessage.contains("CODE_ERROR:") {
            return "验证码错误或已过期"
        } else if rawMessage.contains("PHONE_EXISTS:") {
            return "该手机号已注册，请直接登录"
        } else if rawMessage.contains("未注册") || rawMessage.contains("不存在") {
            return "账号不存在，请先注册"
        } else if rawMessage.contains("密码") || rawMessage.contains("PASSWORD") {
            return "密码错误，请重试"
        } else if rawMessage.contains("验证码") && rawMessage.contains("过期") {
            return "验证码错误或已过期"
        } else if rawMessage.contains("验证码") {
            return "验证码错误或已过期"
        } else if rawMessage.contains("网络") || rawMessage.contains("network") || rawMessage.contains("timed out") {
            return "网络连接失败，请检查网络"
        } else if rawMessage.contains("HTTP Error") {
            return "\(context)失败，请稍后重试"
        } else {
            return rawMessage.isEmpty ? "\(context)失败，请稍后重试" : rawMessage
        }
    }

    private func presentAuthError(_ message: String) {
        errorMessage = message
        showingError = true
    }

    private func isValidPhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: phone)
    }
}
