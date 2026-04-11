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
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var useFrontCamera = true  // ✅ Bug 1: 默认前置摄像头
    @State private var showCameraOptions = false  // ✅ Bug 1: 显示摄像头选项
    
    var body: some View {
        ZStack {
            // ✅ UI 统一：背景色与其他界面一致
            Color(hex: "F5F5F7")
                .ignoresSafeArea(edges: .all)
            
            ScrollView {
                VStack(spacing: 16) {
                    // 类型卡片
                    VStack(alignment: .leading, spacing: 12) {
                        Text("类型")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("类型", selection: $selectedType) {
                            Label("文字", systemImage: "doc.text.fill").tag(TimeCapsule.CapsuleType.text)
                            Label("语音", systemImage: "mic.fill").tag(TimeCapsule.CapsuleType.audio)
                            Label("视频", systemImage: "video.fill").tag(TimeCapsule.CapsuleType.video)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // 内容卡片
                    VStack(alignment: .leading, spacing: 12) {
                        Text("内容")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("标题", text: $title)
                            .padding(12)
                            .background(Color(hex: "F2F2F7"))
                            .cornerRadius(8)
                        
                        if selectedType == .text {
                            TextEditor(text: $content)
                                .frame(minHeight: 150)
                                .padding(12)
                                .background(Color(hex: "F2F2F7"))
                                .cornerRadius(8)
                        } else {
                            // ✅ 修复：视频/语音录制按钮
                            VStack(spacing: 12) {
                                HStack {
                                    Button(action: { showingRecorder = true }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: selectedType == .audio ? "mic.fill" : "video.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white)
                                            
                                            Text(recordedAudioURL != nil || recordedVideoURL != nil ? "重新录制" : "开始录制")
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color(hex: "6366F1"))
                                        .cornerRadius(10)
                                    }
                                    
                                    // ✅ Bug 1: 摄像头切换按钮（仅视频）
                                    if selectedType == .video {
                                        Button(action: { showCameraOptions.toggle() }) {
                                            Image(systemName: useFrontCamera ? "camera.fill" : "camera.rotate.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.leading, 8)
                                    }
                                }
                                
                                // ✅ Bug 1: 摄像头选项菜单
                                if selectedType == .video && showCameraOptions {
                                    HStack(spacing: 16) {
                                        Button(action: {
                                            useFrontCamera = true
                                            showCameraOptions = false
                                        }) {
                                            Label("前置摄像头", systemImage: "person.fill")
                                                .foregroundColor(useFrontCamera ? .indigo : .primary)
                                        }
                                        
                                        Button(action: {
                                            useFrontCamera = false
                                            showCameraOptions = false
                                        }) {
                                            Label("后置摄像头", systemImage: "camera.fill")
                                                .foregroundColor(!useFrontCamera ? .indigo : .primary)
                                        }
                                    }
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                
                                if selectedType == .audio, let url = recordedAudioURL {
                                    PreviewButton(icon: "mic.fill", title: "已录制音频", url: url, showingPlayer: $showingPlayer)
                                } else if selectedType == .video, let url = recordedVideoURL {
                                    PreviewButton(icon: "video.fill", title: "已录制视频", url: url, showingPlayer: $showingPlayer)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // 发送时间卡片
                    VStack(alignment: .leading, spacing: 12) {
                        Text("发送时间")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        DatePicker("发送日期", selection: $sendDate)
                            .datePickerStyle(.compact)
                            .padding(.vertical, 4)
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
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
                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let mediaURL = documentsPath.appendingPathComponent(String(existingCapsule.mediaURL.dropFirst()))
                    if FileManager.default.fileExists(atPath: mediaURL.path) {
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
        .navigationTitle(selectedType == .text ? "编辑胶囊" : "录制胶囊")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    if validateCapsule() {
                        saveCapsule()
                    }
                }
                .disabled(title.isEmpty || (selectedType == .text && content.isEmpty))
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
            
            // 📤 上传媒体文件到服务器
            if let audioURL = recordedAudioURL {
                mediaServerUrl = await DataManager.shared.uploadMediaToServer(audioURL, type: .audio)
                print("📤 音频上传结果：\(mediaServerUrl ?? "失败")")
                // ✅ Bug 修复：保存相对路径（避免 iOS sandbox 变化导致无法播放）
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
                localMediaPath = audioURL.path.replacingOccurrences(of: documentsPath, with: "")
            } else if let videoURL = recordedVideoURL {
                mediaServerUrl = await DataManager.shared.uploadMediaToServer(videoURL, type: .video)
                print("📤 视频上传结果：\(mediaServerUrl ?? "失败")")
                // ✅ Bug 修复：保存相对路径
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
                localMediaPath = videoURL.path.replacingOccurrences(of: documentsPath, with: "")
            }
            
            let capsule = TimeCapsule(
                id: existingCapsule?.id ?? UUID().uuidString,  // ✅ Bug 修复：编辑模式使用原 ID
                title: title,
                content: content,
                type: selectedType,
                mediaURL: localMediaPath,  // ✅ Bug 修复：保存相对路径
                mediaServerURL: mediaServerUrl ?? "",
                sendDate: sendDate,
                isSent: existingCapsule?.isSent ?? false,
                createdAt: existingCapsule?.createdAt ?? Date()  // ✅ Bug 修复：编辑模式保留原创建时间
            )
            
            // ✅ Bug 修复：编辑模式更新，新增模式添加
            if existingCapsule != nil {
                dataManager.updateCapsule(capsule)  // ✅ 更新现有胶囊
            } else {
                dataManager.addCapsule(capsule)  // 新增胶囊
            }
            
            // 📢 通知同步到服务器
            NotificationCenter.default.post(name: NSNotification.Name("CapsuleChanged"), object: nil)
            
            // 📤 同步到云端
            _ = await dataManager.batchSyncCapsules()
            
            dismiss()
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
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F7")
                .ignoresSafeArea(edges: .all)
            
            // ✅ 修复：视频模式下始终显示摄像头预览
            if selectedType == .video {
                CameraPreviewView(session: recorder.captureSession)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 32) {
                Spacer()
                
                // 录制状态
                VStack(spacing: 16) {
                    if recorder.isRecording {
                        Image(systemName: "record.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                            .scaleEffect(recorder.isRecording ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: recorder.isRecording)
                    } else {
                        Image(systemName: selectedType == .audio ? "mic.fill" : "video.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.primary)
                    }
                    
                    Text(recorder.isRecording ? "录制中..." : "点击开始录制")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if recorder.isRecording {
                        Text(String(format: "%02d:%02d", Int(recordingTime) / 60, Int(recordingTime) % 60))
                            .font(.system(size: 32))
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 录制按钮
                Button(action: {
                    if recorder.isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(recorder.isRecording ? Color.red.opacity(0.2) : Color(hex: "6366F1"))
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .fill(recorder.isRecording ? Color.red : Color(hex: "6366F1"))
                            .frame(width: 60, height: 60)
                        
                        if recorder.isRecording {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 32)
                
                Spacer()
            }
        }
        .onAppear {
            // ✅ Bug 1 修复：视频模式下立即初始化摄像头
            if selectedType == .video {
                showCameraPreview = true
                // ✅ 调用 setupCameraForVideo 初始化摄像头（默认前置）
                recorder.setupCameraForVideo(useFrontCamera: true)
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
        recorder.stopRecording()
        
        if let url = recorder.recordingURL {
            onRecordComplete(url)
            dismiss()
        }
    }
    
    private func startTimer() {
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingTime += 1
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
        guard let captureSession = captureSession,
              let videoOutput = videoOutput else {
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
        if let error = error {
            print("❌ 视频录制失败：\(error)")
        } else {
            print("✅ 视频录制成功：\(outputFileURL)")
            recordingURL = outputFileURL
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
