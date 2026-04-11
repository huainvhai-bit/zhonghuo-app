import SwiftUI
//
//  WillTemplateManager.swift
//  终活
//
//  遗嘱模板管理器（V1.1 剩余任务）
//  功能：提供 5+ 种专业遗嘱模板
//

import Foundation

class WillTemplateManager: ObservableObject {
    static let shared = WillTemplateManager()
    
    private init() {}
    
    // MARK: - 遗嘱模板定义
    
    /// 遗嘱模板
    struct WillTemplate: Codable, Identifiable {
        let id = UUID()
        let name: String
        let type: WillModule.WillType
        let description: String
        let contentTemplate: String
        let 适用场景: [String]
        let 法律合规: String
        let recommendedFields: [String]
    }
    
    /// 遗嘱模板列表
    var templates: [WillTemplate] = [
        WillTemplate(
            name: "财产继承遗嘱",
            type: .property,
            description: "传统财产继承遗嘱，适用于房产、存款、股票等财产分配",
            contentTemplate: """
            遗嘱
            
            立遗嘱人：\(UserManager.shared.currentUser?.name ?? "本人")
            身份证号：\(UserManager.shared.currentUser?.phone ?? "未知")
            
            一、遗嘱内容
            
            本人自愿订立本遗嘱，对本人名下财产进行如下分配：
            
            1. 房产
               - 地址：\(UserManager.shared.currentUser?.address ?? "待填写")
               - 产权证号：\(UserManager.shared.currentUser?.propertyId ?? "待填写")
               - 继承人：\(UserManager.shared.currentUser?.spouseName ?? "待填写")
            
            2. 存款
               - 银行：\(UserManager.shared.currentUser?.bank ?? "待填写")
               - 账号：\(UserManager.shared.currentUser?.account ?? "待填写")
               - 继承人：\(UserManager.shared.currentUser?.childName ?? "待填写")
            
            3. 股票/基金
               - 席位：\(UserManager.shared.currentUser?.stock ?? "待填写")
               - 账号：\(UserManager.shared.currentUser?.fund ?? "待填写")
               - 继承人：\(UserManager.shared.currentUser?.relativeName ?? "待填写")
            
            4. 其他财产
               - \(UserManager.shared.currentUser?.otherProperty ?? "待填写")
               - 继承人：待填写
            
            二、遗嘱执行人
            
            指定：\(UserManager.shared.currentUser?.executorName ?? "待填写")
            联系方式：\(UserManager.shared.currentUser?.executorContact ?? "待填写")
            
            三、其他说明
            
            1. 本遗嘱为本人真实意愿，不受任何胁迫、欺骗
            2. 本遗嘱一式两份，本人及执行人各执一份
            3. 本遗嘱自签署之日起生效
            
            立遗嘱人：本人签名
            日期：\(Date().formatted(.dateTime.year().month().day()))
            """,
           适用场景: ["有房产", "有存款", "有股票基金", "财产结构清晰"],
           法律合规: "符合《民法典》第1134条（自书遗嘱）",
            recommendedFields: ["房产信息", "存款信息", "股票信息", "继承人信息", "执行人信息"]
        ),
        
        WillTemplate(
            name: "数字遗产遗嘱",
            type: .otherInstructions,
            description: "专门用于分配数字资产的遗嘱，适用于社交媒体、加密货币、游戏账号等",
            contentTemplate: """
            数字遗产遗嘱
            
            立遗嘱人：\(UserManager.shared.currentUser?.name ?? "本人")
            身份证号：\(UserManager.shared.currentUser?.phone ?? "未知")
            
            一、数字资产清单
            
            1. 社交媒体账号
               - 微信：\(UserManager.shared.currentUser?.wechat ?? "待填写")
               - QQ：\(UserManager.shared.currentUser?.qq ?? "待填写")
               - 微博：\(UserManager.shared.currentUser?.weibo ?? "待填写")
               - 继承人：\(UserManager.shared.currentUser?.socialInheritor ?? "待填写")
            
            2. 加密货币
               - 比特币地址：\(UserManager.shared.currentUser?.bitcoin ?? "待填写")
               - 钱包密码：\(UserManager.shared.currentUser?.walletPassword ?? "待填写")
               - 继承人：\(UserManager.shared.currentUser?.cryptoInheritor ?? "待填写")
            
            3. 云存储账户
               - iCloud：\(UserManager.shared.currentUser?.iCloud ?? "待填写")
               - 百度网盘：\(UserManager.shared.currentUser?.baidu ?? "待填写")
               - 继承人：\(UserManager.shared.currentUser?.cloudInheritor ?? "待填写")
            
            4. 游戏账号
               - 平台：\(UserManager.shared.currentUser?.gamePlatform ?? "待填写")
               - 账号：\(UserManager.shared.currentUser?.gameAccount ?? "待填写")
               - 继承人：\(UserManager.shared.currentUser?.gameInheritor ?? "待填写")
            
            5. 电子邮件
               - 邮箱：\(UserManager.shared.currentUser?.email ?? "待填写")
               - 密码：\(UserManager.shared.currentUser?.emailPassword ?? "待填写")
               - 继承人：\(UserManager.shared.currentUser?.emailInheritor ?? "待填写")
            
            二、处置意愿
            
            1. 社交媒体：\(UserManager.shared.currentUser?.socialInstruction ?? "待填写")
            2. 加密货币：\(UserManager.shared.currentUser?.cryptoInstruction ?? "待填写")
            3. 云存储：\(UserManager.shared.currentUser?.cloudInstruction ?? "待填写")
            4. 游戏账号：\(UserManager.shared.currentUser?.gameInstruction ?? "待填写")
            
            三、数字遗产执行人
            
            指定：\(UserManager.shared.currentUser?.digitalExecutor ?? "待填写")
            联系方式：\(UserManager.shared.currentUser?.digitalContact ?? "待填写")
            
            四、其他说明
            
            1. 本遗嘱为本人真实意愿
            2. 请继承人妥善保管账户信息，防止泄露
            3. 本遗嘱自签署之日起生效
            
            立遗嘱人：本人签名
            日期：\(Date().formatted(.dateTime.year().month().day()))
            """,
           适用场景: ["拥有加密货币", "多个社交媒体账号", "云存储用户", "游戏爱好者"],
           法律合规: "符合《民法典》第1134条 + 《电子签名法》第14条",
            recommendedFields: ["社交媒体账号", "加密货币地址", "云存储账号", "密码保管", "处置意愿"]
        ),
        
        WillTemplate(
            name: "简易继承遗嘱",
            type: .property,
            description: "简洁版遗嘱，适合财产结构简单的用户",
            contentTemplate: """
            遗嘱
            
            立遗嘱人：\(UserManager.shared.currentUser?.name ?? "本人")
            身份证号：\(UserManager.shared.currentUser?.phone ?? "未知")
            
            本人自愿订立本遗嘱，对本人全部财产作如下分配：
            
            1. 所有银行存款及理财资金
               - 继承人：\(UserManager.shared.currentUser?.primaryInheritor ?? "待填写")
               - 比例：100%
            
            2. 所有房产
               - 地址：\(UserManager.shared.currentUser?.address ?? "待填写")
               - 继承人：\(UserManager.shared.currentUser?.propertyInheritor ?? "待填写")
               - 比例：100%
            
            3. 所有车辆
               - 车牌：\(UserManager.shared.currentUser?.carPlate ?? "待填写")
               - 继承人：\(UserManager.shared.currentUser?.carInheritor ?? "待填写")
               - 比例：100%
            
            4. 其他个人物品
               - 继承人：\(UserManager.shared.currentUser?.otherInheritor ?? "待填写")
               - 比例：100%
            
            遗嘱执行人：\(UserManager.shared.currentUser?.executorName ?? "待填写")
            联系方式：\(UserManager.shared.currentUser?.executorContact ?? "待填写")
            
            本遗嘱一式两份，本人及执行人各执一份，自签署之日起生效。
            
            立遗嘱人：本人签名
            日期：\(Date().formatted(.dateTime.year().month().day()))
            """,
           适用场景: ["财产结构简单", "家庭成员少", "希望简化流程"],
           法律合规: "符合《民法典》第1134条（自书遗嘱）",
            recommendedFields: ["主要财产", "继承人信息", "执行人信息"]
        ),
        
        WillTemplate(
            name: "遗嘱+安葬安排",
            type: .property,
            description: "包含财产分配和身后事安排的综合遗嘱",
            contentTemplate: """
            综合遗嘱
            
            立遗嘱人：\(UserManager.shared.currentUser?.name ?? "本人")
            身份证号：\(UserManager.shared.currentUser?.phone ?? "未知")
            
            一、财产分配
            
            1. 银行存款及理财
               - 继承人：\(UserManager.shared.currentUser?.moneyInheritor ?? "待填写")
               - 比例：100%
            
            2. 房产
               - 地址：\(UserManager.shared.currentUser?.address ?? "待填写")
               - 继承人：\(UserManager.shared.currentUser?.propertyInheritor ?? "待填写")
               - 比例：100%
            
            3. 车辆
               - 车牌：\(UserManager.shared.currentUser?.carPlate ?? "待填写")
               - 继承人：\(UserManager.shared.currentUser?.carInheritor ?? "待填写")
               - 比例：100%
            
            二、身后事安排
            
            1. 治丧方式
               - 仪式：\(UserManager.shared.currentUser?.funeralType ?? "待填写")
               - 地点：\(UserManager.shared.currentUser?.funeralLocation ?? "待填写")
            
            2. 安葬方式
               - 方式：\(UserManager.shared.currentUser?.burialType ?? "待填写")
               - 墓地：\(UserManager.shared.currentUser?.cemetery ?? "待填写")
            
            3. 丧葬费用
               - 来源：\(UserManager.shared.currentUser?.funeralFund ?? "待填写")
               - 支配人：\(UserManager.shared.currentUser?.funeralExecutor ?? "待填写")
            
            4. 其他安排
               - \(UserManager.shared.currentUser?.otherArrangement ?? "待填写")
            
            三、遗嘱执行人
            
            指定：\(UserManager.shared.currentUser?.executorName ?? "待填写")
            联系方式：\(UserManager.shared.currentUser?.executorContact ?? "待填写")
            
            四、其他说明
            
            1. 本遗嘱为本人真实意愿
            2. 身后事安排请家属遵照执行
            3. 本遗嘱自签署之日起生效
            
            立遗嘱人：本人签名
            日期：\(Date().formatted(.dateTime.year().month().day()))
            """,
           适用场景: ["希望安排身后事", "简化家属负担", "有明确安葬意愿"],
           法律合规: "符合《民法典》第1134条 + 尊重丧葬习俗",
            recommendedFields: ["财产分配", "治丧安排", "安葬方式", "执行人信息"]
        ),
        
        WillTemplate(
            name: "未成年子女监护遗嘱",
            type: .property,
            description: "专为有未成年子女的用户设计，包含财产管理和监护安排",
            contentTemplate: """
            监护遗嘱
            
            立遗嘱人：\(UserManager.shared.currentUser?.name ?? "本人")
            身份证号：\(UserManager.shared.currentUser?.phone ?? "未知")
            
            本人自愿订立本遗嘱，对未成年子女的监护和财产管理作出如下安排：
            
            一、子女监护
            
            1. 监护人指定
               - 第一顺序：\(UserManager.shared.currentUser?.primaryGuardian ?? "待填写")
               - 第二顺序：\(UserManager.shared.currentUser?.secondaryGuardian ?? "待填写")
               - 监护职责：生活照顾、教育培养、医疗决策
            
            2. 监护期限
               - 起始：本人去世之日
               - 终止：子女年满18周岁
            
            二、财产管理
            
            1. 财产 guardian
               - 管理人：\(UserManager.shared.currentUser?.propertyGuardian ?? "待填写")
               - 管理职责：投资、保管、分配
            
            2. 财产范围
               - 银行存款：待填写
               - 房产：待填写
               - 其他：待填写
            
            3. 财产分配
               - 成年前：每月生活费 \(UserManager.shared.currentUser?.monthlyAllowance ?? "待填写")
               - 成年时：全部财产继承
            
            三、其他安排
            
            1. 探视权：\(UserManager.shared.currentUser?.visitation ?? "待填写")
            2. 教育安排：\(UserManager.shared.currentUser?.education ?? "待填写")
            3. 医疗决定：\(UserManager.shared.currentUser?.medical ?? "待填写")
            
            四、遗嘱执行人
            
            指定：\(UserManager.shared.currentUser?.executorName ?? "待填写")
            联系方式：\(UserManager.shared.currentUser?.executorContact ?? "待填写")
            
            五、其他说明
            
            1. 本遗嘱为本人真实意愿
            2. 监护人及财产管理人应尽职履责
            3. 本遗嘱自签署之日起生效
            
            立遗嘱人：本人签名
            日期：\(Date().formatted(.dateTime.year().month().day()))
            """,
           适用场景: ["有未成年子女", "希望指定监护人", "财产管理规划"],
           法律合规: "符合《民法典》第29条（遗嘱指定监护）+ 第1133条（遗嘱继承）",
            recommendedFields: ["监护人信息", "财产管理人", "子女生活安排", "教育医疗"]
        )
    ]
    
    // MARK: - 模板管理
    
    /// 获取模板
    func getTemplate(by type: WillModule.WillType) -> WillTemplate? {
        return templates.first { $0.type == type }
    }
    
    /// 获取所有模板类型
    func getAllTemplateTypes() -> [WillModule.WillType] {
        return templates.map { $0.type }
    }
    
    // MARK: - 模板应用
    
    /// 应用模板创建遗嘱
    func applyTemplate(
        template: WillTemplate,
        customizations: [String: String]
    ) -> WillModule {
        print("🔵 WillTemplateManager: 应用模板 - \(template.name)")
        
        // 替换模板变量
        var content = template.contentTemplate
        
        // 替换自定义字段
        for (key, value) in customizations {
            content = content.replacingOccurrences(of: key, with: value)
        }
        
        // 创建遗嘱对象
        let will = WillModule(
            id: UUID().uuidString,
            type: template.type,
            content: content,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        print("✅ WillTemplateManager: 遗嘱已创建")
        return will
    }
    
    // MARK: - 用户数据填充
    
    /// 获取用户数据字典（用于模板替换）
    func getUserDataDictionary() -> [String: String] {
        guard let user = UserManager.shared.currentUser else {
            return [:]
        }
        
        return [
            "\(UserManager.shared.currentUser?.name ?? "本人")": user.name ?? "本人",
            "\(UserManager.shared.currentUser?.phone ?? "未知")": user.idNumber ?? "未知",
            // ✅ 添加更多字段
            "\(UserManager.shared.currentUser?.phone ?? "手机号")": user.phone ?? "手机号",
            "[日期]": DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none),
            "[城市]": "[填写城市]",
        ]
    }
}

// MARK: - 预览

struct WillTemplateManager_Previews: PreviewProvider {
    static var previews: some View {
        WillTemplateListView()
    }
}

struct WillTemplateListView: View {
    @StateObject private var manager = WillTemplateManager.shared
    
    @State private var selectedTemplate: WillTemplateManager.WillTemplate?
    @State private var showPreview = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("专业遗嘱模板")) {
                    ForEach(manager.templates) { template in
                        Button(action: {
                            selectedTemplate = template
                            showPreview = true
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(template.name)
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                
                                Text(template.description)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                
                                HStack(spacing: 6) {
                                    ForEach(template.适用场景.prefix(2), id: \.self) { scenario in
                                        Text(scenario)
                                            .font(.system(size: 11))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                    }
                                    
                                    if template.适用场景.count > 2 {
                                        Text("+\(template.适用场景.count - 2)")
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                Section(header: Text("使用说明")) {
                    Text("• 选择模板后，系统会自动生成遗嘱内容")
                    Text("• 您可以根据实际情况修改遗嘱内容")
                    Text("• 遗嘱完成后，建议进行见证人签署")
                    Text("• 重要遗嘱建议前往公证处办理公证")
                }
            }
            .navigationTitle("遗嘱模板")
            .sheet(isPresented: $showPreview) {
                if let template = selectedTemplate {
                    WillTemplatePreviewView(template: template)
                }
            }
        }
    }
}

struct WillTemplatePreviewView: View {
    let template: WillTemplateManager.WillTemplate
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text(template.name)
                    .font(.system(size: 20, weight: .bold))
                
                Text(template.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Divider()
                
                ScrollView {
                    Text(template.contentTemplate)
                        .font(.system(size: 13))
                        .lineHeightMultiple(1.6)
                        .padding()
                        .background(Color(hex: "F6F6F8"))
                        .cornerRadius(8)
                }
                .frame(height: 300)
                
                Section(header: Text("适用场景")) {
                    ForEach(template.适用场景, id: \.self) { scenario in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(scenario)
                        }
                    }
                }
                
                Section(header: Text("法律合规")) {
                    Text(template.legalCompliance)
                }
                
                Button(action: { dismiss() }) {
                    Text("返回")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "AF52DE"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("模板预览")
        }
    }
}
