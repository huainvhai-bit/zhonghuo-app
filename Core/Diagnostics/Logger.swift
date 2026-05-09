//
//  Logger.swift
//  安伴助手
//
//  规范化日志系统
//

import Foundation
import os.log

/// 日志级别
enum LogLevel: Int {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case critical = 5
    
    var emoji: String {
        switch self {
        case .verbose: return "🔍"
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🔥"
        }
    }
}

/// 日志管理器
class Logger {
    static let shared = Logger()
    
    /// 当前日志级别
    var currentLevel: LogLevel = .debug
    
    /// 是否启用日志
    var isEnabled: Bool = true
    
    /// 日志文件路径
    private let logFileURL: URL?
    
    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        logFileURL = documents?.appendingPathComponent("app.log")
    }
    
    /// 记录日志
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        guard isEnabled && level.rawValue >= currentLevel.rawValue else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "\(timestamp) [\(level.emoji)] [\(fileName):\(line)] \(function): \(message)"
        
        // 输出到控制台
        print(logMessage)
        
        // 写入文件
        writeToFile(logMessage)
        
        // 严重错误时发送崩溃报告
        if level == .critical {
            sendCrashReport(message)
        }
    }
    
    /// 写入文件
    private func writeToFile(_ message: String) {
        guard let url = logFileURL else { return }
        
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                let fileHandle = try FileHandle(forWritingTo: url)
                fileHandle.seekToEndOfFile()
                fileHandle.write("\n\(message)".data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                try message.write(to: url, atomically: true, encoding: .utf8)
            }
        } catch {
            print("⚠️ 写入日志失败：\(error)")
        }
    }
    
    /// 发送崩溃报告
    private func sendCrashReport(_ message: String) {
        // TODO: 集成崩溃报告服务
        print("🔥 崩溃报告：\(message)")
    }
    
    /// 便捷方法
    func v(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .verbose, file: file, function: function, line: line)
    }
    
    func d(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func i(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func w(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    func e(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    func c(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, file: file, function: function, line: line)
    }
    
    /// 清理日志文件
    func clearLogs() {
        guard let url = logFileURL else { return }
        try? FileManager.default.removeItem(at: url)
        i("日志文件已清理")
    }
    
    /// 导出日志文件
    func exportLogs() -> URL? {
        return logFileURL
    }
}


// MARK: - 静态便捷方法
extension Logger {
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.e(message, file: file, function: function, line: line)
    }
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.d(message, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.i(message, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.w(message, file: file, function: function, line: line)
    }
    
    static func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.c(message, file: file, function: function, line: line)
    }
    
    static func network(_ method: String, url: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.d("\(method) \(url)", file: file, function: function, line: line)
    }
}
