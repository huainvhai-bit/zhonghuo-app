//
//  APIClient.swift
//  终活
//
//  GraphQL + REST API 客户端
//  职责：统一执行 GraphQL 查询和 REST API 调用
//

import Foundation

/// GraphQL API 客户端
/// 职责：执行 GraphQL 查询、管理 Token、处理响应
class APIClient {
    static let shared = APIClient()
    
    private let baseURL: String
    
    init(baseURL: String = "") {
        self.baseURL = baseURL.isEmpty ? UserDefaults.standard.string(forKey: "serverURL") ?? DataManager.apiURL : baseURL
    }
    
    /// 执行 GraphQL 查询
    func query(_ query: String, variables: [String: Any]? = nil) async throws -> [String: Any] {
        guard let url = URL(string: "\(baseURL)/api/graphql.php") else {
            throw GraphQLError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GraphQLError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw GraphQLError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GraphQLError.decodingError
        }
        
        if let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
            let message = errors[0]["message"] as? String ?? "GraphQL 错误"
            throw GraphQLError.serverError(message)
        }
        
        return json
    }
    
    /// 执行 REST API 调用
    func restRequest(method: String, path: String, body: [String: Any]? = nil) async throws -> [String: Any] {
        guard let url = URL(string: "\(baseURL)\(path)") else {
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
        let query = """
        query {
            getConfig {
                checkinIntervalHours
                notificationReminderThresholdHours
                notificationPushIntervalHours
                smsIsDevelopment
            }
        }
        """
        
        return try await query(query)
    }
}
