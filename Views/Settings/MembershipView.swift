//
//  MembershipView.swift
//  终活
//
//  会员页面
//

import SwiftUI

struct MembershipView: View {
    @StateObject private var membership = MembershipManager.shared
    @StateObject private var iapManager = IAPManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedPlan: String = "yearly"
    @State private var showingPurchaseAlert = false
    @State private var purchaseMessage = ""
    @State private var isPurchasing = false
    
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
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(hex: "F5F5F7"))
            .navigationTitle("开通会员")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .alert("提示", isPresented: $showingPurchaseAlert) {
            Button("确定") {}
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
            
            Text("终活会员")
                .font(.system(size: 28, weight: .bold))
            
            Text("你的数字遗产值得更好的保护")
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
                Text("当前为 \(membership.memberTypeDisplayName())")
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
            Text("选择方案")
                .font(.system(size: 20, weight: .bold))
            
            // 年卡（推荐）
            PlanCard(
                name: "年卡",
                price: "¥68",
                originalPrice: "¥98",
                period: "/年",
                badge: "推荐",
                isSelected: selectedPlan == "yearly",
                onTap: { selectedPlan = "yearly" }
            )
            
            // 月卡
            PlanCard(
                name: "月卡",
                price: "¥8",
                originalPrice: nil,
                period: "/月",
                badge: nil,
                isSelected: selectedPlan == "monthly",
                onTap: { selectedPlan = "monthly" }
            )
        }
    }
    
    // MARK: - 功能对比
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("会员特权")
                .font(.system(size: 20, weight: .bold))
            
            // 表格标题
            HStack {
                Text("功能")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .leading)
                
                Text("免费版")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                
                Text("会员版")
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
                    title: "时光胶囊",
                    free: "5 个",
                    premium: "20 个",
                    isLast: false
                )
                
                Divider()
                
                FeatureTableRow(
                    icon: "mic.fill",
                    title: "语音/视频胶囊",
                    free: "2个/各2分钟",
                    premium: "10个/各5分钟",
                    isLast: false
                )
                
                Divider()
                
                FeatureTableRow(
                    icon: "doc.text.fill",
                    title: "遗嘱嘱托",
                    free: "3 个模块",
                    premium: "无限",
                    isLast: false
                )
                
                Divider()
                
                FeatureTableRow(
                    icon: "icloud.fill",
                    title: "云端备份",
                    free: "-",
                    premium: "自动同步",
                    isLast: false
                )
                
                Divider()
                
                FeatureTableRow(
                    icon: "person.2.fill",
                    title: "家庭守护",
                    free: "1 位家人",
                    premium: "5 位家人",
                    isLast: false
                )
                
                Divider()
                
                FeatureTableRow(
                    icon: "square.and.arrow.up.fill",
                    title: "数据导出",
                    free: "-",
                    premium: "PDF/视频/加密包",
                    isLast: false
                )
                
                Divider()
                
                FeatureTableRow(
                    icon: "brain",
                    title: "AI 辅助",
                    free: "-",
                    premium: "智能分类规划",
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
                        Text("立即开通 \(selectedPlanName)")
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
            
            Text("7天免费试用 · 随时取消")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    private var selectedPlanName: String {
        switch selectedPlan {
        case "monthly": return "月卡会员"
        case "yearly": return "年卡会员"
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
            case .success(let transactionId, let expiryDate):
                // 购买成功，激活会员
                print("✅ IAP 购买成功: transactionId=\(transactionId), expiry=\(expiryDate)")
                
                // 调用服务器激活会员
                await activateMembershipOnServer(type: selectedPlan, transactionId: transactionId, expiryDate: expiryDate)
                
                purchaseMessage = "\(selectedPlanName)开通成功！"
                showingPurchaseAlert = true
                
            case .pending:
                purchaseMessage = "购买处理中，请稍候..."
                showingPurchaseAlert = true
                
            case .cancelled:
                // 用户取消，不显示提示
                break
                
            case .failure(let error):
                purchaseMessage = "购买失败：\(error)"
                showingPurchaseAlert = true
            }
        }
    }
    
    /// 在服务器上激活会员
    private func activateMembershipOnServer(type: String, transactionId: String, expiryDate: Date) async {
        // 1. 先在本地激活
        membership.activatePremium(type: type)
        
        // 2. 同步到服务器
        do {
            let mutation = """
            mutation($memberType: String!, $receipt: String!) {
                activateMembership(memberType: $memberType, receipt: $receipt) {
                    success
                    isPremium
                    memberType
                    memberExpireAt
                }
            }
            """
            
            let variables: [String: Any] = [
                "memberType": type,
                "receipt": transactionId  // 发送交易ID用于验证
            ]
            
            let result = try await GraphQLClient.shared.query(mutation, variables: variables)
            
            if let data = result["data"] as? [String: Any],
               let activation = data["activateMembership"] as? [String: Any],
               let success = activation["success"] as? Bool, success {
                print("✅ 会员激活已同步到服务器")
            } else {
                print("⚠️ 会员激活同步失败，但本地已激活")
            }
        } catch {
            print("❌ 会员激活同步异常：\(error)")
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
