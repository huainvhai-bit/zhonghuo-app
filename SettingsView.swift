//
//  SettingsView.swift
//  终活 - 设置
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        NavigationView {
            List {
                // 个人信息
                Section(header: Text("个人信息")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.primaryPurple)
                        
                        VStack(alignment: .leading) {
                            Text("未登录")
                                .font(.headline)
                            Text("点击登录")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // 紧急联系人
                Section(header: Text("紧急联系人")) {
                    ForEach(dataManager.emergencyContacts) { contact in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(contact.name)
                                    .font(.subheadline)
                                Text(contact.relationship)
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer()
                            Text(contact.phone)
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Button(action: {
                        // 添加联系人
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.primaryPurple)
                            Text("添加紧急联系人")
                                .foregroundColor(.primaryPurple)
                        }
                    }
                }
                
                // 设置
                Section(header: Text("设置")) {
                    NavigationLink(destination: Text("通知设置")) {
                        Label("通知设置", systemImage: "bell.fill")
                    }
                    
                    NavigationLink(destination: Text("隐私设置")) {
                        Label("隐私设置", systemImage: "lock.fill")
                    }
                    
                    NavigationLink(destination: Text("关于")) {
                        Label("关于", systemImage: "info.circle.fill")
                    }
                }
            }
            .navigationTitle("我的")
        }
    }
}

#Preview {
    SettingsView()
}
