//
//  InviteCodeView.swift
//  终活
//
//  添加邀请码页面 - 显示二维码和邀请码
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
                    
                    Text(L10n.text("邀请添加用户", en: "Invite user", ja: "ユーザーを招待", ko: "사용자 초대"))
                        .font(.system(size: 20, weight: .bold))
                    
                    Text(L10n.text("扫描二维码或输入邀请码", en: "Scan the QR code or enter the invite code", ja: "QRコードを読み取るか、招待コードを入力してください", ko: "QR 코드를 스캔하거나 초대 코드를 입력하세요"))
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
                    
                    Text(L10n.text("扫描二维码快速添加", en: "Scan the QR code to add quickly", ja: "QRコードを読み取ってすばやく追加", ko: "QR 코드를 스캔해 빠르게 추가"))
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
                    Text(L10n.text("如何邀请添加用户？", en: "How do I invite a user?", ja: "ユーザーをどう招待しますか？", ko: "사용자를 어떻게 초대하나요?"))
                            .font(.system(size: 15, weight: .semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        InstructionRow(number: 1, text: L10n.text("出示邀请码或二维码给对方", en: "Show the invite code or QR code to the other person.", ja: "招待コードまたはQRコードを相手に見せてください。", ko: "초대 코드나 QR 코드를 상대방에게 보여 주세요."))
                        InstructionRow(number: 2, text: L10n.text("对方在 App 中输入邀请码或扫码", en: "The other person enters the code or scans it in the app.", ja: "相手はアプリでコードを入力するか、スキャンします。", ko: "상대방은 앱에서 코드를 입력하거나 스캔합니다."))
                        InstructionRow(number: 3, text: L10n.text("对方确认后才会正式建立添加", en: "Only after the other side confirms will it be added.", ja: "相手が確認してから正式に追加されます。", ko: "상대방이 확인한 후에야 정식으로 추가됩니다."))
                        InstructionRow(number: 4, text: L10n.text("可以互相查看设备信息", en: "You can view each other's device info.", ja: "お互いの端末情報を確認できます。", ko: "서로의 기기 정보를 볼 수 있습니다."))
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
