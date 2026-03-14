//
//  SettingsView.swift
//  终活
//
//  设置页面 - 个人信息、紧急联系人、通知
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var showingEditProfile = false
    @State private var showingEmergencyContact = false
    
    var body: some View {
        NavigationView {
            List {
                // 个人信息
                Section(header: Text("个人信息")) {
                    HStack {
                        Circle()
                            .fill(Color(hex: "AF52DE").opacity(0.12))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text("用")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(Color(hex: "AF52DE"))
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dataManager.settings.name)
                                .font(.system(size: 17, weight: .semibold))
                            
                            Text("点击编辑个人信息")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingEditProfile = true
                    }
                }
                
                // 紧急联系人
                Section(header: Text("安全")) {
                    Button(action: { showingEmergencyContact = true }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .foregroundColor(Color(hex: "FF3B30"))
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("紧急联系人")
                                    .font(.system(size: 16))
                                
                                if let contact = dataManager.settings.emergencyContact {
                                    Text("\(contact.name) · \(contact.phone)")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("未设置")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(Color(hex: "007AFF"))
                            .frame(width: 30)
                        
                        Text("签到提醒")
                            .font(.system(size: 16))
                        
                        Spacer()
                        
                        Toggle("", isOn: .init(
                            get: { dataManager.settings.notificationsEnabled },
                            set: {
                                dataManager.settings.notificationsEnabled = $0
                                dataManager.saveSettings()
                            }
                        ))
                    }
                    .padding(.vertical, 8)
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(Color(hex: "AF52DE"))
                            .frame(width: 30)
                        
                        Text("签到间隔")
                            .font(.system(size: 16))
                        
                        Spacer()
                        
                        Picker("", selection: $dataManager.checkInInterval) {
                            Text("24 小时").tag(24)
                            Text("48 小时").tag(48)
                            Text("72 小时").tag(72)
                        }
                        .pickerStyle(.menu)
                        .onChange(of: dataManager.checkInInterval) { newValue in
                            dataManager.checkInInterval = newValue
                            dataManager.saveSettings()
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // 数据管理
                Section(header: Text("数据")) {
                    Button(action: {
                        // TODO: 导出数据
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Color(hex: "34C759"))
                                .frame(width: 30)
                            
                            Text("导出数据")
                                .font(.system(size: 16))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Button(action: {
                        // TODO: 导入数据
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(Color(hex: "007AFF"))
                                .frame(width: 30)
                            
                            Text("导入数据")
                                .font(.system(size: 16))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // 关于
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.4.0")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    
                    Button(action: {
                        // TODO: 显示使用说明
                    }) {
                        HStack {
                            Text("使用说明")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Button(action: {
                        // TODO: 隐私政策
                    }) {
                        HStack {
                            Text("隐私政策")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileModal(dataManager: dataManager)
            }
            .sheet(isPresented: $showingEmergencyContact) {
                EmergencyContactModal(dataManager: dataManager)
            }
        }
    }
}

// MARK: - 编辑个人信息弹窗
struct EditProfileModal: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        _name = State(initialValue: dataManager.settings.name)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("姓名")) {
                    TextField("您的姓名", text: $name)
                }
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        dataManager.settings.name = name
                        dataManager.saveSettings()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - 紧急联系人弹窗
struct EmergencyContactModal: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var phone: String
    @State private var relationship: String
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        _name = State(initialValue: dataManager.settings.emergencyContact?.name ?? "")
        _phone = State(initialValue: dataManager.settings.emergencyContact?.phone ?? "")
        _relationship = State(initialValue: dataManager.settings.emergencyContact?.relationship ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("联系人信息")) {
                    TextField("姓名", text: $name)
                    
                    TextField("电话", text: $phone)
                        .keyboardType(.phonePad)
                    
                    TextField("关系（如：配偶、子女、父母）", text: $relationship)
                }
                
                Section(footer: Text("紧急联系人会在您未按时签到时收到通知")) {
                    Button(action: {
                        if !name.isEmpty && !phone.isEmpty {
                            dataManager.settings.emergencyContact = UserSettings.EmergencyContact(
                                name: name,
                                phone: phone,
                                relationship: relationship
                            )
                            dataManager.saveSettings()
                            dismiss()
                        }
                    }) {
                        Text("保存")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(name.isEmpty || phone.isEmpty)
                }
            }
            .navigationTitle("紧急联系人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
