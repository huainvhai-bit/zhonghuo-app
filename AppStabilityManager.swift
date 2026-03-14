//
//  AppStabilityManager.swift
//  终活
//
//  应用稳定性管理 - 崩溃跟踪、错误报告
//

import Foundation

class AppStabilityManager {
    static let shared = AppStabilityManager()
    
    private var crashCount: Int = 0
    private var errorLog: [ErrorLogEntry] = []
    private let maxLogEntries = 100
    
    private init() {
        loadCrashCount()
    }
    
    // MARK: - 崩溃跟踪
    // 暂不启用，避免 C 函数指针问题
    // private func setupUncaughtExceptionHandler() {
    //     NSSetUncaughtExceptionHandler { exception in
    //         self.handleCrash(exception)
    //     }
    // }
    
    private func handleCrash(_ exception: NSException) {
        crashCount += 1
        saveCrashCount()
        
        let logEntry = ErrorLogEntry(
            type: "Crash",
            message: exception.reason ?? "Unknown crash",
            stackTrace: exception.callStackSymbols.joined(separator: "\n"),
            timestamp: Date()
        )
        
        addLogEntry(logEntry)
    }
    
    // MARK: - 错误日志
    func logError(_ error: Error, context: String = "") {
        let logEntry = ErrorLogEntry(
            type: "Error",
            message: error.localizedDescription,
            context: context,
            timestamp: Date()
        )
        
        addLogEntry(logEntry)
    }
    
    private func addLogEntry(_ entry: ErrorLogEntry) {
        errorLog.insert(entry, at: 0)
        
        if errorLog.count > maxLogEntries {
            errorLog.removeLast()
        }
    }
    
    func getErrorLogs() -> [ErrorLogEntry] {
        return errorLog
    }
    
    func clearErrorLogs() {
        errorLog.removeAll()
    }
    
    // MARK: - 持久化
    private func loadCrashCount() {
        crashCount = UserDefaults.standard.integer(forKey: "crashCount")
    }
    
    private func saveCrashCount() {
        UserDefaults.standard.set(crashCount, forKey: "crashCount")
    }
    
    // MARK: - 统计
    func getCrashCount() -> Int {
        return crashCount
    }
    
    func resetCrashCount() {
        crashCount = 0
        saveCrashCount()
    }
    
    var isStable: Bool {
        return crashCount < 5
    }
}

// MARK: - 错误日志条目
struct ErrorLogEntry: Codable {
    let id: String
    let type: String
    let message: String
    let context: String?
    let stackTrace: String?
    let timestamp: Date
    
    init(id: String = UUID().uuidString, type: String, message: String, context: String? = nil, stackTrace: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.message = message
        self.context = context
        self.stackTrace = stackTrace
        self.timestamp = timestamp
    }
}
