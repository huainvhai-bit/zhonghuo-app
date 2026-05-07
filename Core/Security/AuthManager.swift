//
//  AuthManager.swift
//  安心助手 - 认证管理
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
    ///   - identifier: 账号或手机号
    ///   - password: 密码
    /// - Returns: 是否成功
    func login(identifier: String, password: String, captcha: String, captchaPurpose: String = "login") async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let query = """
            mutation Login($identifier: String!, $password: String!, $captcha: String!, $captchaPurpose: String!) {
                login(identifier: $identifier, password: $password, captcha: $captcha, captchaPurpose: $captchaPurpose) {
                    token
                    user {
                        id
                        account
                        name
                        phone
                    }
                }
            }
            """
            let variables: [String: Any] = [
                "identifier": identifier,
                "password": password,
                "captcha": captcha,
                "captchaPurpose": captchaPurpose
            ]
            
            let client = APIClient.shared
            let response = try await client.query(query, variables: variables)
            
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
            if let account = userData["account"] as? String {
                KeychainManager.shared.saveUserAccount(account)
            }
            if let phone = userData["phone"] as? String {
                KeychainManager.shared.saveUserPhone(phone)
            }
            
            // 更新状态
            isLoggedIn = true
            currentUser = name
            authToken = token
            
            Logger.shared.i("登录成功：\(name) (\(identifier))")
            
            // 触发数据同步
            DataManager.shared.initializeAPIConfig()
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            Logger.shared.e("登录失败：\(error)")
            isLoading = false
            return false
        }
    }
    
    /// 用户注册（GraphQL）
    /// - Parameters:
    ///   - account: 账号
    ///   - phone: 手机号（可选）
    ///   - password: 密码
    ///   - name: 用户名
    /// - Returns: 是否成功
    func register(account: String, phone: String?, password: String, name: String, captcha: String, securityQuestion: String, securityAnswer: String, captchaPurpose: String = "register") async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let query = """
            mutation Register($account: String!, $phone: String, $password: String!, $name: String!, $captcha: String!, $captchaPurpose: String!, $securityQuestion: String!, $securityAnswer: String!) {
                register(account: $account, phone: $phone, password: $password, name: $name, captcha: $captcha, captchaPurpose: $captchaPurpose, securityQuestion: $securityQuestion, securityAnswer: $securityAnswer) {
                    token
                    user {
                        id
                        account
                        name
                        phone
                    }
                }
            }
            """
            let phoneValue: Any = (phone?.isEmpty == false) ? phone! : NSNull()
            let variables: [String: Any] = [
                "account": account,
                "phone": phoneValue,
                "password": password,
                "name": name,
                "captcha": captcha,
                "captchaPurpose": captchaPurpose,
                "securityQuestion": securityQuestion,
                "securityAnswer": securityAnswer
            ]
            
            let client = APIClient.shared
            let response = try await client.query(query, variables: variables)
            
            guard let data = response["data"] as? [String: Any],
                  let registerData = data["register"] as? [String: Any],
                  let token = registerData["token"] as? String else {
                throw NSError(domain: "RegisterError", code: -1, userInfo: [NSLocalizedDescriptionKey: "注册响应数据无效"])
            }
            
            // 保存 Token
            KeychainManager.shared.saveToken(token)
            if let userData = registerData["user"] as? [String: Any],
               let userId = userData["id"] as? String {
                KeychainManager.shared.saveUserId(userId)
                if let account = userData["account"] as? String {
                    KeychainManager.shared.saveUserAccount(account)
                }
                if let phone = userData["phone"] as? String {
                    KeychainManager.shared.saveUserPhone(phone)
                }
            }
            
            Logger.shared.i("注册成功：\(name)")
            isLoading = false
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            Logger.shared.e("注册失败：\(error)")
            isLoading = false
            return false
        }
    }
    
    /// 退出登录
    func logout() {
        DataManager.shared.clearSessionUserData()

        // 清除 Token
        KeychainManager.shared.deleteToken()
        KeychainManager.shared.deleteUserId()
        KeychainManager.shared.deleteUserAccount()
        KeychainManager.shared.deleteUserPhone()
        
        // 清除本地用户文件
        UserManager.shared.clearAllUserFiles()
        
        // 重置状态
        isLoggedIn = false
        currentUser = nil
        authToken = nil
        errorMessage = nil
        
        Logger.shared.i("退出登录成功")
    }
    
    /// 检查登录状态（从 Keychain 恢复）
    func checkLoginStatus() -> Bool {
        if let token = KeychainManager.shared.getToken(),
           let _ = KeychainManager.shared.getUserId() {
            isLoggedIn = true
            currentUser = KeychainManager.shared.getUserAccount() ?? KeychainManager.shared.getUserPhone()
            authToken = token
            return true
        }
        return false
    }
}
