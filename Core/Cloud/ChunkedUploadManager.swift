//
//  ChunkedUploadManager.swift
//  终活
//
//  断点续传管理器
//  支持：大文件分片上传、上传中断恢复、进度追踪
//

import Foundation

/// 断点续传状态
enum ChunkedUploadStatus: String {
    case idle = "idle"
    case initializing = "initializing"
    case uploading = "uploading"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
}

/// 分片上传信息
struct ChunkedUploadInfo {
    let uploadId: String
    let chunkSize: Int
    let totalChunks: Int
    let expiresAt: Date
    var uploadedChunks: Set<Int>
    var status: ChunkedUploadStatus
    
    var progress: Double {
        guard totalChunks > 0 else { return 0 }
        return Double(uploadedChunks.count) / Double(totalChunks)
    }
}

/// 上传配置
struct UploadConfig {
    let maxFileSize: Int       // 最大文件大小（字节）
    let maxDailyUploads: Int    // 每天最大上传数
    let maxHourlyUploads: Int   // 每小时最大上传数
    let chunkSize: Int          // 分片大小（字节）
    let allowedExtensions: [String]  // 允许的扩展名
    
    static let `default` = UploadConfig(
        maxFileSize: 50 * 1024 * 1024,  // 50MB
        maxDailyUploads: 100,
        maxHourlyUploads: 20,
        chunkSize: 2 * 1024 * 1024,  // 2MB
        allowedExtensions: ["jpg", "jpeg", "png", "gif", "mp4", "mov", "m4a", "mp3", "wav", "pdf"]
    )
}

/// 断点续传管理器
class ChunkedUploadManager: ObservableObject {
    static let shared = ChunkedUploadManager()
    
    // MARK: - 属性
    @Published var currentUpload: ChunkedUploadInfo?
    @Published var uploadProgress: Double = 0
    @Published var isUploading: Bool = false
    @Published var lastError: String?
    
    private let chunkSize: Int = 2 * 1024 * 1024  // 2MB per chunk
    private let maxRetries = 3
    
    // 上传进度回调
    var onProgress: ((Double) -> Void)?
    var onComplete: ((String) -> Void)?
    var onError: ((String) -> Void)?
    
    // MARK: - 初始化
    
    private init() {}
    
    // MARK: - 公开方法
    
    /// 上传文件（自动分片）
    /// - Parameters:
    ///   - fileURL: 本地文件 URL
    ///   - type: 上传类型（capsule/will/asset）
    ///   - retryCount: 已重试次数
    /// - Returns: 服务器上的文件 URL
    func uploadFile(
        fileURL: URL,
        type: String = "capsule",
        retryCount: Int = 0
    ) async throws -> String {
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw UploadError.fileNotFound
        }
        
        // 获取文件属性
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? Int ?? 0
        
        guard fileSize > 0 else {
            throw UploadError.emptyFile
        }
        
        // 获取上传配置
        let config = try await fetchUploadConfig()
        
        // 检查文件大小
        if fileSize > config.maxFileSize {
            let maxSizeMB = Double(config.maxFileSize) / 1024 / 1024
            throw UploadError.fileTooLarge(maxSizeMB: maxSizeMB)
        }
        
        // 计算分片数
        let totalChunks = Int(ceil(Double(fileSize) / Double(config.chunkSize)))
        
        // 获取文件名和扩展名
        let filename = fileURL.lastPathComponent
        let ext = fileURL.pathExtension.lowercased()
        
        // 初始化分片上传
        let initResult = try await initializeUpload(
            filename: filename,
            fileSize: fileSize,
            totalChunks: totalChunks,
            extension: ext
        )
        
        guard initResult.allowed else {
            throw UploadError.uploadNotAllowed(reason: initResult.message ?? "上传被拒绝")
        }
        
        guard let uploadId = initResult.uploadId else {
            throw UploadError.initializationFailed
        }
        
        // 创建上传信息
        await MainActor.run {
            self.currentUpload = ChunkedUploadInfo(
                uploadId: uploadId,
                chunkSize: config.chunkSize,
                totalChunks: totalChunks,
                expiresAt: Date(timeIntervalSince1970: TimeInterval(initResult.expiresAt)),
                uploadedChunks: [],
                status: .uploading
            )
            self.isUploading = true
        }
        
        // 读取文件数据
        let fileData = try Data(contentsOf: fileURL)
        
        // 上传每个分片
        for chunkIndex in 0..<totalChunks {
            // 检查是否已取消
            if currentUpload?.status == .cancelled {
                throw UploadError.cancelled
            }
            
            // 计算分片范围
            let start = chunkIndex * config.chunkSize
            let end = min(start + config.chunkSize, fileSize)
            let chunkData = fileData.subdata(in: start..<end)
            
            // 检查是否已上传（断点续传）
            if currentUpload?.uploadedChunks.contains(chunkIndex) == true {
                print("📤 分片 \(chunkIndex + 1)/\(totalChunks) 已上传，跳过")
                continue
            }
            
            // 上传分片（带重试）
            for attempt in 1...maxRetries {
                do {
                    try await uploadChunk(
                        uploadId: uploadId,
                        chunkIndex: chunkIndex,
                        chunkData: chunkData
                    )
                    break
                } catch {
                    print("⚠️ 分片 \(chunkIndex + 1) 上传失败（第 \(attempt)/\(maxRetries) 次尝试）：\(error)")
                    if attempt == maxRetries {
                        throw UploadError.chunkUploadFailed(index: chunkIndex, error: error)
                    }
                    // 等待后重试
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000)
                }
            }
            
            // 更新进度
            await MainActor.run {
                self.currentUpload?.uploadedChunks.insert(chunkIndex)
                self.uploadProgress = self.currentUpload?.progress ?? 0
                self.onProgress?(self.uploadProgress)
            }
            
            print("📤 已上传 \(chunkIndex + 1)/\(totalChunks) 分片，进度 \(Int(self.uploadProgress * 100))%")
        }
        
        // 完成上传
        let result = try await completeUpload(uploadId: uploadId, type: type)
        
        await MainActor.run {
            self.currentUpload?.status = .completed
            self.isUploading = false
            self.uploadProgress = 1.0
            self.onComplete?(result.url ?? "")
        }
        
        return result.url ?? ""
    }
    
    /// 取消上传
    func cancelUpload() async {
        guard let uploadId = currentUpload?.uploadId else { return }
        
        do {
            try await cancelUploadRequest(uploadId: uploadId)
        } catch {
            print("⚠️ 取消上传失败：\(error)")
        }
        
        await MainActor.run {
            self.currentUpload?.status = .cancelled
            self.isUploading = false
        }
    }
    
    /// 获取上传状态
    func getUploadStatus(uploadId: String) async throws -> ChunkedUploadStatus {
        let query = """
        query($uploadId: String!) {
            getChunkedUploadStatus(uploadId: $uploadId) {
                status
                uploadedChunks
            }
        }
        """
        
        let variables: [String: Any] = ["uploadId": uploadId]
        let result = try await GraphQLClient.shared.query(query, variables: variables)
        
        guard let data = result["data"] as? [String: Any],
              let statusData = data["getChunkedUploadStatus"] as? [String: Any] else {
            throw UploadError.statusFetchFailed
        }
        
        let statusStr = statusData["status"] as? String ?? "unknown"
        return ChunkedUploadStatus(rawValue: statusStr) ?? .failed
    }
    
    /// 获取上传配置
    func fetchUploadConfig() async throws -> UploadConfig {
        let query = """
        query {
            getUploadConfig {
                maxFileSize
                maxDailyUploads
                maxHourlyUploads
                chunkSize
                allowedExtensions
            }
        }
        """
        
        let result = try await GraphQLClient.shared.query(query, variables: [:])
        
        guard let data = result["data"] as? [String: Any],
              let configData = data["getUploadConfig"] as? [String: Any] else {
            return .default
        }
        
        return UploadConfig(
            maxFileSize: configData["maxFileSize"] as? Int ?? 50 * 1024 * 1024,
            maxDailyUploads: configData["maxDailyUploads"] as? Int ?? 100,
            maxHourlyUploads: configData["maxHourlyUploads"] as? Int ?? 20,
            chunkSize: configData["chunkSize"] as? Int ?? 2 * 1024 * 1024,
            allowedExtensions: configData["allowedExtensions"] as? [String] ?? ["jpg", "jpeg", "png", "gif", "mp4", "mov", "m4a", "mp3", "wav", "pdf"]
        )
    }
    
    // MARK: - 私有方法
    
    /// 初始化分片上传
    private func initializeUpload(
        filename: String,
        fileSize: Int,
        totalChunks: Int,
        extension: String
    ) async throws -> InitChunkedUploadResponse {
        let mutation = """
        mutation($filename: String!, $fileSize: Int!, $totalChunks: Int!, $extension: String!) {
            initChunkedUpload(filename: $filename, fileSize: $fileSize, totalChunks: $totalChunks, extension: $extension) {
                allowed
                uploadId
                chunkSize
                expiresAt
                message
            }
        }
        """
        
        let variables: [String: Any] = [
            "filename": filename,
            "fileSize": fileSize,
            "totalChunks": totalChunks,
            "extension": `extension`
        ]
        
        let result = try await GraphQLClient.shared.query(mutation, variables: variables)
        
        guard let data = result["data"] as? [String: Any],
              let initData = data["initChunkedUpload"] as? [String: Any] else {
            throw UploadError.initializationFailed
        }
        
        return InitChunkedUploadResponse(
            allowed: initData["allowed"] as? Bool ?? false,
            uploadId: initData["uploadId"] as? String,
            chunkSize: initData["chunkSize"] as? Int ?? (2 * 1024 * 1024),
            expiresAt: initData["expiresAt"] as? Int ?? 0,
            message: initData["message"] as? String
        )
    }
    
    /// 上传单个分片
    private func uploadChunk(
        uploadId: String,
        chunkIndex: Int,
        chunkData: Data
    ) async throws {
        let mutation = """
        mutation($uploadId: String!, $chunkIndex: Int!, $chunkData: String!) {
            uploadChunk(uploadId: $uploadId, chunkIndex: $chunkIndex, chunkData: $chunkData) {
                success
                message
            }
        }
        """
        
        // 将分片数据转换为 base64
        let base64Data = chunkData.base64EncodedString()
        
        let variables: [String: Any] = [
            "uploadId": uploadId,
            "chunkIndex": chunkIndex,
            "chunkData": base64Data
        ]
        
        let result = try await GraphQLClient.shared.query(mutation, variables: variables)
        
        guard let resultData = result["data"] as? [String: Any],
              let uploadData = resultData["uploadChunk"] as? [String: Any],
              let success = uploadData["success"] as? Bool, success else {
            let message = ((result["data"] as? [String: Any])?["uploadChunk"] as? [String: Any])?["message"] as? String ?? "上传失败"
            throw UploadError.chunkUploadFailed(index: chunkIndex, error: NSError(domain: "ChunkedUpload", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
        }
    }
    
    /// 完成分片上传
    private func completeUpload(uploadId: String, type: String) async throws -> CompleteChunkedUploadResponse {
        let mutation = """
        mutation($uploadId: String!, $type: String!) {
            completeChunkedUpload(uploadId: $uploadId, type: $type) {
                success
                url
                message
            }
        }
        """
        
        let variables: [String: Any] = [
            "uploadId": uploadId,
            "type": type
        ]
        
        let result = try await GraphQLClient.shared.query(mutation, variables: variables)
        
        guard let resultData = result["data"] as? [String: Any],
              let completeData = resultData["completeChunkedUpload"] as? [String: Any],
              let success = completeData["success"] as? Bool, success else {
            let message = ((result["data"] as? [String: Any])?["completeChunkedUpload"] as? [String: Any])?["message"] as? String ?? "完成上传失败"
            throw UploadError.completeFailed(message: message)
        }
        
        return CompleteChunkedUploadResponse(
            success: true,
            url: completeData["url"] as? String,
            message: completeData["message"] as? String
        )
    }
    
    /// 取消上传请求
    private func cancelUploadRequest(uploadId: String) async throws {
        let mutation = """
        mutation($uploadId: String!) {
            cancelChunkedUpload(uploadId: $uploadId) {
                success
                message
            }
        }
        """
        
        let variables: [String: Any] = ["uploadId": uploadId]
        let _ = try await GraphQLClient.shared.query(mutation, variables: variables)
    }
}

// MARK: - 响应结构

struct InitChunkedUploadResponse {
    let allowed: Bool
    let uploadId: String?
    let chunkSize: Int
    let expiresAt: Int
    let message: String?
}

struct CompleteChunkedUploadResponse {
    let success: Bool
    let url: String?
    let message: String?
}

// MARK: - 上传错误

enum UploadError: LocalizedError {
    case fileNotFound
    case emptyFile
    case fileTooLarge(maxSizeMB: Double)
    case uploadNotAllowed(reason: String)
    case initializationFailed
    case chunkUploadFailed(index: Int, error: Error)
    case completeFailed(message: String)
    case statusFetchFailed
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "文件不存在"
        case .emptyFile:
            return "文件为空"
        case .fileTooLarge(let maxSizeMB):
            return "文件超过大小限制（最大 \(maxSizeMB) MB）"
        case .uploadNotAllowed(let reason):
            return "上传被拒绝：\(reason)"
        case .initializationFailed:
            return "初始化上传失败"
        case .chunkUploadFailed(let index, let error):
            return "分片 \(index) 上传失败：\(error.localizedDescription)"
        case .completeFailed(let message):
            return "完成上传失败：\(message)"
        case .statusFetchFailed:
            return "获取上传状态失败"
        case .cancelled:
            return "上传已取消"
        }
    }
}
