//
//  ReceivedCapsuleListView.swift
//  终活
//
//  我收到的时光胶囊列表
//

import SwiftUI

struct ReceivedCapsuleListView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedCapsule: ReceivedCapsule? = nil
    @State private var showingCapsuleDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea(edges: .all)
                
                if dataManager.receivedCapsules.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(dataManager.receivedCapsules) { capsule in
                                ReceivedCapsuleRow(capsule: capsule)
                                    .onTapGesture {
                                        selectedCapsule = capsule
                                        showingCapsuleDetail = true
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                }
            }
            .navigationTitle("📦 我收到的胶囊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "6366F1"))
                        Text("我收到的胶囊")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "6366F1"))
                }
            }
            .sheet(isPresented: $showingCapsuleDetail) {
                if let capsule = selectedCapsule {
                    ReceivedCapsuleDetailView(capsule: capsule)
                }
            }
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text("暂无收到的胶囊")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("家人分享胶囊后，您将在这里看到")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}

struct ReceivedCapsuleRow: View {
    let capsule: ReceivedCapsule
    
    var body: some View {
        HStack(spacing: 12) {
            // 类型图标
            ZStack {
                Circle()
                    .fill(Color(hex: capsule.typeEnum.color).opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: capsule.typeEnum.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: capsule.typeEnum.color))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(capsule.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("来自：\(capsule.senderName)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(formatDate(capsule.sentAt))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 箭头
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm"
            return displayFormatter.string(from: date)
        }
        // 尝试不带毫秒的格式
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm"
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct ReceivedCapsuleDetailView: View {
    let capsule: ReceivedCapsule
    @Environment(\.dismiss) var dismiss
    @State private var showingMediaPlayer = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea(edges: .all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 头部卡片
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: capsule.typeEnum.color).opacity(0.15))
                                    .frame(width: 80, height: 80)
                                Image(systemName: capsule.typeEnum.icon)
                                    .font(.system(size: 36))
                                    .foregroundColor(Color(hex: capsule.typeEnum.color))
                            }
                            
                            Text(capsule.title)
                                .font(.system(size: 22, weight: .bold))
                                .multilineTextAlignment(.center)
                            
                            Text("发送者：\(capsule.senderName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                        
                        // 内容区域
                        VStack(alignment: .leading, spacing: 12) {
                            Text("内容")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            if let content = capsule.content, !content.isEmpty {
                                Text(content)
                                    .font(.body)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                            } else if capsule.mediaUrl != nil || capsule.mediaServerUrl != nil {
                                Button(action: {
                                    showingMediaPlayer = true
                                }) {
                                    HStack {
                                        Image(systemName: capsule.typeEnum.icon)
                                        Text("点击播放\(capsule.typeEnum.rawValue)")
                                        Spacer()
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 30))
                                    }
                                    .padding(16)
                                    .background(Color(hex: capsule.typeEnum.color).opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .foregroundColor(Color(hex: capsule.typeEnum.color))
                            } else {
                                Text("无文字内容")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // 发送时间
                        VStack(alignment: .leading, spacing: 8) {
                            Text("发送时间")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(formatDate(capsule.sentAt))
                                .font(.body)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("胶囊详情")
                        .font(.system(size: 16, weight: .bold))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "6366F1"))
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm:ss"
            return displayFormatter.string(from: date)
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm:ss"
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}
