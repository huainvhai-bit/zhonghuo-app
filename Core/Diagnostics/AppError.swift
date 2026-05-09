//
//  AppError.swift
//  安伴助手
//
//  统一错误处理 - 参考技术文档第 10 章、第 13 章
//

import Foundation

/// 统一错误类型
/// 
/// 所有业务错误统一转换为 AppError，提供：
/// - userMessage: 用户友好的错误提示
/// - logMessage: 日志输出信息（包含技术细节）
enum AppError: LocalizedError {
    // MARK: - 网络相关错误
    
    /// 网络错误
    case network(Error)
    
    /// 网络连接失败
    case networkConnectionFailed
    
    /// 请求超时
    case requestTimeout
    
    // MARK: - 认证相关错误
    
    /// 认证失败
    case auth(String)
    
    /// Token 无效或过期
    case invalidToken
    
    /// 未登录
    case notLoggedIn
    
    // MARK: - 数据相关错误
    
    /// 数据不存在
    case dataNotFound
    
    /// 数据解析失败
    case dataParsingFailed(String)
    
    /// 本地数据库错误
    case localDatabase(Error)
    
    // MARK: - 服务器相关错误
    
    /// 服务器错误
    case serverError(Int, String)
    
    /// 服务不可用
    case serviceUnavailable
    
    // MARK: - 参数相关错误
    
    /// 无效参数
    case invalidParameter(String)
    
    /// 参数缺失
    case missingParameter(String)
    
    // MARK: - 权限相关错误
    
    /// 权限不足
    case permissionDenied
    
    /// 访问被拒绝
    case accessDenied
    
    // MARK: - 安全相关错误 (参考第 13 章)
    
    /// 安全验证失败
    case securityValidationFailed
    
    /// CSRF 验证失败
    case csrfValidationFailed
    
    /// Token 过期
    case securityTokenExpired
    
    /// Token 无效
    case securityTokenInvalid
    
    /// Session 过期
    case securitySessionExpired
    
    /// 未授权访问
    case securityUnauthorized
    
    /// 禁止访问
    case securityForbidden
    
    /// 数据篡改检测
    case securityDataTampering
    
    /// 可疑活动
    case securitySuspiciousActivity
    
    /// 加密失败
    case securityEncryptionFailed
    
    /// 解密失败
    case securityDecryptionFailed
    
    /// Keychain 错误
    case securityKeychainError(Int)
    
    /// SSL 握手失败
    case securitySSLHandshakeFailed
    
    /// 证书无效
    case securityCertificateInvalid
    
    /// 请求频率限制
    case securityRateLimitExceeded
    
    /// CSRF Token 不匹配
    case securityCSRFTokenMismatch
    
    /// 请求频率限制（通用）
    case rateLimitExceeded
    
    /// 敏感操作被阻止
    case sensitiveOperationBlocked
    
    // MARK: - 其他错误
    
    /// 未知错误
    case unknown(String)
    
    /// 操作取消
    case cancelled
    
    // MARK: - 用户友好消息
    
    /// 用户友好的错误提示
    var userMessage: String {
        switch self {
        case .network(let error):
            return "网络连接失败：\(error.localizedDescription)"
        case .networkConnectionFailed:
            return "网络连接失败，请检查网络设置"
        case .requestTimeout:
            return "请求超时，请检查网络后重试"
            
        case .auth(let message):
            return "认证失败：\(message)"
        case .invalidToken:
            return "登录已过期，请重新登录"
        case .notLoggedIn:
            return "请先登录"
            
        case .dataNotFound:
            return "数据不存在"
        case .dataParsingFailed:
            return "数据解析失败"
        case .localDatabase:
            return "本地数据错误"
            
        case .serverError(_, let msg):
            return msg
        case .serviceUnavailable:
            return "服务暂时不可用，请稍后重试"
            
        case .invalidParameter(let field):
            return "参数错误：\(field)"
        case .missingParameter(let field):
            return "缺少必要参数：\(field)"
            
        case .permissionDenied:
            return "权限不足"
        case .accessDenied:
            return "访问被拒绝"
            
        case .securityValidationFailed:
            return "安全验证失败"
        case .csrfValidationFailed:
            return "安全验证失败，请刷新页面"
        case .securityTokenExpired, .securitySessionExpired:
            return "登录已过期，请重新登录"
        case .securityTokenInvalid:
            return "Token 无效，请重新登录"
        case .securityUnauthorized:
            return "未授权访问"
        case .securityForbidden:
            return "禁止访问"
        case .securityDataTampering:
            return "数据完整性验证失败"
        case .securitySuspiciousActivity:
            return "检测到可疑活动"
        case .securityEncryptionFailed:
            return "加密失败"
        case .securityDecryptionFailed:
            return "解密失败"
        case .securityKeychainError:
            return "安全存储错误"
        case .securitySSLHandshakeFailed, .securityCertificateInvalid:
            return "安全连接失败"
        case .securityRateLimitExceeded, .rateLimitExceeded:
            return "操作过于频繁，请稍后重试"
        case .securityCSRFTokenMismatch:
            return "安全验证失败，请刷新页面"
        case .sensitiveOperationBlocked:
            return "敏感操作被阻止"
            
        case .unknown(let message):
            return message
        case .cancelled:
            return "操作已取消"
        }
    }
    
    // MARK: - 日志消息
    
    /// 日志输出信息（包含技术细节）
    var logMessage: String {
        switch self {
        case .network(let error):
            return "[AppError.network] \(error.localizedDescription)"
        case .networkConnectionFailed:
            return "[AppError.networkConnectionFailed] 网络连接失败"
        case .requestTimeout:
            return "[AppError.requestTimeout] 请求超时"
            
        case .auth(let message):
            return "[AppError.auth] \(message)"
        case .invalidToken:
            return "[AppError.invalidToken] Token 无效或过期"
        case .notLoggedIn:
            return "[AppError.notLoggedIn] 用户未登录"
            
        case .dataNotFound:
            return "[AppError.dataNotFound] 数据不存在"
        case .dataParsingFailed(let reason):
            return "[AppError.dataParsingFailed] \(reason)"
        case .localDatabase(let error):
            return "[AppError.localDatabase] \(error.localizedDescription)"
            
        case .serverError(let code, let msg):
            return "[AppError.serverError] HTTP \(code): \(msg)"
        case .serviceUnavailable:
            return "[AppError.serviceUnavailable] 服务不可用"
            
        case .invalidParameter(let field):
            return "[AppError.invalidParameter] 字段：\(field)"
        case .missingParameter(let field):
            return "[AppError.missingParameter] 缺失字段：\(field)"
            
        case .permissionDenied:
            return "[AppError.permissionDenied] 权限不足"
        case .accessDenied:
            return "[AppError.accessDenied] 访问被拒绝"
            
        case .securityValidationFailed:
            return "[AppError.securityValidationFailed] 安全验证失败"
        case .csrfValidationFailed:
            return "[AppError.csrfValidationFailed] CSRF 验证失败"
        case .securityTokenExpired:
            return "[AppError.securityTokenExpired] Token 过期"
        case .securityTokenInvalid:
            return "[AppError.securityTokenInvalid] Token 无效"
        case .securitySessionExpired:
            return "[AppError.securitySessionExpired] Session 过期"
        case .securityUnauthorized:
            return "[AppError.securityUnauthorized] 未授权访问"
        case .securityForbidden:
            return "[AppError.securityForbidden] 禁止访问"
        case .securityDataTampering:
            return "[AppError.securityDataTampering] 数据篡改检测"
        case .securitySuspiciousActivity:
            return "[AppError.securitySuspiciousActivity] 可疑活动"
        case .securityEncryptionFailed:
            return "[AppError.securityEncryptionFailed] 加密失败"
        case .securityDecryptionFailed:
            return "[AppError.securityDecryptionFailed] 解密失败"
        case .securityKeychainError(let code):
            return "[AppError.securityKeychainError] Keychain 错误：\(code)"
        case .securitySSLHandshakeFailed:
            return "[AppError.securitySSLHandshakeFailed] SSL 握手失败"
        case .securityCertificateInvalid:
            return "[AppError.securityCertificateInvalid] 证书无效"
        case .securityRateLimitExceeded:
            return "[AppError.securityRateLimitExceeded] 请求频率超限"
        case .securityCSRFTokenMismatch:
            return "[AppError.securityCSRFTokenMismatch] CSRF Token 不匹配"
        case .rateLimitExceeded:
            return "[AppError.rateLimitExceeded] 请求频率超限"
        case .sensitiveOperationBlocked:
            return "[AppError.sensitiveOperationBlocked] 敏感操作被阻止"
            
        case .unknown(let message):
            return "[AppError.unknown] \(message)"
        case .cancelled:
            return "[AppError.cancelled] 操作取消"
        }
    }
    
    // MARK: - HTTP 状态码映射
    
    /// 从 HTTP 状态码创建 AppError
    static func fromHTTPStatus(_ statusCode: Int, message: String? = nil) -> AppError {
        let msg = message ?? "服务器错误"
        
        switch statusCode {
        case 400:
            return .invalidParameter("请求参数错误")
        case 401:
            return .invalidToken
        case 403:
            return .permissionDenied
        case 404:
            return .dataNotFound
        case 408:
            return .requestTimeout
        case 429:
            return .rateLimitExceeded
        case 500...599:
            return .serverError(statusCode, msg)
        default:
            return .serverError(statusCode, msg)
        }
    }
    
    // MARK: - LocalizedError 协议
    
    var errorDescription: String? {
        return userMessage
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .network, .networkConnectionFailed, .requestTimeout:
            return "请检查网络连接后重试"
        case .auth, .invalidToken, .notLoggedIn:
            return "请重新登录后重试"
        case .dataNotFound:
            return "数据可能已被删除或不存在"
        case .serverError:
            return "请稍后重试"
        case .permissionDenied, .accessDenied, .securityForbidden:
            return "请联系管理员获取权限"
        case .rateLimitExceeded, .securityRateLimitExceeded:
            return "请等待片刻后重试"
        case .securityTokenExpired, .securityTokenInvalid, .securitySessionExpired, .securityUnauthorized:
            return "请重新登录后重试"
        case .securitySSLHandshakeFailed, .securityCertificateInvalid:
            return "请检查网络连接或联系管理员"
        case .securityKeychainError:
            return "请尝试重新登录"
        default:
            return "请稍后重试"
        }
    }
}

// MARK: - Error 扩展

extension Error {
    /// 转换为 AppError
    var asAppError: AppError {
        if let appError = self as? AppError {
            return appError
        }
        
        let nsError = self as NSError
        switch nsError.domain {
        case NSURLErrorDomain:
            return .network(self)
        default:
            return .unknown(nsError.localizedDescription)
        }
    }
}
