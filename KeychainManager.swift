//
//  KeychainManager.swift
//  终活
//
//  Keychain 安全存储 - 用于永久登录
//  功能：安全存储 Token、密码等敏感信息
//

import Foundation
import Security

/// Keychain 管理器 - 安全存储敏感数据
/// 
/// 核心功能：
/// - 保存 Token（永久登录）
/// - 保存密码（可选，用于自动登录）
/// - 读取 Token
/// - 删除 Token（退出登录）
/// 
/// 技术要点：
/// - 使用 iOS Keychain 服务（最安全的本地存储）
/// - 数据加密存储（系统级加密）
/// - 应用卸载后自动清除
/// - 支持 iCloud 同步（可选）
class KeychainManager {
    static let shared = KeychainManager()
    
    private let serviceName = Bundle.main.bundleIdentifier ?? "com.zhonghuo.app"
    private let tokenKey = "zhonghuo_user_token"
    private let userIdKey = "zhonghuo_user_id"
    private let userPhoneKey = "zhonghuo_user_phone"
    
    // MARK: - 短信 API 密钥管理
    private let aliyunAccessKeyIdKey = "zhonghuo_aliyun_access_key_id"
    private let aliyunAccessKeySecretKey = "zhonghuo_aliyun_access_key_secret"
    private let tencentSecretIdKey = "zhonghuo_tencent_secret_id"
    private let tencentSecretKeyKey = "zhonghuo_tencent_secret_key"
    
    // MARK: - Token 管理
    
    /// 保存 Token 到 Keychain
    /// - Parameter token: JWT Token
    /// - Returns: 是否成功
    @discardableResult
    func saveToken(_ token: String) -> Bool {
        // 先删除旧的（如果有）
        deleteToken()
        
        // 🔧 修复：使用 kSecAttrAccessibleWhenUnlockedThisDeviceOnly 提高安全性
        // 仅在设备解锁时可用，且仅限当前设备（不通过 iCloud 备份）
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: token.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // 添加到 Keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ Keychain: Token 保存成功")
            return true
        } else {
            print("❌ Keychain: Token 保存失败 - \(status)")
            return false
        }
    }
    
    /// 从 Keychain 读取 Token
    /// - Returns: Token 字符串
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let token = String(data: data, encoding: .utf8) {
            print("✅ Keychain: Token 读取成功")
            return token
        } else {
            print("⚠️ Keychain: Token 读取失败 - \(status)")
            return nil
        }
    }
    
    /// 删除 Keychain 中的 Token
    /// - Returns: 是否成功
    @discardableResult
    func deleteToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: tokenKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            print("✅ Keychain: Token 删除成功")
            return true
        } else {
            print("❌ Keychain: Token 删除失败 - \(status)")
            return false
        }
    }
    
    // MARK: - 用户 ID 管理
    
    /// 保存用户 ID
    func saveUserId(_ userId: String) {
        saveItem(key: userIdKey, value: userId)
    }
    
    /// 读取用户 ID
    func getUserId() -> String? {
        return getItem(key: userIdKey)
    }
    
    /// 删除用户 ID
    func deleteUserId() {
        deleteItem(key: userIdKey)
    }
    
    // MARK: - 用户手机号管理
    
    /// 保存用户手机号
    func saveUserPhone(_ phone: String) {
        saveItem(key: userPhoneKey, value: phone)
    }
    
    /// 读取用户手机号
    func getUserPhone() -> String? {
        return getItem(key: userPhoneKey)
    }
    
    /// 删除用户手机号
    func deleteUserPhone() {
        deleteItem(key: userPhoneKey)
    }
    
    // MARK: - 通用方法
    
    /// 保存通用项
    private func saveItem(key: String, value: String) {
        // 先删除旧的
        deleteItem(key: key)
        
        // 🔧 修复：使用 kSecAttrAccessibleWhenUnlockedThisDeviceOnly 提高安全性
        // 仅在设备解锁时可用，且仅限当前设备（不通过 iCloud 备份）
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: value.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            print("✅ Keychain: \(key) 保存成功")
        } else {
            print("❌ Keychain: \(key) 保存失败 - \(status)")
        }
    }
    
    /// 读取通用项
    private func getItem(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }
        
        return nil
    }
    
    /// 删除通用项
    private func deleteItem(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - 短信 API 密钥管理
    
    /// 保存阿里云 AccessKey ID
    func saveAliyunAccessKeyId(_ keyId: String) {
        saveItem(key: aliyunAccessKeyIdKey, value: keyId)
    }
    
    /// 读取阿里云 AccessKey ID
    func getAliyunAccessKeyId() -> String? {
        return getItem(key: aliyunAccessKeyIdKey)
    }
    
    /// 保存阿里云 AccessKey Secret
    func saveAliyunAccessKeySecret(_ secret: String) {
        saveItem(key: aliyunAccessKeySecretKey, value: secret)
    }
    
    /// 读取阿里云 AccessKey Secret
    func getAliyunAccessKeySecret() -> String? {
        return getItem(key: aliyunAccessKeySecretKey)
    }
    
    /// 保存腾讯云 SecretId
    func saveTencentSecretId(_ secretId: String) {
        saveItem(key: tencentSecretIdKey, value: secretId)
    }
    
    /// 读取腾讯云 SecretId
    func getTencentSecretId() -> String? {
        return getItem(key: tencentSecretIdKey)
    }
    
    /// 保存腾讯云 SecretKey
    func saveTencentSecretKey(_ secretKey: String) {
        saveItem(key: tencentSecretKeyKey, value: secretKey)
    }
    
    /// 读取腾讯云 SecretKey
    func getTencentSecretKey() -> String? {
        return getItem(key: tencentSecretKeyKey)
    }
    
    // MARK: - 清空所有数据（退出登录时使用）
    
    /// 清空所有 Keychain 数据
    func clearAll() {
        deleteToken()
        deleteUserId()
        deleteUserPhone()
        // 不清空短信 API 密钥（它们是配置，不是登录凭证）
        print("✅ Keychain: 所有数据已清空")
    }
}
