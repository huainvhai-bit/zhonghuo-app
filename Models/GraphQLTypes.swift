//
//  GraphQLTypes.swift
//  终活
//
//  GraphQL 相关类型定义
//

import Foundation

// MARK: - GraphQL Response

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLErrorItem]?
}

struct GraphQLErrorItem: Decodable {
    let message: String
    let locations: [Location]?
    
    struct Location: Decodable {
        let line: Int
        let column: Int
    }
}

// MARK: - GraphQL Error

enum GraphQLError: LocalizedError {
    case serverError(String)
    case invalidResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .invalidResponse:
            return "无效的响应"
        case .decodingError:
            return "解码失败"
        }
    }
}
