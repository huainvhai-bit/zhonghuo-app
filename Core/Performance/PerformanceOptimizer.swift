//
//  PerformanceOptimizer.swift
//  安伴助手
//
//  性能优化工具类
//

import SwiftUI
import Combine

/// 性能优化器
class PerformanceOptimizer {
    
    static let shared = PerformanceOptimizer()
    
    private init() {}
    
    /// 防抖处理
    func debounce<T: Equatable>(
        _ value: T,
        delay: TimeInterval = 0.3,
        action: @escaping (T) -> Void
    ) -> AnyCancellable {
        Just(value)
            .debounce(for: .seconds(delay), scheduler: RunLoop.main)
            .sink(receiveValue: action)
    }
    
    /// 节流处理
    func throttle<T>(
        _ value: T,
        interval: TimeInterval = 0.5,
        latest: Bool = false,
        action: @escaping (T) -> Void
    ) -> AnyCancellable {
        Just(value)
            .throttle(for: .seconds(interval), scheduler: RunLoop.main, latest: latest)
            .sink(receiveValue: action)
    }
    
    /// 批量处理
    func batchProcess<T>(
        items: [T],
        batchSize: Int = 100,
        process: @escaping ([T]) -> Void
    ) {
        stride(from: 0, to: items.count, by: batchSize).forEach { index in
            let end = min(index + batchSize, items.count)
            process(Array(items[index..<end]))
        }
    }
    
    /// 异步加载
    func loadAsync<T>(
        operation: @escaping () -> T,
        completion: @escaping (T) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = operation()
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    /// 预加载
    func preload<T>(
        items: [T],
        loader: @escaping (T) -> Void
    ) {
        items.forEach { item in
            DispatchQueue.global(qos: .background).async {
                loader(item)
            }
        }
    }
}

/// View 扩展 - 性能优化
extension View {
    /// 条件渲染优化
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// 可选渲染优化
    @ViewBuilder
    func unwrap<T, Content: View>(_ optional: T?, transform: (Self, T) -> Content) -> some View {
        if let value = optional {
            transform(self, value)
        } else {
            self
        }
    }
}
