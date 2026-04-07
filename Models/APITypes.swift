//
//  APITypes.swift
//  终活
//
//  API 相关类型定义（Token 刷新/Refresh Token）
//

import Foundation

// MARK: - Token 刷新服务（P0 修复）

/// Token 自动刷新服务
/// 功能：Token 过期时自动调用 refreshToken API 获取新 Token
/// 优先级：P0（高风险 - 用户体验差）
class TokenRefreshService {
    static let shared = TokenRefreshService()
    
    private var isRefreshing = false
    private var refreshQueue: [(_ token: String?) -> Void] = []
    
    /// 刷新 Token（如果已过期）
    func refreshTokenIfNeeded() async -> String? {
        // 检查 Token 是否存在
        guard let token = KeychainManager.shared.getToken() else {
            return nil
        }
        
        // 检查 Token 是否即将过期（5分钟内）
        guard let expirationTime = KeychainManager.shared.getTokenExpiration(),
              Date().timeIntervalSince1970 >= expirationTime.timeIntervalSince1970 - 300 else {
            return token // Token 仍然有效
        }
        
        // 标记正在刷新（避免并发刷新）
        guard !isRefreshing else {
            // 等待 Refresh 完成
            return await withCheckedContinuation { continuation in
                refreshQueue.append { continuation.resume(returning: $0) }
            }
        }
        
        isRefreshing = true
        
        // 获取 Refresh Token
        guard let refreshToken = KeychainManager.shared.getRefreshToken() else {
            isRefreshing = false
            print("❌ 没有 Refresh Token，无法刷新")
            return nil
        }
        
        print("🔵 Token 即将过期，开始刷新...")
        
        // 调用后端 refreshToken API
        do {
            let result = try await refreshTokenAPI(refreshToken)
            isRefreshing = false
            
            // 更新 Token 和 Refresh Token
            if let newToken = result.token {
                KeychainManager.shared.saveToken(newToken, expiration: result.expiresIn)
                print("✅ Token 刷新成功")
            }
            if let newRefreshToken = result.refreshToken {
                KeychainManager.shared.saveRefreshToken(newRefreshToken)
            }
            
            // 唤醒等待队列
            let callbacks = refreshQueue
            refreshQueue.removeAll()
            callbacks.forEach { $0(result.token) }
            
            return result.token
        } catch {
            isRefreshing = false
            print("❌ Token 刷新失败：\(error.localizedDescription)")
            
            // 刷新失败，清空 Token
            KeychainManager.shared.clearToken()
            
            // 唤醒等待队列
            let callbacks = refreshQueue
            refreshQueue.removeAll()
            callbacks.forEach { $0(nil) }
            
            return nil
        }
    }
    
    /// 重置刷新状态（登录成功后调用）
    func resetRefreshState() {
        isRefreshing = false
        refreshQueue.forEach { $0(nil) }
        refreshQueue.removeAll()
    }
}

// MARK: - Token Refresh Response

struct TokenRefreshResult {
    let token: String?
    let refreshToken: String?
    let expiresIn: Int
}

// MARK: - Token Refresh API

/// 刷新 Token
/// - Parameter refreshToken: Refresh Token
/// - Returns: TokenRefreshResult (包含新 token 和 refresh token)
func refreshTokenAPI(_ refreshToken: String) async throws -> TokenRefreshResult {
    print("🔵 refreshTokenAPI 开始...")
    
    // 从 UserDefaults 读取 serverURL
    let baseURL = UserDefaults.standard.string(forKey: "serverURL") ?? "https://api.zhonghuo.app"
    guard let url = URL(string: "\(baseURL)/api/graphql.php") else {
        throw APIError.invalidURL
    }
    
    // 构建 GraphQL 查询
    let query = """
    mutation {
        refreshToken(refreshToken: "\\(refreshToken)") {
            token
            refreshToken
            expiresIn
        }
    }
    """
    
    // 构建请求
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // 读取当前 Token
    let currentToken = KeychainManager.shared.getToken()
    if let token = currentToken {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    let body: [String: Any] = ["query": query]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    
    // 发送请求
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIError.invalidResponse
    }
    
    guard (200...299).contains(httpResponse.statusCode) else {
        throw APIError.networkError
    }
    
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw APIError.decodingError
    }
    
    // 解析结果
    if let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
        let message = errors[0]["message"] as? String ?? "GraphQL 错误"
        throw GraphQLError.serverError(message)
    }
    
    if let data = json["data"] as? [String: Any],
       let refreshData = data["refreshToken"] as? [String: Any] {
        return TokenRefreshResult(
            token: refreshData["token"] as? String,
            refreshToken: refreshData["refreshToken"] as? String,
            expiresIn: (refreshData["expiresIn"] as? Int) ?? 7200
        )
    }
    
    print("❌ refreshTokenAPI 解析失败：\(json)")
    throw APIError.decodingError
}
