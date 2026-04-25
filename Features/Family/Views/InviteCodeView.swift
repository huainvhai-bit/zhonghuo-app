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
                Color(.systemBackground).ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else if !inviteCode.isEmpty {
                    contentView
                } else {
                    errorView
                }
            }
            .navigationTitle(L10n.text("我的邀请码", en: "My invite code", ja: "招待コード", ko: "내 초대 코드"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: loadInviteCode) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.string(.done)) { dismiss() }
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
            .alert(L10n.string(.error), isPresented: .constant(!errorMessage.isEmpty)) {
                Button(L10n.string(.confirm)) {
                    errorMessage = ""
                    dismiss()
                }
            } message: {
                Text(errorMessage)
            }
        }
        .stackNavigationStyle()
    }
    
    // MARK: - 加载状态
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(L10n.string(.qrGenerating))
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
            
            Text(L10n.text("生成失败", en: "Failed to generate", ja: "生成に失敗しました", ko: "생성 실패"))
                .font(.system(size: 18, weight: .medium))
            
            Text(errorMessage)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: loadInviteCode) {
                Text(L10n.text("重试", en: "Retry", ja: "再試行", ko: "다시 시도"))
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
                    
                    Text(L10n.text("邀请家人", en: "Invite family", ja: "家族を招待", ko: "가족 초대"))
                        .font(.system(size: 20, weight: .bold))
                    
                    Text(L10n.text("扫描二维码或分享邀请码", en: "Scan the QR code or share the invite code", ja: "QRコードを読み取るか、招待コードを共有してください", ko: "QR 코드를 스캔하거나 초대 코드를 공유하세요"))
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
                    
                    Text(L10n.text("扫描二维码快速绑定", en: "Scan the QR code to bind quickly", ja: "QRコードを読み取ってすばやく連携", ko: "QR 코드를 스캔해 빠르게 연결"))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
                
                // 邀请码卡片（放在二维码下面）
                VStack(spacing: 10) {
                    Text(L10n.string(.inviteCode))
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
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    if copied {
                        Text(L10n.text("✓ 已复制到剪贴板", en: "✓ Copied to clipboard", ja: "✓ クリップボードにコピーしました", ko: "✓ 클립보드에 복사됨"))
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
                    Text(L10n.text("或", en: "or", ja: "または", ko: "또는"))
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
                        Text(L10n.string(.bindNow))
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
                    Text(L10n.text("如何邀请家人？", en: "How do I invite family?", ja: "家族を招待するには？", ko: "가족은 어떻게 초대하나요?"))
                            .font(.system(size: 15, weight: .semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        InstructionRow(number: 1, text: L10n.text("分享邀请码或二维码给家人", en: "Share the invite code or QR code with your family.", ja: "招待コードまたはQRコードを家族に共有します。", ko: "초대 코드나 QR 코드를 가족에게 공유하세요."))
                        InstructionRow(number: 2, text: L10n.text("家人在 App 中输入邀请码或扫码", en: "Family members enter the code or scan it in the app.", ja: "家族はアプリでコードを入力するか、スキャンします。", ko: "가족은 앱에서 코드를 입력하거나 스캔합니다."))
                        InstructionRow(number: 3, text: L10n.text("对方确认后才会正式成为家人关系", en: "Only after the other side confirms will both sides become family members.", ja: "相手が確認してから正式に家族関係になります。", ko: "상대방이 확인한 후에야 정식 가족 관계가 됩니다."))
                        InstructionRow(number: 4, text: L10n.text("可以互相查看设备信息和位置", en: "You can view each other's device info and location.", ja: "お互いの端末情報や位置情報を確認できます。", ko: "서로의 기기 정보와 위치를 볼 수 있습니다."))
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
            // ✅ 修复：使用 DataManager 统一函数
            let (code, url) = try await DataManager.shared.getInviteCode()
            
            inviteCode = code
            qrURL = url
            print("✅ 邀请码加载成功：\(inviteCode)")
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            print("❌ 邀请码加载异常：\(error)")
        }
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
