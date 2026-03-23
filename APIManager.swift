//
//  APIManager.swift
//  终活
//
//  统一 API 管理器 - 基于 GraphQL
//  所有数据请求都通过此管理器
//

import Foundation

class APIManager {
    static let shared = APIManager()
    
    private let client = GraphQLClient.shared
    
    /// 获取用户完整数据
    func fetchUserData() async throws -> UserData {
        return try await client.fetchUserData()
    }
    
    /// 签到
    func checkIn(isAuto: Bool = false, location: [String: Any]? = nil) async throws {
        let query = """
        mutation {
            checkIn(isAuto: \(isAuto), location: \(location != nil ? "..." : "null")) {
                success
                checkInTime
            }
        }
        """
        
        // 简化实现，直接调用
        try await client.query(query)
    }
    
    /// 上传位置
    func uploadLocation(latitude: Double, longitude: Double, accuracy: Double?) async throws {
        let query = """
        mutation {
            uploadLocation(latitude: \(latitude), longitude: \(longitude), accuracy: \(accuracy ?? 0)) {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 创建胶囊
    func createCapsule(title: String, type: String, content: String?, openAt: String?) async throws -> String {
        let query = """
        mutation {
            createCapsule(title: "\(title)", type: "\(type)", content: "\(content ?? "")", openAt: "\(openAt ?? "")") {
                id
                success
            }
        }
        """
        
        let result: [String: Any] = try await client.query(query)
        if let data = result["createCapsule"] as? [String: Any],
           let id = data["id"] as? String {
            return id
        }
        throw APIError.createFailed
    }
    
    /// 更新胶囊
    func updateCapsule(id: String, title: String, type: String, content: String?, openAt: String?) async throws {
        let query = """
        mutation {
            updateCapsule(id: "\(id)", title: "\(title)", type: "\(type)", content: "\(content ?? "")", openAt: "\(openAt ?? "")") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 删除胶囊
    func deleteCapsule(id: String) async throws {
        let query = """
        mutation {
            deleteCapsule(id: "\(id)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 创建遗嘱
    func createWill(title: String, type: String, content: String?) async throws -> String {
        let query = """
        mutation {
            createWill(title: "\(title)", type: "\(type)", content: "\(content ?? "")") {
                id
                success
            }
        }
        """
        
        let result: [String: Any] = try await client.query(query)
        if let data = result["createWill"] as? [String: Any],
           let id = data["id"] as? String {
            return id
        }
        throw APIError.createFailed
    }
    
    /// 更新遗嘱
    func updateWill(id: String, title: String, type: String, content: String?) async throws {
        let query = """
        mutation {
            updateWill(id: "\(id)", title: "\(title)", type: "\(type)", content: "\(content ?? "")") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 删除遗嘱
    func deleteWill(id: String) async throws {
        let query = """
        mutation {
            deleteWill(id: "\(id)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 创建资产
    func createAsset(name: String, type: String, value: Double?, description: String?) async throws -> String {
        let query = """
        mutation {
            createAsset(name: "\(name)", type: "\(type)", value: \(value ?? 0), description: "\(description ?? "")") {
                id
                success
            }
        }
        """
        
        let result: [String: Any] = try await client.query(query)
        if let data = result["createAsset"] as? [String: Any],
           let id = data["id"] as? String {
            return id
        }
        throw APIError.createFailed
    }
    
    /// 更新资产
    func updateAsset(id: String, name: String, type: String, value: Double?, description: String?) async throws {
        let query = """
        mutation {
            updateAsset(id: "\(id)", name: "\(name)", type: "\(type)", value: \(value ?? 0), description: "\(description ?? "")") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 删除资产
    func deleteAsset(id: String) async throws {
        let query = """
        mutation {
            deleteAsset(id: "\(id)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 生成邀请码
    func generateInviteCode(relationType: String) async throws -> String {
        let query = """
        mutation {
            inviteFamily(relationType: "\(relationType)") {
                inviteCode
                success
            }
        }
        """
        
        let result: [String: Any] = try await client.query(query)
        if let data = result["inviteFamily"] as? [String: Any],
           let code = data["inviteCode"] as? String {
            return code
        }
        throw APIError.createFailed
    }
    
    /// 接受邀请
    func acceptFamilyInvite(inviteCode: String) async throws {
        let query = """
        mutation {
            acceptFamilyInvite(inviteCode: "\(inviteCode)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 拒绝邀请
    func rejectFamilyInvite(inviteCode: String) async throws {
        let query = """
        mutation {
            rejectFamilyInvite(inviteCode: "\(inviteCode)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 移除家人
    func removeFamily(id: String) async throws {
        let query = """
        mutation {
            removeFamily(id: "\(id)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 创建紧急联系人
    func createEmergencyContact(name: String, phone: String, relationship: String) async throws -> String {
        let query = """
        mutation {
            createEmergencyContact(name: "\(name)", phone: "\(phone)", relationship: "\(relationship)") {
                id
                success
            }
        }
        """
        
        let result: [String: Any] = try await client.query(query)
        if let data = result["createEmergencyContact"] as? [String: Any],
           let id = data["id"] as? String {
            return id
        }
        throw APIError.createFailed
    }
    
    /// 更新紧急联系人
    func updateEmergencyContact(id: String, name: String, phone: String, relationship: String) async throws {
        let query = """
        mutation {
            updateEmergencyContact(id: "\(id)", name: "\(name)", phone: "\(phone)", relationship: "\(relationship)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 删除紧急联系人
    func deleteEmergencyContact(id: String) async throws {
        let query = """
        mutation {
            deleteEmergencyContact(id: "\(id)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 创建见证人
    func createWitness(name: String, phone: String, relationship: String) async throws -> String {
        let query = """
        mutation {
            createWitness(name: "\(name)", phone: "\(phone)", relationship: "\(relationship)") {
                id
                success
            }
        }
        """
        
        let result: [String: Any] = try await client.query(query)
        if let data = result["createWitness"] as? [String: Any],
           let id = data["id"] as? String {
            return id
        }
        throw APIError.createFailed
    }
    
    /// 更新见证人
    func updateWitness(id: String, name: String, phone: String, relationship: String) async throws {
        let query = """
        mutation {
            updateWitness(id: "\(id)", name: "\(name)", phone: "\(phone)", relationship: "\(relationship)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
    
    /// 删除见证人
    func deleteWitness(id: String) async throws {
        let query = """
        mutation {
            deleteWitness(id: "\(id)") {
                success
            }
        }
        """
        
        try await client.query(query)
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case createFailed
    case updateFailed
    case deleteFailed
    case networkError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .createFailed: return "创建失败"
        case .updateFailed: return "更新失败"
        case .deleteFailed: return "删除失败"
        case .networkError: return "网络错误"
        case .unauthorized: return "未授权"
        }
    }
}
