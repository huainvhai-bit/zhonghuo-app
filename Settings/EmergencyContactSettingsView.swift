//
//  Settings/EmergencyContactSettingsView.swift
//  终活
//
//  紧急联系人设置视图
//  职责：添加、编辑、删除紧急联系人
//

import SwiftUI

struct EmergencyContactSettingsView: View {
    @ObservedObject var userManager: UserManager = UserManager.shared
    @State private var showingAddContact = false
    @State private var showingEditContact: User.EmergencyContact?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("紧急联系人")) {
                    if userManager.currentUser?.emergencyContacts.isEmpty == true {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("暂无紧急联系人")
                                .foregroundColor(.secondary)
                            Button("添加联系人") {
                                showingAddContact = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else {
                        ForEach(userManager.currentUser?.emergencyContacts ?? []) { contact in
                            EmergencyContactRow(contact: contact)
                                .onTapGesture {
                                    showingEditContact = contact
                                }
                        }
                        .onDelete(perform: deleteContacts)
                    }
                }
                
                Section {
                    Button("添加联系人") {
                        showingAddContact = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            .navigationTitle("紧急联系人")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddContact) {
                AddEmergencyContactView()
            }
            .sheet(item: $showingEditContact) { contact in
                EditEmergencyContactView(contact: contact)
            }
        }
    }
    
    private func deleteContacts(at offsets: IndexSet) {
        guard var user = userManager.currentUser else { return }
        
        var contacts = user.emergencyContacts
        contacts.remove(atOffsets: offsets)
        
        user.emergencyContacts = contacts
        _ = userManager.saveUser(user)
    }
}

struct EmergencyContactRow: View {
    let contact: User.EmergencyContact
    
    var body: some View {
        HStack {
            Text(contact.name)
                .font(.body)
            Spacer()
            if contact.isConfirmed {
                Text("已确认")
                    .font(.subheadline)
                    .foregroundColor(.green)
            } else {
                Text("待确认")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
    }
}

struct AddEmergencyContactView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userManager: UserManager = UserManager.shared
    @State private var name = ""
    @State private var phone = ""
    @State private var relationship = ""
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("联系人信息")) {
                    TextField("姓名", text: $name)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                    
                    TextField("手机号", text: $phone)
                        .keyboardType(.phonePad)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    
                    TextField("关系", text: $relationship)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Button(action: saveContact) {
                        Text("保存")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "AF52DE"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(isSaving)
                    .opacity(isSaving ? 0.6 : 1)
                }
            }
            .navigationTitle("添加联系人")
            .navigationBarTitleDisplayMode(.inline)
            .alert("错误", isPresented: $showingError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveContact() {
        guard !name.isEmpty else {
            errorMessage = "请输入姓名"
            showingError = true
            return
        }
        
        guard !phone.isEmpty else {
            errorMessage = "请输入手机号"
            showingError = true
            return
        }
        
        guard isValidPhone(phone) else {
            errorMessage = "手机号格式错误"
            showingError = true
            return
        }
        
        isSaving = true
        
        Task {
            await MainActor.run {
                guard var user = userManager.currentUser else {
                    isSaving = false
                    return
                }
                
                let newContact = User.EmergencyContact(
                    name: name,
                    phone: phone,
                    relationship: relationship
                )
                
                user.emergencyContacts.append(newContact)
                _ = userManager.saveUser(user)
                
                isSaving = false
                dismiss()
            }
        }
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: phone)
    }
}

struct EditEmergencyContactView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userManager: UserManager = UserManager.shared
    let contact: User.EmergencyContact
    
    @State private var name: String
    @State private var phone: String
    @State private var relationship: String
    
    init(contact: User.EmergencyContact) {
        self.contact = contact
        _name = State(initialValue: contact.name)
        _phone = State(initialValue: contact.phone)
        _relationship = State(initialValue: contact.relationship)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("联系人信息")) {
                    TextField("姓名", text: $name)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                    
                    TextField("手机号", text: $phone)
                        .keyboardType(.phonePad)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    
                    TextField("关系", text: $relationship)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Button(action: saveContact) {
                        Text("保存")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "AF52DE"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        deleteContact()
                    } label: {
                        Text("删除联系人")
                    }
                }
            }
            .navigationTitle("编辑联系人")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func saveContact() {
        guard !name.isEmpty else { return }
        guard !phone.isEmpty else { return }
        
        Task {
            await MainActor.run {
                guard var user = userManager.currentUser else { return }
                
                if let index = user.emergencyContacts.firstIndex(where: { $0.id == contact.id }) {
                    user.emergencyContacts[index].name = name
                    user.emergencyContacts[index].phone = phone
                    user.emergencyContacts[index].relationship = relationship
                    _ = userManager.saveUser(user)
                }
                
                dismiss()
            }
        }
    }
    
    private func deleteContact() {
        Task {
            await MainActor.run {
                guard var user = userManager.currentUser else { return }
                
                if let index = user.emergencyContacts.firstIndex(where: { $0.id == contact.id }) {
                    user.emergencyContacts.remove(at: index)
                    _ = userManager.saveUser(user)
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    EmergencyContactSettingsView()
}
