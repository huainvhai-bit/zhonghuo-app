//
//  ErrorHandler.swift
//  终活
//
//  统一错误处理
//

import Foundation

enum AppError: LocalizedError {
    case networkError(String)
    case dataError(String)
    case authenticationError(String)
    case storageError(String)
    case validationError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "网络错误：\(message)"
        case .dataError(let message):
            return "数据错误：\(message)"
        case .authenticationError(let message):
            return "认证失败：\(message)"
        case .storageError(let message):
            return "存储错误：\(message)"
        case .validationError(let message):
            return "验证失败：\(message)"
        case .unknownError(let message):
            return "未知错误：\(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "请检查网络连接后重试"
        case .dataError:
            return "请尝试重新加载数据"
        case .authenticationError:
            return "请重新登录后重试"
        case .storageError:
            return "请检查存储空间是否充足"
        case .validationError:
            return "请检查输入是否正确"
        default:
            return "请稍后重试"
        }
    }
}

class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    // MARK: - 错误处理
    func handle(_ error: Error, context: String = "") {
        let appError = convertToAppError(error)
        
        #if DEBUG
        print("❌ 错误 [\(context)]: \(appError.errorDescription ?? "未知错误")")
        #endif
        
        // 记录错误到日志
        AppStabilityManager.shared.logError(error)
        
        // TODO: 显示错误提示给用户
        // 在实际应用中，这里应该触发 UI 层的错误提示
    }
    
    // MARK: - 转换错误
    private func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        let nsError = error as NSError
        
        switch nsError.domain {
        case NSURLErrorDomain:
            return .networkError(nsError.localizedDescription)
        case "com.zhonghuo.app.data":
            return .dataError(nsError.localizedDescription)
        default:
            return .unknownError(nsError.localizedDescription)
        }
    }
    
    // MARK: - 验证输入
    func validate(_ text: String, minLength: Int = 0, maxLength: Int = Int.max) -> Result<String, AppError> {
        if text.count < minLength {
            return .failure(.validationError("内容长度不能少于\(minLength)个字符"))
        }
        
        if text.count > maxLength {
            return .failure(.validationError("内容长度不能超过\(maxLength)个字符"))
        }
        
        return .success(text)
    }
    
    func validateEmail(_ email: String) -> Result<String, AppError> {
        let pattern = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        
        if predicate.evaluate(with: email) {
            return .success(email)
        } else {
            return .failure(.validationError("请输入有效的邮箱地址"))
        }
    }
    
    func validatePhone(_ phone: String) -> Result<String, AppError> {
        let pattern = #"^1[3-9]\d{9}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        
        if predicate.evaluate(with: phone) {
            return .success(phone)
        } else {
            return .failure(.validationError("请输入有效的手机号码"))
        }
    }
}
