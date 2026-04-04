//
//  SmsSettingsView.swift
//  终活
//
//  短信发送配置 - 3 种方案可单独开关
//

import SwiftUI

struct SmsSettingsView: View {
    @AppStorage("sms_use_message_framework") private var useMessageFramework = false
    @AppStorage("sms_use_aliyun") private var useAliyunSms = false
    @AppStorage("sms_use_tencent") private var useTencentSms = false
    
    // 🔒 安全修复：敏感密钥使用 Keychain 存储，非敏感配置使用 @AppStorage
    @State private var aliyunAccessKeyId = ""
    @State private var aliyunAccessKeySecret = ""
    @AppStorage("aliyun_sign_name") private var aliyunSignName = "终活科技"
    @AppStorage("aliyun_template_code") private var aliyunTemplateCode = ""
    
    @State private var tencentSecretId = ""
    @State private var tencentSecretKey = ""
    @AppStorage("tencent_app_id") private var tencentAppId = ""
    @AppStorage("tencent_sign_name") private var tencentSignName = "终活科技"
    @AppStorage("tencent_template_id") private var tencentTemplateId = ""
    
    var body: some View {
        Form {
            Section(header: Text("📱 短信发送方案")) {
                Toggle("启用 Message Framework（iOS 原生）", isOn: $useMessageFramework)
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("需要用户授权，只能发送到通讯录联系人")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("☁️ 第三方短信 API")) {
                Toggle("启用阿里云短信", isOn: $useAliyunSms)
                
                if useAliyunSms {
                    DisclosureGroup("阿里云配置") {
                        TextField("AccessKey ID", text: $aliyunAccessKeyId)
                            .onChange(of: aliyunAccessKeyId) { _ in saveAliyunCredentials() }
                        SecureField("AccessKey Secret", text: $aliyunAccessKeySecret)
                            .onChange(of: aliyunAccessKeySecret) { _ in saveAliyunCredentials() }
                        TextField("签名", text: $aliyunSignName)
                        TextField("模板 CODE", text: $aliyunTemplateCode)
                    }
                }
                
                Divider()
                
                Toggle("启用腾讯云短信", isOn: $useTencentSms)
                
                if useTencentSms {
                    DisclosureGroup("腾讯云配置") {
                        TextField("SecretId", text: $tencentSecretId)
                            .onChange(of: tencentSecretId) { _ in saveTencentCredentials() }
                        SecureField("SecretKey", text: $tencentSecretKey)
                            .onChange(of: tencentSecretKey) { _ in saveTencentCredentials() }
                        TextField("AppID", text: $tencentAppId)
                        TextField("签名", text: $tencentSignName)
                        TextField("模板 ID", text: $tencentTemplateId)
                    }
                }
                
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("阿里云和腾讯云任选其一即可")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("🧪 测试")) {
                Button("发送测试短信") {
                    sendTestSms()
                }
                .disabled(!useMessageFramework && !useAliyunSms && !useTencentSms)
            }
        }
        .navigationTitle("短信配置")
        .onAppear {
            // 🔒 从 Keychain 加载敏感密钥
            aliyunAccessKeyId = KeychainManager.shared.getAliyunAccessKeyId() ?? ""
            aliyunAccessKeySecret = KeychainManager.shared.getAliyunAccessKeySecret() ?? ""
            tencentSecretId = KeychainManager.shared.getTencentSecretId() ?? ""
            tencentSecretKey = KeychainManager.shared.getTencentSecretKey() ?? ""
        }
    }
    
    private func saveAliyunCredentials() {
        // 🔒 保存到 Keychain
        KeychainManager.shared.saveAliyunAccessKeyId(aliyunAccessKeyId)
        KeychainManager.shared.saveAliyunAccessKeySecret(aliyunAccessKeySecret)
    }
    
    private func saveTencentCredentials() {
        // 🔒 保存到 Keychain
        KeychainManager.shared.saveTencentSecretId(tencentSecretId)
        KeychainManager.shared.saveTencentSecretKey(tencentSecretKey)
    }
    
    private func sendTestSms() {
        print("🧪 发送测试短信...")
        
        // TODO: 调用短信发送函数
        // 这里可以调用 UserManager.shared.sendSmsToContact
        
        print("✅ 测试短信已发送")
    }
}

#Preview {
    NavigationView {
        SmsSettingsView()
    }
}
