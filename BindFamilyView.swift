//
//  BindFamilyView.swift
//  终活
//
//  绑定家人页面 - 输入邀请码或扫码
//

import SwiftUI
import Foundation

struct BindFamilyView: View {
    @Environment(\.dismiss) private var dismiss
    let onBound: (() -> Void)?
    
    @State private var inviteCode = ""
    @State private var isBinding = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var showingScanner = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F5F5F7").ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // 说明
                    VStack(spacing: 12) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.indigo)
                        
                        Text("绑定家人")
                            .font(.system(size: 22, weight: .bold))
                        
                        Text("输入邀请码或扫描二维码")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // 输入框
                    VStack(spacing: 12) {
                        Text("邀请码")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            TextField("6 位邀请码", text: $inviteCode)
                                .font(.system(size: 24, weight: .medium, design: .monospaced))
                                .textContentType(.oneTimeCode)
                                .keyboardType(.asciiCapable)
                                .autocapitalization(.allCharacters)
                                .onChange(of: inviteCode) { newValue in
                                    // 限制 6 位，转大写
                                    if newValue.count > 6 {
                                        inviteCode = String(newValue.prefix(6))
                                    }
                                    inviteCode = newValue.uppercased()
                                }
                            
                            // 扫码按钮
                            Button(action: { showingScanner = true }) {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 20))
                                    .foregroundColor(.indigo)
                                    .padding(10)
                                    .background(Color.indigo.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    }
                    .padding(.horizontal, 30)
                    
                    // 绑定按钮
                    Button(action: bindFamily) {
                        HStack {
                            if isBinding {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            }
                            
                            Text(isBinding ? "绑定中..." : "立即绑定")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(inviteCode.count == 6 && !isBinding ? Color.indigo : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(inviteCode.count != 6 || isBinding)
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // 底部说明
                    VStack(spacing: 8) {
                        Divider()
                        
                        Text("温馨提示")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("绑定后双方将成为家人关系，可以互相查看设备信息和位置")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("绑定家人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定") {}
            } message: {
                Text(errorMessage)
            }
            .alert("绑定成功", isPresented: $showingSuccess) {
                Button("完成") {
                    dismiss()
                    onBound?()
                }
            } message: {
                Text("绑定成功，等待对方接受邀请")
            }
            .sheet(isPresented: $showingScanner) {
                QRCodeScannerView(
                    onCodeScanned: { code in
                        showingScanner = false
                        let cleaned = self.extractInviteCode(from: code)
                        if !cleaned.isEmpty {
                            self.inviteCode = cleaned
                            
                            // 震动反馈
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            // 自动绑定
                            self.bindFamily()
                        } else {
                            self.errorMessage = "无效的二维码"
                            self.showingError = true
                        }
                    },
                    onCancel: {
                        showingScanner = false
                    }
                )
            }
        }
    }
    
    // MARK: - 方法
    
    private func bindFamily() {
        guard inviteCode.count == 6 else { return }
        
        isBinding = true
        errorMessage = ""
        
        Task {
            await bindFamilyAsync()
        }
    }
    
    @MainActor
    private func bindFamilyAsync() async {
        let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
        guard !token.isEmpty else {
            errorMessage = "请先登录"
            showingError = true
            isBinding = false
            return
        }
        
        guard !DataManager.apiURL.isEmpty else {
            errorMessage = "API 未初始化"
            showingError = true
            isBinding = false
            return
        }
        
        do {
            let url = URL(string: "\(DataManager.apiURL)/api/family.php?action=bind_family")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let body: [String: String] = ["invite_code": inviteCode]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    let result = try JSONDecoder().decode(FamilyListResponse.self, from: data)
                    
                    if result.status == "success" {
                        // 绑定成功后，自动添加到紧急联系人
                        await addEmergencyContactIfNeeded()
                        showingSuccess = true
                        return
                    } else {
                        errorMessage = result.message ?? "绑定失败"
                    }
                } else {
                    errorMessage = "网络错误：\(httpResponse.statusCode)"
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        showingError = true
        isBinding = false
    }
    
    private func extractInviteCode(from string: String) -> String {
        // 尝试从 URL 中提取 code 参数
        if let url = URL(string: string),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
            return code.uppercased().replacingOccurrences(of: "-", with: "")
        }
        
        // 直接是 6 位邀请码
        let cleaned = string.uppercased().replacingOccurrences(of: "-", with: "")
        if cleaned.count == 6 {
            return cleaned
        }
        
        return ""
    }
    
    @MainActor
    private func addEmergencyContactIfNeeded() async {
        // 绑定成功后，获取家人信息并添加到紧急联系人
        guard !DataManager.apiURL.isEmpty else {
            return
        }
        
        let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
        guard !token.isEmpty else {
            return
        }
        
        do {
            // 获取家人列表
            let url = URL(string: "\(DataManager.apiURL)/api/family.php?action=list_family")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let result = try JSONDecoder().decode(FamilyListResponse.self, from: data)
            
            if result.status == "success", let familyList = result.data?.list, !familyList.isEmpty {
                // 获取最后一个绑定的家人
                let lastMember = familyList.last!
                
                // 添加到紧急联系人
                let emergencyURL = URL(string: "\(DataManager.apiURL)/api/emergency_contacts.php?action=add")!
                var emergencyRequest = URLRequest(url: emergencyURL)
                emergencyRequest.httpMethod = "POST"
                emergencyRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                emergencyRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "name": lastMember.name,
                    "phone": lastMember.phone,
                    "relationship": lastMember.relationship.isEmpty ? "家人" : lastMember.relationship
                ]
                emergencyRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (emergencyData, _) = try await URLSession.shared.data(for: emergencyRequest)
                let emergencyResult = try JSONDecoder().decode(EmergencyContactAddResponse.self, from: emergencyData)
                
                if emergencyResult.status == "success" {
                    print("✅ 紧急联系人自动添加成功：\(lastMember.name)")
                }
            }
        } catch {
            print("❌ 紧急联系人自动添加失败：\(error)")
        }
    }
}

#Preview {
    BindFamilyView(onBound: nil)
}
