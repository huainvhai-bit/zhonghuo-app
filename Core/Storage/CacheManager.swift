//
//  CacheManager.swift
//  终活
//
//  离线缓存管理器 (P1)
//  功能：缓存首页状态、留言列表、重要事项列表等常驻数据
//  策略：App 启动自动预热 + 手动刷新 + 失效自动更新
//

import Foundation

class CacheManager {
    static let shared = CacheManager()
    
    private let cacheDirectory: URL
    private let expirationInterval: TimeInterval = 300  // 5 分钟
    private var timers: [String: Timer] = [:]
    
    private init() {
        let fileManager = FileManager.default
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("zhonghuo_cache", isDirectory: true)
        
        // 创建缓存目录
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - 缓存 Key
    
    enum CacheKey: String {
        case homeStatus = "home_status.json"
        case capsules = "capsules.json"
        case wills = "wills.json"
        case family = "family.json"
        case assets = "assets.json"
        case lastSyncTime = "last_sync_time.json"
    }
    
    // MARK: - 缓存路径
    
    private func cachePath(for key: CacheKey) -> URL {
        return cacheDirectory.appendingPathComponent(key.rawValue)
    }
    
    // MARK: - 写入缓存
    
    /// 写入 JSON 缓存
    private func save<T: Encodable>(_ data: T, for key: CacheKey) {
        do {
            let data = try JSONEncoder().encode(data)
            try data.write(to: cachePath(for: key), options: .atomicWrite)
            print("✅ CacheManager: \(key.rawValue) 缓存已写入")
        } catch {
            print("❌ CacheManager: \(key.rawValue) 缓存写入失败：\(error.localizedDescription)")
        }
    }
    
    // MARK: - 读取缓存
    
    /// 读取 JSON 缓存
    private func load<T: Decodable>(_ type: T.Type, for key: CacheKey) -> T? {
        let path = cachePath(for: key)
        guard FileManager.default.fileExists(atPath: path.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: path)
            let value = try JSONDecoder().decode(T.self, from: data)
            print("✅ CacheManager: \(key.rawValue) 缓存已读取")
            return value
        } catch {
            print("❌ CacheManager: \(key.rawValue) 缓存读取失败：\(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - 缓存有效性检查
    
    /// 检查缓存是否有效（未过期）
    private func isCacheValid(for key: CacheKey) -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: cachePath(for: key).path),
              let modificationDate = attributes[.modificationDate] as? Date else {
            return false
        }
        
        return Date().timeIntervalSince(modificationDate) < expirationInterval
    }
    
    // MARK: - 缓存管理
    
    /// 清空所有缓存
    func clearAll() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
            print("✅ CacheManager: 所有缓存已清空")
        } catch {
            print("❌ CacheManager: 清空缓存失败：\(error.localizedDescription)")
        }
    }
    
    /// 清空特定缓存
    private func clear(for key: CacheKey) {
        let path = cachePath(for: key)
        if FileManager.default.fileExists(atPath: path.path) {
            try? FileManager.default.removeItem(at: path)
            print("✅ CacheManager: \(key.rawValue) 缓存已清空")
        }
    }
    
    // MARK: - 首页状态缓存
    
    /// 保存首页状态
    func saveHomeStatus(_ status: HomeStatus) {
        save(status, for: .homeStatus)
    }
    
    /// 读取首页状态缓存
    func loadHomeStatus() -> HomeStatus? {
        return load(HomeStatus.self, for: .homeStatus)
    }
    
    /// 保存留言列表
    func saveCapsules(_ capsules: [CapsuleInfo]) {
        save(capsules, for: .capsules)
    }
    
    /// 读取留言列表缓存
    func loadCapsules() -> [CapsuleInfo]? {
        return load([CapsuleInfo].self, for: .capsules)
    }
    
    /// 保存重要事项列表
    func saveWills(_ wills: [WillInfo]) {
        save(wills, for: .wills)
    }
    
    /// 读取重要事项列表缓存
    func loadWills() -> [WillInfo]? {
        return load([WillInfo].self, for: .wills)
    }
}

// MARK: - 缓存数据模型

/// 首页状态数据
struct HomeStatus: Codable, Identifiable {
    let id = UUID()

    enum CodingKeys: String, CodingKey {
        case userName, lastCheckIn, checkInCount, capsulesCount, willModulesCount
        case familyCount, assetsCount, lastSyncTime
    }

    let userName: String
    let lastCheckIn: Date?
    let checkInCount: Int
    let capsulesCount: Int
    let willModulesCount: Int
    let familyCount: Int
    let assetsCount: Int
    let lastSyncTime: Date
}

/// 留言信息（与后端同步）
// WillInfo 和 FamilyInfo 定义已移至 Models.swift

/// 资产信息
struct AssetInfo: Codable, Identifiable {
    let id: String
    let type: String  // bank, insurance, stock, crypto, real_estate
    let name: String
    let value: Double
    let createdAt: Date
}

// MARK: - 缓存管理器扩展

extension CacheManager {
    /// 手动刷新缓存
    func refreshCache() {
        print("🔵 CacheManager: 开始刷新缓存...")
        
        // 清空缓存
        clearAll()
        
        // 触发数据同步（由 DataManager 消费缓存事件）
        NotificationCenter.default.post(name: Notification.Name("CacheRefreshed"), object: nil)
        
        print("✅ CacheManager: 缓存已刷新")
    }
    
    /// App 启动时预热缓存
    func preloadCache() {
        print("🔵 CacheManager: 开始预热缓存...")
        
        // 检查是否有有效缓存
        if !isCacheValid(for: .homeStatus) ||
           !isCacheValid(for: .capsules) ||
           !isCacheValid(for: .wills) {
            print("⚠️ CacheManager: 缓存已过期，下次同步时自动更新")
        } else {
            print("✅ CacheManager: 缓存有效，立即可用")
        }
    }
    
    /// 设置自动刷新定时器
    func startAutoRefresh() {
        // 每 5 分钟检查缓存有效性
        if timers["auto_refresh"] == nil {
            timers["auto_refresh"] = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
                self?.autoRefresh()
            }
            print("✅ CacheManager: 自动刷新定时器已启动（5 分钟）")
        }
    }
    
    /// 自动刷新检查
    func autoRefresh() {
        guard !isCacheValid(for: .homeStatus) else { return }
        
        print("⚠️ CacheManager: 缓存已过期，正在刷新...")
        refreshCache()
    }
}
// MARK: - DataManager 缓存集成（P1 离线缓存）

extension CacheManager {
    /// 从缓存加载数据（由 DataManager 调用）
    func loadDataIfNeeded() {
        print("🔵 CacheManager.loadDataIfNeeded 开始...")
        
        // 如果缓存过期，触发刷新
        if !isCacheValid(for: .homeStatus) {
            refreshCache()
        }
        
        print("✅ CacheManager.loadDataIfNeeded 完成")
    }
}
