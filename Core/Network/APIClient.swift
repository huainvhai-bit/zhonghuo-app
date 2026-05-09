//
//  APIClient.swift
//  安伴助手
//
//  GraphQL + REST API 客户端
//  职责：统一执行 GraphQL 查询和 REST API 调用
//

import Foundation

/// GraphQL API 客户端
/// 职责：执行 GraphQL 查询、管理 Token、处理响应
/// 
/// ✅ P0 修复 #2: 完善错误处理和重试机制
class APIClient {
    static let shared = APIClient()
    
    private let configuredBaseURL: String
    private let maxRetries = 2  // 最大重试次数

    private var currentBaseURL: String {
        let rawURL = configuredBaseURL.isEmpty
            ? (UserDefaults.standard.string(forKey: "serverURL") ?? DataManager.apiURL)
            : configuredBaseURL
        let fallbackURL = rawURL.isEmpty ? AppConfig.defaultAPIURL : rawURL
        return NetworkUtils.normalizeBaseURL(fallbackURL)
    }
    
    init(baseURL: String = "") {
        self.configuredBaseURL = baseURL
    }
    
    /// 执行 GraphQL 查询（带重试机制）
    func query(_ query: String, variables: [String: Any]? = nil) async throws -> [String: Any] {
        var lastError: Error?
        
        // 重试机制
        for attempt in 1...maxRetries {
            do {
                return try await executeQuery(query, variables: variables)
            } catch {
                lastError = error
                if attempt < maxRetries {
                    print("⚠️ 请求失败，第 \(attempt) 次重试...")
                    try? await Task.sleep(nanoseconds: 500_000_000) // 等待 500ms
                }
            }
        }
        
        throw lastError ?? GraphQLError.unknown
    }
    
    /// 执行 GraphQL 查询（内部方法）
    private func executeQuery(_ query: String, variables: [String: Any]?) async throws -> [String: Any] {
        guard let url = URL(string: "\(currentBaseURL)/api/graphql.php") else {
            throw GraphQLError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = AppConfig.apiRequestTimeout  // ✅ 使用配置的超时时间
        
        // 动态读取 token（确保使用最新的 token）
        let currentToken = KeychainManager.shared.getToken()
        if let token = currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "query": query,
            "variables": variables ?? [:]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // ✅ 使用带超时的 URLSession 配置
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfig.apiRequestTimeout
        config.timeoutIntervalForResource = AppConfig.apiResourceTimeout
        let session = URLSession(configuration: config)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GraphQLError.invalidResponse
        }
        
        // ✅ 详细的错误处理
        switch httpResponse.statusCode {
        case 200...299:
            break  // 成功
        case 401:
            throw GraphQLError.unauthorized
        case 403:
            throw GraphQLError.forbidden
        case 404:
            throw GraphQLError.notFound
        case 500:
            throw GraphQLError.serverError("服务器内部错误")
        case 503:
            throw GraphQLError.serviceUnavailable
        default:
            throw GraphQLError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GraphQLError.decodingError
        }
        
        if let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
            let message = errors[0]["message"] as? String ?? "GraphQL 错误"
            BackendSecurityPolicy.postViolationIfNeeded(message)
            Logger.shared.e("GraphQL 错误：\(message)")
            throw GraphQLError.serverError(message)
        }
        
        return json
    }
    
    /// 执行 REST API 调用
    func restRequest(method: String, path: String, body: [String: Any]? = nil) async throws -> [String: Any] {
        guard let url = URL(string: "\(currentBaseURL)\(path)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let currentToken = KeychainManager.shared.getToken()
        if let token = currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
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
        
        return json
    }
    
    /// 获取服务器配置
    func fetchServerConfig(from baseURL: String) async throws -> [String: Any] {
        let configQuery = """
        query {
            getConfig {
                checkinIntervalHours
                notificationReminderThresholdHours
                notificationPushIntervalHours
            }
        }
        """
        
        return try await query(configQuery)
    }
}
