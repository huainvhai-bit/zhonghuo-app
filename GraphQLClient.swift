//
//  GraphQLClient.swift
//  终活 App
//
//  GraphQL 客户端 - 发送 GraphQL 查询和 Mutation
//
//  技术文档：📖 终活 App 技术开发文档.md - 第 5 章 GraphQL 架构
//

import Foundation

/// GraphQL 客户端 - 单例模式
///
/// 功能：
/// - 发送 GraphQL 查询
/// - 发送 GraphQL Mutation
/// - 错误处理（网络错误、JSON 解析错误、HTTP 状态码错误）
@MainActor
class GraphQLClient {
    static let shared = GraphQLClient()
    
    private init() {}
    
    // MARK: - 发送 GraphQL 查询
    
    /// 发送 GraphQL 查询
    ///
    /// - Parameters:
    ///   - query: GraphQL 查询字符串
    ///   - variables: 变量字典
    ///   - baseURL: API 地址（如 https://8.136.41.211:3395）
    /// - Returns: 响应数据（[String: Any]）
    /// - Throws: URLError 或 JSON 解析错误
    func sendGraphQLQuery(query: String, variables: [String: Any], baseURL: String) throws -> [String: Any] {
        print("🔵 GraphQLClient: 发送查询")
        
        // 1. 验证 baseURL
        guard !baseURL.isEmpty else {
            print("❌ GraphQLClient: baseURL 为空")
            throw URLError(.badURL)
        }
        
        // 2. 构建 URL
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 3. 构建请求体
        let requestBody: [String: Any] = [
            "query": query,
            "variables": variables
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 4. 发送请求
        print("🔵 GraphQLClient: 请求 URL = \(baseURL)")
        
        let (data, response) = try URLSession.shared.data(for: request)
        
        // 5. 检查 HTTP 状态码
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ GraphQLClient: 无效的响应")
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ GraphQLClient: HTTP 状态码错误 = \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        // 6. 解析 JSON 响应
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let responseDict = json else {
            print("❌ GraphQLClient: JSON 解析失败")
            throw URLError(.badServerResponse)
        }
        
        print("✅ GraphQLClient: 查询成功")
        
        // 7. 检查是否有 GraphQL 错误
        if let errors = responseDict["errors"] as? [[String: Any]] {
            print("⚠️ GraphQLClient: GraphQL errors = \(errors)")
            // 可以在这里添加错误上报
        }
        
        return responseDict
    }
    
    // MARK: - 错误处理
    
    /// 记录 GraphQL 错误
    func handleGraphQLError(_ error: Error, context: String = "") {
        print("❌ GraphQL Error - \(context): \(error.localizedDescription)")
        
        // 可以添加错误上报逻辑
        // Analytics.shared.recordError(error, context: context)
    }
}
