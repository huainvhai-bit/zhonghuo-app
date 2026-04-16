//
//  ResilienceManager.swift
//  终活
//
//  容错与降级管理器
//

import Foundation

/// 容错管理器
class ResilienceManager {
    
    static let shared = ResilienceManager()
    
    /// 最大重试次数
    private let maxRetries = 3
    
    /// 重试延迟 (秒)
    private let retryDelay: TimeInterval = 1.0
    
    private init() {}
    
    /// 带重试的执行
    func executeWithRetry<T>(
        operation: @escaping () async throws -> T,
        maxRetries: Int = 3,
        delay: TimeInterval = 1.0
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(delay * Double(attempt) * 1_000_000_000))
                    print("⚠️ 重试第 \(attempt) 次：\(error.localizedDescription)")
                }
            }
        }
        
        throw lastError ?? NSError(domain: "ResilienceError", code: -1, userInfo: nil)
    }
    
    /// 带超时的执行
    func executeWithTimeout<T>(
        operation: @escaping () async throws -> T,
        timeout: TimeInterval = 30.0
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw NSError(domain: "TimeoutError", code: -1, userInfo: nil)
            }
            
            guard let result = try await group.next() else {
                throw NSError(domain: "TimeoutError", code: -2, userInfo: [NSLocalizedDescriptionKey: "操作超时或无结果"])
            }
            group.cancelAll()
            return result
        }
    }
    
    /// 降级执行
    func executeWithFallback<T>(
        primary: @escaping () async throws -> T,
        fallback: @escaping () async -> T
    ) async -> T {
        do {
            return try await primary()
        } catch {
            print("⚠️ 主操作失败，使用降级方案：\(error.localizedDescription)")
            return await fallback()
        }
    }
}
