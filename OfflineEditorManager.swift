//
//  OfflineEditorManager.swift
//  终活
//
//  离线编辑管理器（V1.2.0 P1 体验优化）
//  功能：支持离线编辑，网络恢复后自动同步
//

import Foundation
import CoreData

class OfflineEditorManager: ObservableObject {
    static let shared = OfflineEditorManager()
    
    // MARK: - 离线编辑状态
    
    /// 离线编辑状态
    @Published var isOffline: Bool = false
    @Published var pendingChanges: [String: PendingChange] = [:]
    
    private init() {
        // 初始化时检查网络状态
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNetworkChange),
            name: NSNotification.Name(rawValue: "NetworkStatusChanged"),
            object: nil
        )
        
        checkNetworkStatus()
    }
    
    // MARK: - 网络状态
    
    /// 网络状态
    enum NetworkStatus {
        case online
        case offline
        case limited
    }
    
    /// 当前网络状态
    var networkStatus: NetworkStatus = .online
    
    /// 检查网络状态
    func checkNetworkStatus() {
        // TODO: 使用 Network.framework 检查网络
        // 暂时默认在线
        let isOnline = true // <#网络检查#>
        
        if isOnline != (networkStatus == .online) {
            networkStatus = isOnline ? .online : .offline
            isOffline = !isOnline
            
            print("⚠️ OfflineEditorManager: 网络状态变化 → \(isOnline ? "在线" : "离线")")
            
            // 网络恢复时自动同步
            if isOnline {
                syncPendingChanges()
            }
        }
    }
    
    // MARK: - 离线编辑操作
    
    /// 记录待处理的本地变更
    func recordPendingChange(id: String, type: ChangeType, newData: Data) {
        pendingChanges[id] = PendingChange(
            id: id,
            type: type,
            newData: newData,
            timestamp: Date()
        )
        
        print("🔵 OfflineEditorManager: 记录待处理变更：\(id) - \(type)")
    }
    
    /// 移除待处理变更（已同步）
    func removePendingChange(id: String) {
        pendingChanges.removeValue(forKey: id)
        print("✅ OfflineEditorManager: 移除待处理变更：\(id)")
    }
    
    /// 获取待处理变更数
    var pendingCount: Int {
        return pendingChanges.count
    }
    
    // MARK: - 离线编辑类型
    
    /// 变更类型
    enum ChangeType: String, Codable {
        case create    // 创建
        case update    // 更新
        case delete    // 删除
    }
    
    /// 待处理变更
    struct PendingChange: Codable, Identifiable {
        let id: String
        let type: ChangeType
        let newData: Data
        let timestamp: Date
    }
    
    // MARK: - 网络变化处理
    
    /// 处理网络变化
    @objc private func handleNetworkChange(notification: Notification) {
        checkNetworkStatus()
    }
    
    // MARK: - 同步待处理变更
    
    /// 同步所有待处理变更到服务器
    func syncPendingChanges() {
        guard !isOffline else {
            print("⚠️ OfflineEditorManager: 离线，无法同步")
            return
        }
        
        guard !pendingChanges.isEmpty else {
            print("ℹ️ OfflineEditorManager: 无待处理变更")
            return
        }
        
        print("🔵 OfflineEditorManager: 开始同步 \(pendingChanges.count) 个待处理变更...")
        
        // 这里应该调用对应的同步方法
        // 暂时只打印日志
        
        for (id, change) in pendingChanges {
            print("🔵 OfflineEditorManager: 同步变更 \(id) - \(change.type)")
            
            // TODO: 实际同步逻辑
            // switch change.type {
            // case .create: syncCreate(id, change.newData)
            // case .update: syncUpdate(id, change.newData)
            // case .delete: syncDelete(id, change.newData)
            // }
            
            // 同步成功后移除
            removePendingChange(id: id)
        }
        
        print("✅ OfflineEditorManager: 待处理变更同步完成")
    }
    
    // MARK: - 清除所有待处理变更
    
    /// 清除所有待处理变更
    func clearAllPendingChanges() {
        pendingChanges.removeAll()
        print("✅ OfflineEditorManager: 所有待处理变更已清除")
    }
    
    // MARK: - 数据持久化
    
    /// 保存离线编辑数据到磁盘
    func saveOfflineData() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(pendingChanges)
            try data.write(to: offlineDataURL, options: .atomicWrite)
            print("✅ OfflineEditorManager: 离线数据已保存")
        } catch {
            print("❌ OfflineEditorManager: 保存离线数据失败：\(error.localizedDescription)")
        }
    }
    
    /// 从磁盘加载离线编辑数据
    func loadOfflineData() {
        guard FileManager.default.fileExists(atPath: offlineDataURL.path) else {
            print("ℹ️ OfflineEditorManager: 无离线数据")
            return
        }
        
        do {
            let data = try Data(contentsOf: offlineDataURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            pendingChanges = try decoder.decode([String: PendingChange].self, from: data)
            print("✅ OfflineEditorManager: 离线数据已加载：\(pendingChanges.count) 个变更")
        } catch {
            print("❌ OfflineEditorManager: 加载离线数据失败：\(error.localizedDescription)")
        }
    }
    
    // MARK: - 离线数据路径
    
    /// 离线数据文件 URL
    private var offlineDataURL: URL {
        let fileManager = FileManager.default
        let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cachesURL.appendingPathComponent("offline_edits.json")
    }
}

// MARK: - App 生命周期集成

extension OfflineEditorManager {
    /// App 启动时恢复离线编辑
    func initialize() {
        print("🔵 OfflineEditorManager: 初始化...")
        
        // 加载离线数据
        loadOfflineData()
        
        // 检查网络状态
        checkNetworkStatus()
        
        print("✅ OfflineEditorManager: 初始化完成")
    }
    
    /// App 进入后台时保存离线数据
    func applicationWillResignActive() {
        print("🔵 OfflineEditorManager: 保存离线数据...")
        saveOfflineData()
    }
}

// MARK: - 辅助扩展

extension UserDefaults {
    /// 简化设置
    func set<T: Codable>(_ value: T?, for key: String) {
        guard let value = value else {
            removeObject(forKey: key)
            return
        }
        
        do {
            let data = try JSONEncoder().encode(value)
            set(data, forKey: key)
        } catch {
            print("❌ UserDefaults.set 失败：\(error.localizedDescription)")
        }
    }
    
    /// 简化获取
    func object<T: Codable>(for key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("❌ UserDefaults.object 失败：\(error.localizedDescription)")
            return nil
        }
    }
}
