//
//  CloudStorageManager.swift
//  终活
//
//  云存储管理 - iCloud 同步
//

import Foundation
import CloudKit

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
            // TODO: 实现 iCloud 同步逻辑
            // 1. 上传本地数据到 CloudKit
            // 2. 下载云端数据
            // 3. 合并冲突
            
            try await Task.sleep(nanoseconds: 1_000_000_000) // 模拟同步
            
            await MainActor.run {
                lastSyncDate = Date()
                isSyncing = false
                saveLastSyncDate()
            }
        } catch {
            await MainActor.run {
                syncError = error.localizedDescription
                isSyncing = false
            }
        }
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
