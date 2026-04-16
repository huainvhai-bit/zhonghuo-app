//
//  LegalConsultationManager.swift
//  终活
//
//  法律咨询服务管理器（简化版）
//  功能：提供法律咨询
//

import Foundation
import UIKit

class LegalConsultationManager: ObservableObject {
    static let shared = LegalConsultationManager()
    
    // 法律咨询电话（示例号码，可配置）
    private let legalHotlineNumber = "12348"
    
    private init() {}
    
    // MARK: - 法律咨询
    
    /// 拨打法律咨询电话
    func callLegalHotline() {
        // ✅ 修复 TODO: 实现法律咨询功能
        let phoneNumber = legalHotlineNumber.replacingOccurrences(of: " ", with: "")
        if let phoneURL = URL(string: "tel://\(phoneNumber)") {
            if UIApplication.shared.canOpenURL(phoneURL) {
                UIApplication.shared.open(phoneURL, options: [:]) { success in
                    print("🔵 法律咨询电话拨打\(success ? "成功" : "失败")")
                }
            } else {
                print("⚠️ 无法拨打法律咨询电话：设备不支持")
            }
        }
    }
    
    /// 打开法律咨询网页
    func openLegalConsultationWeb() {
        // 法律咨询官网（示例）
        let webURL = "https://www.12348.gov.cn"
        if let url = URL(string: webURL) {
            UIApplication.shared.open(url, options: [:]) { success in
                print("🔵 法律咨询网页打开\(success ? "成功" : "失败")")
            }
        }
    }
    
    /// 检查见证人资格
    func checkWitnessQualification(name: String, phone: String) -> (qualified: Bool, message: String) {
        // 简单验证：姓名和电话不能为空
        if name.isEmpty || phone.isEmpty {
            return (false, "姓名和电话不能为空")
        }
        
        // 电话号码验证
        if phone.count < 11 {
            return (false, "电话号码格式不正确")
        }
        
        return (true, "验证通过")
    }
}
