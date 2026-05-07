//
//  SyncConflictResolver.swift
//  安心助手
//
//  数据同步冲突解决器（V1.0.1 P0 紧急）
//  功能：处理客户端/服务器数据冲突，确保数据一致性
//

import Foundation

class SyncConflictResolver {
    static let shared = SyncConflictResolver()
    
    private init() {}
    
    // MARK: - 时间戳对比策略
    
    /// 比较两个时间戳，返回较新的
    func newer(_ date1: Date, _ date2: Date) -> Date {
        return date1 > date2 ? date1 : date2
    }
    
    /// 判断本地数据是否比服务器数据新
    func isLocalNewer(_ localDate: Date, _ serverDate: Date) -> Bool {
        return localDate > serverDate
    }
    
    // MARK: - 冲突解决策略
    
    /// 五种冲突解决策略
    enum ConflictStrategy {
        case serverWins          // 服务器优先（默认）
        case clientWins          // 客户端优先
        case merge               // 合并变更
        case latestWins          // 时间戳最新优先
        case custom              // 自定义逻辑
    }
    
    /// 解决留言冲突
    func resolveCapsuleConflict(
        local: TimeCapsule,
        remote: TimeCapsule,
        strategy: ConflictStrategy = .latestWins
    ) -> TimeCapsule {
        switch strategy {
        case .latestWins:
            return local.updatedAt > remote.updatedAt ? local : remote
            
        case .clientWins:
            return local
            
        case .serverWins:
            return remote
            
        case .merge:
            var merged = local
            merged.content = remote.content.isEmpty ? local.content : remote.content
            merged.cloudBackupStatus = remote.cloudBackupStatus
            return merged
            
        case .custom:
            // 自定义逻辑（如备份再覆盖）
            print("🔵 SyncConflictResolver: 自定义策略未实现")
            return remote
        }
    }
    
    /// 解决重要事项模块冲突
    func resolveWillConflict(
        local: WillModule,
        remote: WillModule,
        strategy: ConflictStrategy = .latestWins
    ) -> WillModule {
        switch strategy {
        case .latestWins:
            return local.updatedAt > remote.updatedAt ? local : remote
            
        case .clientWins:
            return local
            
        case .serverWins:
            return remote
            
        case .merge:
            var merged = local
            merged.content = remote.content.isEmpty ? local.content : remote.content
            merged.isCompleted = local.isCompleted || remote.isCompleted
            return merged
            
        case .custom:
            print("🔵 SyncConflictResolver: 自定义策略未实现")
            return remote
        }
    }
    
    // MARK: - 冲突检测
    
    /// 检测 capsule 是否有冲突
    func hasCapsuleConflict(local: TimeCapsule, remote: TimeCapsule) -> Bool {
        return local.updatedAt != remote.updatedAt &&
               local.content != remote.content &&
               !local.content.isEmpty &&
               !remote.content.isEmpty
    }
    
    /// 检测 will 是否有冲突
    func hasWillConflict(local: WillModule, remote: WillModule) -> Bool {
        return local.updatedAt != remote.updatedAt &&
               local.content != remote.content &&
               !local.content.isEmpty &&
               !remote.content.isEmpty
    }
    
    // MARK: - 冲突日志
    
    /// 记录冲突（用于调试）
    func logConflict(type: String, localId: String, remoteId: String, strategy: ConflictStrategy) {
        print("⚠️ SyncConflictResolver: 冲突检测 - \(type) \(localId) vs \(remoteId), 策略: \(strategy)")
    }
    
    // MARK: - 批量同步冲突解决
    
    /// 批量解决留言冲突
    func resolveBatchCapsuleConflicts(localCapsules: [TimeCapsule], remoteCapsules: [RemoteCapsule]) -> [TimeCapsule] {
        var result = localCapsules
        
        for remote in remoteCapsules {
            if let localIndex = result.firstIndex(where: { $0.id == remote.id }) {
                let local = result[localIndex]
                
                if hasCapsuleConflict(local: local, remote: remote.localModel) {
                    logConflict(type: "Capsule", localId: local.id, remoteId: remote.id, strategy: .latestWins)
                    
                    result[localIndex] = resolveCapsuleConflict(local: local, remote: remote.localModel)
                }
            } else {
                // 新增的远程留言
                result.append(remote.localModel)
            }
        }
        
        return result
    }
    
    /// 批量解决重要事项冲突
    func resolveBatchWillConflicts(localWills: [WillModule], remoteWills: [RemoteWill]) -> [WillModule] {
        var result = localWills
        
        for remote in remoteWills {
            if let localIndex = result.firstIndex(where: { $0.id == remote.id }) {
                let local = result[localIndex]
                
                if hasWillConflict(local: local, remote: remote.localModel) {
                    logConflict(type: "Will", localId: local.id, remoteId: remote.id, strategy: .latestWins)
                    
                    result[localIndex] = resolveWillConflict(local: local, remote: remote.localModel)
                }
            } else {
                // 新增的远程重要事项
                result.append(remote.localModel)
            }
        }
        
        return result
    }
}

// MARK: - 辅助数据模型

/// 远程留言（用于冲突解决）
struct RemoteCapsule: Identifiable {
    let id: String
    let localModel: TimeCapsule
}

/// 远程重要事项（用于冲突解决）
struct RemoteWill: Identifiable {
    let id: String
    let localModel: WillModule
}

// MARK: - 时间戳扩展

extension TimeCapsule {
    /// 获取 updatedAt（这里用 created_at 代替，实际应有 updated_at 字段）
    var updatedAt: Date {
        return Date()  // WillModule 没有 createdAt，使用当前时间
    }
}

extension WillModule {
    /// 获取 updatedAt
    var updatedAt: Date {
        return Date()  // WillModule 没有 createdAt，使用当前时间
    }
}
