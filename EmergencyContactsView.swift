//
//  EmergencyContactsView.swift
//  终活
//
//  紧急联系人和见证人管理页面
//

import SwiftUI

struct EmergencyContactsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var userManager = UserManager.shared
    @State private var showingAddEmergencyContact = false
    @State private var showingAddWitness = false
    @State private var selectedWitness: Witness?
    @State private var showingEditWitness = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 紧急联系人列表
                emergencyContactList
                
                // 见证人进度卡片
                witnessProgressCard
                
                // 见证人列表
                if !dataManager.witnesses.isEmpty {
                    witnessList
                } else {
                    emptyWitnessState
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color(hex: "F6F6F8"))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddEmergencyContact) {
            AddEmergencyContactModal()
        }
        .sheet(isPresented: $showingAddWitness) {
            AddWitnessModal()
        }
        .sheet(item: $selectedWitness) { witness in
            EditWitnessModal(witness: witness)
        }
    }
    
    // MARK: - 紧急联系人列表
    @State private var selectedContact: User.EmergencyContact?
    @State private var showingEditContact = false
    
    private var emergencyContactList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark.fill")
                        .font(.system(size: 18))
                    Text("紧急联系人")
                        .font(.headline)
                }
                .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showingAddEmergencyContact = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "DC2626"))
                }
            }
            
            if let contacts = userManager.currentUser?.emergencyContacts, !contacts.isEmpty {
                ForEach(contacts, id: \.id) { contact in
                    EmergencyContactCard(
                        contact: contact,
                        onEdit: {
                            selectedContact = contact
                            showingEditContact = true
                        },
                        onDelete: {
                            deleteEmergencyContact(contact)
                        }
                    )
                }
            } else {
                emptyContactState
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .sheet(item: $selectedContact) { contact in
            EditEmergencyContactModal(contact: contact, isPresented: $showingEditContact)
        }
    }
    
    private var emptyContactState: some View {
        Button(action: { showingAddEmergencyContact = true }) {
            VStack(spacing: 8) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 30))
                    .foregroundColor(.secondary)
                Text("添加紧急联系人")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    private func deleteEmergencyContact(_ contact: User.EmergencyContact) {
        userManager.currentUser?.emergencyContacts.removeAll { $0.id == contact.id }
        userManager.saveUser(userManager.currentUser!)
    }
    
    // MARK: - 见证人进度卡片
    private var witnessProgressCard: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16))
                    Text("见证人进度")
                        .font(.headline)
                }
                .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(dataManager.getWitnessProgressString())")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "AF52DE"))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "E5E5EA"))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "AF52DE").opacity(0.7), Color(hex: "AF52DE")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * dataManager.getWitnessProgress(), height: 8)
                        .shadow(color: Color(hex: "AF52DE").opacity(0.3), radius: 3, x: 0, y: 2)
                }
            }
            .frame(height: 8)
            
            HStack {
                Label("\(dataManager.witnesses.filter { $0.isConfirmed }.count) 已确认", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
                
                Spacer()
                
                Label("\(dataManager.witnesses.count) 已邀请", systemImage: "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 见证人列表
    private var witnessList: some View {
        VStack(spacing: 12) {
            HStack {
                Text("见证人列表")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button(action: { showingAddWitness = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "AF52DE"))
                }
            }
            .padding(.horizontal, 4)
            
            ForEach(dataManager.witnesses, id: \.id) { witness in
                WitnessCard(witness: witness, onEdit: {
                    selectedWitness = witness
                    showingEditWitness = true
                }, onDelete: {
                    // 删除逻辑
                })
            }
        }
    }
    
    // MARK: - 空状态
    private var emptyWitnessState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("还没有见证人")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("邀请 2 位见证人，让您的嘱托更有保障")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            Button(action: { showingAddWitness = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("添加见证人")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "AF52DE"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "AF52DE").opacity(0.1))
                .cornerRadius(20)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 添加紧急联系人弹窗
// MARK: - 紧急联系人卡片
struct EmergencyContactCard: View {
    let contact: User.EmergencyContact
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Label(contact.relationship, systemImage: "person.crop.rectangle")
                            .font(.system(size: 12))
                        
                        Spacer()
                        
                        Label(contact.phone, systemImage: "phone.fill")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 操作按钮
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "AF52DE"))
                    }
                    
                    Button(action: { showingDeleteConfirm = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "FF3B30"))
                    }
                }
            }
        }
        .padding(12)
        .background(Color(hex: "F6F6F8"))
        .cornerRadius(8)
        .confirmationDialog("删除确认", isPresented: $showingDeleteConfirm) {
            Button("删除", role: .destructive, action: onDelete)
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除紧急联系人 \"\(contact.name)\" 吗？")
        }
    }
}

// MARK: - 编辑紧急联系人弹窗
struct EditEmergencyContactModal: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userManager = UserManager.shared
    let contact: User.EmergencyContact
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var phone = ""
    @State private var relationship = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("联系人信息")) {
                    TextField("姓名", text: $name)
                    TextField("电话", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("与用户关系", text: $relationship)
                }
                
                Section(footer: Text("紧急联系人将在需要时接收您的位置信息和安全状态")) {
                    Text("提示")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("编辑紧急联系人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        updateContact()
                    }
                    .disabled(name.isEmpty || phone.isEmpty)
                }
            }
        }
        .onAppear {
            name = contact.name
            phone = contact.phone
            relationship = contact.relationship
        }
    }
    
    private func updateContact() {
        if var user = userManager.currentUser {
            if let index = user.emergencyContacts.firstIndex(where: { $0.id == contact.id }) {
                user.emergencyContacts[index].name = name
                user.emergencyContacts[index].phone = phone
                user.emergencyContacts[index].relationship = relationship
                userManager.currentUser = user
                _ = userManager.saveUser(user)
            }
        }
        dismiss()
    }
}

struct AddEmergencyContactModal: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userManager = UserManager.shared
    @State private var name = ""
    @State private var phone = ""
    @State private var relationship = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("联系人信息")) {
                    TextField("姓名", text: $name)
                    TextField("电话", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("与用户关系", text: $relationship)
                }
                
                Section(footer: Text("紧急联系人将在需要时接收您的位置信息和安全状态")) {
                    Text("提示")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("添加紧急联系人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let contact = User.EmergencyContact(
                            name: name,
                            phone: phone,
                            relationship: relationship
                        )
                        // 添加到用户数据
                        if var user = userManager.currentUser {
                            user.emergencyContacts.append(contact)
                            userManager.currentUser = user
                            _ = userManager.saveUser(user)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty || phone.isEmpty)
                }
            }
        }
    }
}
