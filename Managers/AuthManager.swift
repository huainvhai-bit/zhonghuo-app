//
//  AuthManager.swift
//  终活 - 认证管理
//

import Foundation

// ✅ 修复 #5: 标记为 @MainActor，确保所有 @Published 属性更新在主线程执行
@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isLoggedIn = false
    @Published var currentUser: String?
    
    private init() {}
    
    func login(email: String, password: String) async -> Bool {
        // TODO: 实现真实登录
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isLoggedIn = true
        currentUser = email
        return true
    }
    
    func register(email: String, password: String) async -> Bool {
        // TODO: 实现真实注册
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return true
    }
    
    func logout() {
        isLoggedIn = false
        currentUser = nil
    }
}
