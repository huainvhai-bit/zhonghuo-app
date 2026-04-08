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
                                .padding(.vertical, 12)
                                .background(Color(hex: "6366F1"))
                                .cornerRadius(10)
                            }
                            
                            if selectedType == .audio, let url = recordedAudioURL {
                                PreviewButton(icon: "mic.fill", title: "已录制音频", url: url, showingPlayer: $showingPlayer)
                            } else if selectedType == .video, let url = recordedVideoURL {
                                PreviewButton(icon: "video.fill", title: "已录制视频", url: url, showingPlayer: $showingPlayer)
                            }
                        }
                        .sheet(isPresented: $showingPlayer) {
                            if let url = recordedAudioURL ?? recordedVideoURL {
                                playerView(for: url)
                            }
                        }
                    }
                }
                
                Section(header: Text("发送时间")) {
                    DatePicker("发送日期", selection: $sendDate)
                        .datePickerStyle(.compact)
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
                        saveCapsule()
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
        }
    }
    
    private func saveCapsule() {
        let capsule = TimeCapsule(
            id: UUID().uuidString,
            title: title,
            content: content,
            type: selectedType,
            sendDate: sendDate,
            isSent: false,
            createdAt: Date()
        )
        
        dataManager.addCapsule(capsule)
        dismiss()
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

// MARK: - 媒体录制视图
struct CapsuleMediaRecorderView: View {
    let selectedType: TimeCapsule.CapsuleType
    @Environment(\.dismiss) var dismiss
    @StateObject var recorder = MediaRecorder()
    @State var onRecordComplete: (URL) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if recorder.isRecording {
                    HStack {
                        Image(systemName: "waveform")
                            .font(.system(size: 32))
                            .foregroundColor(.red)
                        Text("录制中")
                            .font(.headline)
                    }
                    .padding()
                    
                    Button(action: recorder.stopRecording) {
                        HStack {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 24))
                            Text("停止录制")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                } else {
                    Button(action: recorder.startRecording) {
                        HStack {
                            Image(systemName: "record.fill")
                                .font(.system(size: 48))
                            Text("点击开始录制")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 24)
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                }
            }
            .navigationTitle(selectedType == .audio ? "录制音频" : "录制视频")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onChange(of: recorder.recordingURL) { newURL in
                if let url = newURL {
                    onRecordComplete(url)
                }
            }
        }
    }
}

// MARK: - MediaRecorder 类
class MediaRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var recordingURL: URL?
    private var audioRecorder: AVAudioRecorder?
    
    func startRecording() {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [])
        try? session.setActive(true)
        
        let fileName = UUID().uuidString + ".m4a"
        let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TimeCapsules")
            .appendingPathComponent(fileName)
        
        do {
            audioRecorder = try AVAudioRecorder(url: filePath, settings: settings)
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("录制失败：\(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        recordingURL = audioRecorder?.url
    }
}

// MARK: - 预览按钮
struct PreviewButton: View {
    let icon: String
    let title: String
    let url: URL
    @Binding var showingPlayer: Bool
    
    var body: some View {
        Button(action: { showingPlayer = true }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                Text(title)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hex: "6366F1"))
            .cornerRadius(8)
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
