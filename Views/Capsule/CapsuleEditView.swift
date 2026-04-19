//
//  Capsule/CapsuleEditView.swift
//  终活
//
//  时光胶囊编辑视图
//  职责：添加/编辑胶囊
//

import SwiftUI
import AVFoundation
import AVKit

struct CapsuleEditView: View {
    @ObservedObject var dataManager: DataManager
    var existingCapsule: TimeCapsule? = nil  // ✅ Bug 修复：添加编辑模式支持
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
    @State private var showingUpgradePrompt = false  // ✅ 升级提示
    @State private var upgradePromptMessage = ""  // ✅ 升级提示信息
    @State private var showingMembershipView = false  // ✅ 会员页面
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var useFrontCamera = true  // ✅ Bug 1: 默认前置摄像头
    @State private var showCameraOptions = false  // ✅ Bug 1: 显示摄像头选项
    @State private var isSaving = false  // ✅ 防止重复保存
    
    var body: some View {
        ZStack {
            // ✅ UI 统一：背景色与其他界面一致
            Color(hex: "F5F5F7")
                .ignoresSafeArea(edges: .all)
            
            ScrollView {
                VStack(spacing: 16) {
                    // 类型卡片（编辑模式只显示当前类型，不允许修改）
                    VStack(alignment: .leading, spacing: 12) {
                        Text("胶囊类型")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        if existingCapsule != nil {
                            // 编辑模式：只显示当前类型
                            HStack {
                                Image(systemName: iconForType(existingCapsule!.type))
                                    .foregroundColor(Color(hex: "6366F1"))
                                Text(existingCapsule!.type.rawValue)
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                                Text("不可修改")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(Color(hex: "6366F1").opacity(0.1))
                            .cornerRadius(10)
                        } else {
                            // 新建模式：显示类型选择器
                            Picker("类型", selection: $selectedType) {
                                Label("文字", systemImage: "doc.text.fill").tag(TimeCapsule.CapsuleType.text)
                                Label("语音", systemImage: "mic.fill").tag(TimeCapsule.CapsuleType.audio)
                                Label("视频", systemImage: "video.fill").tag(TimeCapsule.CapsuleType.video)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: selectedType) { newType in
                                // ✅ 检查媒体胶囊数量限制
                                if newType == .audio || newType == .video {
                                    let membership = MembershipManager.shared
                                    let currentMediaCount = dataManager.capsules.filter { $0.type == .audio || $0.type == .video }.count
                                    if !membership.canCreateMediaCapsule(currentMediaCount: currentMediaCount) {
                                        upgradePromptMessage = "语音/视频胶囊已达上限（\(currentMediaCount)/\(membership.maxMediaCapsules)），升级会员可享受更多"
                                        showingUpgradePrompt = true
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "6366F1").opacity(0.06), radius: 10, x: 0, y: 3)
                    .padding(.horizontal, 16)
                    
                    // 内容卡片
                    VStack(alignment: .leading, spacing: 12) {
                        Text("内容")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        TextField("请输入标题", text: $title)
                            .padding(14)
                            .background(Color(hex: "F5F5F7"))
                            .cornerRadius(10)
                        
                        if selectedType == .text {
                            TextEditor(text: $content)
                                .frame(minHeight: 150)
                                .padding(12)
                                .background(Color(hex: "F2F2F7"))
                                .cornerRadius(8)
                        } else {
                            // ✅ 修复：视频/语音录制按钮
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    // 录制入口按钮
                                    Button(action: { showingRecorder = true }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: selectedType == .audio ? "mic.fill" : "video.fill")
                                                .font(.system(size: 18))
                                            Text("录制\(selectedType == .audio ? "语音" : "视频")")
                                                .font(.system(size: 15, weight: .medium))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(Color(hex: "6366F1"))
                                        .cornerRadius(25)
                                    }
                                    
                                    // 已录制：播放按钮
                                    if selectedType == .audio, let _ = recordedAudioURL {
                                        Button(action: { showingPlayer = true }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "play.fill").font(.system(size: 14))
                                                Text("播放").font(.system(size: 14, weight: .medium))
                                            }
                                            .foregroundColor(Color(hex: "6366F1"))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color(hex: "6366F1").opacity(0.1))
                                            .cornerRadius(20)
                                        }
                                    } else if selectedType == .video, let _ = recordedVideoURL {
                                        Button(action: { showingPlayer = true }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "play.fill").font(.system(size: 14))
                                                Text("播放").font(.system(size: 14, weight: .medium))
                                            }
                                            .foregroundColor(Color(hex: "6366F1"))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color(hex: "6366F1").opacity(0.1))
                                            .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "6366F1").opacity(0.06), radius: 10, x: 0, y: 3)
                    .padding(.horizontal, 16)
                    
                    // 发送时间卡片
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(Color(hex: "6366F1"))
                            Text("发送时间")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        
                        DatePicker("发送日期", selection: $sendDate)
                            .datePickerStyle(.compact)
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "6366F1").opacity(0.06), radius: 10, x: 0, y: 3)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            // ✅ Bug 修复：编辑模式下加载已有胶囊数据
            if let existingCapsule = existingCapsule {
                title = existingCapsule.title
                content = existingCapsule.content
                selectedType = existingCapsule.type
                sendDate = existingCapsule.sendDate
                
                // ✅ Bug 修复：加载已有胶囊的媒体文件
                if !existingCapsule.mediaURL.isEmpty {
                    var mediaPath = existingCapsule.mediaURL
                    
                    // ✅ 修复：正确的路径处理逻辑（与 CapsuleDetailView 一致）
                    if mediaPath.contains("Documents/TimeCapsules") {
                        // 旧数据：已经是完整的Documents路径，直接使用
                        print("📍 使用旧数据路径：\(mediaPath)")
                    } else if mediaPath.hasPrefix("/") {
                        // 新数据格式：/TimeCapsules/xxx
                        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        mediaPath = documentsPath.path + mediaPath
                    } else {
                        // 纯相对路径
                        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        mediaPath = documentsPath.appendingPathComponent(mediaPath).path
                    }
                    
                    let mediaURL = URL(fileURLWithPath: mediaPath)
                    if FileManager.default.fileExists(atPath: mediaPath) {
                        if existingCapsule.type == .audio {
                            recordedAudioURL = mediaURL
                        } else if existingCapsule.type == .video {
                            recordedVideoURL = mediaURL
                        }
                        print("✅ 加载已有媒体文件：\(mediaURL.path)")
                    } else {
                        print("⚠️ 媒体文件不存在：\(mediaURL.path)")
                    }
                }
            }
        }
        .navigationTitle(existingCapsule == nil ? "新增胶囊" : "编辑胶囊")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // ✅ 取消按钮（左上角）
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            
            // ✅ 保存按钮（右上角）
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "保存中..." : "保存") {
                    guard !isSaving else { return }
                    print("🔵 保存按钮被点击")
                    if validateCapsule() {
                        print("🔵 验证通过，开始保存")
                        isSaving = true
                        saveCapsule()
                    }
                }
                .disabled(title.isEmpty || (selectedType == .text && content.isEmpty) || isSaving)
            }
        }
        .sheet(isPresented: $showingRecorder) {
            CapsuleMediaRecorderView(selectedType: selectedType, onRecordComplete: { url in
                if selectedType == .audio {
                    recordedAudioURL = url
                } else {
                    recordedVideoURL = url
                }
                showingRecorder = false
            })
        }
        .sheet(isPresented: $showingPlayer) {
            if let url = recordedAudioURL ?? recordedVideoURL {
                playerView(for: url)
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingUpgradePrompt) {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                MediaCapsuleLimitPromptView(
                    currentCount: dataManager.capsules.filter { $0.type == .audio || $0.type == .video }.count,
                    onUpgrade: {
                        showingUpgradePrompt = false
                        showingMembershipView = true
                    },
                    onCancel: {
                        showingUpgradePrompt = false
                        selectedType = .text  // 切换回文字类型
                    }
                )
            }
        }
        .sheet(isPresented: $showingMembershipView) {
            NavigationView {
                MembershipView()
            }
        }
    }
    
    // ✅ 添加验证方法
    private func validateCapsule() -> Bool {
        if title.isEmpty {
            alertMessage = "请输入标题"
            showingAlert = true
            return false
        }
        
        if selectedType == .text && content.isEmpty {
            alertMessage = "请输入内容"
            showingAlert = true
            return false
        }
        
        if (selectedType == .audio && recordedAudioURL == nil) ||
           (selectedType == .video && recordedVideoURL == nil) {
            alertMessage = "请先录制\(selectedType == .audio ? "语音" : "视频")"
            showingAlert = true
            return false
        }
        
        return true
    }
    
    private func saveCapsule() {
        Task {
            var mediaServerUrl: String? = nil
            var localMediaPath: String = ""  // ✅ Bug 修复：保存相对路径
            
            print("🔵 saveCapsule 开始: selectedType=\(selectedType), recordedAudioURL=\(recordedAudioURL?.absoluteString ?? "nil"), recordedVideoURL=\(recordedVideoURL?.absoluteString ?? "nil")")
            
            // 📤 上传媒体文件到服务器
            if let audioURL = recordedAudioURL {
                print("📤 开始上传音频: \(audioURL)")
                mediaServerUrl = await DataManager.shared.uploadMediaToServer(audioURL, type: .audio)
                print("📤 音频上传结果：\(mediaServerUrl ?? "失败")")
                // ✅ Bug 修复：保存相对路径（避免 iOS sandbox 变化导致无法播放）
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
                localMediaPath = audioURL.path.replacingOccurrences(of: documentsPath, with: "")
            } else if let videoURL = recordedVideoURL {
                print("📤 开始上传视频: \(videoURL)")
                mediaServerUrl = await DataManager.shared.uploadMediaToServer(videoURL, type: .video)
                print("📤 视频上传结果：\(mediaServerUrl ?? "失败")")
                // ✅ Bug 修复：保存相对路径
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
                localMediaPath = videoURL.path.replacingOccurrences(of: documentsPath, with: "")
            } else {
                print("⚠️ 没有录制文件（recordedAudioURL 和 recordedVideoURL 都是 nil）")
            }
            
            let capsule = TimeCapsule(
                id: existingCapsule?.id ?? UUID().uuidString,  // ✅ Bug 修复：编辑模式使用原 ID
                title: title,
                content: content,
                type: selectedType,
                mediaURL: localMediaPath.isEmpty ? (existingCapsule?.mediaURL ?? "") : localMediaPath,  // ✅ 保留原有本地路径
                mediaServerURL: mediaServerUrl ?? existingCapsule?.mediaServerURL ?? "",  // ✅ 保留原有服务器URL
                sendDate: sendDate,
                isSent: existingCapsule?.isSent ?? false,
                createdAt: existingCapsule?.createdAt ?? Date()  // ✅ 修复：编辑模式保持原创建时间
            )
            
            print("🔵 保存胶囊：id=\(capsule.id), title=\(capsule.title), 编辑模式=\(existingCapsule != nil ? "是" : "否")")
            
            // ✅ Bug 修复：编辑模式更新，新增模式添加
            if existingCapsule != nil {
                print("🔵 更新胶囊")
                dataManager.updateCapsule(capsule)
            } else {
                print("🔵 添加胶囊")
                dataManager.addCapsule(capsule)
            }
            
            // 📢 通知同步到服务器
            NotificationCenter.default.post(name: NSNotification.Name("CapsuleChanged"), object: nil)
            
            // 📤 同步到云端
            _ = await dataManager.batchSyncCapsules()
            
            // ✅ 防止重复保存：保存完成后重置状态
            isSaving = false
            dismiss()
        }
    }
    
    /// 根据胶囊类型返回图标名称
    private func iconForType(_ type: TimeCapsule.CapsuleType) -> String {
        switch type {
        case .text: return "doc.text.fill"
        case .audio, .voice: return "mic.fill"
        case .video, .image, .sticker: return "video.fill"
        @unknown default: return "capsule.fill"
        }
    }
    
    private func playerView(for url: URL) -> AnyView {
        // ✅ Bug 修复：处理相对路径
        let absoluteURL: URL
        if url.path.hasPrefix("/") && !url.path.contains("Documents") {
            // 旧数据：绝对路径但 sandbox 已变化
            absoluteURL = url
        } else if url.path.hasPrefix("/") {
            // 新数据：相对路径，需要转换
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            absoluteURL = documentsPath.appendingPathComponent(String(url.path.dropFirst()))
        } else {
            absoluteURL = url
        }
        
        if FileManager.default.fileExists(atPath: absoluteURL.path) {
            let player = AVPlayer(url: absoluteURL)
            player.actionAtItemEnd = .none
            player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            
            return AnyView(
                AVPlayerView(player: player)
                    .onAppear { player.play() }
            )
        } else {
            return AnyView(
                VStack(spacing: 16) {
                    Image(systemName: "player.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text("媒体文件无法播放")
                        .font(.headline)
                    Text("文件路径：\(absoluteURL.path)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            )
        }
    }
}

// MARK: - 媒体录制视图（✅ 修复：支持视频和语音录制）
struct CapsuleMediaRecorderView: View {
    let selectedType: TimeCapsule.CapsuleType
    @Environment(\.dismiss) var dismiss
    @StateObject var recorder = MediaRecorder()
    let onRecordComplete: (URL) -> Void  // ✅ 修复：闭包不能用 @State
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showingPermissionAlert = false
    @State private var showCameraPreview = false
    @State private var useFrontCamera = true  // ✅ 新增：跟踪摄像头方向
    
    // 会员时长限制
    private var maxRecordingSeconds: Int {
        MembershipManager.shared.maxVideoRecordingSeconds()
    }
    
    // 是否显示倒计时模式
    private var isCountdownMode: Bool {
        // 只有媒体胶囊（语音/视频）才有时长限制
        return selectedType != .text && maxRecordingSeconds > 0
    }
    
    var body: some View {
        ZStack {
            // 背景色
            Color.black
                .ignoresSafeArea(edges: .all)
            
            // ✅ 视频模式下显示摄像头预览
            if selectedType == .video {
                CameraPreviewView(session: recorder.captureSession)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // 顶部工具栏
                topToolbar
                
                Spacer()
                
                // 中间录制状态
                centerContent
                
                Spacer()
                
                // 底部录制控制栏
                bottomControls
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            // ✅ Bug 1 修复：视频模式下立即初始化摄像头
            if selectedType == .video {
                showCameraPreview = true
                // ✅ 调用 setupCameraForVideo 初始化摄像头（默认前置）
                recorder.setupCameraForVideo(useFrontCamera: useFrontCamera)
            }
        }
        .navigationTitle(selectedType == .audio ? "录制语音" : "录制视频")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    if recorder.isRecording {
                        recorder.stopRecording()
                    }
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
        .alert("需要访问权限", isPresented: $showingPermissionAlert) {
            Button("取消", role: .cancel) { dismiss() }
            Button("去设置") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
        } message: {
            Text(selectedType == .audio ? "请允许访问麦克风" : "请允许访问相机和麦克风")
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // MARK: - 顶部工具栏
    private var topToolbar: some View {
        HStack {
            // 取消按钮
            Button(action: {
                if recorder.isRecording {
                    recorder.stopRecording()
                }
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // 摄像头切换按钮（仅视频模式，且未在录制时显示）
            if selectedType == .video && !recorder.isRecording {
                Button(action: switchCamera) {
                    Image(systemName: "camera.rotate.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    // MARK: - 中间内容
    private var centerContent: some View {
        VStack(spacing: 20) {
            if recorder.isRecording {
                // 录制中状态
                Image(systemName: "record.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("录制中...")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                // ✅ 时长显示：倒计时模式或计时模式
                Group {
                    if isCountdownMode {
                        // 倒计时模式
                        let remaining = max(0, maxRecordingSeconds - Int(recordingTime))
                        Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                            .foregroundColor(remaining < 10 ? .orange : .white)
                    } else {
                        // 计时模式
                        Text(String(format: "%02d:%02d", Int(recordingTime) / 60, Int(recordingTime) % 60))
                            .foregroundColor(.white)
                    }
                }
                .font(.system(size: 36, weight: .bold))
                .monospacedDigit()
                
                // 显示会员时长限制提示
                if isCountdownMode && !MembershipManager.shared.isPremium {
                    Text("升级会员可录制\(MembershipManager.Limits.premiumMaxVideoMinutes)分钟")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
            } else {
                // 待机状态
                Image(systemName: selectedType == .audio ? "mic.fill" : "video.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("点击下方按钮开始录制")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    // MARK: - 底部控制栏
    private var bottomControls: some View {
        VStack(spacing: 24) {
            // 录制按钮
            Button(action: {
                if recorder.isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                ZStack {
                    // 外圈
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    // 内圈
                    Circle()
                        .fill(recorder.isRecording ? Color.red : Color.white)
                        .frame(width: recorder.isRecording ? 32 : 64, height: recorder.isRecording ? 32 : 64)
                        .animation(.easeInOut(duration: 0.2), value: recorder.isRecording)
                }
            }
            
            Text(recorder.isRecording ? "点击停止" : "长按录制")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - 切换摄像头
    private func switchCamera() {
        useFrontCamera.toggle()
        recorder.switchCamera(useFront: useFrontCamera)
        print("📷 切换到\(useFrontCamera ? "前置" : "后置")摄像头")
    }
    
    private func startRecording() {
        print("🎥 开始录制，类型：\(selectedType)")
        
        // ✅ 检查权限
        if selectedType == .video {
            print("🎥 请求视频权限...")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                print("🎥 视频权限：\(granted ? "已允许" : "已拒绝")")
                if granted {
                    print("🎥 请求音频权限...")
                    AVCaptureDevice.requestAccess(for: .audio) { granted in
                        print("🎥 音频权限：\(granted ? "已允许" : "已拒绝")")
                        if granted {
                            DispatchQueue.main.async {
                                print("🎥 开始启动录制...")
                                recorder.startRecording(type: .video)
                                startTimer()
                            }
                        } else {
                            DispatchQueue.main.async {
                                showingPermissionAlert = true
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        showingPermissionAlert = true
                    }
                }
            }
        } else {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    DispatchQueue.main.async {
                        recorder.startRecording(type: .audio)
                        startTimer()
                    }
                } else {
                    DispatchQueue.main.async {
                        showingPermissionAlert = true
                    }
                }
            }
        }
    }
    
    private func stopRecording() {
        timer?.invalidate()
        
        // ✅ 根据类型停止录制
        if selectedType == .video {
            // 视频录制：使用回调机制（解决异步时序问题）
            // 注意：CapsuleMediaRecorderView 是 struct，不需要 weak self
            let onComplete = onRecordComplete
            recorder.onVideoRecordingComplete = { [dismiss] url in
                DispatchQueue.main.async {
                    onComplete(url)
                    dismiss()
                }
            }
            recorder.stopRecording()
        } else {
            // 音频录制：同步完成
            recorder.stopRecording()
            if let url = recorder.recordingURL {
                onRecordComplete(url)
                dismiss()
            }
        }
    }
    
    private func startTimer() {
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            self.recordingTime += 1
            
            // ✅ 达到最大时长时自动停止
            if self.isCountdownMode && Int(self.recordingTime) >= self.maxRecordingSeconds {
                print("⏱️ 达到最大录制时长 \(self.maxRecordingSeconds) 秒，自动停止")
                self.stopRecording()
            }
        }
    }
}

// MARK: - MediaRecorder 类（✅ 修复：支持视频和语音录制）
class MediaRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingURL: URL?
    @Published var captureSession: AVCaptureSession?  // ✅ 公开 captureSession 用于预览
    private var audioRecorder: AVAudioRecorder?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // ✅ 新增：视频录制完成回调（解决异步时序问题）
    var onVideoRecordingComplete: ((URL) -> Void)?
    
    enum RecordingType {
        case audio
        case video
    }
    
    // ✅ Bug 1 修复：初始化摄像头（在视图出现时调用，支持前后切换）
    func setupCameraForVideo(useFrontCamera: Bool = true) {
        guard captureSession == nil else { return }  // 已初始化
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession = AVCaptureSession()
            self.captureSession?.sessionPreset = .high
            
            // ✅ Bug 1: 根据参数选择前置或后置摄像头
            let cameraPosition: AVCaptureDevice.Position = useFrontCamera ? .front : .back
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
                  let audioDevice = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
                  let captureSession = self.captureSession,
                  captureSession.canAddInput(videoInput),
                  captureSession.canAddInput(audioInput) else {
                print("❌ 无法初始化摄像头（前置=\(useFrontCamera)）")
                return
            }
            
            captureSession.addInput(videoInput)
            captureSession.addInput(audioInput)
            
            self.videoOutput = AVCaptureMovieFileOutput()
            if captureSession.canAddOutput(self.videoOutput!) {
                captureSession.addOutput(self.videoOutput!)
            }
            
            // ✅ 启动 session（但不开始录制）
            captureSession.startRunning()
            print("🎥 摄像头已初始化并启动（前置=\(useFrontCamera)）")
        }
    }
    
    // ✅ 新增：切换前后摄像头
    func switchCamera(useFront: Bool) {
        guard let captureSession = captureSession else {
            print("⚠️ captureSession 未初始化")
            return
        }
        
        // 停止当前录制
        if videoOutput?.isRecording == true {
            videoOutput?.stopRecording()
        }
        
        // 移除所有输入
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        
        // 获取新摄像头
        let cameraPosition: AVCaptureDevice.Position = useFront ? .front : .back
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let audioDevice = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
            print("❌ 无法获取摄像头（前置=\(useFront)）")
            return
        }
        
        // 添加新输入
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        if captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }
        
        print("📷 摄像头已切换（前置=\(useFront)）")
    }
    
    func startRecording(type: RecordingType) {
        if type == .video {
            startVideoRecording()
        } else {
            startAudioRecording()
        }
    }
    
    private func startAudioRecording() {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [])
        try? session.setActive(true)
        
        // ✅ 创建 TimeCapsules 目录
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timeCapsulesDir = documentsPath.appendingPathComponent("TimeCapsules")
        try? FileManager.default.createDirectory(at: timeCapsulesDir, withIntermediateDirectories: true)
        
        let fileName = UUID().uuidString + ".m4a"
        let filePath = timeCapsulesDir.appendingPathComponent(fileName)
        
        do {
            audioRecorder = try AVAudioRecorder(url: filePath, settings: settings)
            audioRecorder?.record()
            isRecording = true
            print("✅ 开始录制音频：\(filePath)")
        } catch {
            print("❌ 音频录制失败：\(error)")
        }
    }
    
    private func startVideoRecording() {
        // ✅ 使用已初始化的 captureSession（由 setupCameraForVideo 创建）
        guard let videoOutput = videoOutput else {
            print("❌ 摄像头未初始化，无法录制")
            return
        }
        
        // ✅ 创建 TimeCapsules 目录
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timeCapsulesDir = documentsPath.appendingPathComponent("TimeCapsules")
        try? FileManager.default.createDirectory(at: timeCapsulesDir, withIntermediateDirectories: true)
        
        let fileName = UUID().uuidString + ".mp4"
        let filePath = timeCapsulesDir.appendingPathComponent(fileName)
        recordingURL = filePath
        
        // ✅ 开始录制
        videoOutput.startRecording(to: filePath, recordingDelegate: self)
        isRecording = true
        print("✅ 开始录制视频：\(filePath)")
    }
    
    func stopRecording() {
        if let videoOutput = videoOutput, videoOutput.isRecording {
            videoOutput.stopRecording()
            captureSession?.stopRunning()
            print("🎥 停止视频录制")
        } else if let audioRecorder = audioRecorder, audioRecorder.isRecording {
            audioRecorder.stop()
            recordingURL = audioRecorder.url  // ✅ Bug 3 修复：保存语音文件 URL
            print("🎵 停止语音录制：\(recordingURL?.absoluteString ?? "nil")")
        } else {
            print("⚠️ 没有在录制的媒体")
        }
        isRecording = false
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension MediaRecorder: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                print("❌ 视频录制失败：\(error)")
            } else {
                print("✅ 视频录制成功：\(outputFileURL)")
                self?.recordingURL = outputFileURL
                // ✅ 触发回调通知录制完成
                if let url = self?.recordingURL {
                    self?.onVideoRecordingComplete?(url)
                }
            }
        }
    }
}

// MARK: - 摄像头预览视图
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        print("🎥 CameraPreviewView.makeUIView: session=\(session != nil ? "已设置" : "nil")")
        
        // ✅ 修复：立即设置 previewLayer
        if let session = session {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            print("🎥 CameraPreviewView: PreviewLayer 已创建，frame=\(view.bounds)")
        } else {
            print("⚠️ CameraPreviewView: session 为 nil，无法创建预览层")
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let session = session else { return }
        
        // ✅ 修复：确保 previewLayer 正确更新
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.session = session
            previewLayer.frame = uiView.bounds
            print("🎥 CameraPreviewView.updateUIView: PreviewLayer 已更新")
        } else {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = uiView.bounds
            uiView.layer.addSublayer(previewLayer)
            print("🎥 CameraPreviewView.updateUIView: 创建新的 PreviewLayer")
        }
    }
}

// MARK: - 预览按钮（✅ UI 统一）
struct PreviewButton: View {
    let icon: String
    let title: String
    let url: URL
    @Binding var showingPlayer: Bool
    
    var body: some View {
        Button(action: { showingPlayer = true }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(hex: "6366F1"))
            .cornerRadius(10)
        }
    }
}

// MARK: - AVPlayerViewController
class AVPlayerViewController: UIViewController {
    var player: AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        if let player = player {
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspect
            playerLayer.frame = view.bounds
            view.layer.addSublayer(playerLayer)
        }
    }
}

#Preview {
    CapsuleEditView(dataManager: DataManager.shared)
}
