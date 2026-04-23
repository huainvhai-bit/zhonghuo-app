//
//  Benchmark.swift
//  终活
//
//  性能基准测试工具
//

import Foundation

/// 性能基准测试器
class Benchmark {
    
    static let shared = Benchmark()
    
    private var measurements: [String: [TimeInterval]] = [:]
    
    private init() {}
    
    /// 执行基准测试
    func measure(_ name: String, iterations: Int = 1000, block: () -> Void) -> TimeInterval {
        var total: TimeInterval = 0
        
        for _ in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            block()
            let end = CFAbsoluteTimeGetCurrent()
            total += (end - start)
        }
        
        let average = total / TimeInterval(iterations)
        measurements[name, default: []].append(average)
        
        Logger.shared.d("📊 \(name): \(average * 1000)ms (平均，\(iterations) 次迭代)")
        return average
    }
    
    /// 执行异步基准测试
    func measureAsync(_ name: String, iterations: Int = 100, block: @escaping () async -> Void) async -> TimeInterval {
        var total: TimeInterval = 0
        
        for _ in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            await block()
            let end = CFAbsoluteTimeGetCurrent()
            total += (end - start)
        }
        
        let average = total / TimeInterval(iterations)
        measurements[name, default: []].append(average)
        
        Logger.shared.d("📊 \(name): \(average * 1000)ms (平均异步，\(iterations) 次迭代)")
        return average
    }
    
    /// 比较多个实现
    func compare(_ name: String, implementations: [(String, () -> Void)]) {
        var output = "\n🔬 比较测试：\(name)\n================================"
        
        var results: [(String, TimeInterval)] = []
        
        for (implName, block) in implementations {
            let time = measure("\(name) - \(implName)", iterations: 100, block: block)
            results.append((implName, time))
        }
        
        // 排序并显示结果
        results.sort { $0.1 < $1.1 }
        
        output += "\n\n🏆 排名:"
        for (index, (implName, time)) in results.enumerated() {
            output += "\n\(index + 1). \(implName): \(time * 1000)ms"
        }
        output += "\n================================\n"
        Logger.shared.i(output)
    }
    
    /// 获取统计数据
    func getStatistics(for name: String) -> (min: TimeInterval, max: TimeInterval, avg: TimeInterval, count: Int)? {
        guard let measurements = measurements[name], !measurements.isEmpty,
              let min = measurements.min(),
              let max = measurements.max() else {
            return nil
        }
        
        let avg = measurements.reduce(0, +) / TimeInterval(measurements.count)
        
        return (min, max, avg, measurements.count)
    }
    
    /// 清除所有测量数据
    func clear() {
        measurements.removeAll()
    }
    
    /// 导出测量数据
    func export() -> [String: [TimeInterval]] {
        return measurements
    }
}

/// 性能测试宏
func BENCHMARK(_ name: String, iterations: Int = 1000, _ block: () -> Void) {
    Benchmark.shared.measure(name, iterations: iterations, block: block)
}

/// 异步性能测试宏
func BENCHMARK_ASYNC(_ name: String, iterations: Int = 100, _ block: @escaping () async -> Void) async {
    await Benchmark.shared.measureAsync(name, iterations: iterations, block: block)
}

/// 比较测试宏
func BENCHMARK_COMPARE(_ name: String, _ implementations: (String, () -> Void)...) {
    Benchmark.shared.compare(name, implementations: implementations)
}
