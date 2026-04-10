//
//  Capsule/CapsuleList.swift
//  终活
//
//  时光胶囊列表
//  职责：胶囊展示 + 筛选 + 空状态
//

import SwiftUI
import UIKit

struct CapsuleList: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedFilter: TimeCapsule.CapsuleType? = nil
    
    var filteredCapsules: [TimeCapsule] {
        dataManager.getFilteredCapsules(type: selectedFilter)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // ✅ 背景色全屏覆盖（与首页一致）
                Color(hex: "F5F5F7")
                    .ignoresSafeArea(edges: .all)
                
                ScrollView {
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
                    .padding(.vertical, 14)
                }
            }
            .navigationTitle("⏰ 时光胶囊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "capsule.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("时光胶囊")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                setupNavigationBar()
                
                // 📥 从文件加载胶囊数据
                let loadedCapsules = dataManager.loadCapsulesFromFile()
                dataManager.capsules = loadedCapsules
                
                // 📤 同步胶囊到云端
                Task {
                    await dataManager.batchSyncCapsules()
                }
            }
        }
        .onAppear {
            // 从文件加载胶囊数据
            let loadedCapsules = dataManager.loadCapsulesFromFile()
            dataManager.capsules = loadedCapsules
            
            // 设置紫色导航栏背景
            setupNavigationBar()
            
            // 同步胶囊到云端
            Task {
                await dataManager.batchSyncCapsules()
            }
        }
    }
    
    // 设置紫色导航栏背景（与首页一致）
    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "6366F1")
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
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
                
                Text("\(dataManager.capsules.count)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 12) {
                StatItem(icon: "capsule.fill", value: "\(dataManager.capsules.count)", label: "全部", color: .white)
                StatItem(icon: "clock.fill", value: "\(dataManager.capsules.filter { !$0.isSent }.count)", label: "待发送", color: .white)
                StatItem(icon: "checkmark.circle.fill", value: "\(dataManager.capsules.filter { $0.isSent }.count)", label: "已发送", color: .white)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color(hex: "6366F1").opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部按钮
                FilterButton(title: "全部", icon: "square.grid.2x2", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                
                // 文字胶囊
                FilterButton(title: "文字", icon: "doc.text", isSelected: selectedFilter == .text) {
                    selectedFilter = .text
                }
                
                // 语音胶囊
                FilterButton(title: "语音", icon: "mic", isSelected: selectedFilter == .audio) {
                    selectedFilter = .audio
                }
                
                // 视频胶囊
                FilterButton(title: "视频", icon: "video", isSelected: selectedFilter == .video) {
                    selectedFilter = .video
                }
            }
        }
    }
    
    private var capsuleList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(filteredCapsules) { capsule in
                    NavigationLink(destination: CapsuleEditView(dataManager: dataManager)) {
                        CapsuleCard(capsule: capsule)
                    }
                }
                .onDelete(perform: deleteCapsules)  // ✅ 添加删除功能
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "capsule")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "6366F1").opacity(0.5))
            
            Text("还没有时光胶囊")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)
            
            Text("点击右上角 ➕ 创建第一个胶囊")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            NavigationLink(destination: CapsuleEditView(dataManager: dataManager)) {
                Text("创建胶囊")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "6366F1"))
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, 40)
    }
    
    private func deleteCapsules(at offsets: IndexSet) {
        for index in offsets {
            let capsule = filteredCapsules[index]
            dataManager.capsules.removeAll { $0.id == capsule.id }
            dataManager.saveCapsulesToFile()
        }
        
        // 同步删除到云端
        Task {
            await dataManager.batchSyncCapsules()
        }
    }
}

// MARK: - 筛选按钮
struct FilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Color(hex: "6366F1"))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.white
                    }
                }
            )
            .cornerRadius(20)
            .shadow(color: isSelected ? Color(hex: "6366F1").opacity(0.3) : Color.clear, radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - 胶囊卡片（✅ 优化：增强视觉效果）
struct CapsuleCard: View {
    let capsule: TimeCapsule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // 类型图标
                Image(systemName: iconForType(capsule.type))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(10)
                
                // 标题和类型
                VStack(alignment: .leading, spacing: 4) {
                    Text(capsule.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Image(systemName: iconForType(capsule.type))
                            .font(.system(size: 10))
                        Text(capsule.type.rawValue)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 状态图标
                VStack(spacing: 4) {
                    Image(systemName: capsule.isSent ? "checkmark.circle.fill" : "clock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(capsule.isSent ? .green : .orange)
                    
                    Text(capsule.isSent ? "已发送" : "待发送")
                        .font(.system(size: 10))
                        .foregroundColor(capsule.isSent ? .green : .orange)
                }
            }
            
            // 发送日期
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                Text(formatSendDate(capsule.sendDate))
                    .font(.system(size: 13))
            }
            .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(hex: "6366F1").opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private func iconForType(_ type: TimeCapsule.CapsuleType) -> String {
        switch type {
        case .text: return "doc.text.fill"
        case .audio, .voice: return "mic.fill"
        case .video, .image, .sticker: return "video.fill"
        @unknown default: return "capsule.fill"
        }
    }
    
    private func formatSendDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 MM 月 dd 日 发送"
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
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(color.opacity(0.8))
        }
    }
}

// MARK: - 胶囊行
struct CapsuleRow: View {
    let capsule: TimeCapsule
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: capsule.type.icon)
                        .foregroundColor(.secondary)
                    Text(capsule.title)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if !capsule.isSent {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.orange)
                        }
                        
                        if capsule.isSent {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Text(capsule.content)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(formatSendDate(capsule.sendDate))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(capsule.type.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "6366F1"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "6366F1").opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatSendDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = capsule.isSent ? "yyyy 年 MM 月 dd 日 已发送" : "yyyy 年 MM 月 dd 日 发送"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        CapsuleList(dataManager: DataManager.shared)
    }
}