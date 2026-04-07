//
//  Capsule/CapsuleList.swift
//  终活
//
//  时光胶囊列表
//  职责：胶囊展示 + 筛选 + 空状态
//

import SwiftUI

struct CapsuleList: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedFilter: TimeCapsule.CapsuleType? = nil
    
    var filteredCapsules: [TimeCapsule] {
        dataManager.getFilteredCapsules(type: selectedFilter)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 统计卡片
            statsCard
            
            // 类型筛选
            filterButtons
            
            // 胶囊列表
            if filteredCapsules.isEmpty {
                emptyState
            } else {
                capsuleList
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private var statsCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("⏰ 时光胶囊")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Text("记录美好，留给未来的自己")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                StatItem(icon: "capsule.fill", value: "\(dataManager.capsules.count)", label: "全部", color: .white)
                StatItem(icon: "clock.fill", value: "\(dataManager.capsules.filter { !$0.isSent }.count)", label: "待发送", color: .white)
                StatItem(icon: "checkmark.circle.fill", value: "\(dataManager.capsules.filter { $0.isSent }.count)", label: "已发送", color: .white)
                StatItem(icon: "link.circle.fill", value: "\(dataManager.capsules.filter { $0.privacy == .private }.count)", label: "私密", color: .white)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: { selectedFilter = nil }) {
                    Text("全部")
                        .foregroundColor(selectedFilter == nil ? .white : Color(hex: "6366F1"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedFilter == nil ? Color(hex: "6366F1") : Color.white)
                        .cornerRadius(20)
                }
                
                ForEach(TimeCapsule.CapsuleType.allCases, id: \.self) { type in
                    Button(action: { selectedFilter = type }) {
                        Text(type.displayName)
                            .foregroundColor(selectedFilter == type ? .white : Color(hex: "6366F1"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFilter == type ? Color(hex: "6366F1") : Color.white)
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
    
    private var capsuleList: some View {
        List {
            Section {
                ForEach(filteredCapsules) { capsule in
                    CapsuleRow(capsule: capsule)
                }
                .onDelete(perform: deleteCapsules)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "hourglass")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("暂无胶囊")
                    .font(.headline)
                Text("请点击 + 号创建第一个时光胶囊")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {}) {
                Text("创建胶囊")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color(hex: "6366F1"))
                    .cornerRadius(12)
            }
        }
    }
    
    private func deleteCapsules(at offsets: IndexSet) {
        let capsulesToDelete = filteredCapsules
            .safe Subset(offsets)
            .map { $0.id }
        
        for capsuleId in capsulesToDelete {
            dataManager.deleteCapsule(capsuleId: capsuleId)
        }
    }
}

// MARK: - 胶囊行
struct CapsuleRow: View {
    let capsule: TimeCapsule
    @State private var showingDeleteConfirm = false
    @State private var onEdit: () -> Void = {}
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: capsule.type.icon)
                        .foregroundColor(.secondary)
                    Text(capsule.title)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(formatSendDate(capsule.sendDate))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if capsule.privacy == .private {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.orange)
                }
                
                if !capsule.isSent {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .alert("删除胶囊", isPresented: $showingDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive, action: onDelete)
        } message: {
            Text("确定要删除\"\(capsule.title)\"吗？此操作无法撤销。")
        }
    }
    
    private func onDelete() {
        // 处理删除
        dataManager.deleteCapsule(capsuleId: capsule.id)
    }
    
    private func formatSendDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = capsule.isSent ? "yyyy 年 MM 月 dd 日 已发送" : "yyyy 年 MM 月 dd 日 发送"
        return formatter.string(from: date)
    }
}

// MARK: - 统计项
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(color.opacity(0.8))
        }
    }
}

#Preview {
    CapsuleList(dataManager: DataManager.shared)
}
