//
//  HelpPolicyView.swift
//  终活
//
//  使用说明和隐私政策
//

import SwiftUI

struct HelpPolicyView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab 选择器
                Picker("", selection: $selectedTab) {
                    Text("使用说明").tag(0)
                    Text("隐私政策").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                TabView(selection: $selectedTab) {
                    userGuide
                        .tag(0)
                    
                    privacyPolicy
                        .tag(1)
                }
            }
            .navigationTitle("帮助与政策")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - 使用说明
    private var userGuide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 应用介绍
                sectionView(
                    title: "📱 关于终活",
                    content: """
                    终活（Zhonghuo）是一款生命末期规划应用，帮助您提前安排身后事务，让家人朋友更从容地面对离别。
                    
                    我们希望通过科技的力量，让生命更有尊严，让告别更有温度。
                    """
                )
                
                // 主要功能
                sectionView(
                    title: "✨ 主要功能",
                    content: """
                    1. 时光胶囊
                       - 给未来的自己或亲友留言
                       - 支持文字、语音、视频多种形式
                       - 可设置在未来特定时间自动发送
                    
                    2. 遗嘱与资产
                       - 提供专业遗嘱模板
                       - 记录各类资产信息（银行、保险、房产等）
                       - 支持 PDF 导出和打印
                    
                    3. 见证人管理
                       - 添加信任的见证人
                       - 见证人可确认知晓您的安排
                       - 保障遗嘱的法律效力
                    
                    4. 紧急联系人
                       - 设置 2 位以上紧急联系人
                       - 在需要时自动通知
                    
                    5. 每日签到
                       - 记录您的生活状态
                       - 长期未签到将自动通知紧急联系人
                    """
                )
                
                // 使用流程
                sectionView(
                    title: "📝 使用流程",
                    content: """
                    第 1 步：完成注册，设置个人信息
                    
                    第 2 步：添加至少 2 位紧急联系人
                    
                    第 3 步：填写遗嘱和资产信息
                    
                    第 4 步：邀请见证人确认
                    
                    第 5 步：定期签到，保持更新
                    """
                )
                
                // 法律提示
                sectionView(
                    title: "⚖️ 法律提示",
                    content: """
                    1. 本应用生成的遗嘱仅供参考，不替代专业法律意见
                    
                    2. 根据《中华人民共和国民法典》，自书遗嘱需满足以下条件才具有法律效力：
                       - 立遗嘱人亲笔书写
                       - 立遗嘱人亲笔签名
                       - 注明年、月、日
                    
                    3. 建议：
                       - 有 2 名以上无利害关系的见证人在场
                       - 前往公证处办理公证
                       - 咨询专业律师
                    
                    4. 本应用不存储您的密码和完整账号信息，仅记录资产概况
                    """
                )
                
                // 联系我们
                sectionView(
                    title: "📧 联系我们",
                    content: """
                    如有任何问题或建议，欢迎联系我们：
                    
                    邮箱：support@zhonghuo.app
                    微信：终活小助手
                    
                    我们承诺在 24 小时内回复您的反馈。
                    """
                )
            }
            .padding()
        }
        .background(Color(hex: "F6F6F8"))
    }
    
    // MARK: - 隐私政策
    private var privacyPolicy: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 引言
                sectionView(
                    title: "🔒 隐私政策",
                    content: """
                    最后更新：2026 年 3 月 15 日
                    
                    终活（以下简称"我们"）非常重视您的隐私保护。本隐私政策说明我们如何收集、使用、存储和保护您的个人信息。
                    
                    请您在使用本应用前，仔细阅读并了解本隐私政策。
                    """
                )
                
                // 信息收集
                sectionView(
                    title: "一、信息收集",
                    content: """
                    我们收集的信息包括：
                    
                    1. 您主动提供的信息：
                       - 注册信息（姓名、手机号）
                       - 紧急联系人信息
                       - 遗嘱和资产信息
                       - 时光胶囊内容
                    
                    2. 自动收集的信息：
                       - 设备信息（型号、操作系统）
                       - 使用日志
                       - 签到记录
                    """
                )
                
                // 信息使用
                sectionView(
                    title: "二、信息使用",
                    content: """
                    我们使用收集的信息用于：
                    
                    1. 提供和维护服务
                    2. 改进和优化应用
                    3. 在您授权的情况下通知紧急联系人
                    4. 遵守法律法规要求
                    
                    我们不会将您的信息用于任何其他目的，也不会出售或出租给第三方。
                    """
                )
                
                // 信息存储
                sectionView(
                    title: "三、信息存储",
                    content: """
                    1. 存储地点：所有数据存储在您的设备本地
                    
                    2. 存储期限：在您删除应用或主动清除数据前，我们将一直保存您的信息
                    
                    3. 云同步：未来版本将提供加密云同步功能（可选）
                    
                    4. 安全措施：
                       - 本地数据加密存储
                       - 不上传敏感信息到服务器
                       - 定期安全审计
                    """
                )
                
                // 信息共享
                sectionView(
                    title: "四、信息共享",
                    content: """
                    我们仅在以下情况下共享您的信息：
                    
                    1. 经您明确同意
                    2. 根据法律法规要求
                    3. 为维护社会公共利益
                    4. 为保护您或他人的合法权益
                    
                    除上述情况外，我们不会与任何第三方共享您的个人信息。
                    """
                )
                
                // 用户权利
                sectionView(
                    title: "五、您的权利",
                    content: """
                    您对自己的信息享有以下权利：
                    
                    1. 访问权：随时查看您的信息
                    2. 更正权：修改不准确的信息
                    3. 删除权：删除您的账户和数据
                    4. 撤回同意：撤回已授予的权限
                    
                    如需行使上述权利，请联系我们的客服。
                    """
                )
                
                // 政策更新
                sectionView(
                    title: "六、政策更新",
                    content: """
                    我们可能会不时更新本隐私政策。更新后的政策将在应用内公布，并通过通知告知您。
                    
                    如您继续使用本应用，即表示您同意更新后的政策。
                    """
                )
                
                // 联系我们
                sectionView(
                    title: "七、联系我们",
                    content: """
                    如对本隐私政策有任何疑问、意见或建议，请通过以下方式联系我们：
                    
                    邮箱：privacy@zhonghuo.app
                    
                    我们将在 15 个工作日内回复您的询问。
                    """
                )
            }
            .padding()
        }
        .background(Color(hex: "F6F6F8"))
    }
    
    // MARK: - 通用 Section
    private func sectionView(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "AF52DE"))
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
    }
}

#Preview {
    HelpPolicyView()
}
