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
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F7")
                .ignoresSafeArea(edges: .all)
            
            ScrollView {
                VStack(spacing: 16) {
                    // 胶囊信息卡片
                    infoCard
                    
                    // 内容卡片
                    contentCard
                    
                    // 操作按钮
                    actionButtons
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("胶囊详情")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPlayer) {
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private var infoCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // 类型图标
                Image(systemName: iconForType(capsule.type))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(capsule.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        Label(capsule.type.rawValue, systemImage: iconForType(capsule.type))
                            .font(.system(size: 12))
                        
                        Image(systemName: capsule.isSent ? "checkmark.circle.fill" : "clock.fill")
                            .font(.system(size: 12))
                        Text(capsule.isSent ? "已发送" : "待发送")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("发送日期")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(formatSendDate(capsule.sendDate))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("创建日期")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(formatCreateDate(capsule.createdAt))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(hex: "6366F1").opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("内容")
                .font(.headline)
                .foregroundColor(.primary)
            
            if capsule.type == .text {
                Text(capsule.content)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if capsule.type == .audio || capsule.type == .video {
                // ✅ Bug 2 修复：显示播放按钮
                Button(action: playMedia) {
                    HStack(spacing: 12) {
                        Image(systemName: capsule.type == .audio ? "play.circle.fill" : "play.rectangle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                        
                        Text("播放\(capsule.type == .audio ? "语音" : "视频")")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "6366F1"))
                    .cornerRadius(10)
                }
            } else {
                Text(capsule.content)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(hex: "6366F1").opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // ✅ 删除按钮
            Button(action: deleteCapsule) {
                Label("删除胶囊", systemImage: "trash.fill")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red)
                    .cornerRadius(10)
            }
        }
    }
    
    private func playMedia() {
        // ✅ Bug 2 修复：播放视频/语音
        guard let mediaPath = capsule.mediaPath, !mediaPath.isEmpty else {
            alertMessage = "没有找到媒体文件"
            showingAlert = true
            return
        }
        
        let fileURL = URL(fileURLWithPath: mediaPath)
        
        if !FileManager.default.fileExists(atPath: mediaPath) {
            alertMessage = "媒体文件不存在：\(mediaPath)"
            showingAlert = true
            return
        }
        
        if capsule.type == .video {
            player = AVPlayer(url: fileURL)
            showingPlayer = true
            print("🎥 播放视频：\(fileURL)")
        } else if capsule.type == .audio {
            player = AVPlayer(url: fileURL)
            showingPlayer = true
            print("🎵 播放语音：\(fileURL)")
        }
    }
    
    private func deleteCapsule() {
        dataManager.capsules.removeAll { $0.id == capsule.id }
        dataManager.saveCapsulesToFile()
        
        Task {
            await dataManager.batchSyncCapsules()
        }
        
        dismiss()
    }
    
    private func dismiss() {
        // 返回上一页
        NotificationCenter.default.post(name: NSNotification.Name("CapsuleDeleted"), object: nil)
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
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        CapsuleDetailView(
            dataManager: DataManager.shared,
            capsule: TimeCapsule(
                id: UUID(),
                title: "测试胶囊",
                type: .video,
                content: "测试内容",
                sendDate: Date(),
                mediaPath: "",
                createdAt: Date()
            )
        )
    }
}
