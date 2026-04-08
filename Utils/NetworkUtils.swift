//
//  NetworkUtils.swift
//  终活
//
//  网络工具类
//  职责：自动识别 HTTP/HTTPS 协议、URL 处理
//

import Foundation

/// 网络协议工具
enum NetworkProtocol {
    case http
    case https
    case auto
    
    var scheme: String {
        switch self {
        case .http: return "http"
        case .https: return "https"
        case .auto: return "http" // 默认使用 HTTP
        }
    }
}

/// 网络工具类
class NetworkUtils {
    
    /// 自动检测服务器协议（HTTP 或 HTTPS）
    /// - Parameter baseURL: 服务器地址（可以不带协议）
    /// - Returns: 带有正确协议的完整 URL
    static func normalizeBaseURL(_ baseURL: String) -> String {
        // 如果已经包含协议，直接返回
        if baseURL.hasPrefix("http://") || baseURL.hasPrefix("https://") {
            return baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 默认使用 HTTP（适配本地开发环境）
        return "http://\(baseURL.trimmingCharacters(in: .whitespacesAndNewlines))"
    }
    
    /// 智能检测服务器协议
    /// 先尝试 HTTPS，失败后回退到 HTTP
    /// - Parameter baseURL: 服务器地址
    /// - Returns: 可用的协议类型
    static func detectProtocol(baseURL: String) async -> NetworkProtocol {
        let cleanURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果已经指定协议，直接返回
        if cleanURL.hasPrefix("https://") {
            return .https
        }
        if cleanURL.hasPrefix("http://") {
            return .http
        }
        
        // 先尝试 HTTPS
        let httpsURL = "https://\(cleanURL)/api/health.php"
        if await checkURLAccessibility(url: httpsURL) {
            return .https
        }
        
        // HTTPS 失败，尝试 HTTP
        let httpURL = "http://\(cleanURL)/api/health.php"
        if await checkURLAccessibility(url: httpURL) {
            return .http
        }
        
        // 都无法访问，默认返回 HTTP（本地开发常用）
        return .http
    }
    
    /// 检查 URL 是否可访问
    /// - Parameter url: 要检查的 URL
    /// - Returns: 是否可访问
    private static func checkURLAccessibility(url: String) async -> Bool {
        guard let validURL = URL(string: url) else {
            return false
        }
        
        var request = URLRequest(url: validURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            return (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 404
        } catch {
            return false
        }
    }
    
    /// 获取完整的 API URL（自动识别协议）
    /// - Parameters:
    ///   - baseURL: 服务器基础地址
    ///   - path: API 路径
    /// - Returns: 完整的 API URL
    static func buildAPIURL(baseURL: String, path: String) -> String {
        let normalizedBase = normalizeBaseURL(baseURL)
        return "\(normalizedBase)\(path)"
    }
}
