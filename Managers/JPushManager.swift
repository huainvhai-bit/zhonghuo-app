//
//  JPushManager.swift
//  终活
//
//  极光推送管理
//  ⚠️ 占位符版本 - 需通过 Xcode 完成 SDK 集成
//

import Foundation
import UIKit
import UserNotifications

class JPushManager: NSObject {
    static let shared = JPushManager()
    
    // MARK: - 配置
    // ⚠️ 替换为实际的极光 AppKey
    private let jpushAppKey = "你的极光AppKey"
    
    // MARK: - 回调
    var onReceiveNotification: (([AnyHashable: Any]) -> Void)?
    var onReceiveMessage: ((String, [AnyHashable: Any]) -> Void)?
    
    private override init() {
        super.init()
    }
    
    // MARK: - 初始化
    func setup() {
        print("JPush 初始化完成（占位符）")
    }
    
    // MARK: - 设置别名（绑定用户 ID）
    func setAlias(userId: String) {
        print("JPush 设置别名: \(userId)")
    }
    
    // MARK: - 删除别名
    func deleteAlias() {
        print("JPush 删除别名")
    }
    
    // MARK: - 获取 Registration ID
    func getRegistrationID() -> String? {
        return UserDefaults.standard.string(forKey: "jpush_registration_id")
    }
    
    // MARK: - 处理 Device Token
    func handleRemoteNotification(deviceToken: Data) {
        let tokenString = deviceToken.reduce("") { $0 + String(format: "%02x", $1) }
        print("JPush Device Token: \(tokenString)")
        saveRegistrationID(tokenString)
    }
    
    // MARK: - 处理通知
    func handleNotification(userInfo: [AnyHashable: Any]) {
        print("JPush 收到通知: \(userInfo)")
        
        if let type = userInfo["type"] as? String {
            switch type {
            case "capsule_received":
                NotificationCenter.default.post(name: .didReceiveCapsuleShare, object: userInfo)
            case "checkin_missed":
                NotificationCenter.default.post(name: .didReceiveCheckInMissed, object: userInfo)
            default:
                print("未知的通知类型: \(type)")
            }
        }
    }
    
    // MARK: - 本地通知
    func showLocalNotification(title: String, body: String, userInfo: [String: Any] = [:]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("本地通知发送失败: \(error)")
            } else {
                print("本地通知发送成功")
            }
        }
    }
    
    // MARK: - 保存 Registration ID
    func saveRegistrationID(_ registrationId: String) {
        UserDefaults.standard.set(registrationId, forKey: "jpush_registration_id")
        print("JPush RegistrationID 已保存: \(registrationId)")
        
        Task {
            await uploadRegistrationID(registrationId)
        }
    }
    
    private func uploadRegistrationID(_ registrationId: String) async {
        guard !DataManager.apiURL.isEmpty else { return }
        
        do {
            let mutation = """
            mutation {
                updateDeviceToken(token: "\(registrationId)") {
                    success
                    message
                }
            }
            """
            let _ = try await APIClient.shared.query(mutation)
            print("RegistrationID 上传成功")
        } catch {
            print("RegistrationID 上传失败: \(error)")
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let didReceiveCapsuleShare = Notification.Name("didReceiveCapsuleShare")
    static let didReceiveCheckInMissed = Notification.Name("didReceiveCheckInMissed")
}
