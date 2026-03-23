//
//  GraphQLClient.swift
//  终活
//
//  GraphQL 客户端 - 统一数据查询
//

import Foundation

class GraphQLClient {
    static let shared = GraphQLClient()
    
    private let baseURL: String
    private var token: String?
    
    init() {
        self.baseURL = UserDefaults.standard.string(forKey: "serverURL") ?? DataManager.apiURL
        self.token = UserDefaults.standard.string(forKey: "userToken")
    }
    
    /// 执行 GraphQL 查询
    func query<T: Decodable>(_ query: String, variables: [String: Any]? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)/api/graphql.php") else {
            throw GraphQLError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
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
        
        let result = try JSONDecoder().decode(GraphQLResponse<T>.self, from: data)
        
        if let errors = result.errors, !errors.isEmpty {
            throw GraphQLError.serverError(errors[0].message)
        }
        
        guard let data = result.data else {
            throw GraphQLError.noData
        }
        
        return data
    }
    
    /// 设置 Token
    func setToken(_ token: String?) {
        self.token = token
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

// MARK: - GraphQL Queries

extension GraphQLClient {
    /// 获取用户完整数据（一次性查询）
    func fetchUserData() async throws -> UserData {
        let query = """
        {
            user {
                id
                name
                phone
                createdAt
                lastLoginAt
                lastLoginIp
                checkinCount
                stats {
                    emergencyContactsCount
                    witnessesCount
                    capsulesCount
                    willModulesCount
                    familyCount
                }
            }
            capsules {
                id
                title
                type
                content
                openAt
                createdAt
            }
            wills {
                id
                type
                title
                content
                createdAt
            }
            family {
                id
                relationType
                relatedUserId
                relatedUserName
                relatedUserPhone
            }
        }
        """
        
        return try await query(query)
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
