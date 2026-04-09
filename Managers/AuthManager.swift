//
//  AuthManager.swift
//  终活 - 认证管理
//
//  ✅ P0 修复 #1: 实现真实登录逻辑
//

import Foundation

// ✅ 修复 #5: 标记为 @MainActor，确保所有 @Published 属性更新在主线程执行
@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isLoggedIn = false
    @Published var currentUser: String?
    @Published var authToken: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    /// 用户登录（GraphQL）
    /// - Parameters:
    ///   - phone: 手机号
    ///   - code: 验证码（或密码）
    /// - Returns: 是否成功
    func login(phone: String, code: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let query = """
            mutation {
                login(phone: "\(phone)", code: "\(code)") {
                    token
                    user {
                        id
                        name
                        phone
                    }
                }
            }
            """
            
            let client = APIClient.shared
            let response = try await client.query(query)
            
            guard let data = response["data"] as? [String: Any],
                  let loginData = data["login"] as? [String: Any],
                  let token = loginData["token"] as? String,
                  let userData = loginData["user"] as? [String: Any],
                  let userId = userData["id"] as? String,
                  let name = userData["name"] as? String else {
                throw NSError(domain: "LoginError", code: -1, userInfo: [NSLocalizedDescriptionKey: "登录响应数据无效"])
            }
            
            // 保存 Token 到 Keychain
            KeychainManager.shared.saveToken(token)
            KeychainManager.shared.saveUserId(userId)
            KeychainManager.shared.saveUserPhone(phone)
            
            // 更新状态
            isLoggedIn = true
            currentUser = name
            authToken = token
            
            print("✅ 登录成功：\(name) (\(phone))")
            
            // 触发数据同步
            await DataManager.shared.initializeAPIConfig()
            
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ 登录失败：\(error)")
            return false
        }
        
        isLoading = false
    }
    
    /// 用户注册（GraphQL）
    /// - Parameters:
    ///   - phone: 手机号
    ///   - code: 验证码
    ///   - name: 用户名
    /// - Returns: 是否成功
    func register(phone: String, code: String, name: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let query = """
            mutation {
                register(phone: "\(phone)", code: "\(code)", name: "\(name)") {
                    token
                    user {
                        id
                        name
                        phone
                    }
                }
            }
            """
            
            let client = APIClient.shared
            let response = try await client.query(query)
            
            guard let data = response["data"] as? [String: Any],
                  let registerData = data["register"] as? [String: Any],
                  let token = registerData["token"] as? String else {
                throw NSError(domain: "RegisterError", code: -1, userInfo: [NSLocalizedDescriptionKey: "注册响应数据无效"])
            }
            
            // 保存 Token
            KeychainManager.shared.saveToken(token)
            
            print("✅ 注册成功：\(name)")
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ 注册失败：\(error)")
            return false
        }
        
        isLoading = false
    }
    
    /// 退出登录
    func logout() {
        // 清除 Token
        KeychainManager.shared.deleteToken()
        KeychainManager.shared.deleteUserId()
        KeychainManager.shared.deleteUserPhone()
        
        // 清除本地用户文件
        UserManager.shared.clearAllUserFiles()
        
        // 重置状态
        isLoggedIn = false
        currentUser = nil
        authToken = nil
        errorMessage = nil
        
        print("🚪 退出登录成功")
    }
    
    /// 检查登录状态（从 Keychain 恢复）
    func checkLoginStatus() -> Bool {
        if let token = KeychainManager.shared.getToken(),
           let userId = KeychainManager.shared.getUserId() {
            isLoggedIn = true
            currentUser = KeychainManager.shared.getUserPhone() // 临时使用手机号
            authToken = token
            return true
        }
        return false
    }
}
