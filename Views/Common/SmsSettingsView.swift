//
//  SmsSettingsView.swift
//  终活
//
//  短信发送配置（简化版）
//

import SwiftUI

struct SmsSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("短信发送配置")) {
                Text("短信功能待实现")
                    .foregroundColor(.secondary)
                
                Text("支持以下短信服务商：")
                    .font(.headline)
                
                List {
                    HStack {
                        Text("Message Framework (iOS 原生)")
                        Spacer()
                        Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                    }
                    
                    HStack {
                        Text("阿里云短信")
                        Spacer()
                        Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                    }
                    
                    HStack {
                        Text("腾讯云短信")
                        Spacer()
                        Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("短信配置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SmsSettingsView()
}
