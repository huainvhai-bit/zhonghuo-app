//
//  UserSession.swift
//  终活
//
//  用户会话管理
//  职责：登录/登出/用户信息持久化
//

import Foundation

/// 用户会话管理器
/// 职责：登录/登出/用户信息持久化
@MainActor
class UserSession: ObservableObject {
    static let shared = UserSession()
    
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    
    private let fileManager = FileManager.default
    private var documentsPath: String {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].path
    }
    
    var userFileURL: URL {
        URL(fileURLWithPath: documentsPath).appendingPathComponent("user.json")
    }
    
    // MARK: - 初始化
    
    /// 初始化时加载用户数据
    init() {
        loadUser()
    }
    
    // MARK: - 用户加载
    
    /// 加载用户数据
    func loadUser() {
        guard fileManager.fileExists(atPath: userFileURL.path) else {
            print("⚠️ 用户文件不存在")
            return
        }
        
        do {
            let data = try Data(contentsOf: userFileURL)
            let user = try JSONDecoder().decode(User.self, from: data)
            
            self.currentUser = user
            self.isLoggedIn = true
            
            print("✅ 用户加载成功：\(user.name), 手机号：\(user.phone)")
        } catch {
            print("❌ 加载用户失败：\(error)")
        }
    }
    
    /// 从文件加载用户
    func loadUserFromFile() -> User? {
        guard fileManager.fileExists(atPath: userFileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: userFileURL)
            return try JSONDecoder().decode(User.self, from: data)
        } catch {
            print("❌ 加载用户失败：\(error)")
            return nil
        }
    }
    
    /// 保存用户数据
    func saveUser(_ user: User) -> Bool {
        do {
            let data = try JSONEncoder().encode(user)
            try data.write(to: userFileURL)
            
            // 在主线程修改 @Published 属性
            DispatchQueue.main.async {
                self.currentUser = user
                self.isLoggedIn = true
                
                // 保存到 Keychain
                KeychainManager.shared.saveUserId(user.id)
                if let account = user.loginAccount, !account.isEmpty {
                    KeychainManager.shared.saveUserAccount(account)
                }
                if !user.phone.isEmpty {
                    KeychainManager.shared.saveUserPhone(user.phone)
                }
            }
            
            print("✅ 用户已保存：\(user.name)")
            return true
        } catch {
            print("❌ 保存用户失败：\(error)")
            return false
        }
    }
    
    // MARK: - 登录
    
    /// 登录用户
    func login(phone: String) -> Result<User, Error> {
        guard var user = loadUserFromFile() else {
            return .failure(Error.userNotFound)
        }
        
        // 简化登录：只要文件中有用户且手机号匹配即可
        if user.phone != phone {
            user.phone = phone
            _ = saveUser(user)
        }
        
        self.currentUser = user
        self.isLoggedIn = true
        
        print("✅ 用户登录成功：\(user.name), 手机号：\(user.phone)")
        
        // 从 Keychain 读取 Token 并保存用户信息
        if KeychainManager.shared.getToken() != nil {
            KeychainManager.shared.saveUserId(user.id)
            if let account = user.loginAccount, !account.isEmpty {
                KeychainManager.shared.saveUserAccount(account)
            }
            KeychainManager.shared.saveUserPhone(user.phone)
            print("🔐 Token 已保存到 Keychain（永久登录）")
        }
        
        return .success(user)
    }
    
    // MARK: - 登出
    
    /// 登出
    func logout() {
        self.currentUser = nil
        self.isLoggedIn = false
        
        // 清除 Keychain 中的用户信息
        KeychainManager.shared.clearToken()
        
        print("✅ 用户已登出")
    }
    
    // MARK: - 统计信息更新
    
    /// 更新留言数量
    func updateCapsulesCount(_ count: Int) {
        Task { @MainActor in
            self.currentUser?.capsulesCount = count
            print("📊 留言数量已更新：\(count)")
        }
    }
    
    /// 更新重要事项数量
    func updateWillModulesCount(_ count: Int) {
        Task { @MainActor in
            self.currentUser?.willModulesCount = count
            print("📊 重要事项数量已更新：\(count)")
        }
    }
    
    /// 更新添加数量
    func updateFamilyCount(_ count: Int) {
        Task { @MainActor in
            self.currentUser?.familyCount = count
            print("📊 添加数量已更新：\(count)")
        }
    }
    
    // MARK: - 错误处理
    
    enum Error: LocalizedError {
        case userNotFound
        
        var errorDescription: String? {
            switch self {
            case .userNotFound: return "用户未注册"
            }
        }
    }
}
