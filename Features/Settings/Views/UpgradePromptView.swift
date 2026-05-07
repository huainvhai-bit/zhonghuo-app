//
//  UpgradePromptView.swift
//  安心助手
//
//  升级提示弹窗
//

import SwiftUI

struct UpgradePromptView: View {
    let feature: String
    let statusText: String
    let currentLimit: String
    let targetLimit: String
    let onUpgrade: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 图标
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "FFD700"))
            
            // 标题
            Text(L10n.string(.openMembership))
                .font(.system(size: 22, weight: .bold))
            
            // 描述
            Text(statusText)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            // 对比
            HStack(spacing: 20) {
                VStack {
                    Text(L10n.string(.tabMe))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(currentLimit)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)
                
                VStack {
                    Text(L10n.string(.openMembership))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(targetLimit)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // 按钮
            VStack(spacing: 12) {
                Button(action: onUpgrade) {
                    Text(L10n.string(.updateNow))
                        .font(.system(size: 16, weight: .semibold))
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
                        .cornerRadius(10)
                }
                
                Button(action: onCancel) {
                    Text(L10n.string(.later))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 20)
        .padding(.horizontal, 40)
    }
}

// MARK: - 留言数量限制提示
struct CapsuleLimitPromptView: View {
    let currentCount: Int
    let maxCount: Int
    let onUpgrade: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        UpgradePromptView(
            feature: L10n.string(.tabCapsule),
            statusText: "当前时光留言数量已达上限",
            currentLimit: "\(currentCount)/\(maxCount)",
            targetLimit: "20个",
            onUpgrade: onUpgrade,
            onCancel: onCancel
        )
    }
}

// MARK: - 媒体留言限制提示
struct MediaCapsuleLimitPromptView: View {
    let currentCount: Int
    let onUpgrade: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        UpgradePromptView(
            feature: "语音/视频留言",
            statusText: "当前媒体留言数量已达上限",
            currentLimit: "\(currentCount)/2",
            targetLimit: "10个（各5分钟）",
            onUpgrade: onUpgrade,
            onCancel: onCancel
        )
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.5)
            .ignoresSafeArea()
        
        CapsuleLimitPromptView(
            currentCount: 5,
            maxCount: 5,
            onUpgrade: {},
            onCancel: {}
        )
    }
}
