//
//  SettingsView.swift
//  终活
//
//  设置页面 - 个人信息、紧急联系人、通知
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var userManager = UserManager.shared
    @State private var showingEditProfile = false
    @State private var showingEmergencyContact = false
    @State private var showingLocationAlert = false
    
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
                                Text(String(userManager.currentUser?.name.first ?? "用"))
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(Color(hex: "AF52DE"))
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userManager.currentUser?.name ?? "用户")
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
                
                // 定位权限
                Section(header: Text("安全")) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(Color(hex: "AF52DE"))
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("定位服务")
                                .font(.system(size: 16))
                            
                            Text(locationStatusText)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if userManager.locationAuthStatus != .authorizedAlways {
                            Button(action: {
                                userManager.requestLocationPermission()
                                showingLocationAlert = true
                            }) {
                                Text("开启")
                                    .foregroundColor(Color(hex: "AF52DE"))
                            }
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 8)
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
                            ForEach(CheckInInterval.allCases, id: \.self) { interval in
                                Text(interval.rawValue).tag(interval)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: dataManager.checkInInterval) { _ in
                            dataManager.saveSettings()
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // 数据同步
                Section(header: Text("数据")) {
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundColor(Color(hex: "007AFF"))
                            .frame(width: 30)
                        
                        Text("自动同步")
                            .font(.system(size: 16))
                        
                        Spacer()
                        
                        Text("实时同步中")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // 关于
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("终活 v2.0 ✅")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    
                    NavigationLink(destination: HelpPolicyView()) {
                        HStack {
                            Text("使用说明")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    NavigationLink(destination: HelpPolicyView()) {
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
                EditProfileModal(dataManager: dataManager, userManager: userManager)
            }
            .sheet(isPresented: $showingEmergencyContact) {
                EmergencyContactModal(dataManager: dataManager, userManager: userManager)
            }
            .alert("定位权限", isPresented: $showingLocationAlert) {
                Button("稍后", role: .cancel) {}
                Button("去设置") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("为了您的安全，建议开启\"始终允许\"定位权限，这样即使不打开 App 也能获取位置信息。")
            }
        }
    }
    
    private var locationStatusText: String {
        switch userManager.locationAuthStatus {
        case .authorizedAlways:
            return "后台定位已开启"
        case .authorizedWhenInUse:
            return "仅使用期间允许"
        case .denied:
            return "已拒绝"
        default:
            return "未设置"
        }
    }
}

// MARK: - 编辑个人信息弹窗
struct EditProfileModal: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var userManager: UserManager
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var showingIntervalPicker = false
    
    init(dataManager: DataManager, userManager: UserManager) {
        self.dataManager = dataManager
        self.userManager = userManager
        _name = State(initialValue: userManager.currentUser?.name ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("姓名")) {
                    TextField("您的姓名", text: $name)
                }
                
                Section(header: Text("签到间隔")) {
                    Button(action: { showingIntervalPicker = true }) {
                        HStack {
                            Text("签到提醒间隔")
                            Spacer()
                            Text(userManager.currentUser?.checkInInterval.rawValue ?? "2 天")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.secondary)
                        Text("当前位置")
                        Spacer()
                        if let location = userManager.getCurrentLocation() {
                            Text(location)
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        } else {
                            Text("获取中...")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                    }
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
                        if !name.isEmpty {
                            // 更新用户名
                            if var user = userManager.currentUser {
                                user.name = name
                                userManager.currentUser = user
                                userManager.saveUser(user)
                            }
                            dataManager.settings.name = name
                            dataManager.saveSettings()
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
            .confirmationDialog("选择签到间隔", isPresented: $showingIntervalPicker) {
                ForEach(CheckInInterval.allCases, id: \.self) { interval in
                    Button(interval.rawValue) {
                        let _ = userManager.updateCheckInInterval(interval)
                    }
                }
                Button("取消", role: .cancel) {}
            }
        }
    }
}

// MARK: - 紧急联系人弹窗
struct EmergencyContactModal: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var userManager: UserManager
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var phone: String
    @State private var relationship: String
    
    init(dataManager: DataManager, userManager: UserManager) {
        self.dataManager = dataManager
        self.userManager = userManager
        _name = State(initialValue: "")
        _phone = State(initialValue: "")
        _relationship = State(initialValue: "")
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
                            let _ = userManager.addEmergencyContact(
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
