//
//  Settings/PrivacySettingsView.swift
//  终活
//
//  隐私设置视图
//  职责：隐私政策、服务条款展示
//

import SwiftUI

struct PrivacySettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("隐私政策")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text("生效日期：2026年1月1日")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Section {
                    Text("**1. 信息收集**")
                        .font(.headline)
                    Text("我们收集以下信息：")
                        .font(.body)
                    Text("• 手机号：用于用户身份验证")
                    Text("• 位置信息：用于签到打卡")
                    Text("• 个人资料：用于完善用户信息")
                }
                
                Section {
                    Text("**2. 信息使用**")
                        .font(.headline)
                    Text("我们承诺：")
                        .font(.body)
                    Text("• 严格保密用户信息")
                    Text("• 不向第三方共享用户数据")
                    Text("• 仅在法律要求时披露信息")
                }
                
                Section {
                    Text("**3. 数据安全**")
                        .font(.headline)
                    Text("我们采取以下措施保护您的数据：")
                        .font(.body)
                    Text("• 加密存储敏感信息")
                    Text("• 定期安全审计")
                    Text("• 紧急响应机制")
                }
                
                Section {
                    Text("**4. 用户权利**")
                        .font(.headline)
                    Text("您有权：")
                        .font(.body)
                    Text("• 查询您的个人信息")
                    Text("• 修正错误信息")
                    Text("• 删除账号")
                }
                
                Spacer()
                Text("© 2026 终活 App. All rights reserved.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
            }
            .padding()
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("服务条款")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text("生效日期：2026年1月1日")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Section {
                    Text("**1. 使用规则**")
                        .font(.headline)
                    Text("用户承诺：")
                        .font(.body)
                    Text("• 使用真实信息注册")
                    Text("• 不滥用系统功能")
                    Text("• 不传播违法内容")
                }
                
                Section {
                    Text("**2. 服务说明**")
                        .font(.headline)
                    Text("终活 App 提供：")
                        .font(.body)
                    Text("• 时间胶囊服务")
                    Text("• 遗嘱管理服务")
                    Text("• 紧急联系人管理")
                }
                
                Section {
                    Text("**3. 免责声明**")
                        .font(.headline)
                    Text("以下情况终活 App 不承担责任：")
                        .font(.body)
                    Text("• 不可抗力导致的服务中断")
                    Text("• 用户操作失误造成的损失")
                    Text("• 第三方服务问题")
                }
                
                Spacer()
                Text("© 2026 终活 App. All rights reserved.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
            }
            .padding()
        }
        .navigationTitle("服务条款")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PrivacySettingsView()
}
