//
//  Capsule/CapsuleDetailView.swift
//  终活
//
//  时光胶囊详情视图
//  职责：查看/播放胶囊内容
//

import SwiftUI
import AVKit

struct CapsuleDetailView: View {
    @ObservedObject var dataManager: DataManager
    let capsule: TimeCapsule
    @State private var showingPlayer = false
    @State private var player: AVPlayer?
    @State private var showingDeleteAlert = false
    @State private var showingEditView = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F7")
                .ignoresSafeArea(edges: .all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // 顶部信息卡片
                    headerCard
                    
                    // 内容卡片
                    if capsule.type == .text {
                        textContentCard
                    } else {
                        mediaContentCard
                    }
                    
                    // 日期信息
                    dateCard
                    
                    // 底部操作按钮
                    bottomButtons
                        .padding(.top, 20)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("胶囊详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditView = true }) {
                    Image(systemName: "pencil")
                        .foregroundColor(Color(hex: "6366F1"))
                }
            }
        }
        .sheet(isPresented: $showingPlayer) {
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showingEditView) {
            NavigationView {
                CapsuleEditView(dataManager: dataManager, existingCapsule: capsule)
            }
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                deleteCapsule()
            }
        } message: {
            Text("确定要删除胶囊「\(capsule.title)」吗？此操作不可恢复。")
        }
    }
    
    // MARK: - 顶部信息卡片
    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // 类型图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: iconForType(capsule.type))
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(capsule.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        // 类型标签
                        Text(capsule.type.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "6366F1"))
                            .cornerRadius(10)
                        
                        // 状态标签
                        HStack(spacing: 4) {
                            Image(systemName: capsule.isSent ? "checkmark.circle.fill" : "clock.fill")
                                .font(.system(size: 12))
                            Text(capsule.isSent ? "已发送" : "待发送")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(capsule.isSent ? .green : .orange)
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(hex: "6366F1").opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 文字内容卡片
    private var textContentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(Color(hex: "6366F1"))
                Text("文字内容")
                    .font(.headline)
            }
            
            Divider()
            
            Text(capsule.content.isEmpty ? "（无内容）" : capsule.content)
                .font(.system(size: 16))
                .foregroundColor(capsule.content.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(hex: "6366F1").opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 媒体内容卡片（视频/语音）
    private var mediaContentCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: capsule.type == .audio ? "mic.fill" : "video.fill")
                    .foregroundColor(Color(hex: "6366F1"))
                Text(capsule.type == .audio ? "语音内容" : "视频内容")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            // 播放按钮
            Button(action: playMedia) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "6366F1"))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: capsule.type == .audio ? "play.fill" : "play.rectangle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("点击播放")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(capsule.type == .audio ? "语音" : "视频")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color(hex: "F5F5F7"))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(hex: "6366F1").opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 日期卡片
    private var dateCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Color(hex: "6366F1"))
                Text("日期信息")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("发送日期")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text(formatSendDate(capsule.sendDate))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("创建日期")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text(formatCreateDate(capsule.createdAt))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(hex: "6366F1").opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 底部操作按钮
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // 删除按钮（放在最下方）
            Button(action: { showingDeleteAlert = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                    Text("删除胶囊")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 操作方法
    private func playMedia() {
        var mediaPath = capsule.mediaURL
        
        // 处理相对路径
        if !mediaPath.isEmpty && !mediaPath.hasPrefix("/") {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            mediaPath = documentsPath.appendingPathComponent(mediaPath).path
        }
        
        guard !mediaPath.isEmpty else {
            return
        }
        
        let fileURL = URL(fileURLWithPath: mediaPath)
        
        guard FileManager.default.fileExists(atPath: mediaPath) else {
            print("⚠️ 媒体文件不存在：\(mediaPath)")
            return
        }
        
        player = AVPlayer(url: fileURL)
        showingPlayer = true
        print("🎬 播放媒体：\(fileURL)")
    }
    
    private func deleteCapsule() {
        dataManager.capsules.removeAll { $0.id == capsule.id }
        dataManager.saveCapsulesToFile()
        
        Task {
            await dataManager.batchSyncCapsules()
        }
        
        dismiss()
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
        formatter.dateFormat = "yyyy 年 MM 月 dd 日"
        return formatter.string(from: date)
    }
    
    private func formatCreateDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 MM 月 dd 日"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        CapsuleDetailView(
            dataManager: DataManager.shared,
            capsule: TimeCapsule(
                id: UUID().uuidString,
                title: "测试胶囊",
                content: "测试内容",
                type: .video,
                sendDate: Date(),
                isSent: false,
                createdAt: Date()
            )
        )
    }
}
