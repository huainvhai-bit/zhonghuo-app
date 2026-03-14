//
//  ErrorHandler.swift
//  终活 - 错误处理
//

import Foundation

enum AppError: LocalizedError {
    case networkError
    case authenticationError
    case dataError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .networkError: return "网络连接失败"
        case .authenticationError: return "认证失败"
        case .dataError: return "数据错误"
        case .unknown: return "未知错误"
        }
    }
}

class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    func handle(_ error: Error) {
        print("❌ 错误：\(error.localizedDescription)")
    }
}
