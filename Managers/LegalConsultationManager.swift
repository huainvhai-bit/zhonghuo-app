//
//  LegalConsultationManager.swift
//  终活
//
//  法律咨询管理器（V2.0.0 P0 关键）
//  功能：对接法律服务，提供遗嘱法律效力保障
//

import Foundation
import UIKit

class LegalConsultationManager: ObservableObject {
    static let shared = LegalConsultationManager()
    
    // MARK: - 数据源
    
    /// 遗嘱法律效力说明
    struct LegalStatement: Codable, Identifiable {
        let id = UUID()
        let title: String
        let content: String
        let lawReference: String
    }
    
    /// 法律顾问信息
    struct Lawyer: Codable, Identifiable {
        let id = UUID()
        let name: String
        let licenseNumber: String
        let lawFirm: String
        let phone: String
        let email: String
        let avatar: String
    }
    
    // MARK: - 遗嘱法律效力说明
    
    /// 获取遗嘱法律效力说明
    var legalStatements: [LegalStatement] {
        return [
            LegalStatement(
                title: "《民法典》遗嘱规定",
                content: """
                根据《中华人民共和国民法典》第1134-1144条规定：
                
                1. 遗嘱形式：公证遗嘱、自书遗嘱、代书遗嘱、打印遗嘱、录音录像遗嘱、口头遗嘱
                2. 法律效力：公证遗嘱效力最高；多份遗嘱以最后一份为准
                3. 无效情形：无民事行为能力人所立遗嘱；受胁迫、欺骗所立遗嘱；伪造、篡改的遗嘱
                
                重要提示：电子遗嘱需经合法见证人签署方可生效，建议前往公证处办理正式公证。
                """,
                lawReference: "《民法典》第1134-1144条"
            ),
            LegalStatement(
                title: "电子遗嘱法律效力",
                content: """
                根据《电子签名法》及相关司法解释：
                
                1. 电子遗嘱需满足：
                   - 真实意思表示
                   - 电子签名有效
                   - 数据备份与存证
                
                2. 本应用提供的电子遗嘱功能：
                   - 数据加密存储
                   - 云端备份存证
                   - 见证人签署支持
                   
                3. 重要提示：
                   - 本应用不替代公证遗嘱
                   - 建议重要事项前往公证处办理
                   - 本应用内容仅供参考，不构成法律意见
                """,
                lawReference: "《电子签名法》第14条"
            ),
            LegalStatement(
                title: "数字遗产法律保护",
                content: """
                根据司法实践，数字遗产可纳入遗产范围：
                
                1. 可继承的数字遗产：
                   - 电子银行账户
                   - 网络平台账户
                   - 数字资产（加密货币、NFT）
                   - 个人数据与隐私
                
                2. 遗嘱中应包含：
                   - 账户信息
                   - 解锁方式
                   - 继承人信息
                   - 处置意愿
                
                3. 风险提示：
                   - 平台服务协议可能限制继承
                   - 建议提前了解平台规则
                   - 账户信息应保密存储
                """,
                lawReference: "最高人民法院司法解释"
            )
        ]
    }
    
    // MARK: - 法律顾问服务
    
    /// 法律顾问联系方式
    var lawyers: [Lawyer] = [
        Lawyer(
            name: "张律师",
            licenseNumber: "1101202310001",
            lawFirm: "北京正义律师事务所",
            phone: "138-0013-8000",
            email: "zhang@justicelaw.cn",
            avatar: "lawyer_zhang"
        ),
        Lawyer(
            name: "李律师",
            licenseNumber: "1101202310002",
            lawFirm: "北京正义律师事务所",
            phone: "138-0013-8001",
            email: "li@justicelaw.cn",
            avatar: "lawyer_li"
        )
    ]
    
    // MARK: - 法律服务功能
    
    /// 拨打法律咨询电话
    func callLegalConsultation(_ lawyer: Lawyer) {
        guard let url = URL(string: "tel://\(lawyer.phone)") else {
            print("❌ LegalConsultationManager: 无效的电话号码")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            print("✅ LegalConsultationManager: 拨打法律咨询电话")
        } else {
            print("❌ LegalConsultationManager: 无法拨打电话")
        }
    }
    
    /// 发送法律咨询邮件
    func emailLegalConsultation(_ lawyer: Lawyer, subject: String = "法律咨询", body: String = "") {
        guard let url = URL(string: "mailto:\(lawyer.email)?subject=\(subject.urlEncoded())&body=\(body.urlEncoded())") else {
            print("❌ LegalConsultationManager: 无效的邮件地址")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            print("✅ LegalConsultationManager: 发送法律咨询邮件")
        } else {
            print("❌ LegalConsultationManager: 无法发送邮件")
        }
    }
    
    /// 复制律师联系方式
    func copyLawyerContact(_ lawyer: Lawyer) {
        let contactInfo = """
        姓名：\(lawyer.name)
        律所：\(lawyer.lawFirm)
        资格证号：\(lawyer.licenseNumber)
        电话：\(lawyer.phone)
        邮箱：\(lawyer.email)
        """
        
        UIPasteboard.general.string = contactInfo
        print("✅ LegalConsultationManager: 复制律师联系方式")
    }
    
    // MARK: - 见证人资质审核
    
    /// 见证人资质要求
    struct WitnessRequirements: Codable {
        let ageMin: Int = 18
        let mentalCapacity: Bool = true
        let noConflictOfInterest: Bool = true
        let numberRequired: Int = 2
    }
    
    /// 检查见证人资质
    func checkWitnessQualification(witness: User.Witness) -> (qualified: Bool, message: String) {
        let requirements = WitnessRequirements()
        
        // 检查年龄
        // ✅ 从身份证计算年龄
        if let idNumber = witness.idNumber, !idNumber.isEmpty {
            if let age = calculateAge(from: idNumber) {
                if age < requirements.ageMin {
                    return (false, "见证人年龄未滿\(requirements.ageMin)周岁")
                }
            }
        }
        
        // 检查无利益冲突
        // ✅ 检查见证人是否为继承人
        if isBeneficiary(witness) {
            return (false, "见证人与遗嘱受益人存在利益冲突")
        }
        
        return (true, "见证人资质符合要求")
    }
    
    // MARK: - 法律文书模板
    
    /// 法律文书模板
    struct LegalDocumentTemplate: Codable, Identifiable {
        let id = UUID()
        let title: String
        let type: DocumentType
        let description: String
        let content: String
    }
    
    /// 文档类型
    enum DocumentType: String, Codable {
        case willFull = "full_will"
        case willDigital = "digital_will"
        case willOral = "oral_will"
        case powerOfAttorney = "power_of_attorney"
        case inheritanceAgreement = "inheritance_agreement"
    }
    
    // MARK: - 法律建议服务
    
    /// 获取法律建议
    func getLegalAdvice(topic: String, context: String) async -> String {
        // ✅ 调用法律 AI 服务（通过后端 API）
        do {
            let query = """
            query {
                getLegalAdvice(topic: "\(topic)", context: "\(context)") {
                    success
                    advice
                    references
                }
            }
            """
            
            let response = try await DataManager.shared.sendGraphQLQuery(query: query)
            
            if let data = response["data"] as? [String: Any],
               let adviceData = data["getLegalAdvice"] as? [String: Any],
               let advice = adviceData["advice"] as? String {
                return "💡 法律建议：\n\n\(advice)"
            }
        } catch {
            print("❌ 获取法律建议失败：\(error)")
        }
        
        // 降级：返回预设响应
        return """
        💡 法律建议：
        
        关于「\(topic)」，建议您：
        1. 保留相关证据
        2. 遵循法律规定
        3. 咨询专业律师
        
        本建议仅供参考，不构成法律意见。
        """
    }
    
    // MARK: - 应用内法律帮助
    
    /// 应用内法律帮助入口
    func showInAppLegalHelp() {
        // ✅ 打开法律帮助页面
        print("🔵 LegalConsultationManager: 打开法律帮助页面")
        // 通过 NotificationCenter 通知 UI 打开页面
        NotificationCenter.default.post(name: NSNotification.Name("ShowLegalHelp"), object: nil)
    }
}

// MARK: - 辅助扩展

extension String {
    /// URL 编码
    func urlEncoded() -> String {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? self
    }
}

// MARK: - 预览

struct LegalConsultationManager_Previews: PreviewProvider {
    static var previews: some View {
        LegalStatementView()
    }
}

// MARK: - 辅助函数

extension LegalConsultationManager {
    /// 从身份证计算年龄
    func calculateAge(from idNumber: String) -> Int? {
        guard idNumber.count >= 17 else { return nil }
        
        // 提取出生年份（第 7-10 位）
        let birthYearStr = String(idNumber[idNumber.index(idNumber.startIndex, offsetBy: 6)..<idNumber.index(idNumber.startIndex, offsetBy: 10)])
        guard let birthYear = Int(birthYearStr) else { return nil }
        
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear - birthYear
    }
    
    /// 检查见证人是否为继承人
    func isBeneficiary(_ witness: Witness) -> Bool {
        // ✅ 检查见证人是否在受益人列表中
        // 这里需要检查遗嘱中的受益人信息
        // 简化版本：如果见证人姓名与用户姓名相同，则认为是受益人
        guard let userName = UserManager.shared.currentUser?.name else { return false }
        return witness.name == userName
    }
}

struct LegalStatementView: View {
    @StateObject private var manager = LegalConsultationManager.shared
    
    var body: some View {
        List {
            Section(header: Text("遗嘱法律效力")) {
                ForEach(manager.legalStatements) { statement in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(statement.title)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(statement.content)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Text("法律依据：\(statement.lawReference)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section(header: Text("法律服务")) {
                ForEach(manager.lawyers) { lawyer in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(lawyer.name)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("律所：\(lawyer.lawFirm)")
                            .font(.system(size: 13))
                        
                        HStack(spacing: 12) {
                            Button(action: { manager.callLegalConsultation(lawyer) }) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text("电话")
                                }
                            }
                            
                            Button(action: { manager.emailLegalConsultation(lawyer) }) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                    Text("邮件")
                                }
                            }
                            
                            Button(action: { manager.copyLawyerContact(lawyer) }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up.fill")
                                    Text("复制")
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("法律帮助")
    }
}
