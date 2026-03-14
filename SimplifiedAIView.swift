//
//  SimplifiedAIView.swift
//  终活
//
//  AI 助手页面 - 简化版（主要功能在悬浮机器人）
//

import SwiftUI

struct SimplifiedAIView: View {
    @State private var messages: [String] = [
        "您好！我是您的终活助手。",
        "您可以点击右下角的悬浮按钮与我对话。",
        "我可以帮助您：",
        "• 解答关于终活规划的问题",
        "• 协助填写遗嘱和资产信息",
        "• 提供法律常识咨询",
        "• 帮助您整理身后事务"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 提示卡片
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Text("🤖")
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI 助手")
                                    .font(.headline)
                                
                                Text("点击右下角悬浮按钮开始对话")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(hex: "AF52DE").opacity(0.08))
                        .cornerRadius(12)
                    }
                    
                    // 功能列表
                    VStack(alignment: .leading, spacing: 12) {
                        Text("我可以帮助您")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            AIServiceCard(icon: "📝", title: "遗嘱撰写", desc: "提供模板和指导，帮您完成遗嘱")
                            AIServiceCard(icon: "💰", title: "资产整理", desc: "协助记录和管理各类资产")
                            AIServiceCard(icon: "⚖️", title: "法律咨询", desc: "解答遗嘱相关的法律问题")
                            AIServiceCard(icon: "📋", title: "事务清单", desc: "帮您整理身后待办事项")
                            AIServiceCard(icon: "💌", title: "时光胶囊", desc: "协助撰写给家人的留言")
                        }
                    }
                    
                    // 常见问题
                    VStack(alignment: .leading, spacing: 12) {
                        Text("常见问题")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            FAQCard(question: "如何订立有效的自书遗嘱？")
                            FAQCard(question: "见证人需要满足什么条件？")
                            FAQCard(question: "资产信息如何确保安全？")
                            FAQCard(question: "时光胶囊如何定时发送？")
                        }
                    }
                }
                .padding(.top, 16)
            }
            .background(Color(hex: "F2F2F7"))
            .navigationTitle("AI 助手")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - AI 服务卡片
struct AIServiceCard: View {
    let icon: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(Color.white)
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - FAQ 卡片
struct FAQCard: View {
    let question: String
    
    var body: some View {
        HStack {
            Text(question)
                .font(.system(size: 14))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}

#Preview {
    SimplifiedAIView()
}
