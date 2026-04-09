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
            
            // 📤 上传媒体文件到服务器
            if let audioURL = recordedAudioURL {
                mediaServerUrl = await DataManager.shared.uploadMediaToServer(audioURL, type: .audio)
                print("📤 音频上传结果：\(mediaServerUrl ?? "失败")")
            } else if let videoURL = recordedVideoURL {
                mediaServerUrl = await DataManager.shared.uploadMediaToServer(videoURL, type: .video)
                print("📤 视频上传结果：\(mediaServerUrl ?? "失败")")
            }
            
            let capsule = TimeCapsule(
                id: UUID().uuidString,
                title: title,
                content: content,
                type: selectedType,
                mediaServerURL: mediaServerUrl ?? "",
                sendDate: sendDate,
                isSent: false,
                createdAt: Date()
            )
            
            dataManager.addCapsule(capsule)
            
            // 📢 通知同步到服务器
            NotificationCenter.default.post(name: NSNotification.Name("CapsuleChanged"), object: nil)
            
            // 📤 同步到云端
            await dataManager.batchSyncCapsules()
            
            dismiss()
        }
    }
    
    private func playerView(for url: URL) -> AnyView {
        if FileManager.default.fileExists(atPath: url.path) {
            let player = AVPlayer(url: url)
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
                    Text("文件可能已损坏或不存在")
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
    @State var onRecordComplete: (URL) -> Void
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showingPermissionAlert = false
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F7")
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 32) {
                Spacer()
                
                // 录制图标
                VStack(spacing: 16) {
                    if recorder.isRecording {
                        Image(systemName: "record.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                            .symbolEffect(.pulse)
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
                            .font(.system(size: 32, monospacedDigit: true))
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
        // ✅ 检查权限
        if selectedType == .video {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    AVCaptureDevice.requestAccess(for: .audio) { granted in
                        if granted {
                            Task { @MainActor in
                                recorder.startRecording(type: .video)
                                startTimer()
                            }
                        } else {
                            showingPermissionAlert = true
                        }
                    }
                } else {
                    showingPermissionAlert = true
                }
            }
        } else {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    Task { @MainActor in
                        recorder.startRecording(type: .audio)
                        startTimer()
                    }
                } else {
                    showingPermissionAlert = true
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
class MediaRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var recordingURL: URL?
    private var audioRecorder: AVAudioRecorder?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var captureSession: AVCaptureSession?
    
    enum RecordingType {
        case audio
        case video
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
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let audioDevice = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
              let captureSession = captureSession,
              captureSession.canAddInput(videoInput),
              captureSession.canAddInput(audioInput) else {
            print("❌ 无法设置视频录制")
            return
        }
        
        captureSession.addInput(videoInput)
        captureSession.addInput(audioInput)
        
        videoOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(videoOutput!) {
            captureSession.addOutput(videoOutput!)
            
            // ✅ 创建 TimeCapsules 目录
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let timeCapsulesDir = documentsPath.appendingPathComponent("TimeCapsules")
            try? FileManager.default.createDirectory(at: timeCapsulesDir, withIntermediateDirectories: true)
            
            let fileName = UUID().uuidString + ".mp4"
            let filePath = timeCapsulesDir.appendingPathComponent(fileName)
            recordingURL = filePath
            
            captureSession.startRunning()
            videoOutput?.startRecording(to: filePath, recordingDelegate: self)
            isRecording = true
            print("✅ 开始录制视频：\(filePath)")
        }
    }
    
    func stopRecording() {
        if let videoOutput = videoOutput, videoOutput.isRecording {
            videoOutput.stopRecording()
            captureSession?.stopRunning()
        } else {
            audioRecorder?.stop()
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
