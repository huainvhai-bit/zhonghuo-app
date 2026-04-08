//
//  InviteCodeView.swift
//  终活
//
//  邀请码页面 - 显示二维码和邀请码
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct InviteCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    @State private var qrURL = ""
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var copied = false
    @State private var showingBindFamily = false
    @State private var bindFamilyTrigger = false  // ✅ 修复 #3: 用于触发绑定页面
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F5F5F7").ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else if !inviteCode.isEmpty {
                    contentView
                } else {
                    errorView
                }
            }
            .navigationTitle("我的邀请码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: loadInviteCode) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                loadInviteCode()
            }
            .sheet(isPresented: $showingBindFamily) {
                BindFamilyView(onBound: {
                    loadInviteCode()
                    dismiss()
                })
            }
            .alert("错误", isPresented: .constant(!errorMessage.isEmpty)) {
                Button("确定") {
                    errorMessage = ""
                    dismiss()
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - 加载状态
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("正在生成邀请码...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 错误状态
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("生成失败")
                .font(.system(size: 18, weight: .medium))
            
            Text(errorMessage)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: loadInviteCode) {
                Text("重试")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.indigo)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    // MARK: - 内容视图（二维码 + 邀请码合并）
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 25) {
                // 顶部说明
                VStack(spacing: 8) {
                    Image(systemName: "person.2")
                        .font(.system(size: 40))
                        .foregroundColor(.indigo)
                    
                    Text("邀请家人")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("扫描二维码或分享邀请码")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // 二维码卡片
                VStack(spacing: 12) {
                    if !qrURL.isEmpty {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                            
                            if let qrImage = generateQRCode(from: qrURL) {
                                Image(uiImage: qrImage)
                                    .interpolation(.none)
                                    .resizable()
                                    .frame(width: 200, height: 200)
                            } else {
                                ProgressView()
                            }
                        }
                        .frame(width: 220, height: 220)
                    }
                    
                    Text("扫描二维码快速绑定")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
                
                // 邀请码卡片（放在二维码下面）
                VStack(spacing: 10) {
                    Text("邀请码")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Text(formatInviteCode(inviteCode))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.indigo)
                            .tracking(4)
                        
                        Button(action: copyCode) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 18))
                                .foregroundColor(copied ? .green : .indigo)
                                .padding(8)
                                .background(Color.indigo.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    if copied {
                        Text("✓ 已复制到剪贴板")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 30)
                
                // 分割线
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    Text("或")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, 40)
                
                // 立即绑定按钮
                Button(action: { 
                    print("🔵 点击立即绑定按钮")
                    showingBindFamily = true
                }) {
                    HStack {
                        Image(systemName: "link")
                        Text("立即绑定")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.indigo)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .padding(.horizontal, 30)
                
                // ✅ 修复 #3: 隐藏的全局导航链接，确保绑定页面能正确打开
                NavigationLink(destination: BindFamilyView(onBound: {
                    loadInviteCode()
                    dismiss()
                }), isActive: $showingBindFamily) {
                    EmptyView()
                }
                .opacity(0)
                
                // 使用说明
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.orange)
                        Text("如何邀请家人？")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        InstructionRow(number: 1, text: "分享邀请码或二维码给家人")
                        InstructionRow(number: 2, text: "家人在 App 中输入邀请码或扫码")
                        InstructionRow(number: 3, text: "双方自动成为家人关系")
                        InstructionRow(number: 4, text: "可以互相查看设备信息和位置")
                    }
                    .padding()
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - 方法
    
    private func loadInviteCode() {
        isLoading = true
        errorMessage = ""
        
        Task {
            await loadInviteCodeAsync()
        }
    }
    
    @MainActor
    private func loadInviteCodeAsync() async {
        let token = KeychainManager.shared.getToken() ?? ""
        guard !token.isEmpty else {
            errorMessage = "请先登录"
            isLoading = false
            return
        }
        
        guard !DataManager.apiURL.isEmpty else {
            errorMessage = "API 未初始化"
            isLoading = false
            return
        }
        
        do {
            // 使用 GraphQL getInviteCode mutation
            let query = """
            mutation {
                getInviteCode {
                    success
                    message
                    data { inviteCode qrUrl }
                }
            }
            """
            
            let result = try await GraphQLClient.shared.query(query)
            print("📡 GraphQL 邀请码响应：\(result)")
            
            if let data = result["data"] as? [String: Any],
               let inviteResult = data["getInviteCode"] as? [String: Any] {
                let success = inviteResult["success"] as? Bool ?? false
                if success {
                    if let resultData = inviteResult["data"] as? [String: Any] {
                        inviteCode = resultData["inviteCode"] as? String ?? ""
                        qrURL = resultData["qrUrl"] as? String ?? ""
                        print("✅ 邀请码加载成功：\(inviteCode)")
                    }
                } else {
                    errorMessage = inviteResult["message"] as? String ?? "生成失败"
                    print("❌ 邀请码生成失败：\(errorMessage)")
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ 邀请码加载异常：\(error)")
        }
        
        isLoading = false
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func formatInviteCode(_ code: String) -> String {
        // 格式化为 XXX-XXX
        if code.count == 6 {
            return "\(code.prefix(3))-\(code.suffix(3))"
        }
        return code
    }
    
    private func copyCode() {
        guard !inviteCode.isEmpty else {
            print("⚠️ 邀请码为空，无法复制")
            return
        }
        
        UIPasteboard.general.string = inviteCode
        print("✅ 邀请码已复制：\(inviteCode)")
        copied = true
        
        // 震动反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 2 秒后重置状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.copied = false
        }
    }
}

// MARK: - 说明行
struct InstructionRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.indigo)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
    }
}

#Preview {
    InviteCodeView()
}
