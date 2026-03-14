//
//  SecureStorage.swift
//  终活 - 安全存储
//

import Foundation

class SecureStorage {
    static let shared = SecureStorage()
    
    private init() {}
    
    func save(key: String, value: String) {
        // TODO: 实现安全存储
    }
    
    func load(key: String) -> String? {
        return nil
    }
}
