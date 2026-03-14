//
//  CloudStorageManager.swift
//  终活 - 云存储管理
//

import Foundation

class CloudStorageManager: ObservableObject {
    static let shared = CloudStorageManager()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    
    private init() {}
    
    func syncToCloud() async -> Bool {
        isSyncing = true
        defer { isSyncing = false }
        try? await Task.sleep(nanoseconds: 500_000_000)
        lastSyncDate = Date()
        return true
    }
}
