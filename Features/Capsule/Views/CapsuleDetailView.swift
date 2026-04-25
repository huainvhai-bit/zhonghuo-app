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
    @State private var showingDeleteAlert = false
    @State private var showingEditView = false
    @State private var showingMediaError = false  // 媒体播放错误提示
    @State private var mediaErrorMessage = ""  // 错误信息
    @State private var playbackItem: PlaybackItem?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
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
        .navigationTitle(L10n.string(.capsuleDetail))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $playbackItem) { item in
            CapsuleMediaPlayerSheet(url: item.url)
        }
        .sheet(isPresented: $showingEditView) {
            NavigationView {
                CapsuleEditView(dataManager: dataManager, existingCapsule: capsule)
            }
        }
        .alert(L10n.string(.deleteCapsule), isPresented: $showingDeleteAlert) {
            Button(L10n.string(.cancel), role: .cancel) {}
            Button(L10n.string(.deleteAction), role: .destructive) {
                deleteCapsule()
            }
        } message: {
            Text(String(format: L10n.string(.deleteCapsuleMessage), capsule.title))
        }
        .alert(L10n.string(.playFailed), isPresented: $showingMediaError) {
            Button(L10n.string(.confirm), role: .cancel) {}
        } message: {
            Text(mediaErrorMessage)
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
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: iconForType(capsule.type))
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(capsule.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 10) {
                        // 类型标签
                        Text(capsule.type.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                        
                        // 状态标签
                        HStack(spacing: 4) {
                            Image(systemName: capsule.isSent ? "checkmark.circle.fill" : "clock.fill")
                                .font(.system(size: 11))
                            Text(capsule.isSent ? L10n.string(.sent) : L10n.string(.pendingSend))
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(capsule.isSent ? .green : .orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(capsule.isSent ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(hex: "6366F1").opacity(0.08), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - 文字内容卡片
    private var textContentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(Color(hex: "6366F1"))
                Text(L10n.string(.textContent))
                    .font(.headline)
            }
            
            Divider()
            
            Text(capsule.content.isEmpty ? L10n.string(.noContent) : capsule.content)
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
                Text(capsule.type == .audio ? L10n.string(.audioContent) : L10n.string(.videoContent))
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            // 播放按钮
            Button(action: playMedia) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: capsule.type == .audio ? "play.fill" : "play.rectangle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.string(.clickToPlay))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(capsule.type == .audio ? L10n.string(.audioContent) : L10n.string(.videoContent))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .padding(16)
                .background(Color(.systemBackground))
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
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Color(hex: "6366F1"))
                Text(L10n.string(.dateInfo))
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 16) {
                // 发送日期
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "6366F1"))
                        Text(L10n.string(.sendDate))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    Text(formatSendDate(capsule.sendDate))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .background(Color.secondary.opacity(0.3))
                    .frame(height: 40)
                
                // 创建日期
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8B5CF6"))
                        Text(L10n.string(.createdDate))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    Text(formatCreateDate(capsule.createdAt))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(hex: "6366F1").opacity(0.08), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - 底部操作按钮
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // 编辑按钮
            Button(action: { showingEditView = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                    Text(L10n.string(.editCapsule))
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "6366F1"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            // 删除按钮
            Button(action: { showingDeleteAlert = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                    Text(L10n.string(.deleteCapsule))
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
        let playbackURL = resolveCapsulePlaybackURL(primary: capsule.mediaURL, fallback: capsule.mediaServerURL)
        
        print("🎬 playMedia: mediaURL=\(capsule.mediaURL), mediaServerURL=\(capsule.mediaServerURL)")
        
        guard let playbackURL else {
            print("❌ 没有可用的媒体地址")
            mediaErrorMessage = "媒体文件不存在或尚未同步"
            showingMediaError = true
            return
        }

        playbackItem = PlaybackItem(url: playbackURL)
        print("🎬 播放器已准备好：\(playbackURL)")
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
        date.chineseDateString()
    }
    
    private func formatCreateDate(_ date: Date) -> String {
        date.chineseDateString()
    }
}

private struct PlaybackItem: Identifiable {
    let id = UUID()
    let url: URL
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
