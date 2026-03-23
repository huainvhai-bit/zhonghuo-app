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
    
    // MARK: - 批量同步
    
    /// 批量同步胶囊
    func batchSyncCapsules(_ capsules: [CapsuleInput]) async throws -> BatchSyncResult {
        // 构建胶囊输入
        let capsulesInput = capsules.map { c in
            var parts: [String] = []
            parts.append("id: \"\(c.id)\"")
            parts.append("title: \"\(c.title.replacingOccurrences(of: "\"", with: "\\\""))\"")
            parts.append("type: \"\(c.type)\"")
            if let content = c.content {
                parts.append("content: \"\(content.replacingOccurrences(of: "\"", with: "\\\""))\"")
            }
            if let openAt = c.openAt {
                parts.append("openAt: \"\(openAt)\"")
            }
            return "{ \(parts.joined(separator: ", ")) }"
        }.joined(separator: ", ")
        
        let query = """
        mutation {
            batchSyncCapsules(capsules: [\(capsulesInput)]) {
                total
                created
                updated
            }
        }
        """
        
        let result = try await client.query(query)
        if let data = result["batchSyncCapsules"] as? [String: Any],
           let total = data["total"] as? Int,
           let created = data["created"] as? Int,
           let updated = data["updated"] as? Int {
            return BatchSyncResult(total: total, created: created, updated: updated)
        }
        throw APIError.networkError
    }
    
    /// 批量同步遗嘱
    func batchSyncWills(_ wills: [WillInput]) async throws -> BatchSyncResult {
        let willsInput = wills.map { w in
            var parts: [String] = []
            parts.append("id: \"\(w.id)\"")
            parts.append("type: \"\(w.type)\"")
            parts.append("title: \"\(w.title.replacingOccurrences(of: "\"", with: "\\\""))\"")
            if let content = w.content {
                parts.append("content: \"\(content.replacingOccurrences(of: "\"", with: "\\\""))\"")
            }
            return "{ \(parts.joined(separator: ", ")) }"
        }.joined(separator: ", ")
        
        let query = """
        mutation {
            batchSyncWills(wills: [\(willsInput)]) {
                total
                created
                updated
            }
        }
        """
        
        let result = try await client.query(query)
        if let data = result["batchSyncWills"] as? [String: Any],
           let total = data["total"] as? Int,
           let created = data["created"] as? Int,
           let updated = data["updated"] as? Int {
            return BatchSyncResult(total: total, created: created, updated: updated)
        }
        throw APIError.networkError
    }
    
    /// 批量同步紧急联系人
    func batchSyncEmergencyContacts(_ contacts: [ContactInput]) async throws -> BatchSyncResult {
        let contactsInput = contacts.map { c in
            var parts: [String] = []
            parts.append("id: \"\(c.id)\"")
            parts.append("name: \"\(c.name.replacingOccurrences(of: "\"", with: "\\\""))\"")
            parts.append("phone: \"\(c.phone)\"")
            parts.append("relationship: \"\(c.relationship.replacingOccurrences(of: "\"", with: "\\\""))\"")
            return "{ \(parts.joined(separator: ", ")) }"
        }.joined(separator: ", ")
        
        let query = """
        mutation {
            batchSyncEmergencyContacts(contacts: [\(contactsInput)]) {
                total
                created
                updated
            }
        }
        """
        
        let result = try await client.query(query)
        if let data = result["batchSyncEmergencyContacts"] as? [String: Any],
           let total = data["total"] as? Int,
           let created = data["created"] as? Int,
           let updated = data["updated"] as? Int {
            return BatchSyncResult(total: total, created: created, updated: updated)
        }
        throw APIError.networkError
    }
    
    /// 批量同步见证人
    func batchSyncWitnesses(_ witnesses: [WitnessInput]) async throws -> BatchSyncResult {
        let witnessesInput = witnesses.map { w in
            var parts: [String] = []
            parts.append("id: \"\(w.id)\"")
            parts.append("name: \"\(w.name.replacingOccurrences(of: "\"", with: "\\\""))\"")
            parts.append("phone: \"\(w.phone)\"")
            parts.append("relationship: \"\(w.relationship.replacingOccurrences(of: "\"", with: "\\\""))\"")
            if let status = w.status {
                parts.append("status: \"\(status)\"")
            }
            return "{ \(parts.joined(separator: ", ")) }"
        }.joined(separator: ", ")
        
        let query = """
        mutation {
            batchSyncWitnesses(witnesses: [\(witnessesInput)]) {
                total
                created
                updated
            }
        }
        """
        
        let result = try await client.query(query)
        if let data = result["batchSyncWitnesses"] as? [String: Any],
           let total = data["total"] as? Int,
           let created = data["created"] as? Int,
           let updated = data["updated"] as? Int {
            return BatchSyncResult(total: total, created: created, updated: updated)
        }
        throw APIError.networkError
    }
}

// MARK: - Input Types

struct CapsuleInput {
    let id: String
    let title: String
    let type: String
    let content: String?
    let openAt: String?
}

struct WillInput {
    let id: String
    let type: String
    let title: String
    let content: String?
}

struct ContactInput {
    let id: String
    let name: String
    let phone: String
    let relationship: String
}

struct WitnessInput {
    let id: String
    let name: String
    let phone: String
    let relationship: String
    let status: String?
}

struct BatchSyncResult {
    let total: Int
    let created: Int
    let updated: Int
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
