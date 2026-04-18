//
//  MembershipView.swift
//  终活
//
//  会员页面
//

import SwiftUI

struct MembershipView: View {
    @StateObject private var membership = MembershipManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedPlan: String = "yearly"
    @State private var showingPurchaseAlert = false
    @State private var purchaseMessage = ""
    
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
    
    // MARK: - 功能对比
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("会员特权")
                .font(.system(size: 20, weight: .bold))
            
            FeatureRow(
                icon: "capsule.fill",
                title: "时光胶囊",
                free: "5 个",
                premium: "20 个"
            )
            
            FeatureRow(
                icon: "mic.fill",
                title: "语音/视频胶囊",
                free: "2 个（各2分钟）",
                premium: "10 个（各5分钟）"
            )
            
            FeatureRow(
                icon: "doc.text.fill",
                title: "遗嘱嘱托",
                free: "3 个模块",
                premium: "无限"
            )
            
            FeatureRow(
                icon: "icloud.fill",
                title: "云端备份",
                free: "❌",
                premium: "✅ 自动同步"
            )
            
            FeatureRow(
                icon: "person.2.fill",
                title: "家庭守护",
                free: "1 位家人",
                premium: "5 位家人"
            )
            
            FeatureRow(
                icon: "square.and.arrow.up.fill",
                title: "数据导出",
                free: "❌",
                premium: "PDF/视频/加密包"
            )
            
            FeatureRow(
                icon: "brain",
                title: "AI 辅助",
                free: "❌",
                premium: "智能分类规划"
            )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - 会员方案
    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
            
            // 终身
            PlanCard(
                name: "终身",
                price: "¥298",
                originalPrice: nil,
                period: "",
                badge: "最划算",
                isSelected: selectedPlan == "lifetime",
                onTap: { selectedPlan = "lifetime" }
            )
        }
    }
    
    // MARK: - 购买按钮
    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                purchaseMembership()
            }) {
                Text("立即开通 \(selectedPlanName)")
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
            
            Text("7天免费试用 · 随时取消")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    private var selectedPlanName: String {
        switch selectedPlan {
        case "monthly": return "月卡会员"
        case "yearly": return "年卡会员"
        case "lifetime": return "终身会员"
        default: return ""
        }
    }
    
    private func purchaseMembership() {
        // TODO: 接入 Apple IAP
        // 目前先模拟购买成功
        membership.activatePremium(type: selectedPlan)
        purchaseMessage = "\(selectedPlanName)开通成功！"
        showingPurchaseAlert = true
    }
}

// MARK: - 功能对比行
struct FeatureRow: View {
    let icon: String
    let title: String
    let free: String
    let premium: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "6366F1"))
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 15))
            
            Spacer()
            
            Text(free)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 80)
            
            Text(premium)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.green)
        }
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
            .background(isSelected ? Color(hex: "6366F1").opacity(0.1) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "6366F1") : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MembershipView()
}
