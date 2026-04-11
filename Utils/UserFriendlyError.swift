//
//  UserFriendlyError.swift
//  终活
//
//  用户友好错误消息工具类
//

import Foundation

/// 用户友好错误
struct UserFriendlyError: LocalizedError {
    let title: String
    let message: String
    let suggestion: String
    let errorCode: String
    
    var errorDescription: String? { message }
    var recoverySuggestion: String? { suggestion }
    var failureReason: String? { title }
    
    /// 创建网络错误
    static func networkError(_ error: Error) -> UserFriendlyError {
        return UserFriendlyError(
            title: "网络连接失败",
            message: "无法连接到服务器，请检查网络连接",
            suggestion: "1. 检查 Wi-Fi 或移动数据\n2. 切换飞行模式后关闭\n3. 稍后重试",
            errorCode: "NETWORK_001"
        )
    }
    
    /// 创建认证错误
    static func authError() -> UserFriendlyError {
        return UserFriendlyError(
            title: "登录已过期",
            message: "您的登录状态已过期，请重新登录",
            suggestion: "点击下方按钮重新登录",
            errorCode: "AUTH_001"
        )
    }
    
    /// 创建数据错误
    static func dataError(_ fieldName: String) -> UserFriendlyError {
        return UserFriendlyError(
            title: "数据格式错误",
            message: "\(fieldName) 格式不正确",
            suggestion: "请检查输入格式后重试",
            errorCode: "DATA_001"
        )
    }
    
    /// 创建服务器错误
    static func serverError() -> UserFriendlyError {
        return UserFriendlyError(
            title: "服务器繁忙",
            message: "服务器暂时无法处理请求",
            suggestion: "请稍后再试，如问题持续请联系客服",
            errorCode: "SERVER_001"
        )
    }
    
    /// 创建权限错误
    static func permissionError(_ permission: String) -> UserFriendlyError {
        return UserFriendlyError(
            title: "需要授权",
            message: "需要\(permission)权限才能使用此功能",
            suggestion: "前往设置 > 隐私 > \(permission) 开启权限",
            errorCode: "PERMISSION_001"
        )
    }
    
    /// 创建存储错误
    static func storageError() -> UserFriendlyError {
        return UserFriendlyError(
            title: "存储空间不足",
            message: "设备存储空间不足，无法保存数据",
            suggestion: "1. 清理不需要的照片和视频\n2. 删除不常用的 App\n3. 重试操作",
            errorCode: "STORAGE_001"
        )
    }
}

/// Error 扩展 - 转换为用户友好错误
extension Error {
    var userFriendly: UserFriendlyError {
        if let urlError = self as? URLError {
            return .networkError(self)
        }
        if let apiError = self as? APIError {
            switch apiError {
            case .unauthorized, .invalidToken:
                return .authError()
            case .serverError:
                return .serverError()
            default:
                return .networkError(self)
            }
        }
        return .networkError(self)
    }
}
