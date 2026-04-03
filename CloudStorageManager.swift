//
//  CloudStorageManager.swift
//  终活
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
            let status = await checkCloudKitStatus()
            guard status == .available else {
                throw CloudStorageError.unavailable("iCloud 不可用：\(status.rawValue)")
            }
            
            // 2. 同步用户数据
            try await syncUserData()
            
            // 3. 同步遗嘱数据
            try await syncWillData()
            
            // 4. 同步胶囊数据
            try await syncCapsuleData()
            
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
    func checkCloudKitStatus() async -> CKApplicationPermissionsStatus {
        do {
            let status = try await container.status(for: .userDiscoverability)
            return status
        } catch {
            // 🔴 统一使用 ErrorHandler 处理错误
            ErrorHandler.shared.handle(error, context: "CloudKit 状态检查", showAlert: false)
            print("❌ CloudKit 状态检查失败：\(error)")
            return .unavailable
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
        
        record["name"] = CKRecord.Field(string: user.name)
        record["phone"] = CKRecord.Field(string: user.phone)
        record["lastSyncDate"] = CKRecord.Field(date: Date())
        
        try await uploadRecord(record)
        print("✅ 用户数据同步完成")
    }
    
    /// 同步遗嘱数据
    private func syncWillData() async throws {
        let wills = DataManager.shared.wills
        print("📝 同步 \(wills.count) 条遗嘱数据")
        
        for will in wills {
            let recordID = CKRecord.ID(recordName: "will_\(will.id)")
            let record = CKRecord(recordType: "Will", recordID: recordID)
            
            record["title"] = CKRecord.Field(string: will.title)
            record["content"] = CKRecord.Field(string: will.content)
            record["createdAt"] = CKRecord.Field(date: will.createdAt)
            record["updatedAt"] = CKRecord.Field(date: will.updatedAt)
            
            try await uploadRecord(record)
        }
        
        print("✅ 遗嘱数据同步完成")
    }
    
    /// 同步胶囊数据
    private func syncCapsuleData() async throws {
        let capsules = DataManager.shared.capsules
        print("📦 同步 \(capsules.count) 条胶囊数据")
        
        for capsule in capsules {
            let recordID = CKRecord.ID(recordName: "capsule_\(capsule.id)")
            let record = CKRecord(recordType: "TimeCapsule", recordID: recordID)
            
            record["title"] = CKRecord.Field(string: capsule.title)
            record["content"] = CKRecord.Field(string: capsule.content)
            record["sendDate"] = CKRecord.Field(date: capsule.sendDate)
            record["isSent"] = CKRecord.Field(integer: capsule.isSent ? 1 : 0)
            
            try await uploadRecord(record)
        }
        
        print("✅ 胶囊数据同步完成")
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
