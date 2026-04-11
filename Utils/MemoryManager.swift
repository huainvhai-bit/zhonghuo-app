//
//  MemoryManager.swift
//  终活
//
//  内存管理工具类
//

import Foundation
import UIKit

/// 内存管理器
class MemoryManager {
    
    static let shared = MemoryManager()
    
    private init() {
        // 监听内存警告
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    /// 处理内存警告
    @objc private func handleMemoryWarning() {
        print("⚠️ 收到内存警告")
        clearCaches()
    }
    
    /// 清理缓存
    func clearCaches() {
        // 清理图片缓存
        UIImageCache.shared.removeAll()
        
        // 清理网络缓存
        URLCache.shared.removeAllCachedResponses()
        
        print("✅ 缓存已清理")
    }
    
    /// 获取当前内存使用
    func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else {
            return 0
        }
        
        return info.resident_size
    }
    
    /// 获取内存使用百分比
    func getMemoryUsagePercentage() -> Double {
        let usage = getCurrentMemoryUsage()
        let total = ProcessInfo.processInfo.physicalMemory
        return Double(usage) / Double(total) * 100
    }
    
    /// 低内存模式
    func isLowMemoryMode() -> Bool {
        return getMemoryUsagePercentage() > 80
    }
}

/// 图片缓存
class UIImageCache {
    static let shared = NSCache<NSString, UIImage>()
    
    func set(_ image: UIImage, forKey key: String) {
        shared.setObject(image, forKey: key as NSString)
    }
    
    func get(forKey key: String) -> UIImage? {
        return shared.object(forKey: key as NSString)
    }
    
    func remove(forKey key: String) {
        shared.removeObject(forKey: key as NSString)
    }
    
    func removeAll() {
        shared.removeAllObjects()
    }
}
