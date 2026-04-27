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
    @Published var identifier = ""
    @Published var password = ""
    @Published var captchaInput = ""
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
        let trimmedIdentifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        identifier = trimmedIdentifier
        guard isValidIdentifier(trimmedIdentifier) else {
            presentAuthError("请输入 4-30 位账号或有效手机号")
            return false
        }

        guard !password.isEmpty else {
            presentAuthError("请输入密码")
            return false
        }

        guard !captchaInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            presentAuthError("请输入图形验证码")
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
        let trimmedIdentifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let mutation = """
            mutation($identifier: String!, $password: String!, $captcha: String!, $captchaPurpose: String!) {
                login(identifier: $identifier, password: $password, captcha: $captcha, captchaPurpose: $captchaPurpose) {
                    success
                    token
                    user {
                        id
                        account
                        name
                        phone
                    }
                }
            }
        }
        """

        let variables: [String: Any] = [
            "identifier": trimmedIdentifier,
            "password": password,
            "captcha": captchaInput.trimmingCharacters(in: .whitespacesAndNewlines),
            "captchaPurpose": "login"
        ]

        let response = try await graphqlAuthRequest(mutation: mutation, variables: variables)
        return await handleAuthSuccess(response)
    }

    private func graphqlAuthRequest(mutation: String, variables: [String: Any]) async throws -> [String: Any] {
        let rawBaseURL = UserDefaults.standard.string(forKey: "lastUsedBaseURL") ?? "zhonghuo.zhonghuo.xyz"
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
            let fallbackMessage = bodyErrorMessage(from: data, statusCode: httpResponse.statusCode, context: "登录")
            throw NSError(domain: fallbackMessage, code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: fallbackMessage])
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
        if let account = user["account"] as? String, !account.isEmpty {
            KeychainManager.shared.saveUserAccount(account)
        }
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
        if errorMsg.contains("CAPTCHA_ERROR:") {
            captchaInput = ""
        }
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
        case 401: return "登录已失效，请重新登录"
        case 403: return "当前账号无权限操作"
        case 500: return "\(context)失败，请稍后重试"
        case 503: return "服务器暂不可用，请稍后重试"
        default: return "服务器返回 \(statusCode)"
        }
    }

    private func mappedAuthMessage(from rawMessage: String, context: String) -> String {
        if rawMessage.contains("SQLSTATE") || rawMessage.contains("Unknown column") || rawMessage.contains("doesn't have a default value") || rawMessage.contains("cannot be null") {
            return rawMessage
        } else if rawMessage.contains("ACCOUNT_NOT_FOUND:") {
            return "账号不存在，请先注册"
        } else if rawMessage.contains("PASSWORD_ERROR:") {
            return "密码错误，请重试"
        } else if rawMessage.contains("CAPTCHA_ERROR:") {
            return "图形验证码错误或已过期，请刷新后重试"
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

    private func isValidIdentifier(_ identifier: String) -> Bool {
        guard !identifier.isEmpty, identifier.count <= 30 else { return false }
        if identifier.rangeOfCharacter(from: .whitespacesAndNewlines) != nil {
            return false
        }
        let phonePattern = "^1[3-9]\\d{9}$"
        let accountPattern = "^[^\\s]{4,30}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phonePattern)
        let accountPredicate = NSPredicate(format: "SELF MATCHES %@", accountPattern)
        let result = phonePredicate.evaluate(with: identifier) || accountPredicate.evaluate(with: identifier)
        return result
    }
}
