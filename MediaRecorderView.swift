//
//  MediaRecorderView.swift
//  终活
//
//  录音录像 - 带保存按钮
//

import SwiftUI
import AVFoundation
import AVKit

struct MediaRecorderView: View {
    let type: TimeCapsule.CapsuleType
    @Binding var recordedURL: URL?
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var recorder = Recorder()
    @State private var showingPlayer = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if type == .audio {
                    audioView
                } else {
                    videoView
                }
            }
            .navigationTitle(type == .audio ? "录音" : "录像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if recorder.recordedURL != nil && !recorder.isRecording {
                        Button("使用") {
                            recordedURL = recorder.recordedURL
                            dismiss()
                        }
                        .foregroundColor(.indigo)
                    }
                }
            }
            .alert("提示", isPresented: $recorder.showAlert) {
                Button("确定") { }
            } message: {
                Text(recorder.alertMessage)
            }
            .onAppear {
                print("🎬 MediaRecorderView onAppear, type: \(type.rawValue)")
                recorder.requestPermission(for: type)
            }
        }
    }
    
    private var audioView: some View {
        VStack(spacing: 30) {
            if !recorder.permissionGranted {
                Spacer()
                ProgressView()
                Text("等待权限...")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                Spacer()
                
                Image(systemName: recorder.isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.indigo)
                
                if recorder.isRecording {
                    Text(recorder.formattedTime)
                        .font(.system(size: 32, weight: .light, design: .monospaced))
                }
                
                Text(recorder.isRecording ? "录音中..." : "点击开始录音")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    print("🎙️ 点击录音按钮")
                    recorder.toggleRecording()
                }) {
                    Circle()
                        .fill(recorder.isRecording ? .red : .indigo)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        )
                }
                
                // 播放按钮：只在录制结束后显示
                if recorder.recordedURL != nil && !recorder.isRecording {
                    Button("播放录音") {
                        showingPlayer = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingPlayer) {
            if let url = recorder.recordedURL {
                AVPlayerView(player: AVPlayer(url: url))
            }
        }
    }
    
    private var videoView: some View {
        ZStack {
            if !recorder.permissionGranted {
                Color.black.ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("等待权限...")
                                .foregroundColor(.white)
                        }
                    )
            } else if recorder.cameraReady {
                CameraPreview(session: recorder.captureSession)
                    .ignoresSafeArea()
                
                VStack {
                    // 录制时长显示
                    if recorder.isRecording {
                        HStack {
                            Spacer()
                            Text(recorder.formattedTime)
                                .font(.system(size: 20, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                            Spacer()
                        }
                        .padding(.top, 50)
                    }
                    
                    Spacer()
                    
                    // 录制按钮
                    Button(action: {
                        print("📹 点击录像按钮")
                        recorder.toggleRecording()
                    }) {
                        Circle()
                            .fill(recorder.isRecording ? .red.opacity(0.5) : .red)
                            .frame(width: 70, height: 70)
                    }
                    .padding(.bottom, 30)
                    
                    // 播放按钮：只在录制结束后显示
                    if recorder.recordedURL != nil && !recorder.isRecording {
                        Button("播放视频") {
                            showingPlayer = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .padding(.bottom, 10)
                    }
                }
            } else {
                Color.black.ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("启动摄像头...")
                                .foregroundColor(.white)
                        }
                    )
            }
        }
        .sheet(isPresented: $showingPlayer) {
            if let url = recorder.recordedURL {
                AVPlayerView(player: AVPlayer(url: url))
            }
        }
    }
}

// MARK: - 录制器
class Recorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var formattedTime = "00:00"
    @Published var cameraReady = false
    @Published var permissionGranted = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var recordedURL: URL?
    
    var captureSession: AVCaptureSession?
    private var audioRecorder: AVAudioRecorder?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var timer: Timer?
    private var recordingTime = 0
    private var currentType: TimeCapsule.CapsuleType = .text
    
    override init() {
        super.init()
        print("🎬 Recorder init()")
    }
    
    // MARK: - 权限请求
    func requestPermission(for type: TimeCapsule.CapsuleType) {
        currentType = type
        print("🔑 requestPermission for: \(type.rawValue)")
        
        if type == .audio {
            print("🎤 请求麦克风权限...")
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                print("🎤 麦克风权限结果：\(granted)")
                DispatchQueue.main.async {
                    self?.handleMicPermission(granted)
                }
            }
        } else {
            print("📷 请求摄像头权限...")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                print("📷 摄像头权限结果：\(granted)")
                DispatchQueue.main.async {
                    self?.handleCameraPermission(granted)
                }
            }
        }
    }
    
    private func handleMicPermission(_ granted: Bool) {
        print("🎤 handleMicPermission: \(granted)")
        if granted {
            permissionGranted = true
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.setupAudioSession()
            }
        } else {
            alertMessage = "需要麦克风权限才能录音，请在设置中开启"
            showAlert = true
        }
    }
    
    private func handleCameraPermission(_ granted: Bool) {
        print("📷 handleCameraPermission: \(granted)")
        if granted {
            permissionGranted = true
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.setupCamera()
            }
        } else {
            alertMessage = "需要摄像头权限才能录像，请在设置中开启"
            showAlert = true
        }
    }
    
    // MARK: - 音频设置
    private func setupAudioSession() {
        print("🎤 setupAudioSession 开始")
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
            print("✅ 音频会话设置成功")
        } catch {
            print("❌ 音频会话失败：\(error)")
            DispatchQueue.main.async {
                self.alertMessage = "音频设置失败：\(error.localizedDescription)"
                self.showAlert = true
            }
        }
    }
    
    // MARK: - 摄像头设置
    private func setupCamera() {
        print("📷 setupCamera 开始")
        do {
            captureSession = AVCaptureSession()
            captureSession?.sessionPreset = .high
            
            guard let session = captureSession else {
                print("❌ captureSession 创建失败")
                return
            }
            
            session.beginConfiguration()
            print("📷 beginConfiguration")
            
            // 前置摄像头
            if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                print("📷 找到前置摄像头")
                let input = try AVCaptureDeviceInput(device: camera)
                if session.canAddInput(input) {
                    session.addInput(input)
                    print("✅ 摄像头输入已添加")
                } else {
                    print("❌ 无法添加摄像头输入")
                }
            } else {
                print("❌ 未找到前置摄像头")
            }
            
            // 麦克风
            let audioDevice = AVCaptureDevice.default(for: .audio)
            if let audioDevice = audioDevice {
                print("🎤 找到麦克风")
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                    print("✅ 麦克风输入已添加")
                } else {
                    print("❌ 无法添加麦克风输入")
                }
            } else {
                print("❌ 未找到麦克风")
            }
            
            // 视频输出
            videoOutput = AVCaptureMovieFileOutput()
            if let output = videoOutput, session.canAddOutput(output) {
                session.addOutput(output)
                print("✅ 视频输出已添加")
            } else {
                print("❌ 无法添加视频输出")
            }
            
            session.commitConfiguration()
            print("📷 commitConfiguration")
            
            // 异步启动
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                print("📷 开始 startRunning...")
                session.startRunning()
                print("✅ 摄像头会话已启动")
                DispatchQueue.main.async {
                    self?.cameraReady = true
                    print("📷 cameraReady = true")
                }
            }
        } catch {
            print("❌ 摄像头设置失败：\(error)")
            DispatchQueue.main.async { [weak self] in
                self?.alertMessage = "摄像头设置失败：\(error.localizedDescription)"
                self?.showAlert = true
                self?.permissionGranted = false
            }
        }
    }
    
    // MARK: - 录制控制
    func toggleRecording() {
        print("🎬 toggleRecording, isRecording: \(isRecording)")
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        print("🎬 startRecording 开始")
        let filename = "capsule_" + UUID().uuidString + (videoOutput != nil ? ".mov" : ".m4a")
        
        // 使用稳定的文档目录路径，确保文件持久化
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let capsulesFolder = documentsPath.appendingPathComponent("TimeCapsules")
        
        // 创建胶囊文件夹（如果不存在）
        if !FileManager.default.fileExists(atPath: capsulesFolder.path) {
            try? FileManager.default.createDirectory(at: capsulesFolder, withIntermediateDirectories: true, attributes: nil)
            print("📁 创建胶囊文件夹：\(capsulesFolder.path)")
        }
        
        let url = capsulesFolder.appendingPathComponent(filename)
        recordedURL = url
        print("📁 录制文件路径（持久化）：\(url.path)")
        print("📁 文件名：\(filename)")
        print("📁 文件夹存在：\(FileManager.default.fileExists(atPath: capsulesFolder.path))")
        print("📁 可写权限：\(FileManager.default.isWritableFile(atPath: capsulesFolder.path))")
        
        if videoOutput != nil {
            print("📹 开始录像...")
            videoOutput?.startRecording(to: url, recordingDelegate: self)
            startTimer()  // 录像也要启动计时器
        } else {
            do {
                let settings: [String: Any] = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                print("🎤 创建 AVAudioRecorder...")
                audioRecorder = try AVAudioRecorder(url: url, settings: settings)
                print("🎤 开始录音...")
                audioRecorder?.record()
                print("✅ 开始录音成功")
            } catch {
                print("❌ 录音失败：\(error)")
                alertMessage = "录音失败：\(error.localizedDescription)"
                showAlert = true
            }
            startTimer()
        }
        isRecording = true
    }
    
    private func stopRecording() {
        print("🎬 stopRecording, recordingTime: \(recordingTime)秒")
        if videoOutput != nil {
            // 录像：stopRecording 是异步的，在 delegate 中处理完成
            videoOutput?.stopRecording()
            // 但计时器要立即停止
            timer?.invalidate()
        } else {
            // 录音：同步停止
            audioRecorder?.stop()
            timer?.invalidate()
            formattedTime = "00:00"
        }
        isRecording = false
    }
    
    // MARK: - 计时器
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.recordingTime += 1
            let mins = (self?.recordingTime ?? 0) / 60
            let secs = (self?.recordingTime ?? 0) % 60
            self?.formattedTime = String(format: "%02d:%02d", mins, secs)
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension Recorder: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("❌ 录像失败：\(error)")
            DispatchQueue.main.async { [weak self] in
                self?.alertMessage = "录像失败：\(error.localizedDescription)"
                self?.showAlert = true
            }
        } else {
            print("✅ 录像完成：\(outputFileURL.lastPathComponent)")
            print("✅ 文件路径：\(outputFileURL.path)")
            let attributes = try? FileManager.default.attributesOfItem(atPath: outputFileURL.path)
            let fileSize = attributes?[.size] as? Int ?? 0
            print("✅ 文件大小：\(fileSize) bytes")
            print("✅ 文件存在：\(FileManager.default.fileExists(atPath: outputFileURL.path))")
            
            // 验证文件可读性
            if FileManager.default.isReadableFile(atPath: outputFileURL.path) {
                print("✅ 文件可读")
            } else {
                print("⚠️ 文件不可读，尝试修复权限")
                try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: outputFileURL.path)
            }
        }
    }
}

// MARK: - 摄像头预览
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession?
    
    func makeUIView(context: Context) -> UIView {
        print("📷 CameraPreview makeUIView")
        let view = UIView(frame: UIScreen.main.bounds)
        
        guard let session = session else {
            print("❌ CameraPreview session 为 nil")
            return view
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}

// MARK: - 播放器
struct AVPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
