//
//  UserRegistration.swift
//  终活
//
//  用户注册管理
//  职责：用户注册、手机号验证
//

import Foundation

/// 用户注册管理器
/// 职责：用户注册、手机号验证
class UserRegistration {
    static let shared = UserRegistration()
    
    private let fileManager = FileManager.default
    private var documentsPath: String {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].path
    }
    
    var userFileURL: URL {
        URL(fileURLWithPath: documentsPath).appendingPathComponent("user.json")
    }
    
    // MARK: - 用户注册
    
    /// 注册用户
    func register(name: String, phone: String) -> Result<User, Error> {
        // 验证手机号格式
        guard isValidPhone(phone) else {
            return .failure(Error.invalidPhone)
        }
        
        // 检查是否已注册
        guard !fileManager.fileExists(atPath: userFileURL.path) else {
            return .failure(Error.alreadyRegistered)
        }
        
        // 创建新用户
        let user = User(
            id: UUID().uuidString,
            name: name,
            phone: phone,
            createdAt: Date(),
            emergencyContacts: [],
            checkInInterval: .twoDays,
            notificationsEnabled: true,
            cloudSyncEnabled: true,
            lastCheckInDate: nil,
            lastLoginAt: nil,
            lastLoginIp: nil,
            checkinCount: 0
        )
        
        // 保存用户
        do {
            let data = try JSONEncoder().encode(user)
            try data.write(to: userFileURL)
            print("✅ 用户注册成功：\(user.name)")
            return .success(user)
        } catch {
            print("❌ 保存用户失败：\(error)")
            return .failure(Error.saveFailed)
        }
    }
    
    // MARK: - 辅助方法
    
    /// 验证手机号格式
    private func isValidPhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: phone)
    }
    
    // MARK: - 错误处理
    
    enum Error: LocalizedError {
        case invalidPhone
        case alreadyRegistered
        case saveFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidPhone: return "请输入有效的手机号码"
            case .alreadyRegistered: return "该设备已注册"
            case .saveFailed: return "操作失败，请重试"
            }
        }
    }
}
