//
//  ServerConfig.swift
//  终活
//
//  服务器配置模型
//

import Foundation

// MARK: - 服务器配置
struct ServerConfig: Codable {
    let success: Bool
    let data: ServerConfigData?
    let error: String?
    
    struct ServerConfigData: Codable {
        let apiVersion: String
        let serverName: String
        let endpoints: Endpoints
        let features: Features
        let limits: Limits
        let sms: SMSConfig?  // 短信配置
        let serverInfo: ServerInfo?  // 服务器信息（用于调试）
        
        struct Endpoints: Codable {
            let base: String
            let api: String
            let upload: String
        }
        
        struct Features: Codable {
            let userSync: Bool
            let capsuleSync: Bool
            let willSync: Bool
            let checkinSync: Bool
            let witnessSync: Bool
        }
        
        struct Limits: Codable {
            let maxUploadSize: Int
            let maxCapsules: Int
            let maxWillModules: Int
        }
        
        struct SMSConfig: Codable {
            let enabled: Bool
            let provider: String
            let isDevelopment: Bool
        }
        
        struct ServerInfo: Codable {
            let configuredUrl: String
            let detectedUrl: String
            let usingConfigured: Bool
        }
    }
}

// MARK: - 签到同步响应
struct ServerCheckInResponse: Codable {
    let success: Bool
    let data: CheckInData?
    let error: String?
    
    struct CheckInData: Codable {
        let status: String
        let lastCheckInAt: String?
        let nextCheckInAt: String?
        let checkInCount: Int
    }
}
