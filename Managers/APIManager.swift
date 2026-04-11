//
//  APIManager.swift
//  终活
//
//  后端 API 管理器 - 批量同步等功能
//

import Foundation

/// API 管理器
/// 职责：批量同步、GraphQL mutation 等高级 API 操作
class APIManager {
    static let shared = APIManager()
    
    private let apiClient = APIClient.shared
    
    init() {}
    
    // MARK: - 批量同步胶囊
    
    /// 批量同步胶囊
    func batchSyncCapsules(_ inputs: [[String: Any]]) async throws -> [String: Any] {
        let mutation = """
        mutation($capsules: [TimeCapsuleInput!]!) {
            batchSyncCapsules(capsules: $capsules) {
                total
                created
                updated
            }
        }
        """
        
        let variables: [String: Any] = ["capsules": inputs]
        return try await apiClient.query(mutation, variables: variables)
    }
    
    // MARK: - 批量同步遗嘱
    
    /// 批量同步遗嘱
    func batchSyncWills(_ inputs: [[String: Any]]) async throws -> [String: Any] {
        let mutation = """
        mutation($wills: [WillInput!]!) {
            batchSyncWills(wills: $wills) {
                total
                created
                updated
            }
        }
        """
        
        let variables: [String: Any] = ["wills": inputs]
        return try await apiClient.query(mutation, variables: variables)
    }
    
    // MARK: - 批量同步紧急联系人
    
    /// 批量同步紧急联系人
    func batchSyncEmergencyContacts(_ inputs: [[String: Any]]) async throws -> [String: Any] {
        let mutation = """
        mutation($contacts: [EmergencyContactInput!]!) {
            batchSyncEmergencyContacts(contacts: $contacts) {
                total
                created
                updated
            }
        }
        """
        
        let variables: [String: Any] = ["contacts": inputs]
        return try await apiClient.query(mutation, variables: variables)
    }
    
    // MARK: - 批量同步见证人
    
    /// 批量同步见证人
    func batchSyncWitnesses(_ inputs: [[String: Any]]) async throws -> [String: Any] {
        let mutation = """
        mutation($witnesses: [WitnessInput!]!) {
            batchSyncWitnesses(witnesses: $witnesses) {
                total
                created
                updated
            }
        }
        """
        
        let variables: [String: Any] = ["witnesses": inputs]
        return try await apiClient.query(mutation, variables: variables)
    }
    
    // MARK: - 批量同步资产
    
    /// 批量同步资产
    func batchSyncAssets(_ inputs: [[String: Any]]) async throws -> [String: Any] {
        let mutation = """
        mutation($assets: [AssetInput!]!) {
            batchSyncAssets(assets: $assets) {
                total
                created
                updated
            }
        }
        """
        
        let variables: [String: Any] = ["assets": inputs]
        return try await apiClient.query(mutation, variables: variables)
    }
    
    // MARK: - 家人相关
    
    /// 绑定家人
    func bindFamilyMember(inviteCode: String) async throws -> [String: Any] {
        let mutation = """
        mutation($inviteCode: String!) {
            bindFamily(inviteCode: $inviteCode) {
                success
                message
            }
        }
        """
        
        let variables: [String: Any] = ["inviteCode": inviteCode]
        return try await apiClient.query(mutation, variables: variables)
    }
    
    /// 生成邀请码
    func generateInviteCode() async throws -> [String: Any] {
        let mutation = """
        mutation {
            generateInviteCode {
                success
                inviteCode
            }
        }
        """
        
        return try await apiClient.query(mutation)
    }
    
    /// 获取家人列表
    func getFamilyMembers() async throws -> [String: Any] {
        let query = """
        query {
            family {
                success
                message
                data {
                    members {
                        id
                        name
                        phone
                        role
                    }
                    invited {
                        id
                        name
                        phone
                        status
                    }
                }
            }
        }
        """
        
        return try await apiClient.query(query)
    }
}
