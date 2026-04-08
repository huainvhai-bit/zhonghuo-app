//
//  MessageManager.swift
//  终活
//
//  使用苹果原生 iMessage 发送紧急通知
//

import Foundation
import MessageUI
import UIKit

/// 紧急联系人模型（简化版，避免依赖 Models.swift）
struct EmergencyContactInfo {
    let id: String
    let name: String
    let phone: String
    let relationship: String
}

/// iMessage 管理器 - 用于发送紧急通知
class MessageManager: NSObject {
    static let shared = MessageManager()
    
    private var messageComposeDelegate: MessageComposeDelegate?
    
    override init() {
        super.init()
    }
    
    /// 检查是否支持发送短信
    static var canSendSMS: Bool {
        return MFMessageComposeViewController.canSendText()
    }
    
    /// 发送 iMessage 短信
    /// - Parameters:
    ///   - recipients: 收件人手机号数组
    ///   - body: 短信内容
    ///   - completion: 完成回调（成功/失败）
    func sendMessage(
        to recipients: [String],
        body: String,
        completion: ((Bool, String?) -> Void)? = nil
    ) {
        guard MFMessageComposeViewController.canSendText() else {
            print("❌ 设备不支持发送短信")
            completion?(false, "设备不支持发送短信")
            return
        }
        
        print("📱 准备发送 iMessage 通知")
        print("   - 收件人：\(recipients)")
        print("   - 内容：\(body)")
        
        // 在主线程中创建并展示短信界面
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let messageVC = MFMessageComposeViewController()
            messageVC.body = body
            messageVC.recipients = recipients
            
            // 设置代理处理发送结果
            let delegate = MessageComposeDelegate()
            delegate.completion = completion
            messageVC.messageComposeDelegate = delegate
            
            self.messageComposeDelegate = delegate
            
            // 获取当前窗口并展示
            if let window = UIApplication.shared.windows.first {
                if let rootVC = window.rootViewController {
                    // 递归查找最顶层的视图控制器
                    let topVC = self.findTopViewController(from: rootVC)
                    topVC.present(messageVC, animated: true, completion: nil)
                }
            }
        }
    }
    
    /// 递归查找最顶层的视图控制器
    private func findTopViewController(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return findTopViewController(from: presented)
        }
        if let nav = vc as? UINavigationController {
            return findTopViewController(from: nav.visibleViewController ?? nav)
        }
        if let tab = vc as? UITabBarController {
            return findTopViewController(from: tab.selectedViewController ?? tab)
        }
        return vc
    }
    
    /// 发送生命体征确认通知（给紧急联系人）
    /// - Parameters:
    ///   - contacts: 紧急联系人列表
    ///   - userName: 用户姓名
    ///   - hoursOverdue: 超时小时数
    ///   - completion: 完成回调
    func sendLifeCheckAlert(
        to contacts: [EmergencyContactInfo],
        userName: String,
        hoursOverdue: Int,
        completion: ((Bool, String?) -> Void)? = nil
    ) {
        guard !contacts.isEmpty else {
            print("⚠️ 没有紧急联系人，跳过短信通知")
            completion?(false, "没有紧急联系人")
            return
        }
        
        // 提取手机号
        let phoneNumbers = contacts.map { $0.phone }
        
        // 构建短信内容
        let message = """
        【终活】紧急通知
        
        \(userName) 已超过 \(hoursOverdue) 小时未签到，可能遇到危险。
        
        请尽快联系确认其安全状况！
        
        终活 App - 生命守护
        """
        
        print("🚨 发送生命体征确认通知")
        print("   - 联系人：\(contacts.count) 人")
        print("   - 超时：\(hoursOverdue) 小时")
        
        sendMessage(to: phoneNumbers, body: message, completion: completion)
    }
}

/// 短信发送完成代理
class MessageComposeDelegate: NSObject, MFMessageComposeViewControllerDelegate {
    var completion: ((Bool, String?) -> Void)?
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
        
        switch result {
        case .sent:
            print("✅ 短信发送成功")
            completion?(true, nil)
        case .cancelled:
            print("❌ 用户取消发送")
            completion?(false, "用户取消")
        case .failed:
            print("❌ 短信发送失败")
            completion?(false, "发送失败")
        @unknown default:
            print("⚠️ 未知结果")
            completion?(false, "未知错误")
        }
    }
}
