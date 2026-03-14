//
//  HomeStatusView.swift
//  终活 - 首页状态
//

import SwiftUI

struct HomeStatusView: View {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 欢迎卡片
                welcomeCard
                
                // 生命签到卡片
                LifeCheckStatusCard()
                
                // 快速统计
                QuickStatsView()
                
                // 最近胶囊
                RecentCapsulesView()
                
                // 待办清单
                PendingChecklistView()
            }
            .padding()
        }
        .background(Color.backgroundLight)
    }
    
    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("下午好")
                .font(.title2)
                .fontWeight(.bold)
            Text("今天也要记得签到哦")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardLight)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct LifeCheckStatusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.errorRed)
                Text("生命签到")
                    .font(.headline)
                Spacer()
                Text("剩余 23 小时 59 分")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            ProgressView(value: 0.8)
                .progressViewStyle(LinearProgressViewStyle(tint: .primaryPurple))
        }
        .padding()
        .background(Color.cardLight)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct QuickStatsView: View {
    var body: some View {
        HStack(spacing: 15) {
            StatCard(icon: "envelope.fill", title: "胶囊", value: "2", color: .primaryPurple)
            StatCard(icon: "doc.fill", title: "遗嘱", value: "0", color: .warningOrange)
            StatCard(icon: "star.fill", title: "资产", value: "0", color: .accentGreen)
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption2)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.cardLight)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct RecentCapsulesView: View {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近的时光胶囊")
                .font(.headline)
            
            ForEach(dataManager.timeCapsules.prefix(3)) { capsule in
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.primaryPurple)
                    VStack(alignment: .leading) {
                        Text(capsule.title)
                            .font(.subheadline)
                        Text("开启日期：\(capsule.openDate, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    if capsule.isLocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding()
                .background(Color.cardLight)
                .cornerRadius(8)
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

struct PendingChecklistView: View {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("待办事项")
                .font(.headline)
            
            ForEach(dataManager.checklistItems.filter { !$0.isCompleted }) { item in
                HStack {
                    Image(systemName: "circle")
                        .foregroundColor(.textSecondary)
                    Text(item.title)
                        .font(.subheadline)
                    Spacer()
                    Text(item.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.backgroundLight)
                        .cornerRadius(4)
                }
                .padding()
                .background(Color.cardLight)
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    HomeStatusView()
}
