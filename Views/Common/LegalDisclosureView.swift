//
//  LegalDisclosureView.swift
//  终活
//
//  电子遗嘱效力说明（V2.0.0 法律合规）
//  功能：《民法典》第1134-1144条说明
//

import SwiftUI

struct LegalDisclosureView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 24) {
                    // 标题
                    Text("电子遗嘱效力说明")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                    
                    // 法律依据
                    legalSection(
                        title: "法律依据",
                        content: """
                        根据《中华人民共和国民法典》：
                        
                        • 第1134条：遗嘱形式包括公证遗嘱、自书遗嘱、代书遗嘱、录音遗嘱、口头遗嘱
                        • 第1137条：以录音录像形式立的遗嘱，应当有两个以上见证人在场见证
                        • 第1133条：自然人可以立遗嘱将个人财产指定由法定继承人中的一人或者数人继承
                        • 第1144条：遗嘱人可以指定遗嘱执行人
                        """
                    )
                    
                    // 电子遗嘱有效性
                    legalSection(
                        title: "电子遗嘱有效性",
                        content: """
                        ✅ 本应用立遗嘱方式符合《民法典》第1136条：
                        • 内容真实：用户自愿输入，内容真实反映意愿
                        • 形式合规：遗嘱内容完整，包括财产清单、继承人信息
                        • 时间戳：系统记录遗嘱创建/修改时间
                        • 用户认证：登录用户方可操作，身份可追溯
                        
                        ⚠️ 重要提示：
                        • 本应用遗嘱为参考模板，建议结合公证遗嘱使用
                        • 涉及房产、大额资产继承，建议前往公证处办理公证遗嘱
                        • 遗嘱执行过程中，建议聘请专业律师提供法律咨询
                        """
                    )
                    
                    // 电子签名法
                    legalSection(
                        title: "电子签名法",
                        content: """
                        根据《中华人民共和国电子签名法》：
                        
                        • 第14条：可靠的电子签名与手写签名或者盖章具有同等的法律效力
                        • 第13条：电子签名同时符合下列条件的，视为可靠的电子签名：
                          1. 电子签名用于签署的文件为签名人本人
                          2. 签名时电子签名制作数据仅由签名人控制
                          3. 签名后对电子签名的任何改动能够被发现
                          4. 签名后对数据电文内容和形式的任何改动能够被发现
                        
                        本应用使用：
                        • 用户账号认证（身份唯一性）
                        • 时间戳服务（防篡改）
                        • 操作日志记录（可追溯）
                        """
                    )
                    
                    // 见证人资质
                    legalSection(
                        title: "见证人资质要求",
                        content: """
                        根据《民法典》第1140条，下列人员不能作为遗嘱见证人：
                        
                        ❌ 无行为能力人、限制行为能力人
                        ❌ 继承人、受遗赠人
                        ❌ 与继承人、受遗赠人有利害关系的人
                        
                        ✅ 本应用见证人审核流程：
                        1. 见证人需实名认证（身份证号 + 手机号）
                        2. 见证人需确认无利益冲突
                        3. 见证人需在场见证并电子签名
                        4. 见证记录永久存证（区块链存证，规划中）
                        """
                    )
                    
                    // 适用场景
                    legalSection(
                        title: "适用场景",
                        content: """
                        ✅ 推荐使用：
                        • 小额财产继承
                        • 动产（存款、车辆、贵重物品）
                        • 数字资产（虚拟货币、游戏账号）
                        • 遗产分配意向表达
                        
                        ⚠️ 建议公证：
                        • 不动产（房产、土地）
                        • 大额资产（公司股权、信托产品）
                        • 复杂继承（多子女、再婚家庭）
                        • 涉外继承（外国人、境外资产）
                        """
                    )
                    
                    // 法律声明
                    legalSection(
                        title: "法律声明",
                        content: """
                        本应用提供的遗嘱模板仅供参考，不构成法律意见。
                        
                        使用本应用立遗嘱，视为您已阅读并接受以下条款：
                        1. 遗嘱内容由您本人真实意愿表达
                        2. 您已完全理解遗嘱法律效力
                        3. 您已知悉电子遗嘱的局限性
                        4. 如有疑问，建议咨询专业律师
                        
                        本应用不对遗嘱的法律效力承担保证责任。
                        """
                    )
                    
                    Spacer()
                    
                    // 返回按钮
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("我已阅读并理解")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "6366F1"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.hex("F5F5F7"))
            .navigationTitle("电子遗嘱效力")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - 法律章节组件
    func legalSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.hex("1F2937"))
                .padding(.top, 16)
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(Color.hex("374151"))
                .lineHeightMultiple(1.6)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 预览
struct LegalDisclosureView_Previews: PreviewProvider {
    static var previews: some View {
        LegalDisclosureView()
    }
}
