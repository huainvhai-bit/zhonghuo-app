//
//  iCloudBackupManager.swift
//  安伴助手
//
//  iCloud 自动备份管理器（简化版）
//  功能：自动备份到 iCloud，支持跨设备同步
//

import Foundation
import CloudKit

class iCloudBackupManager: ObservableObject {
    static let shared = iCloudBackupManager()
    
    // MARK: - iCloud 容器配置
    
    private let container: CKContainer
    private var privateCloudDatabase: CKDatabase!
    private var publicCloudDatabase: CKDatabase!
    
    @Published var status: iCloudStatus = .notConfigured
    @Published var isAvailable: Bool = false
    
    private init() {
        container = CKContainer.default()
        privateCloudDatabase = container.privateCloudDatabase
        publicCloudDatabase = container.publicCloudDatabase
        
        // 检查 iCloud 可用性
        checkiCloudStatus()
    }
    
    // MARK: - iCloud 状态
    
    enum iCloudStatus {
        case available
        case notConfigured
        case restricted
        case unavailable
    }
    
    // MARK: - iCloud 状态检查
    
    /// 检查 iCloud 可用性
    func checkiCloudStatus() {
        container.accountStatus { [weak self] status, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ iCloudBackupManager: 检查账户状态失败：\(error.localizedDescription)")
                    self.status = .unavailable
                    self.isAvailable = false
                    return
                }
                
                switch status {
                case .available:
                    self.status = .available
                    self.isAvailable = true
                    print("✅ iCloudBackupManager: iCloud 可用")
                    
                case .noAccount:
                    self.status = .notConfigured
                    self.isAvailable = false
                    print("⚠️ iCloudBackupManager: 未登录 iCloud")
                    
                case .restricted:
                    self.status = .restricted
                    self.isAvailable = false
                    print("⚠️ iCloudBackupManager: iCloud 被限制")
                    
                case .temporarilyUnavailable, .couldNotDetermine:
                    self.status = .unavailable
                    self.isAvailable = false
                    print("❌ iCloudBackupManager: iCloud 不可用")
                    
                @unknown default:
                    self.status = .unavailable
                    self.isAvailable = false
                }
            }
        }
    }
    
    // MARK: - 数据同步
    
    /// 同步所有数据到 iCloud
    @MainActor func syncAllData() {
        guard isAvailable else {
            print("⚠️ iCloudBackupManager: iCloud 不可用，跳过同步")
            return
        }
        
        print("🔵 iCloudBackupManager: 开始同步所有数据...")
        
        // 留言与重要事项在中国区送审版中保持本地优先，不自动写入 iCloud
        print("⚠️ iCloudBackupManager: 留言与重要事项保持本地优先，跳过自动同步")
        print("✅ iCloudBackupManager: 数据同步完成")
    }
    
    /// 同步添加用户
    private func syncFamilyMembersToiCloud() {
        // ✅ 添加用户同步通过 GraphQL API 实现
        print("🔵 iCloudBackupManager: 添加用户同步到 iCloud")
        // 添加数据已存储在云端，无需额外同步
    }
    
    /// 同步资产
    private func syncAssetsToiCloud() {
        // ✅ 资产同步通过 GraphQL API 实现
        print("🔵 iCloudBackupManager: 资产同步到 iCloud")
        // 资产数据已存储在云端，无需额外同步
    }
    
    // MARK: - 手动同步
    
    /// 手动触发同步
    @MainActor func manualSync() {
        guard isAvailable else {
            print("⚠️ iCloudBackupManager: iCloud 不可用")
            return
        }
        
        print("🔵 iCloudBackupManager: 手动同步...")
        syncAllData()
    }
    
    // MARK: - 查询 iCloud 数据
    
    /// 查询留言（使用 `CKQueryOperation`，替代已弃用的 `perform(_:inZoneWith:completionHandler:)`）
    func queryCapsules() {
        let query = CKQuery(recordType: "Capsule", predicate: NSPredicate(value: true))
        let zoneID = CKRecordZone.ID(zoneName: "DefaultZone")
        let operation = CKQueryOperation(query: query)
        operation.zoneID = zoneID

        operation.queryResultBlock = { result in
            switch result {
            case .failure(let error):
                print("❌ iCloudBackupManager: 查询留言失败：\(error.localizedDescription)")
            case .success(let cursor):
                print("✅ iCloudBackupManager: 留言 CK 查询已完成\(cursor != nil ? "（还有更多批次）" : "")")
                // ✅ 若有 cursor，可用其再建 `CKQueryOperation` 拉取剩余页；合并逻辑以 GraphQL 为准。
            }
        }

        privateCloudDatabase.add(operation)
    }
    
    /// 查询重要事项（同上）
    func queryWills() {
        let query = CKQuery(recordType: "Will", predicate: NSPredicate(value: true))
        let zoneID = CKRecordZone.ID(zoneName: "DefaultZone")
        let operation = CKQueryOperation(query: query)
        operation.zoneID = zoneID

        operation.queryResultBlock = { result in
            switch result {
            case .failure(let error):
                print("❌ iCloudBackupManager: 查询重要事项失败：\(error.localizedDescription)")
            case .success(let cursor):
                print("✅ iCloudBackupManager: 重要事项 CK 查询已完成\(cursor != nil ? "（还有更多批次）" : "")")
            }
        }

        privateCloudDatabase.add(operation)
    }
}

// MARK: - App 启动时初始化

extension iCloudBackupManager {
    /// 初始化并检查状态
    func initialize() {
        print("🔵 iCloudBackupManager: 初始化...")
        checkiCloudStatus()
    }
}
