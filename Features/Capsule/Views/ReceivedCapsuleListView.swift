//
//  ReceivedCapsuleListView.swift
//  终活
//
//  我收到的时光胶囊列表
//

import SwiftUI
import AVKit

struct ReceivedCapsuleListView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedCapsule: ReceivedCapsule? = nil
    
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
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                }
            }
            .navigationTitle(L10n.text("我收到的胶囊", en: "Received Capsules", ja: "受け取ったカプセル", ko: "받은 캡슐"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "6366F1"))
                        Text(L10n.text("我收到的胶囊", en: "Received Capsules", ja: "受け取ったカプセル", ko: "받은 캡슐"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.string(.done)) {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "6366F1"))
                }
            }
            .sheet(item: $selectedCapsule, onDismiss: {
                selectedCapsule = nil
            }) { capsule in
                ReceivedCapsuleDetailView(capsule: capsule)
            }
        }
        .stackNavigationStyle()
    }
    
    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text(L10n.text("暂无收到的胶囊", en: "No received capsules yet", ja: "まだ受け取ったカプセルはありません", ko: "아직 받은 캡슐이 없습니다"))
                .font(.headline)
                .foregroundColor(.secondary)
            Text(L10n.text("家人分享胶囊后，您将在这里看到", en: "Capsules shared by family will appear here.", ja: "家族が共有したカプセルはここに表示されます。", ko: "가족이 공유한 캡슐이 여기에 표시됩니다."))
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
                    Text(L10n.text("来自：\(capsule.senderName)", en: "From: \(capsule.senderName)", ja: "送信元：\(capsule.senderName)", ko: "발신: \(capsule.senderName)"))
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
            return date.chineseDateTimeString()
        }
        // 尝试不带毫秒的格式
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date.chineseDateTimeString()
        }
        return dateString
    }

}

struct ReceivedCapsuleDetailView: View {
    let capsule: ReceivedCapsule
    @Environment(\.dismiss) var dismiss
    @State private var playbackItem: ReceivedCapsulePlaybackItem?
    
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
                            
                            Text(L10n.text("发送者：\(capsule.senderName)", en: "Sender: \(capsule.senderName)", ja: "送信者：\(capsule.senderName)", ko: "보낸 사람: \(capsule.senderName)"))
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
                            Text(L10n.string(.textContent))
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
                                    prepareMediaPlayer()
                                }) {
                                    HStack {
                                        Image(systemName: capsule.typeEnum.icon)
                                        Text(L10n.text("点击播放\(capsule.typeEnum.rawValue)", en: "Tap to play \(capsule.typeEnum.rawValue)", ja: "\(capsule.typeEnum.rawValue)をタップして再生", ko: "\(capsule.typeEnum.rawValue)를 탭하여 재생"))
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
                                Text(L10n.text("无文字内容", en: "No text content", ja: "テキスト内容なし", ko: "텍스트 내용 없음"))
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
                            Text(L10n.string(.sendDate))
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
                    Text(L10n.string(.capsuleDetail))
                        .font(.system(size: 16, weight: .bold))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.string(.close)) {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "6366F1"))
                }
            }
            .sheet(item: $playbackItem) { item in
                CapsuleMediaPlayerSheet(url: item.url)
            }
        }
        .stackNavigationStyle()
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date.chineseDateTimeSecondString()
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date.chineseDateTimeSecondString()
        }
        return dateString
    }

    private func prepareMediaPlayer() {
        guard let url = resolveCapsulePlaybackURL(primary: capsule.mediaUrl, fallback: capsule.mediaServerUrl) else {
            return
        }
        playbackItem = ReceivedCapsulePlaybackItem(url: url)
    }
}

private struct ReceivedCapsulePlaybackItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct CapsuleMediaPlayerSheet: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player {
                CapsuleVideoPlayerContainer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView(L10n.text("正在加载播放器", en: "Loading player", ja: "プレーヤーを読み込み中", ko: "플레이어 로딩 중"))
                    .foregroundColor(.white)
                    .tint(.white)
            }
        }
        .onAppear {
            if player == nil {
                let loadedPlayer = AVPlayer(url: url)
                player = loadedPlayer
                loadedPlayer.play()
            }
        }
        .onDisappear {
            player?.pause()
        }
    }
}

struct CapsuleVideoPlayerContainer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVKit.AVPlayerViewController {
        let controller = AVKit.AVPlayerViewController()
        controller.player = player
        controller.videoGravity = .resizeAspect
        controller.allowsPictureInPicturePlayback = false
        return controller
    }

    func updateUIViewController(_ uiViewController: AVKit.AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

func resolveCapsulePlaybackURL(primary: String?, fallback: String? = nil) -> URL? {
    let candidates = [primary, fallback]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    for rawString in candidates {
        if rawString.hasPrefix("http://") || rawString.hasPrefix("https://") {
            if let remoteURL = URL(string: rawString) {
                return remoteURL
            }
            continue
        }

        if rawString.hasPrefix("/uploads/") || rawString.hasPrefix("uploads/") {
            let cleaned = rawString.hasPrefix("/") ? String(rawString.dropFirst()) : rawString
            let base = DataManager.apiURL.trimmingCharacters(in: .whitespacesAndNewlines)
            if !base.isEmpty {
                return URL(string: "\(base)/\(cleaned)")
            }
        }

        if rawString.contains("Documents/TimeCapsules") {
            let localURL = URL(fileURLWithPath: rawString)
            if FileManager.default.fileExists(atPath: localURL.path) {
                return localURL
            }
            continue
        }

        if rawString.hasPrefix("/") {
            let localURL = documentsPath.appendingPathComponent(String(rawString.dropFirst()))
            if FileManager.default.fileExists(atPath: localURL.path) {
                return localURL
            }
            continue
        }

        let localURL = documentsPath.appendingPathComponent(rawString)
        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }

        if let remoteURL = URL(string: rawString) {
            return remoteURL
        }
    }

    return nil
}
