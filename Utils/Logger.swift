//
//  Logger.swift
//  终活
//
//  统一日志工具 - 符合第 10 章 10.3 节日志规范
//

import Foundation
import os.log

// MARK: - Logger 统一日志工具
/// 日志规范 (第 10 章 10.3 节):
/// - DEBUG: 调试信息，仅开发环境
/// - INFO: 正常业务日志
/// - WARNING: 警告信息，不影响功能
/// - ERROR: 错误信息，需要处理
enum Logger {
    /// 日志级别 (带 Emoji 标识)
    enum Level: String {
        case debug = "🔍"
        case info = "ℹ️"
        case warning = "⚠️"
        case error = "❌"
        case critical = "🚨"
        
        /// OSLog 类型映射
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error, .critical: return .error
            }
        }
        
        /// 日志级别数值 (用于过滤)
        var priority: Int {
            switch self {
            case .debug: return 1
            case .info: return 2
            case .warning: return 3
            case .error: return 4
            case .critical: return 5
            }
        }
    }
    
    // MARK: - 配置
    
    /// 是否启用日志 (生产环境可关闭)
    private static var isEnabled: Bool {
        #if DEBUG
        return true
        #else
        return UserDefaults.standard.bool(forKey: "LoggerEnabled")
        #endif
    }
    
    /// 最低日志级别 (低于此级别的日志不输出)
    private static var minimumLevel: Level = .debug
    
    /// 日志模块分类
    private static let osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.zhonghuo.app", category: "App")
    
    /// 日志文件路径 (用于生产环境日志收集)
    private static var logFilePath: String {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        return "\(documentsPath)/Logs/app.log"
    }
    
    /// 日志文件最大大小 (字节) - 10MB
    private static let maxLogFileSize: Int = 10 * 1024 * 1024
    
    // MARK: - 核心日志方法
    
    /// 核心日志输出方法
    /// - Parameters:
    ///   - message: 日志消息
    ///   - level: 日志级别
    ///   - file: 源文件名 (自动获取)
    ///   - line: 源文件行号 (自动获取)
    ///   - function: 函数名 (自动获取)
    static func log(_ message: String,
                    level: Level = .info,
                    file: String = #file,
                    line: Int = #line,
                    function: String = #function) {
        // 检查日志开关和级别
        guard isEnabled && level.priority >= minimumLevel.priority else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "\(level.rawValue) [\(timestamp)] [\(fileName):\(line)] \(function) → \(message)"
        
        // 输出到控制台 (开发环境)
        #if DEBUG
        print(logMessage)
        #endif
        
        // 使用 OSLog 输出 (系统日志)
        os_log("%{public}@", log: osLog, type: level.osLogType, logMessage)
        
        // 生产环境写入文件 (用于问题排查)
        #if !DEBUG
        if isEnabled {
            writeToFile(logMessage, level: level)
        }
        #endif
        
        // 严重错误上报 (可选：集成 Firebase Crashlytics)
        if level == .critical {
            reportCriticalError(message, file: fileName, line: line, function: function)
        }
    }
    
    // MARK: - 便捷方法
    
    /// 输出 DEBUG 级别日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 源文件名
    ///   - line: 源文件行号
    static func debug(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .debug, file: file, line: line)
    }
    
    /// 输出 INFO 级别日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 源文件名
    ///   - line: 源文件行号
    static func info(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .info, file: file, line: line)
    }
    
    /// 输出 WARNING 级别日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 源文件名
    ///   - line: 源文件行号
    static func warning(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .warning, file: file, line: line)
    }
    
    /// 输出 ERROR 级别日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 源文件名
    ///   - line: 源文件行号
    static func error(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .error, file: file, line: line)
    }
    
    /// 输出 CRITICAL 级别日志 (严重错误)
    /// - Parameters:
    ///   - message: 日志消息
    ///   - file: 源文件名
    ///   - line: 源文件行号
    static func critical(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .critical, file: file, line: line)
    }
    
    // MARK: - 结构化日志方法
    
    /// 记录网络请求日志
    static func network(_ method: String,
                        url: String,
                        statusCode: Int? = nil,
                        duration: TimeInterval? = nil,
                        error: Error? = nil,
                        file: String = #file,
                        line: Int = #line) {
        var message = "[HTTP \(method)] \(url)"
        
        if let statusCode = statusCode {
            message += " → \(statusCode)"
        }
        
        if let duration = duration {
            message += " (\(String(format: "%.2f", duration))s)"
        }
        
        if let requestError = error {
            message += " ❌ \(requestError.localizedDescription)"
            Logger.error(message, file: file, line: line)
        } else {
            Logger.info(message, file: file, line: line)
        }
    }
    
    /// 记录用户操作日志
    static func userAction(_ action: String,
                           userId: String? = nil,
                           metadata: [String: Any]? = nil,
                           file: String = #file,
                           line: Int = #line) {
        var message = "[用户操作] \(action)"
        
        if let userId = userId {
            // 脱敏处理 (第 13 章 13.1 节)
            let maskedId = String(userId.prefix(3)) + "***"
            message += " - 用户：\(maskedId)"
        }
        
        if let metadata = metadata {
            message += " - 元数据：\(metadata)"
        }
        
        info(message, file: file, line: line)
    }
    
    /// 记录数据同步日志
    static func sync(_ operation: String,
                     entityType: String,
                     count: Int? = nil,
                     success: Bool = true,
                     error: Error? = nil,
                     file: String = #file,
                     line: Int = #line) {
        var message = "[数据同步] \(operation) - \(entityType)"
        
        if let count = count {
            message += " (\(count) 条)"
        }
        
        if success {
            message += " ✅ 成功"
            Logger.info(message, file: file, line: line)
        } else {
            message += " ❌ 失败"
            if let operationError = error {
                message += " - \(operationError.localizedDescription)"
            }
            Logger.error(message, file: file, line: line)
        }
    }
    
    /// 记录安全相关日志 (第 13 章)
    static func security(_ event: String,
                         detail: String? = nil,
                         isSensitive: Bool = false,
                         file: String = #file,
                         line: Int = #line) {
        var message = "[安全] \(event)"
        
        if let detail = detail {
            // 敏感信息不记录详情
            if !isSensitive {
                message += " - \(detail)"
            } else {
                message += " - [敏感信息已隐藏]"
            }
        }
        
        // 安全事件始终记录
        warning(message, file: file, line: line)
    }
    
    /// 记录性能日志
    static func performance(_ operation: String,
                            duration: TimeInterval,
                            threshold: TimeInterval = 1.0,
                            file: String = #file,
                            line: Int = #line) {
        let message = "[性能] \(operation) - \(String(format: "%.3f", duration))s"
        
        if duration > threshold {
            warning("\(message) ⚠️ 超过阈值 \(threshold)s", file: file, line: line)
        } else {
            debug(message, file: file, line: line)
        }
    }
    
    // MARK: - 私有方法
    
    /// 写入日志到文件 (生产环境)
    private static func writeToFile(_ message: String, level: Level) {
        // 检查日志文件大小
        if let fileSize = try? FileManager.default.attributesOfItem(atPath: logFilePath)[.size] as? Int {
            if fileSize > maxLogFileSize {
                // 删除旧日志
                try? FileManager.default.removeItem(atPath: logFilePath)
            }
        }
        
        // 追加日志
        if let data = "\(message)\n".data(using: .utf8) {
            if let fileHandle = FileHandle(forWritingAtPath: logFilePath) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                // 创建日志文件
                try? data.write(to: URL(fileURLWithPath: logFilePath), options: .atomicWrite)
            }
        }
    }
    
    /// 上报严重错误 (集成 Crashlytics 等)
    private static func reportCriticalError(_ message: String,
                                            file: String,
                                            line: Int,
                                            function: String) {
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().log("[CRITICAL] \(file):\(line) \(function) - \(message)")
        #endif
        
        // 可以在这里添加其他错误上报逻辑
        info("🚨 严重错误已上报：\(message)", file: file, line: line)
    }
    
    // MARK: - 日志管理
    
    /// 设置最低日志级别
    static func setMinimumLevel(_ level: Level) {
        minimumLevel = level
        info("日志级别已设置为：\(level.rawValue)", file: #file, line: #line)
    }
    
    /// 启用/禁用日志 (生产环境)
    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "LoggerEnabled")
        info("日志已\(enabled ? "启用" : "禁用")", file: #file, line: #line)
    }
    
    /// 获取日志文件路径
    static func getLogFilePath() -> String {
        return logFilePath
    }
    
    /// 清除日志文件
    static func clearLogFile() {
        try? FileManager.default.removeItem(atPath: logFilePath)
        info("日志文件已清除", file: #file, line: #line)
    }
    
    /// 导出日志文件 (用于问题排查)
    static func exportLogFile() -> URL? {
        guard FileManager.default.fileExists(atPath: logFilePath) else {
            return nil
        }
        return URL(fileURLWithPath: logFilePath)
    }
}

// MARK: - 使用示例
/*
 
 // 基础用法
 Logger.debug("调试信息")
 Logger.info("用户登录成功")
 Logger.warning("Token 即将过期")
 Logger.error("网络请求失败：\(error)")
 Logger.critical("数据库损坏")
 
 // 网络请求日志
 Logger.network("GET", url: "https://api.example.com/users", statusCode: 200, duration: 0.5)
 
 // 用户操作日志 (自动脱敏)
 Logger.userAction("登录", userId: "user123")
 
 // 数据同步日志
 Logger.sync("上传", entityType: "胶囊", count: 5, success: true)
 
 // 安全日志 (敏感信息自动隐藏)
 Logger.security("Token 刷新", detail: "old_token_xxx", isSensitive: true)
 
 // 性能日志 (超过阈值自动警告)
 Logger.performance("数据同步", duration: 2.5, threshold: 1.0)
 
 */
