//
//  GraphQLTypes.swift
//  终活
//
//  GraphQL 相关类型定义
//

import Foundation

// MARK: - API Errors

enum APIError: LocalizedError {
    case createFailed
    case updateFailed
    case deleteFailed
    case networkError
    case unauthorized
    case invalidURL
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .createFailed: return "创建失败"
        case .updateFailed: return "更新失败"
        case .deleteFailed: return "删除失败"
        case .networkError: return "网络错误"
        case .unauthorized: return "未授权"
        case .invalidURL: return "无效的 URL"
        case .decodingError: return "解码失败"
        }
    }
}

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

// MARK: - GraphQL Errors

enum GraphQLError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case noData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 URL"
        case .invalidResponse: return "无效的响应"
        case .httpError(let code): return "HTTP 错误：\(code)"
        case .serverError(let message): return "服务器错误：\(message)"
        case .noData: return "没有数据"
        case .decodingError: return "解码错误"
        }
    }
}

// MARK: - User Data Models

struct UserData: Decodable {
    let user: UserInfo
    let capsules: [CapsuleInfo]
    let wills: [WillInfo]
    let family: [FamilyInfo]
}

struct UserInfo: Decodable {
    let id: String
    let name: String
    let phone: String
    let createdAt: String
    let lastLoginAt: String?
    let lastLoginIp: String?
    let checkinCount: Int
    let stats: UserStats
}

struct UserStats: Decodable {
    let emergencyContactsCount: Int
    let witnessesCount: Int
    let capsulesCount: Int
    let willModulesCount: Int
    let familyCount: Int
    let assetsCount: Int
    let checkinCount: Int
}

struct CapsuleInfo: Decodable {
    let id: String
    let title: String
    let type: String
    let content: String?
    let openAt: String?
    let createdAt: String
}

struct WillInfo: Decodable {
    let id: String
    let type: String
    let title: String
    let content: String?
    let createdAt: String
}

struct FamilyInfo: Decodable {
    let id: String
    let relationType: String
    let relatedUserId: String
    let relatedUserName: String?
    let relatedUserPhone: String?
}
