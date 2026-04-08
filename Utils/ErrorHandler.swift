//
//  ErrorHandler.swift
//  终活
//
//  统一错误处理类
//  注意：AppError 定义在 AppError.swift 中
//

import Foundation
import UIKit

// MARK: - ErrorHandler 统一错误处理类
class ErrorHandler {
    static let shared = ErrorHandler()
    
    // 错误提示闭包（由 UI 层设置）
    var showErrorAlert: ((String, String?) -> Void)?
    
    private init() {}
    
    // MARK: - 错误处理
    /// 处理错误并记录日志
    func handle(_ error: Error, context: String = "", showAlert: Bool = true, file: String = #file, line: Int = #line) {
        let appError = convertToAppError(error)
        let fileName = (file as NSString).lastPathComponent
        
        // 记录错误日志 (第 10 章 10.3 节)
        Logger.error("[\(context)] \(appError.userMessage)", file: fileName, line: line)
        Logger.debug("💡 建议：\(appError.recoverySuggestion ?? "")", file: fileName, line: line)
        
        // 记录错误到稳定性管理器
        AppStabilityManager.shared.logError(error, context: context)
        
        // 显示错误提示给用户
        if showAlert {
            showUserFriendlyAlert(for: appError, context: context)
        }
    }
    
    /// 显示用户友好的错误提示
    private func showUserFriendlyAlert(for appError: AppError, context: String) {
        let title = getErrorTitle(for: appError)
        let message = "\(appError.userMessage)\n\n💡 \(appError.recoverySuggestion ?? "请稍后重试")"
        
        Logger.debug("🔔 错误提示：\(title) - \(message)")
        
        // 通过闭包通知 UI 层显示弹窗
        DispatchQueue.main.async { [weak self] in
            self?.showErrorAlert?(title, message)
        }
    }
    
    /// 获取错误标题
    private func getErrorTitle(for error: AppError) -> String {
        switch error {
        case .network, .networkConnectionFailed, .requestTimeout, .serverError, .serviceUnavailable:
            return "⚠️ 网络问题"
        case .auth, .invalidToken, .notLoggedIn, .securityTokenExpired, .securityTokenInvalid, .securitySessionExpired, .securityUnauthorized:
            return "🔐 认证失败"
        case .dataNotFound, .localDatabase, .dataParsingFailed:
            return "📦 数据异常"
        case .invalidParameter, .missingParameter:
            return "✏️ 输入错误"
        case .permissionDenied, .accessDenied, .securityForbidden:
            return "🚫 权限不足"
        case .localDatabase:
            return "💾 存储问题"
        case .securityDataTampering, .securitySuspiciousActivity, .securityEncryptionFailed, .securityDecryptionFailed:
            return "🛡️ 安全问题"
        case .securityKeychainError:
            return "🔑 安全存储错误"
        case .securitySSLHandshakeFailed, .securityCertificateInvalid:
            return "🔒 安全连接失败"
        case .securityRateLimitExceeded, .rateLimitExceeded:
            return "⏱️ 操作频繁"
        case .securityCSRFTokenMismatch, .csrfValidationFailed, .securityValidationFailed:
            return "🔄 安全验证失败"
        case .unknown, .cancelled, .sensitiveOperationBlocked:
            return "⚠️ 发生错误"
        }
    }
    
    // MARK: - 转换错误
    private func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        let nsError = error as NSError
        
        switch nsError.domain {
        case NSURLErrorDomain:
            // 网络错误
            if nsError.code == NSURLErrorNotConnectedToInternet ||
               nsError.code == NSURLErrorTimedOut {
                return .network(error)
            } else if nsError.code == NSURLErrorServerCertificateUntrusted ||
                      nsError.code == NSURLErrorSecureConnectionFailed {
                return .securitySSLHandshakeFailed
            }
            return .network(error)
            
        case "com.zhonghuo.app.data":
            return .localDatabase(error)
            
        case "com.apple.security.keychain":
            return .securityKeychainError(nsError.code)
            
        default:
            // 检查 HTTP 状态码
            if let httpResponse = nsError.userInfo["NSURLErrorFailingURLResponseErrorKey"] as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 401:
                    return .securityUnauthorized
                case 403:
                    return .securityForbidden
                case 404:
                    return .dataNotFound
                case 419:
                    return .securityTokenExpired
                case 429:
                    return .securityRateLimitExceeded
                case 500...599:
                    return .serverError(httpResponse.statusCode, "服务器错误 (\(httpResponse.statusCode))")
                default:
                    break
                }
            }
            return .unknown(nsError.localizedDescription)
        }
    }
    
    // MARK: - 验证输入 (第 13 章 13.1 节)
    /// 验证文本长度
    func validate(_ text: String, minLength: Int = 0, maxLength: Int = Int.max) -> Result<String, AppError> {
        if text.count < minLength {
            return .failure(.invalidParameter("内容长度不能少于\(minLength)个字符"))
        }
        
        if text.count > maxLength {
            return .failure(.invalidParameter("内容长度不能超过\(maxLength)个字符"))
        }
        
        return .success(text)
    }
    
    /// 验证邮箱 (第 13 章 13.1 节)
    func validateEmail(_ email: String) -> Result<String, AppError> {
        let pattern = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        
        if predicate.evaluate(with: email) {
            return .success(email)
        } else {
            return .failure(.invalidParameter("请输入有效的邮箱地址"))
        }
    }
    
    /// 验证手机号 (第 13 章 13.1 节)
    func validatePhone(_ phone: String) -> Result<String, AppError> {
        let pattern = #"^1[3-9]\d{9}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        
        if predicate.evaluate(with: phone) {
            return .success(phone)
        } else {
            return .failure(.invalidParameter("请输入有效的手机号码"))
        }
    }
    
    /// 验证邀请码 (6 位大写字母或数字)
    func validateInviteCode(_ code: String) -> Result<String, AppError> {
        let pattern = #"^[A-Z0-9]{6}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        
        if predicate.evaluate(with: code.uppercased()) {
            return .success(code.uppercased())
        } else {
            return .failure(.invalidParameter("邀请码格式错误 (6 位字母或数字)"))
        }
    }
    
    /// 验证 UUID 格式
    func validateUUID(_ uuid: String) -> Result<String, AppError> {
        let pattern = #"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        
        if predicate.evaluate(with: uuid.lowercased()) {
            return .success(uuid.lowercased())
        } else {
            return .failure(.invalidParameter("无效的 UUID 格式"))
        }
    }
    
    // MARK: - 安全相关方法 (第 13 章)
    
    /// 脱敏手机号 (第 13 章 13.1 节)
    func maskPhone(_ phone: String) -> String {
        guard phone.count >= 7 else { return phone }
        let prefix = phone.prefix(3)
        let suffix = phone.suffix(4)
        return "\(prefix)****\(suffix)"
    }
    
    /// 脱敏邮箱
    func maskEmail(_ email: String) -> String {
        guard let atIndex = email.firstIndex(of: "@") else { return email }
        let prefix = email[..<atIndex]
        let domain = email[atIndex...]
        
        if prefix.count > 2 {
            let maskedPrefix = String(prefix.prefix(2)) + "***"
            return maskedPrefix + domain
        }
        return email
    }
    
    /// 检查 HTTPS (第 13 章 13.1 节 ATS 配置)
    func isSecureURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme == "https"
    }
}

// MARK: - 扩展 Result 类型支持 AppError
extension Result where Failure == AppError {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
}
