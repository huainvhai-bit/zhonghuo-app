//
//  CloudStorageManager.swift
//  安心助手
//
//  云存储管理 - iCloud 同步
//

import Foundation
import CloudKit

// 🔴 云存储错误类型
enum CloudStorageError: LocalizedError {
    case unavailable(String)
    case syncFailed(String)
    case recordNotFound(String)
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .unavailable(let message):
            return "iCloud 不可用：\(message)"
        case .syncFailed(let message):
            return "同步失败：\(message)"
        case .recordNotFound(let message):
            return "记录不存在：\(message)"
        case .permissionDenied:
            return "无权限访问 iCloud"
        }
    }
}

// ✅ 修复 #5: 标记为 @MainActor，确保所有 @Published 属性更新在主线程执行
@MainActor
class CloudStorageManager: ObservableObject {
    static let shared = CloudStorageManager()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private let container = CKContainer(identifier: "iCloud.com.zhonghuo.app")
    private let database: CKDatabase
    
    init() {
        database = container.privateCloudDatabase
        loadLastSyncDate()
    }
    
    // MARK: - 同步数据
    func syncData() async {
        await MainActor.run {
            isSyncing = true
            syncError = nil
        }
        
        do {
            // ✅ 实现基础 iCloud 同步逻辑
            // 1. 检查 iCloud 可用性
            let isAvailable = await checkCloudKitStatus()
            guard isAvailable else {
                throw CloudStorageError.unavailable("iCloud 不可用")
            }
            
            // 2. 同步用户数据
            try await syncUserData()
            
            // 3. 事项与留言保持本地优先，不再自动写入 iCloud
            print("⚠️ 事项与留言已切换为本地优先，跳过 iCloud 自动同步")
            
            await MainActor.run {
                lastSyncDate = Date()
                isSyncing = false
                saveLastSyncDate()
            }
        } catch {
            // 🔴 统一使用 ErrorHandler 处理错误
            ErrorHandler.shared.handle(error, context: "云同步", showAlert: true)
            
            await MainActor.run {
                syncError = error.localizedDescription
                isSyncing = false
            }
        }
    }
    
    // MARK: - CloudKit 状态检查
    
    /// 检查 CloudKit 可用性
    // ✅ 修复 #4: 修复 CKApplicationPermissionsStatus 类型问题 - 使用 Bool 返回类型
    func checkCloudKitStatus() async -> Bool {
        do {
            // 尝试访问 private database 来检查 iCloud 可用性
            _ = try await container.requestApplicationPermission(.userDiscoverability)
            return true
        } catch {
            // 🔴 统一使用 ErrorHandler 处理错误
            ErrorHandler.shared.handle(error, context: "CloudKit 状态检查", showAlert: false)
            print("❌ CloudKit 状态检查失败：\(error)")
            return false
        }
    }
    
    // MARK: - 数据同步实现
    
    /// 同步用户数据
    private func syncUserData() async throws {
        guard let user = UserManager.shared.currentUser else {
            print("⚠️ 无用户数据，跳过同步")
            return
        }
        
        let recordID = CKRecord.ID(recordName: "user_\(user.id)")
        let record = CKRecord(recordType: "User", recordID: recordID)
        
        // ✅ 修复：新版 CloudKit 直接使用值，不需要 CKRecord.Field
        record["name"] = user.name as CKRecordValue
        record["phone"] = user.phone as CKRecordValue
        record["lastSyncDate"] = Date() as CKRecordValue
        
        try await uploadRecord(record)
        print("✅ 用户数据同步完成")
    }
    
    // MARK: - 上传记录
    func uploadRecord(_ record: CKRecord) async throws {
        try await database.save(record)
    }
    
    // MARK: - 下载记录
    func fetchRecords(withType recordType: String) async throws -> [CKRecord] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { _, result in
            try? result.get()
        }
    }
    
    // MARK: - 删除记录
    func deleteRecord(withID recordID: CKRecord.ID) async throws {
        try await database.deleteRecord(withID: recordID)
    }
    
    // MARK: - 持久化同步时间
    private func loadLastSyncDate() {
        if let timestamp = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date {
            lastSyncDate = timestamp
        }
    }
    
    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
    }
}
