//
//  MembershipView.swift
//  终活
//
//  会员页面
//

import SwiftUI
import StoreKit

struct MembershipView: View {
    @StateObject private var membership = MembershipManager.shared
    @StateObject private var iapManager = IAPManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedPlan: String = "yearly"
    @State private var showingPurchaseAlert = false
    @State private var purchaseMessage = ""
    @State private var isPurchasing = false
    @State private var isRestoring = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 头部
                    headerSection
                    
                    // 当前状态
                    if membership.isPremium {
                        currentStatusSection
                    }
                    
                    // 功能对比
                    featuresSection
                    
                    // 会员方案
                    plansSection
                    
                    // 购买按钮
                    purchaseButton

                    // 辅助操作：恢复购买 / 管理订阅
                    subscriptionActionsSection

                    // 自动续费披露 + 隐私政策 + 用户协议
                    legalDisclosureSection

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle(L10n.string(.openMembership))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string(.close)) {
                        dismiss()
                    }
                }
            }
        }
        .stackNavigationStyle()
        .alert(L10n.string(.prompt), isPresented: $showingPurchaseAlert) {
            Button(L10n.string(.confirm)) {}
        } message: {
            Text(purchaseMessage)
        }
    }
    
    // MARK: - 头部
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "FFD700"))
            
            Text(L10n.string(.appName) + L10n.text("会员", en: " Membership", ja: "会員", ko: " 멤버십"))
                .font(.system(size: 28, weight: .bold))
            
            Text(L10n.text("你的数字遗产值得更好的保护", en: "Your digital legacy deserves better protection", ja: "あなたのデジタル資産は、より良い保護に値します", ko: "당신의 디지털 유산은 더 나은 보호를 받을 가치가 있습니다"))
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - 当前状态
    private var currentStatusSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                Text(L10n.text("当前为 \(membership.memberTypeDisplayName())", en: "Current plan: \(membership.memberTypeDisplayName())", ja: "現在のプラン：\(membership.memberTypeDisplayName())", ko: "현재 플랜: \(membership.memberTypeDisplayName())"))
                    .font(.system(size: 16, weight: .medium))
            }
            
            if let expireInfo = membership.memberExpireDisplay() {
                Text(expireInfo)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 会员方案
    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("选择方案", en: "Choose a plan", ja: "プランを選択", ko: "플랜 선택"))
                .font(.system(size: 20, weight: .bold))
            
            // 年卡（推荐）
            PlanCard(
                name: L10n.text("年卡", en: "Yearly", ja: "年額", ko: "연간"),
                price: "¥68",
                originalPrice: "¥98",
                period: L10n.text("/年", en: "/year", ja: "/年", ko: "/년"),
                badge: L10n.text("推荐", en: "Recommended", ja: "おすすめ", ko: "추천"),
                isSelected: selectedPlan == "yearly",
                onTap: { selectedPlan = "yearly" }
            )
            
            // 月卡
            PlanCard(
                name: L10n.text("月卡", en: "Monthly", ja: "月額", ko: "월간"),
                price: "¥8",
                originalPrice: nil,
                period: L10n.text("/月", en: "/month", ja: "/月", ko: "/월"),
                badge: nil,
                isSelected: selectedPlan == "monthly",
                onTap: { selectedPlan = "monthly" }
            )
        }
    }
    
    // MARK: - 功能对比
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("会员特权", en: "Member benefits", ja: "会員特典", ko: "멤버십 혜택"))
                .font(.system(size: 20, weight: .bold))
            
            // 表格标题
            HStack {
                Text(L10n.text("功能", en: "Feature", ja: "機能", ko: "기능"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .leading)
                
                Text(L10n.text("免费版", en: "Free", ja: "無料版", ko: "무료"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                
                Text(L10n.text("会员版", en: "Premium", ja: "会員版", ko: "유료"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "6366F1"))
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // 表格内容
            VStack(spacing: 0) {
                FeatureTableRow(
                    icon: "capsule.fill",
                    title: L10n.string(.tabCapsule),
                    free: L10n.text("5 个", en: "5", ja: "5個", ko: "5개"),
                    premium: L10n.text("20 个", en: "20", ja: "20個", ko: "20개"),
                    isLast: false
                )
                
                Divider()
                
                FeatureTableRow(
                    icon: "mic.fill",
                    title: L10n.text("语音/视频胶囊", en: "Audio / Video Capsules", ja: "音声 / 動画カプセル", ko: "음성 / 비디오 캡슐"),
                    free: L10n.text("2个/各2分钟", en: "2 / 2 min each", ja: "2個 / 各2分", ko: "2개 / 각 2분"),
                    premium: L10n.text("10个/各5分钟", en: "10 / 5 min each", ja: "10個 / 各5分", ko: "10개 / 각 5분"),
                    isLast: false
                )
                
                Divider()
                
                FeatureTableRow(
                    icon: "doc.text.fill",
                    title: L10n.string(.myWills),
                    free: L10n.text("3 个模块", en: "3 modules", ja: "3モジュール", ko: "3개 모듈"),
                    premium: L10n.text("无限", en: "Unlimited", ja: "無制限", ko: "무제한"),
                    isLast: false
                )
                
                Divider()
                
                FeatureTableRow(
                    icon: "icloud.fill",
                    title: L10n.text("云端同步", en: "Cloud sync", ja: "クラウド同期", ko: "클라우드 동기화"),
                    free: L10n.text("自动同步", en: "Auto sync", ja: "自動同期", ko: "자동 동기화"),
                    premium: L10n.text("自动同步 + 一键恢复", en: "Auto sync + one-tap restore", ja: "自動同期 + ワンタップ復元", ko: "자동 동기화 + 원탭 복원"),
                    isLast: false
                )
                
                Divider()
                
                FeatureTableRow(
                    icon: "person.2.fill",
                    title: L10n.string(.familyGuard),
                    free: L10n.text("1 位家人", en: "1 family member", ja: "1人", ko: "1명"),
                    premium: L10n.text("5 位家人", en: "5 family members", ja: "5人", ko: "5명"),
                    isLast: false
                )
                
                Divider()
                
                FeatureTableRow(
                    icon: "square.and.arrow.up.fill",
                    title: L10n.text("数据导出", en: "Data export", ja: "データ書き出し", ko: "데이터 내보내기"),
                    free: "-",
                    premium: L10n.text("PDF/视频/加密包（含媒体下载地址）", en: "PDF / video / encrypted package (with media download links)", ja: "PDF / 動画 / 暗号化パッケージ（メディアダウンロードリンク付き）", ko: "PDF / 비디오 / 암호화 패키지(미디어 다운로드 링크 포함)"),
                    isLast: true
                )
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 购买按钮
    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                purchaseMembership()
            }) {
                Group {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(L10n.text("立即开通 \(selectedPlanName)", en: "Subscribe \(selectedPlanName)", ja: "\(selectedPlanName)を開通", ko: "\(selectedPlanName) 시작하기"))
                    }
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(isPurchasing)
            
            Text(L10n.text("7天免费试用 · 随时取消", en: "7-day free trial · Cancel anytime", ja: "7日間無料体験・いつでも解約可", ko: "7일 무료 체험 · 언제든지 취소 가능"))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    private var selectedPlanName: String {
        switch selectedPlan {
        case "monthly": return L10n.text("月卡会员", en: "Monthly", ja: "月額会員", ko: "월간 멤버십")
        case "yearly": return L10n.text("年卡会员", en: "Yearly", ja: "年額会員", ko: "연간 멤버십")
        default: return ""
        }
    }
    
    private func purchaseMembership() {
        Task {
            isPurchasing = true
            
            // 确保商品已加载
            if iapManager.products.isEmpty {
                await iapManager.loadProducts()
            }
            
            // 确定商品类型
            let productType: IAPProductType = selectedPlan == "monthly" ? .monthly : .yearly
            
            // 执行购买
            let result = await iapManager.purchase(productType)
            
            isPurchasing = false
            
            switch result {
            case .success(let transactionId, let originalTransactionId, let expiryDate):
                // 购买成功，激活会员
                print("✅ IAP 购买成功: txId=\(transactionId), origTxId=\(originalTransactionId), expiry=\(expiryDate)")
                
                // 调用服务器激活会员（带上 originalTransactionId 用于跨设备绑定）
                await activateMembershipOnServer(
                    type: selectedPlan,
                    transactionId: transactionId,
                    originalTransactionId: originalTransactionId,
                    expiryDate: expiryDate
                )
                
                purchaseMessage = L10n.text("\(selectedPlanName)开通成功！", en: "\(selectedPlanName) subscription activated!", ja: "\(selectedPlanName)の開通に成功しました！", ko: "\(selectedPlanName) 시작에 성공했습니다!")
                showingPurchaseAlert = true
                
            case .pending:
                purchaseMessage = L10n.text("购买处理中，请稍候...", en: "Purchase pending, please wait...", ja: "購入処理中です。しばらくお待ちください...", ko: "구매 처리 중입니다. 잠시만 기다려 주세요...")
                showingPurchaseAlert = true
                
            case .cancelled:
                // 用户取消，不显示提示
                break
                
            case .failure(let error):
                purchaseMessage = L10n.text("购买失败：\(error)", en: "Purchase failed: \(error)", ja: "購入に失敗しました：\(error)", ko: "구매 실패: \(error)")
                showingPurchaseAlert = true
            }
        }
    }
    
    /// 在服务器上激活会员
    /// - Parameters:
    ///   - type: 月卡/年卡
    ///   - transactionId: 当前事务 ID
    ///   - originalTransactionId: 原始订阅事务 ID，整条订阅链不变；服务器据此把订阅绑定到 App 账号
    private func activateMembershipOnServer(
        type: String,
        transactionId: String,
        originalTransactionId: String,
        expiryDate: Date
    ) async {
        // 1. 先在本地激活
        membership.activatePremium(type: type)
        
        // 2. 同步到服务器
        do {
            let mutation = """
            mutation($memberType: String!, $receipt: String!, $originalTransactionId: String) {
                activateMembership(memberType: $memberType, receipt: $receipt, originalTransactionId: $originalTransactionId) {
                    success
                    isPremium
                    memberType
                    memberExpireAt
                    message
                }
            }
            """
            
            let variables: [String: Any] = [
                "memberType": type,
                "receipt": transactionId,
                "originalTransactionId": originalTransactionId
            ]
            
            let result = try await GraphQLClient.shared.query(mutation, variables: variables)
            
            if let data = result["data"] as? [String: Any],
               let activation = data["activateMembership"] as? [String: Any],
               let success = activation["success"] as? Bool, success {
                print("✅ 会员激活已同步到服务器")
            } else {
                let message = ((result["data"] as? [String: Any])?["activateMembership"] as? [String: Any])?["message"] as? String
                    ?? (result["errors"] as? [[String: Any]])?.first?["message"] as? String
                    ?? "未知错误"
                print("⚠️ 会员激活同步失败：\(message)")
            }
        } catch {
            print("❌ 会员激活同步异常：\(error)")
        }
    }

    // MARK: - 恢复购买 / 管理订阅
    private var subscriptionActionsSection: some View {
        HStack(spacing: 24) {
            Button(action: { restorePurchases() }) {
                HStack(spacing: 6) {
                    if isRestoring {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(L10n.text("恢复购买", en: "Restore Purchases", ja: "購入を復元", ko: "구매 복원"))
                }
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "6366F1"))
            }
            .disabled(isRestoring)

            Text("|")
                .foregroundColor(.secondary)

            Button(action: { openManageSubscriptions() }) {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape")
                    Text(L10n.text("管理订阅", en: "Manage Subscription", ja: "サブスクリプション管理", ko: "구독 관리"))
                }
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "6366F1"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var legalDisclosureSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text(
                "订阅说明：通过 Apple ID 账户扣款，订阅将自动续期。如需取消，请在当前订阅周期结束前至少 24 小时，前往 Apple ID 的「订阅」中关闭自动续期。续订费用将在当前周期结束前 24 小时内扣除。购买后可在 Apple ID 设置中或本页「管理订阅」入口取消或更换套餐。",
                en: "Subscription terms: Payment will be charged to your Apple ID account at confirmation of purchase. Subscriptions automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period. Renewal is charged within 24 hours prior to the end of the current period. You can manage and cancel your subscription in your Apple ID account settings, or via the “Manage Subscription” entry above.",
                ja: "サブスクリプションについて：お支払いは購入確定時に Apple ID アカウントへ請求されます。サブスクリプションは現在の期間終了の少なくとも 24 時間前に自動更新を解除しない限り、自動的に更新されます。更新料金は現在の期間終了の 24 時間以内に請求されます。Apple ID の設定または上記「サブスクリプション管理」からいつでも管理・解約できます。",
                ko: "구독 안내: 결제는 구매 확인 시 Apple ID 계정에 청구됩니다. 현재 기간 종료 24시간 전까지 자동 갱신을 해제하지 않으면 구독이 자동으로 갱신됩니다. 갱신 비용은 현재 기간 종료 전 24시간 이내에 청구됩니다. Apple ID 설정 또는 위의 ‘구독 관리’에서 언제든지 관리하거나 취소할 수 있습니다."
            ))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                if let url = URL(string: "https://zhonghuo.cn/privacy") {
                    Link(L10n.string(.privacyPolicy), destination: url)
                        .font(.system(size: 12))
                }
                Text("|")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                if let url = URL(string: "https://zhonghuo.cn/terms") {
                    Link(L10n.string(.termsOfService), destination: url)
                        .font(.system(size: 12))
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 4)
    }

    private func restorePurchases() {
        Task {
            isRestoring = true
            await iapManager.restorePurchases()
            // 拉一次服务器最新会员状态，把恢复出的订阅同步到当前 App 账号
            await UserManager.shared.fetchUserData()
            isRestoring = false
            if iapManager.isSubscribed {
                purchaseMessage = L10n.text(
                    "已为当前账号恢复有效订阅。",
                    en: "Active subscription restored for the current account.",
                    ja: "現在のアカウントに有効なサブスクリプションを復元しました。",
                    ko: "현재 계정에 활성 구독이 복원되었습니다."
                )
            } else {
                purchaseMessage = L10n.text(
                    "未发现可恢复的订阅。如有疑问，请联系客服或登录原 App 账号。",
                    en: "No restorable subscription was found. Please contact support or sign in with the original account if needed.",
                    ja: "復元可能なサブスクリプションが見つかりません。必要に応じてカスタマーサポートに連絡するか、元のアカウントでサインインしてください。",
                    ko: "복원 가능한 구독을 찾을 수 없습니다. 필요한 경우 고객지원에 문의하거나 원본 계정으로 로그인하세요."
                )
            }
            showingPurchaseAlert = true
        }
    }

    private func openManageSubscriptions() {
        Task {
            // iOS 15+ 直接拉起 App 内系统订阅管理 sheet；失败时回退到打开订阅管理 URL
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                do {
                    try await AppStore.showManageSubscriptions(in: scene)
                    return
                } catch {
                    print("⚠️ showManageSubscriptions 失败: \(error)")
                }
            }
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
}

// MARK: - 表格形式的功能对比行
struct FeatureTableRow: View {
    let icon: String
    let title: String
    let free: String
    let premium: String
    let isLast: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "6366F1"))
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 14))
            }
            .frame(width: 100, alignment: .leading)
            
            Text(free)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
            
            Text(premium)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "34C759"))
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }
}

// MARK: - 方案卡片
struct PlanCard: View {
    let name: String
    let price: String
    let originalPrice: String?
    let period: String
    let badge: String?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(name)
                            .font(.system(size: 16, weight: .semibold))
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(badge == "推荐" ? Color.orange : Color.green)
                                .cornerRadius(4)
                        }
                    }
                    
                    if let original = originalPrice {
                        Text(original)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .strikethrough()
                    }
                }
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.system(size: 24, weight: .bold))
                    Text(period)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color(hex: "6366F1") : .gray)
                    .font(.system(size: 22))
            }
            .padding()
            .background(isSelected ? Color(hex: "6366F1").opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "6366F1") : Color(.separator), lineWidth: isSelected ? 2 : 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MembershipView()
}
