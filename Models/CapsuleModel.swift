//
//  CapsuleModel.swift
//  终活
//
//  时光胶囊模型
//

import Foundation

// MARK: - 时光胶囊
struct TimeCapsule: Identifiable, Codable {
    var id: String
    var title: String
    var content: String
    var type: CapsuleType
    var mediaURL: String = ""          // 本地媒体文件 URL
    var mediaServerURL: String = ""    // 服务器媒体文件 URL（云存储）
    var mediaDuration: Double = 0      // 媒体时长（秒）
    var sendDate: Date
    var isSent: Bool
    var createdAt: Date
    var deletedAt: Date? = nil  // 删除标记
    
    // 🔥 云存储状态
    var cloudBackupStatus: CloudBackupStatus = .pending
    var cloudBackupAt: Date? = nil
    
    enum CloudBackupStatus: String, Codable {
        case pending = "待备份"
        case uploading = "上传中"
        case backedUp = "已备份"
        case failed = "失败"
        
        var icon: String {
            switch self {
            case .pending: return "⏳"
            case .uploading: return "☁️"
            case .backedUp: return "✅"
            case .failed: return "❌"
            }
        }
        
        var color: String {
            switch self {
            case .pending: return "FF9500"
            case .uploading: return "007AFF"
            case .backedUp: return "34C759"
            case .failed: return "FF3B30"
            }
        }
    }
    
    enum CapsuleType: String, Codable {
        case text = "文字"
        case audio = "语音"
        case video = "视频"
        case image = "图片"
        case sticker = "表情"
        case voice = "录音"
        
        var icon: String {
            switch self {
            case .text: return "✉️"
            case .audio: return "🎙️"
            case .video: return "🎥"
            case .image: return "🖼️"
            case .sticker: return "😊"
            case .voice: return "🎤"
            }
        }
        
        var systemImage: String {
            switch self {
            case .text: return "doc.text.fill"
            case .audio: return "mic.fill"
            case .video: return "video.fill"
            case .image: return "photo.fill"
            case .sticker: return "face.smiling.fill"
            case .voice: return "waveform.rectangle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .text: return "007AFF"
            case .audio: return "FF9500"
            case .video: return "AF52DE"
            case .image: return "34C759"
            case .sticker: return "FFD60A"
            case .voice: return "5856D6"
            }
        }
        
        var mediaType: String {
            switch self {
            case .text, .sticker: return "image"
            case .audio, .voice: return "audio"
            case .video: return "video"
            case .image: return "image"
            }
        }
    }
}

struct CapsuleInput {
    let id: String
    let title: String
    let type: String
    let content: String?
    let openAt: String?
}

struct BatchSyncResult {
    let total: Int
    let created: Int
    let updated: Int
}
