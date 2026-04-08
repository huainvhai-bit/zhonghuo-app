//
//  AccountValidator.swift
//  终活
//
//  启动时账号验证 - 验证本地账号与服务器是否一致
//

import Foundation
import SwiftUI

/// 账号验证管理器
@MainActor
class AccountValidator: ObservableObject {
    static let shared = AccountValidator()
    
    @Published var isValidating = false
    @Published var validationError: String?
    @Published var shouldLogout = false
    
    private let userManager = UserManager.shared
    private let dataManager = DataManager.shared
    
    private init() {}
    
    /// 启动时验证账号
    /// - Returns: 是否验证成功
    func validateAccountOnLaunch() async -> Bool {
        // 如果用户未登录，跳过验证
        guard userManager.isLoggedIn, let user = userManager.currentUser else {
            print("⚠️ 用户未登录，跳过账号验证")
            return true
        }
        
        print("🔐 开始验证账号：\(user.name) (\(user.phone))")
        isValidating = true
        validationError = nil
        
        // 等待网络可用
        if !await waitForNetwork() {
            validationError = "网络不可用，请稍后重试"
            isValidating = false
            return false
        }
        
        // 验证账号
        let result = await validateUserCredentials(user: user)
        
        if result {
            print("✅ 账号验证成功")
        } else {
            print("❌ 账号验证失败：\(validationError ?? "未知错误")")
            // 自动退出登录
            await logout()
        }
        
        isValidating = false
        return result
    }
    
    /// 等待网络可用（最多等待 5 秒）
    private func waitForNetwork() async -> Bool {
        let maxWaitTime: TimeInterval = 5.0
        let checkInterval: TimeInterval = 0.5
        var waitedTime: TimeInterval = 0
        
        while waitedTime < maxWaitTime {
            if await isNetworkAvailable() {
                return true
            }
            
            try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
            waitedTime += checkInterval
        }
        
        print("⚠️ 等待网络超时")
        return false
    }
    
    /// 检查网络是否可用
    private func isNetworkAvailable() async -> Bool {
        guard !dataManager.apiURL.isEmpty else {
            return false
        }
        
        // 尝试访问 GraphQL API
        do {
            let query = "query { getConfig { checkinIntervalHours } }"
            let url = URL(string: "\(dataManager.apiURL)/api/graphql.php")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query])
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                return (200...299).contains(httpResponse.statusCode)
            }
        } catch {
            print("⚠️ 网络检查失败：\(error)")
        }
        
        return false
    }
    
    /// 验证用户凭证（使用 Token 验证，不再存储密码）
    private func validateUserCredentials(user: User) async -> Bool {
        // ✅ 安全修复：不再使用密码验证，仅使用 Token 验证
        return await validateByUserInfo(user: user)
    }
    
    /// 通过获取用户信息验证（兼容旧版本）
    private func validateByUserInfo(user: User) async -> Bool {
        guard !dataManager.apiURL.isEmpty else {
            validationError = "API 未初始化"
            return false
        }
        
        let token = KeychainManager.shared.getToken() ?? ""
        
        do {
            let query = """
            query {
                user {
                    id
                    name
                    phone
                    status
                }
            }
            """
            
            let url = URL(string: "\(dataManager.apiURL)/api/graphql.php")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query])
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    if let userData = json?["data"] as? [String: Any],
                       let userDataDict = userData["user"] as? [String: Any],
                       let phone = userDataDict["phone"] as? String {
                        // 验证手机号是否匹配
                        if phone == user.phone {
                            return true
                        } else {
                            validationError = "账号信息不匹配"
                            return false
                        }
                    } else {
                        validationError = result.message ?? "获取用户信息失败"
                        return false
                    }
                } else if httpResponse.statusCode == 401 {
                    validationError = "登录已过期，请重新登录"
                    return false
                } else {
                    validationError = "服务器错误：\(httpResponse.statusCode)"
                    return false
                }
            }
        } catch {
            print("❌ 获取用户信息失败：\(error)")
            validationError = error.localizedDescription
        }
        
        return false
    }
    
    /// 退出登录
    private func logout() {
        print("🚪 自动退出登录")
        
        // 清除用户数据
        userManager.logout()
        
        // 清除 Keychain 中的 Token
        KeychainManager.shared.clearAll()
        
        // 标记需要退出
        shouldLogout = true
        
        // 发送通知
        NotificationCenter.default.post(name: NSNotification.Name("AccountInvalid"), object: nil)
    }
}

// MARK: - 响应模型

struct ValidateResponse: Codable {
    let status: String
    let message: String?
}

struct UserInfoResponse: Codable {
    let status: String
    let data: UserInfoData?
    let message: String?
}

struct UserInfoData: Codable {
    let id: String
    let name: String
    let phone: String
    let avatar: String?
}

// MARK: - 通知扩展

extension NotificationCenter {
    func postAccountInvalid() {
        post(name: NSNotification.Name("AccountInvalid"), object: nil)
    }
    
    func postContactChanged() {
        post(name: NSNotification.Name("EmergencyContactChanged"), object: nil)
    }
}
