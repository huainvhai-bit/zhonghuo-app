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
    @State private var showingUpgradeForFamily = false
    @State private var showingMembershipView = false
    @State private var showingInviteConfirmation = false
    @State private var pendingInvitePreview: FamilyInvitePreview?
    @State private var successMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // 说明
                    VStack(spacing: 12) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.indigo)
                        
                        Text(L10n.text("绑定家人", en: "Bind Family", ja: "家族を連携", ko: "가족 연결"))
                            .font(.system(size: 22, weight: .bold))
                        
                        Text(L10n.text("输入邀请码或扫描二维码", en: "Enter the invite code or scan the QR code", ja: "招待コードを入力するか、QRコードを読み取ってください", ko: "초대 코드를 입력하거나 QR 코드를 스캔하세요"))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // 输入框
                    VStack(spacing: 12) {
                        Text(L10n.string(.inviteCode))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            TextField(L10n.text("6 位邀请码", en: "6-digit invite code", ja: "6桁の招待コード", ko: "6자리 초대 코드"), text: $inviteCode)
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
                            Button(action: { handleScannerEntry() }) {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 20))
                                    .foregroundColor(.indigo)
                                    .padding(10)
                                    .background(Color.indigo.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding()
                        .background(Color(.systemBackground))
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
                            
                            Text(isBinding ? L10n.string(.binding) : L10n.string(.bindNow))
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
                        
                        Text(L10n.text("温馨提示", en: "Tip", ja: "ヒント", ko: "안내"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(L10n.text("确认后会先提交绑定申请，等待对方最终确认后才会正式成为家人关系。", en: "After confirmation, a binding request will be submitted first. The relationship becomes official only after the other side confirms it.", ja: "確認するとまず連携申請が送信されます。相手が最終確認してから正式な家族関係になります。", ko: "확인하면 먼저 연결 요청이 제출됩니다. 상대방이 최종 확인해야 정식 가족 관계가 됩니다."))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(L10n.text("绑定家人", en: "Bind Family", ja: "家族を連携", ko: "가족 연결"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.string(.cancel)) { dismiss() }
                }
            }
            .alert(L10n.string(.error), isPresented: $showingError) {
                Button(L10n.string(.confirm)) {}
            } message: {
                Text(errorMessage)
            }
            .alert(L10n.string(.bindSuccess), isPresented: $showingSuccess) {
                Button(L10n.string(.done)) {
                    dismiss()
                    onBound?()
                }
            } message: {
                Text(successMessage.isEmpty
                     ? L10n.text("绑定成功", en: "Binding succeeded", ja: "連携に成功しました", ko: "연결에 성공했습니다")
                     : successMessage)
            }
            .confirmationDialog(
                L10n.text("确认家人绑定", en: "Confirm family binding", ja: "家族連携を確認", ko: "가족 연결 확인"),
                isPresented: $showingInviteConfirmation,
                titleVisibility: .visible
            ) {
                Button(L10n.text("提交申请", en: "Submit request", ja: "申請を送信", ko: "요청 제출")) {
                    Task { await acceptPendingInvite() }
                }
                Button(L10n.string(.cancel), role: .cancel) {
                    pendingInvitePreview = nil
                }
            } message: {
                if let preview = pendingInvitePreview {
                    Text(L10n.text(
                        "将与 \(preview.inviterName)（\(preview.inviterPhone)）提交绑定申请，等待对方最终确认后才会正式生效。",
                        en: "You are about to submit a binding request with \(preview.inviterName) (\(preview.inviterPhone)). The binding becomes official only after the other side confirms it.",
                        ja: "\(preview.inviterName)（\(preview.inviterPhone)）へ連携申請を送信します。相手が最終確認してから正式に有効になります。",
                        ko: "\(preview.inviterName)(\(preview.inviterPhone))에게 연결 요청을 제출합니다. 상대방이 최종 확인해야 정식으로 적용됩니다."
                    ))
                }
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
                            
                            // 进入绑定确认流程
                            self.bindFamily()
                        } else {
                            self.errorMessage = L10n.string(.invalidQRCode)
                            self.showingError = true
                        }
                    },
                    onCancel: {
                        showingScanner = false
                    }
                )
            }
            .sheet(isPresented: $showingUpgradeForFamily) {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    UpgradePromptView(
                        feature: L10n.text("绑定家人", en: "Bind Family", ja: "家族を連携", ko: "가족 연결"),
                        statusText: L10n.text("当前家人数量已达上限", en: "You have reached the family limit", ja: "家族数の上限に達しました", ko: "가족 수 한도에 도달했습니다"),
                        currentLimit: L10n.text("当前最多 \(MembershipManager.shared.currentFamilyLimit()) 位家人", en: "Up to \(MembershipManager.shared.currentFamilyLimit()) family members", ja: "最大 \(MembershipManager.shared.currentFamilyLimit()) 人の家族", ko: "최대 \(MembershipManager.shared.currentFamilyLimit())명의 가족"),
                        targetLimit: L10n.text("会员版可绑定更多家人", en: "Premium can bind more family members", ja: "会員プランではより多く連携できます", ko: "멤버십에서는 더 많은 가족을 연결할 수 있습니다"),
                        onUpgrade: {
                            showingUpgradeForFamily = false
                            showingMembershipView = true
                        },
                        onCancel: {
                            showingUpgradeForFamily = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingMembershipView) {
                NavigationView {
                    MembershipView()
                }
                .stackNavigationStyle()
            }
        }
        .stackNavigationStyle()
    }
    
    // MARK: - 方法
    
    private func bindFamily() {
        print("🔵 手动输入邀请码：\(inviteCode)")

        let currentCount = DataManager.shared.familyMembers.count
        if !MembershipManager.shared.canAddFamilyMember(currentCount: currentCount) {
            showingUpgradeForFamily = true
            return
        }

        guard inviteCode.count == 6 else {
            print("❌ 邀请码长度不正确：\(inviteCode.count) 位")
            errorMessage = L10n.text("邀请码必须是 6 位", en: "Invite code must be 6 digits.", ja: "招待コードは6桁で入力してください。", ko: "초대 코드는 6자리여야 합니다.")
            showingError = true
            return
        }
        
        isBinding = true
        errorMessage = ""
        
        Task {
            await bindFamilyAsync()
        }
    }

    private func handleScannerEntry() {
        let currentCount = DataManager.shared.familyMembers.count
        if !MembershipManager.shared.canAddFamilyMember(currentCount: currentCount) {
            showingUpgradeForFamily = true
            return
        }
        showingScanner = true
    }
    
    @MainActor
    private func bindFamilyAsync() async {
        let currentCount = DataManager.shared.familyMembers.count
        if !MembershipManager.shared.canAddFamilyMember(currentCount: currentCount) {
            errorMessage = L10n.text("家人数量已达上限，升级会员可绑定更多家人", en: "You have reached the family limit. Upgrade to bind more family members.", ja: "家族数の上限に達しました。会員プランでより多く連携できます。", ko: "가족 수 한도에 도달했습니다. 멤버십을 업그레이드하면 더 많이 연결할 수 있습니다.")
            showingUpgradeForFamily = true
            isBinding = false
            return
        }
        
        let token = KeychainManager.shared.getToken() ?? ""
        guard !token.isEmpty else {
            errorMessage = L10n.text("请先登录", en: "Please sign in first.", ja: "先にログインしてください。", ko: "먼저 로그인하세요.")
            showingError = true
            isBinding = false
            return
        }
        
        guard !DataManager.apiURL.isEmpty else {
            errorMessage = L10n.text("API 未初始化", en: "API not initialized.", ja: "API が初期化されていません。", ko: "API가 초기화되지 않았습니다.")
            showingError = true
            isBinding = false
            return
        }
        
        do {
            // ✅ 修复：使用 DataManager 统一函数
            let result = try await DataManager.shared.bindFamilyByInviteCode(inviteCode: inviteCode)
            print("📡 绑定家人响应：\(result)")
            
            let success = result["success"] as? Bool ?? false
            if success {
            if let preview = makeInvitePreview(from: result), preview.requiresConfirmation {
                pendingInvitePreview = preview
                showingInviteConfirmation = true
                isBinding = false
                return
            }

            _ = try? await DataManager.shared.refreshFamilyMembers()
            successMessage = result["message"] as? String ?? L10n.string(.bindSuccess)
            isBinding = false
            showingSuccess = true
            return
            } else {
                errorMessage = result["message"] as? String ?? "绑定失败"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        showingError = true
        isBinding = false
    }

    @MainActor
    private func acceptPendingInvite() async {
        guard let preview = pendingInvitePreview else { return }
        isBinding = true
        showingInviteConfirmation = false

        do {
            let result = try await DataManager.shared.acceptFamilyInvite(relationId: preview.id)
            print("📡 确认家人关系响应：\(result)")

            let success = result["success"] as? Bool ?? false
            if success {
                _ = try? await DataManager.shared.refreshFamilyMembers()
                pendingInvitePreview = nil
                successMessage = result["message"] as? String ?? L10n.text("已提交绑定申请，等待对方确认", en: "Binding request submitted. Waiting for the other side to confirm.", ja: "連携申請を送信しました。相手の確認をお待ちください。", ko: "연결 요청을 제출했습니다. 상대방의 확인을 기다려 주세요.")
                showingSuccess = true
            } else {
                errorMessage = result["message"] as? String ?? L10n.string(.bindFailed)
                showingError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }

        isBinding = false
    }

    private func makeInvitePreview(from result: [String: Any]) -> FamilyInvitePreview? {
        guard let relationId = result["relationId"] as? String, !relationId.isEmpty else { return nil }

        return FamilyInvitePreview(
            id: relationId,
            inviteCode: result["inviteCode"] as? String ?? inviteCode,
            inviterId: result["inviterId"] as? String ?? "",
            inviterName: result["inviterName"] as? String ?? "",
            inviterPhone: result["inviterPhone"] as? String ?? "",
            relationType: result["relationType"] as? String ?? "family",
            requiresConfirmation: result["requiresConfirmation"] as? Bool ?? false,
            status: result["status"] as? String ?? "pending"
        )
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
    
    }

#Preview {
    BindFamilyView(onBound: nil)
}
