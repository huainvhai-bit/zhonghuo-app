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
    @State private var showingQRCode = false
    @State private var copied = false
    
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                loadInviteCode()
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
    
    // MARK: - 内容视图
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 二维码
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
                    
                    Text("扫描二维码绑定家人")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                Divider()
                    .padding(.horizontal, 40)
                
                // 邀请码
                VStack(spacing: 12) {
                    Text("邀请码")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Text(formatInviteCode(inviteCode))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.indigo)
                            .tracking(4)
                        
                        Button(action: copyCode) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 20))
                                .foregroundColor(copied ? .green : .indigo)
                                .padding(10)
                                .background(Color.indigo.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    if copied {
                        Text("已复制")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }
                
                // 使用说明
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.indigo)
                        Text("使用说明")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InstructionRow(number: 1, text: "将邀请码或二维码分享给家人")
                        InstructionRow(number: 2, text: "家人在 App 中输入邀请码或扫码")
                        InstructionRow(number: 3, text: "等待家人接受邀请")
                        InstructionRow(number: 4, text: "绑定成功后即可查看设备信息")
                    }
                    .padding()
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                
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
        let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
        guard !token.isEmpty else {
            errorMessage = "请先登录"
            isLoading = false
            return
        }
        
        do {
            let url = URL(string: "\(DataManager.apiURL)/api/family.php?action=get_invite_code")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let result = try JSONDecoder().decode(InviteCodeResponse.self, from: data)
            
            if result.status == "success" {
                inviteCode = result.data?.invite_code ?? ""
                qrURL = result.data?.qr_url ?? ""
            } else {
                errorMessage = result.message ?? "生成失败"
            }
        } catch {
            errorMessage = error.localizedDescription
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
        UIPasteboard.general.string = inviteCode
        copied = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
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
