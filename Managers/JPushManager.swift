//
//  JPushManager.swift
//  终活
//
//  极光推送管理
//  ⚠️ 需要先运行 `pod install` 安装 JPush SDK
//

import Foundation
import UIKit
import UserNotifications

// MARK: - JPush 占位符（编译通过后取消注释）
// import JPush

class JPushManager: NSObject {
    static let shared = JPushManager()
    
    // MARK: - 配置
    // ⚠️ 替换为实际的极光 AppKey
    private let jpushAppKey = "你的极光AppKey"
    
    // MARK: - 回调
    var onReceiveNotification: (([AnyHashable: Any]) -> Void)?
    var onReceiveMessage: ((String, [AnyHashable: Any]) -> Void)?
    var onTagsCallback: ((Int, Set<String>?, [String]?) -> Void)?
    var onAliasCallback: ((Int, String?, [String]?) -> Void)?
    
    private override init() {
        super.init()
    }
    
    // MARK: - 初始化
    func setup() {
        // ⚠️ 需要在 Podfile 添加 JPush 后取消注释以下代码
        /*
        // 初始化 JPush
        JMServices.shared().register(withToken: nil)
        
        // 设置日志
        JPushInterface.setLogOff()
        
        // 设置推送代理
        JPushInterface.shared().jpushDelegate = self
        
        // 获取 Registration ID
        JPushInterface.getRegistrationID { [weak self] registrationId in
            print("JPush RegistrationID: \(registrationId ?? "nil")")
            if let regId = registrationId {
                self?.saveRegistrationID(regId)
            }
        }
        */
        
        print("JPush 初始化完成（SDK 未安装，跳过）")
    }
    
    // MARK: - 设置别名（绑定用户 ID）
    func setAlias(userId: String) {
        // ⚠️ 需要在 Podfile 添加 JPush 后取消注释
        /*
        JPushInterface.setAlias(userId, completion: { [weak self] (resCode, alias, seq) in
            print("JPush 设置别名: resCode=\(resCode), alias=\(alias ?? "nil")")
            self?.onAliasCallback?(resCode, alias, nil)
        }, seq: 0)
        */
        print("JPush 设置别名: \(userId)")
    }
    
    // MARK: - 删除别名
    func deleteAlias() {
        // ⚠️ 需要在 Podfile 添加 JPush 后取消注释
        /*
        JPushInterface.deleteAlias({ (resCode, alias, seq) in
            print("JPush 删除别名: resCode=\(resCode)")
        }, seq: 0)
        */
    }
    
    // MARK: - 设置标签
    func setTags(_ tags: Set<String>) {
        // ⚠️ 需要在 Podfile 添加 JPush 后取消注释
        /*
        JPushInterface.setTags(tags, completion: { [weak self] (resCode, tags, seq) in
            print("JPush 设置标签: resCode=\(resCode)")
            self?.onTagsCallback?(resCode, tags, nil)
        }, seq: 0)
        */
    }
    
    // MARK: - 添加监听
    func addObserver(_ observer: Any) {
        // ⚠️ 需要在 Podfile 添加 JPush 后取消注释
        // JPushInterface.shared().jpushDelegate = observer as? JPushDelegate
    }
    
    // MARK: - 获取 Registration ID
    func getRegistrationID() -> String? {
        // ⚠️ 需要在 Podfile 添加 JPush 后取消注释
        // return JPushInterface.getRegistrationID()
        return nil
    }
    
    // MARK: - 处理 Token
    func handleRemoteNotification(deviceToken: Data) {
        // ⚠️ 需要在 Podfile 添加 JPush 后取消注释
        // JPushInterface.registerDeviceToken(deviceToken)
        let tokenString = deviceToken.reduce("") { $0 + String(format: "%02x", $1) }
        print("JPush Device Token: \(tokenString)")
        saveRegistrationID(tokenString)
    }
    
    // MARK: - 处理通知打开
    func handleNotification(userInfo: [AnyHashable: Any]) {
        print("JPush 收到通知: \(userInfo)")
        
        // 解析通知类型
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
        
        // 上传到服务器
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
class JPushNotificationDelegate: NSObject /* ⚠️ 需要添加: , JPushDelegate */ {
    // ⚠️ 需要在 Podfile 添加 JPush 后取消注释并实现代理方法
    /*
    func jpushNotificationCenter(_ center: Any!, didReceive response: UNNotificationResponse!, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("JPush 通知被点击: \(userInfo)")
        JPushManager.shared.handleNotification(userInfo: userInfo as? [AnyHashable: Any] ?? [:])
        completionHandler()
    }
    
    func jpushNotificationCenter(_ center: Any!, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (Int) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("JPush 收到通知: \(userInfo)")
        JPushManager.shared.handleNotification(userInfo: userInfo as? [AnyHashable: Any] ?? [:])
        completionHandler(Int(JEPushNotificationAlertResult.alert.rawValue))
    }
    
    func jpushReceiveRegistrationID(_ registrationId: String!, error: Error!) {
        if let error = error {
            print("JPush RegistrationID 获取失败: \(error)")
            return
        }
        print("JPush RegistrationID: \(registrationId ?? "nil")")
        if let regId = registrationId {
            JPushManager.shared.saveRegistrationID(regId)
        }
    }
    */
}
