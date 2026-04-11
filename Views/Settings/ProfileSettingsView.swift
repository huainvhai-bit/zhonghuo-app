//
//  Settings/ProfileSettingsView.swift
//  �终活
//
//  个人资料设置视图
//  职责：修改姓名、手机号等个人信息
//

import SwiftUI

struct ProfileSettingsView: View {
    @ObservedObject var userManager: UserManager = UserManager.shared
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("个人信息")) {
                    TextField("姓名", text: $name)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                    
                    TextField("手机号", text: $phone)
                        .keyboardType(.phonePad)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Button(action: saveProfile) {
                        Text("保存修改")
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
            .navigationTitle("个人资料")
            .navigationBarTitleDisplayMode(.inline)
            .alert("错误", isPresented: $showingError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadProfile()
            }
        }
    }
    
    private func loadProfile() {
        guard let user = userManager.currentUser else { return }
        name = user.name
        phone = user.phone
    }
    
    private func saveProfile() {
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
        
        Task { @MainActor in
            try? await Task.checkCancellation()
            await MainActor.run {
                guard var user = userManager.currentUser else {
                    isSaving = false
                    return
                }
                
                user.name = name
                user.phone = phone
                
                _ = userManager.saveUser(user)
                
                isSaving = false
            }
        }
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: phone)
    }
}

#Preview {
    ProfileSettingsView()
}
