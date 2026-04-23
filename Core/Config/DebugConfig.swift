//
//  DebugConfig.swift
//  终活
//
//  性能优化：统一控制调试日志
//

import Foundation

struct DebugConfig {
    // 🔴 生产环境设为 false，开发环境设为 true
    static let enableLogs = false
    
    // 分级日志控制
    static let enableVerboseLogs = false  // 详细日志（🔵🟢🟡🔴）
    static let enableErrorLogs = true     // 错误日志（❌）
    static let enableNetworkLogs = false  // 网络请求日志
}

// 便捷打印函数（自动检查开关）
func debugPrint(_ items: Any..., file: String = #file, line: Int = #line, function: String = #function) {
    guard DebugConfig.enableLogs else { return }
    let fileName = (file as NSString).lastPathComponent
    print("[\(fileName):\(line)] \(function) -", terminator: " ")
    print(items.map { "\($0)" }.joined(separator: " "))
}

func verbosePrint(_ items: Any..., file: String = #file, line: Int = #line, function: String = #function) {
    guard DebugConfig.enableVerboseLogs else { return }
    let fileName = (file as NSString).lastPathComponent
    print("[VERBOSE:\(fileName):\(line)]", terminator: " ")
    print(items.map { "\($0)" }.joined(separator: " "))
}

func errorPrint(_ items: Any..., file: String = #file, line: Int = #line, function: String = #function) {
    guard DebugConfig.enableErrorLogs else { return }
    let fileName = (file as NSString).lastPathComponent
    print("[ERROR:\(fileName):\(line)]", terminator: " ")
    print(items.map { "\($0)" }.joined(separator: " "))
}
