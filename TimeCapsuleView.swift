//
//  TimeCapsuleView.swift
//  终活
//
//  时光胶囊 - 完整的增删改查
//

import SwiftUI
import AVFoundation
import AVKit

struct TimeCapsuleView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var selectedFilter: TimeCapsule.CapsuleType? = nil
    @State private var showingAddModal = false
    @State private var editingCapsule: TimeCapsule? = nil
    
    var filteredCapsules: [TimeCapsule] {
        dataManager.getFilteredCapsules(type: selectedFilter)
    }
    
    var body: some View {
        NavigationView {
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
                .padding(.top, 16)
            }
            .background(Color(hex: "F5F5F7"))
            .navigationTitle("时光胶囊")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 设置导航栏背景色（兼容 iOS 15+）
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(hex: "6366F1")
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("时光胶囊")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddModal = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "6366F1"))
                    }
                }
            }
            .sheet(isPresented: $showingAddModal) {
                AddCapsuleModal(dataManager: dataManager)
            }
            .sheet(item: $editingCapsule) { capsule in
                EditCapsuleModal(dataManager: dataManager, capsule: capsule)
            }
        }
    }
    
    // MARK: - 统计卡片
    private var statsCard: some View {
        VStack(spacing: 12) {
            // 欢迎语
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
            
            // 统计
            HStack(spacing: 12) {
                StatItem(icon: "capsule.fill", value: "\(dataManager.capsules.count)", label: "全部", color: .white)
                StatItem(icon: "clock.fill", value: "\(dataManager.capsules.filter { !$0.isSent }.count)", label: "待发送", color: .white)
                StatItem(icon: "checkmark.circle.fill", value: "\(dataManager.capsules.filter { $0.isSent }.count)", label: "已发送", color: .white)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color(hex: "6366F1").opacity(0.3), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - 筛选按钮
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterButton(text: "全部", systemImage: "square.grid.2x2", isActive: selectedFilter == nil) {
                    selectedFilter = nil
                }
                
                FilterButton(text: "文字", systemImage: "doc.text.fill", isActive: selectedFilter == .text) {
                    selectedFilter = .text
                }
                
                FilterButton(text: "语音", systemImage: "mic.fill", isActive: selectedFilter == .audio) {
                    selectedFilter = .audio
                }
                
                FilterButton(text: "视频", systemImage: "video.fill", isActive: selectedFilter == .video) {
                    selectedFilter = .video
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - 胶囊列表
    private var capsuleList: some View {
        VStack(spacing: 12) {
            ForEach(filteredCapsules) { capsule in
                CapsuleCard(capsule: capsule, onEdit: {
                    editingCapsule = capsule
                }, onDelete: {
                    dataManager.deleteCapsule(capsule)
                })
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "capsule.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("暂无时光胶囊")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("点击右上角 + 创建您的第一个胶囊")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: { showingAddModal = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("创建胶囊")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(hex: "6366F1"))
                .cornerRadius(12)
            }
        }
        .padding(.vertical, 60)
    }
}

// MARK: - 统计项
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)  // ✅ 图标改为白色
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)  // ✅ 数字改为白色
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.85))  // ✅ 文字改为白色
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 筛选按钮
struct FilterButton: View {
    let text: String
    let systemImage: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(text)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isActive ? Color(hex: "6366F1") : Color.white)
            .foregroundColor(isActive ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isActive ? Color.clear : Color(hex: "E5E5EA"), lineWidth: 1)
            )
            .shadow(color: isActive ? Color(hex: "6366F1").opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - 胶囊卡片
struct CapsuleCard: View {
    let capsule: TimeCapsule
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            Image(systemName: capsule.type.systemImage)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 52, height: 52)
                .background(Color(hex: capsule.type.color).opacity(0.12))
                .foregroundColor(Color(hex: capsule.type.color))
                .cornerRadius(14)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(capsule.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Image(systemName: capsule.isSent ? "checkmark.circle.fill" : "clock.fill")
                        .font(.system(size: 10))
                    Text(formatSendDate(capsule.sendDate))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 删除按钮
            Button(action: { showingDeleteConfirm = true }) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
    
    private func formatSendDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = capsule.isSent ? "yyyy 年 MM 月 dd 日 已发送" : "yyyy 年 MM 月 dd 日 发送"
        return formatter.string(from: date)
    }
}

// MARK: - 添加胶囊弹窗
struct AddCapsuleModal: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var selectedType: TimeCapsule.CapsuleType = .text
    @State private var sendDate = Date()
    @State private var isRecording = false
    @State private var recordedAudioURL: URL?
    @State private var recordedVideoURL: URL?
    @State private var showingRecorder = false
    @State private var showingPlayer = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("类型")) {
                    Picker("类型", selection: $selectedType) {
                        Label("文字", systemImage: "doc.text.fill").tag(TimeCapsule.CapsuleType.text)
                        Label("语音", systemImage: "mic.fill").tag(TimeCapsule.CapsuleType.audio)
                        Label("视频", systemImage: "video.fill").tag(TimeCapsule.CapsuleType.video)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("内容")) {
                    TextField("标题", text: $title)
                    
                    if selectedType == .text {
                        TextEditor(text: $content)
                            .frame(minHeight: 100)
                    } else {
                        VStack(spacing: 12) {
                            // 录制按钮
                            Button(action: {
                                showingRecorder = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedType == .audio ? "mic.fill" : "video.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                    
                                    Text(recordedAudioURL != nil || recordedVideoURL != nil ? "重新录制" : "开始录制")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "6366F1"))
                                .cornerRadius(10)
                            }
                            
                            // 预览按钮（录制完成后显示）
                            if selectedType == .audio, let url = recordedAudioURL {
                                PreviewButton(icon: "mic.fill", title: "已录制音频", url: url, showingPlayer: $showingPlayer)
                            } else if selectedType == .video, let url = recordedVideoURL {
                                PreviewButton(icon: "video.fill", title: "已录制视频", url: url, showingPlayer: $showingPlayer)
                            }
                        }
                        .sheet(isPresented: $showingPlayer) {
                            // 优先使用录制的 URL
                            if let url = recordedAudioURL ?? recordedVideoURL {
                                AVPlayerView(player: AVPlayer(url: url))
                            }
                        }
                    }
                }
                
                Section(header: Text("发送时间")) {
                    DatePicker("发送日期", selection: $sendDate, in: Date()..., displayedComponents: .date)
                }
            }
            .navigationTitle("新建时光胶囊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        Task {
                            await createCapsule()
                        }
                    }
                    .disabled(title.isEmpty || (selectedType != .text && recordedAudioURL == nil && recordedVideoURL == nil))
                }
            }
            .sheet(isPresented: $showingRecorder) {
                MediaRecorderView(
                    type: selectedType,
                    recordedURL: selectedType == .audio ? $recordedAudioURL : $recordedVideoURL
                )
            }
        }
    }
    
    // 🎬 创建胶囊（支持媒体文件持久化和上传）
    @MainActor
    private func createCapsule() async {
        print("🎬 开始创建胶囊...")
        
        var capsuleContent = content
        var mediaURL: String? = nil
        
        // 📁 处理媒体文件（音频/视频）
        if selectedType != .text {
            let mediaFileURL = selectedType == .audio ? recordedAudioURL : recordedVideoURL
            
            if let tempURL = mediaFileURL {
                print("📁 处理媒体文件：\(tempURL.path)")
                print("📁 文件存在：\(FileManager.default.fileExists(atPath: tempURL.path))")
                let tempAttributes = try? FileManager.default.attributesOfItem(atPath: tempURL.path)
                let tempFileSize = tempAttributes?[.size] as? Int ?? 0
                print("📁 文件大小：\(tempFileSize) bytes")
                
                // 1. 移动到持久化目录
                if let permanentURL = await DataManager.shared.persistMediaFile(tempURL) {
                    print("✅ 媒体文件已持久化：\(permanentURL.path)")
                    capsuleContent = permanentURL.absoluteString
                    
                    // 验证持久化后的文件
                    print("📁 持久化文件存在：\(FileManager.default.fileExists(atPath: permanentURL.path))")
                    let permAttributes = try? FileManager.default.attributesOfItem(atPath: permanentURL.path)
                    let permFileSize = permAttributes?[.size] as? Int ?? 0
                    print("📁 持久化文件大小：\(permFileSize) bytes")
                    
                    // 2. 上传到服务器（如果已登录）
                    if UserDefaults.standard.string(forKey: "userToken") != nil {
                        print("☁️ 上传媒体文件到服务器...")
                        if let serverURL = await DataManager.shared.uploadMediaToServer(permanentURL, type: selectedType) {
                            print("✅ 媒体文件已上传：\(serverURL)")
                            mediaURL = serverURL
                        } else {
                            print("⚠️ 上传失败，但本地文件仍可用")
                        }
                    } else {
                        print("⚠️ 未登录，仅保存本地文件")
                    }
                } else {
                    print("❌ 持久化失败，无法创建胶囊")
                    return
                }
            } else {
                print("❌ 未找到媒体文件")
                return
            }
        }
        
        // 3. 创建胶囊
        var capsule = TimeCapsule(
            id: UUID().uuidString,
            title: title,
            content: capsuleContent,
            type: selectedType,
            sendDate: sendDate,
            isSent: false,
            createdAt: Date()
        )
        
        // 4. 保存服务器 URL（如果有）
        if let serverURL = mediaURL {
            capsule.mediaServerURL = serverURL
        }
        
        dataManager.addCapsule(capsule)
        print("✅ 胶囊创建成功：\(capsule.title)")
        dismiss()
    }
}

// MARK: - 预览按钮
struct PreviewButton: View {
    let icon: String
    let title: String
    let url: URL
    @Binding var showingPlayer: Bool
    
    var body: some View {
        Button(action: {
            showingPlayer = true
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.green)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            }
            .padding(12)
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

// MARK: - 编辑胶囊弹窗
struct EditCapsuleModal: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    let capsule: TimeCapsule
    @State private var title: String
    @State private var content: String
    @State private var sendDate: Date
    @State private var showingPlayer = false
    
    init(dataManager: DataManager, capsule: TimeCapsule) {
        self.dataManager = dataManager
        self.capsule = capsule
        _title = State(initialValue: capsule.title)
        _content = State(initialValue: capsule.content)
        _sendDate = State(initialValue: capsule.sendDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("内容")) {
                    TextField("标题", text: $title)
                    
                    if capsule.type == .text {
                        TextEditor(text: $content)
                            .frame(minHeight: 100)
                    } else {
                        // 播放按钮
                        Button(action: {
                            showingPlayer = true
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: capsule.type == .audio ? "waveform" : "film")
                                    .font(.system(size: 20))
                                    .foregroundColor(.green)
                                
                                Text(capsule.type == .audio ? "播放录音" : "播放视频")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                            }
                            .padding(12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        Text("文件路径：\(content)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                }
                
                Section(header: Text("发送时间")) {
                    DatePicker("发送日期", selection: $sendDate, in: Date()..., displayedComponents: .date)
                }
            }
            .navigationTitle("编辑胶囊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        var updated = capsule
                        updated.title = title
                        updated.content = content
                        updated.sendDate = sendDate
                        dataManager.updateCapsule(updated)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPlayer) {
                if let url = parseMediaURL(from: content) {
                    AVPlayerView(player: AVPlayer(url: url))
                }
            }
        }
    }
    
    /// 解析媒体文件 URL
    private func parseMediaURL(from path: String) -> URL? {
        print("🔍 解析媒体文件路径：\(path)")
        
        var url: URL?
        
        // 如果已经是完整 URL，直接返回
        if path.hasPrefix("file://") {
            url = URL(string: path)
            print("📍 使用 file:// URL: \(url?.path ?? "nil")")
        }
        // 如果是绝对路径
        else if path.hasPrefix("/") {
            url = URL(fileURLWithPath: path)
            print("📍 使用绝对路径：\(url?.path ?? "nil")")
        }
        // 如果是相对路径（只包含文件名），构建完整路径
        else {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
            let capsulesFolder = URL(fileURLWithPath: documentsPath).appendingPathComponent("TimeCapsules")
            url = capsulesFolder.appendingPathComponent(path)
            print("📍 构建路径：\(url?.path ?? "nil")")
        }
        
        // 验证文件
        if let url = url {
            let fileExists = FileManager.default.fileExists(atPath: url.path)
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes?[.size] as? Int ?? 0
            let isReadable = FileManager.default.isReadableFile(atPath: url.path)
            
            print("📁 文件验证:")
            print("   - 存在：\(fileExists)")
            print("   - 大小：\(fileSize) bytes")
            print("   - 可读：\(isReadable)")
            
            if !fileExists {
                print("❌ 文件不存在！")
                return nil
            }
            
            if fileSize == 0 {
                print("❌ 文件大小为 0，已损坏！")
                return nil
            }
            
            if !isReadable {
                print("❌ 文件不可读！")
                return nil
            }
            
            print("✅ 文件验证通过")
            return url
        }
        
        return nil
    }
}

#Preview {
    TimeCapsuleView()
}
