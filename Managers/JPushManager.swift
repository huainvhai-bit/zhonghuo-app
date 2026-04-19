//
//  JPushManager.swift
//  终活
//
//  极光推送管理 (JPush 6.x)
//

import Foundation
import UIKit
import UserNotifications

// JPush 通过 bridging header 导入
// import JPUSHService.h (in Bridging-Header.h)

class JPushManager: NSObject {
    static let shared = JPushManager()
    
    // MARK: - 配置
    private let jpushAppKey = "a8ce5336b2833bfe4c91618c"
    
    // MARK: - 回调
    var onReceiveNotification: (([AnyHashable: Any]) -> Void)?
    var onReceiveMessage: ((String, [AnyHashable: Any]) -> Void)?
    
    private override init() {
        super.init()
    }
    
    // MARK: - 初始化
    func setup() {
        // 初始化 JPush
        JPUSHService.setup(withOption: nil, appKey: jpushAppKey, channel: "App Store", apsForProduction: true)
        
        // 设置推送代理
        let entity = JPUSHRegisterEntity()
        entity.types = Int(UInt(UNAuthorizationOptions.alert.rawValue | UNAuthorizationOptions.sound.rawValue | UNAuthorizationOptions.badge.rawValue))
        JPUSHService.register(forRemoteNotificationConfig: entity, delegate: self)
        
        // 获取 Registration ID
        JPUSHService.getAllTags({ (resCode, tags, seq) in
            print("JPush Tags: resCode=\(resCode)")
        }, seq: 0)
        
        print("JPush 初始化完成，AppKey: \(jpushAppKey)")
    }
    
    // MARK: - 设置别名（绑定用户 ID）
    func setAlias(userId: String) {
        JPUSHService.setAlias(userId, completion: { (resCode, alias, seq) in
            print("JPush 设置别名: resCode=\(resCode), alias=\(alias ?? "nil")")
            if resCode == 0 {
                print("别名绑定成功")
                UserDefaults.standard.set(userId, forKey: "jpush_alias")
            } else {
                print("别名绑定失败，错误码: \(resCode)")
            }
        }, seq: 0)
    }
    
    // MARK: - 删除别名
    func deleteAlias() {
        JPUSHService.deleteAlias({ (resCode, alias, seq) in
            print("JPush 删除别名: resCode=\(resCode)")
        }, seq: 0)
    }
    
    // MARK: - 获取 Registration ID
    func getRegistrationID() -> String? {
        return UserDefaults.standard.string(forKey: "jpush_registration_id")
    }
    
    // MARK: - 处理 Device Token
    func handleRemoteNotification(deviceToken: Data) {
        JPUSHService.registerDeviceToken(deviceToken)
        let tokenString = deviceToken.reduce("") { $0 + String(format: "%02x", $1) }
        print("JPush Device Token: \(tokenString)")
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

// MARK: - JPush Delegate
extension JPushManager: JPUSHRegisterDelegate {
    
    // MARK: - 收到通知（App 在前台）
    func jpushNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (Int) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("JPush 收到通知（前台）: \(userInfo)")
        handleNotification(userInfo: userInfo as? [AnyHashable: Any] ?? [:])
        completionHandler(Int(UNNotificationPresentationOptions.banner.rawValue | UNNotificationPresentationOptions.sound.rawValue))
    }
    
    // MARK: - 通知被点击
    func jpushNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("JPush 通知被点击: \(userInfo)")
        handleNotification(userInfo: userInfo as? [AnyHashable: Any] ?? [:])
        completionHandler()
    }
    
    // MARK: - 打开设置
    @available(iOS 12.0, *)
    func jpushNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification) {
        print("JPush 打开通知设置")
    }
    
    // MARK: - 授权状态
    func jpushNotificationAuthorization(_ status: JPAuthorizationStatus, withInfo info: [AnyHashable: Any]?) {
        print("JPush 通知授权状态: \(status.rawValue)")
    }
    
    // MARK: - 收到自定义消息
    func jpushReceive(_ center: Any!, didReceive remoteNotification: [AnyHashable: Any]) {
        print("JPush 收到自定义消息: \(remoteNotification)")
        handleNotification(userInfo: remoteNotification)
    }
}
