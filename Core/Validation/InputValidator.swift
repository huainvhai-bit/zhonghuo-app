//
//  InputValidator.swift
//  安伴助手
//
//  输入验证工具类
//

import Foundation

/// 输入验证器
class InputValidator {
    
    /// 验证手机号
    static func validatePhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: phone)
    }
    
    /// 验证密码强度
    static func validatePassword(_ password: String) -> Bool {
        // 至少 8 位，包含字母和数字
        guard password.count >= 8 else { return false }
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        return hasLetter && hasNumber
    }
    
    /// 验证邮箱
    static func validateEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: email)
    }
    
    /// 验证身份证号
    static func validateIDCard(_ idCard: String) -> Bool {
        let pattern = "^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\\d|3[01])\\d{3}[\\dXx]$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: idCard)
    }
    
    /// 验证文本长度
    static func validateLength(_ text: String, min: Int = 0, max: Int = Int.max) -> Bool {
        return text.count >= min && text.count <= max
    }
    
    /// 验证是否为空
    static func validateNotEmpty(_ text: String?) -> Bool {
        guard let text = text else { return false }
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 过滤特殊字符
    static func sanitizeInput(_ input: String) -> String {
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 防止 SQL 注入
    static func escapeSQL(_ string: String) -> String {
        return string.replacingOccurrences(of: "'", with: "''")
    }
}
