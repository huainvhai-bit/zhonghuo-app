//
//  MetricsTracker.swift
//  终活
//
//  指标追踪系统
//

import Foundation

/// 指标类型
enum MetricType {
    case counter      // 计数器
    case gauge        // 仪表盘
    case histogram    // 直方图
    case summary      // 摘要
    case latency      // 延迟
    case throughput   // 吞吐量
    case errorRate    // 错误率
    case successRate  // 成功率
}

/// 指标数据
struct MetricData {
    let name: String
    let type: MetricType
    let value: Double
    let timestamp: Date
    let labels: [String: String]
}

/// 指标追踪器
class MetricsTracker {
    
    static let shared = MetricsTracker()
    
    private var metrics: [String: [MetricData]] = [:]
    private var counters: [String: Int] = [:]
    private var gauges: [String: Double] = [:]
    private var histograms: [String: [Double]] = [:]
    
    private init() {}
    
    // MARK: - 计数器
    
    /// 增加计数器
    func incrementCounter(_ name: String, by value: Int = 1, labels: [String: String] = [:]) {
        counters[name, default: 0] += value
        
        let data = MetricData(
            name: name,
            type: .counter,
            value: Double(counters[name]!),
            timestamp: Date(),
            labels: labels
        )
        
        metrics[name, default: []].append(data)
    }
    
    /// 获取计数器值
    func getCounter(_ name: String) -> Int {
        return counters[name] ?? 0
    }
    
    // MARK: - 仪表盘
    
    /// 设置仪表盘值
    func setGauge(_ name: String, value: Double, labels: [String: String] = [:]) {
        gauges[name] = value
        
        let data = MetricData(
            name: name,
            type: .gauge,
            value: value,
            timestamp: Date(),
            labels: labels
        )
        
        metrics[name, default: []].append(data)
    }
    
    /// 获取仪表盘值
    func getGauge(_ name: String) -> Double? {
        return gauges[name]
    }
    
    // MARK: - 直方图
    
    /// 观察直方图值
    func observeHistogram(_ name: String, value: Double, labels: [String: String] = [:]) {
        histograms[name, default: []].append(value)
        
        let data = MetricData(
            name: name,
            type: .histogram,
            value: value,
            timestamp: Date(),
            labels: labels
        )
        
        metrics[name, default: []].append(data)
    }
    
    /// 获取直方图统计
    func getHistogramStats(_ name: String) -> (count: Int, sum: Double, avg: Double, min: Double, max: Double)? {
        guard let values = histograms[name], !values.isEmpty,
              let min = values.min(),
              let max = values.max() else {
            return nil
        }
        
        let count = values.count
        let sum = values.reduce(0, +)
        let avg = sum / Double(count)
        
        return (count, sum, avg, min, max)
    }
    
    // MARK: - 延迟追踪
    
    /// 追踪延迟
    func trackLatency(_ name: String, labels: [String: String] = [:], block: () -> Void) {
        let start = CFAbsoluteTimeGetCurrent()
        block()
        let end = CFAbsoluteTimeGetCurrent()
        let latency = end - start
        
        observeHistogram("\(name)_latency", value: latency, labels: labels)
        incrementCounter("\(name)_count", labels: labels)
    }
    
    /// 异步追踪延迟
    func trackLatencyAsync(_ name: String, labels: [String: String] = [:], block: @escaping () async -> Void) async {
        let start = CFAbsoluteTimeGetCurrent()
        await block()
        let end = CFAbsoluteTimeGetCurrent()
        let latency = end - start
        
        observeHistogram("\(name)_latency", value: latency, labels: labels)
        incrementCounter("\(name)_count", labels: labels)
    }
    
    // MARK: - 错误率
    
    /// 记录错误
    func recordError(_ name: String, labels: [String: String] = [:]) {
        incrementCounter("\(name)_errors", labels: labels)
    }
    
    /// 记录成功
    func recordSuccess(_ name: String, labels: [String: String] = [:]) {
        incrementCounter("\(name)_successes", labels: labels)
    }
    
    /// 获取错误率
    func getErrorRate(_ name: String) -> Double? {
        let errors = getCounter("\(name)_errors")
        let successes = getCounter("\(name)_successes")
        let total = errors + successes
        
        guard total > 0 else { return nil }
        return Double(errors) / Double(total)
    }
    
    /// 获取成功率
    func getSuccessRate(_ name: String) -> Double? {
        let errorRate = getErrorRate(name)
        return errorRate.map { 1.0 - $0 }
    }
    
    // MARK: - 吞吐量
    
    /// 记录吞吐量
    func recordThroughput(_ name: String, count: Int, labels: [String: String] = [:]) {
        let timestamp = Date()
        let key = "\(name)_throughput"
        
        if let lastRecord = metrics[key]?.last {
            let timeDiff = timestamp.timeIntervalSince(lastRecord.timestamp)
            if timeDiff > 0 {
                let throughput = Double(count) / timeDiff
                setGauge(key, value: throughput, labels: labels)
            }
        }
        
        incrementCounter("\(name)_total", by: count, labels: labels)
    }
    
    // MARK: - 导出
    
    /// 导出所有指标
    func export() -> [String: [MetricData]] {
        return metrics
    }
    
    /// 清除所有指标
    func clear() {
        metrics.removeAll()
        counters.removeAll()
        gauges.removeAll()
        histograms.removeAll()
    }
    
    /// 打印指标报告
    func printReport() {
        var report = "\n📊 指标报告\n================================"
        
        for (name, data) in metrics {
            report += "\n\n\(name):"
            if let stats = getHistogramStats(name) {
                report += "\n  计数：\(stats.count)"
                report += "\n  平均：\(stats.avg * 1000)ms"
                report += "\n  最小：\(stats.min * 1000)ms"
                report += "\n  最大：\(stats.max * 1000)ms"
            }
            if let errorRate = getErrorRate(name) {
                report += "\n  错误率：\(errorRate * 100)%"
            }
            if let successRate = getSuccessRate(name) {
                report += "\n  成功率：\(successRate * 100)%"
            }
        }
        
        report += "\n================================\n"
        Logger.shared.i(report)
    }
}

/// 便捷函数
func TRACK_LATENCY(_ name: String, _ block: () -> Void) {
    MetricsTracker.shared.trackLatency(name, block: block)
}

func RECORD_ERROR(_ name: String) {
    MetricsTracker.shared.recordError(name)
}

func RECORD_SUCCESS(_ name: String) {
    MetricsTracker.shared.recordSuccess(name)
}

func INCREMENT_COUNTER(_ name: String, by value: Int = 1) {
    MetricsTracker.shared.incrementCounter(name, by: value)
}

func SET_GAUGE(_ name: String, value: Double) {
    MetricsTracker.shared.setGauge(name, value: value)
}
