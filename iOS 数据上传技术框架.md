# iOS 数据上传完整技术框架

**终活 App 数据上传技术审计与优化方案**  
**日期**: 2026-03-19  
**版本**: v2.0

---

## 一、上传框架概览

### 1.1 上传数据类型

| 数据类型 | 大小 | 频率 | 优先级 | 当前状态 |
|---------|------|------|--------|---------|
| 签到记录 | <1KB | 每 48 小时 | 🔴 高 | ✅ 已实现 |
| 位置信息 | <1KB | 每次签到 | 🔴 高 | ✅ 已实现 |
| 时光胶囊 | 1KB-50MB | 用户添加时 | 🟡 中 | ⚠️ 需优化 |
| 遗嘱模块 | 1-10KB | 用户编辑时 | 🟡 中 | ⚠️ 需优化 |
| 紧急联系人 | <1KB | 用户添加时 | 🟢 低 | ⚠️ 需优化 |
| 见证人 | <1KB | 用户添加时 | 🟢 低 | ⚠️ 需优化 |

### 1.2 网络请求框架

```swift
// 当前使用的网络请求方式
URLSession.shared.data(for: request)

// 推荐的网络请求框架
enum NetworkFramework {
    case urlSession          // ✅ 系统原生，轻量
    case Alamofire           // 封装更好，功能丰富
    case URLSessionWebSocket // 实时通信
}
```

**当前选择**: `URLSession` (系统原生)  
**理由**: 轻量、无需额外依赖、支持后台上传

---

## 二、上传格式规范

### 2.1 请求格式

```swift
// ✅ 正确的请求格式
struct UploadRequest {
    let url: URL
    let method: String = "POST"
    let headers: [String: String] = [
        "Content-Type": "application/json",
        "Authorization": "Bearer <token>"
    ]
    let body: [String: Any]
    let timeout: TimeInterval = 30
}

// ❌ 错误示例 - 缺少必要字段
struct BadRequest {
    let url: URL
    // 缺少 headers
    // 缺少 timeout
    // 缺少错误处理
}
```

### 2.2 响应格式

```swift
// ✅ 标准响应格式
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String
    let data: T?
    let error: APIError?
}

struct APIError: Codable {
    let code: String
    let message: String
    let details: [String: Any]?
}

// 后端返回示例
{
    "success": true,
    "message": "同步成功",
    "data": {
        "total": 10,
        "created": 5,
        "updated": 5
    }
}

// 错误响应示例
{
    "success": false,
    "error": {
        "code": "INVALID_TOKEN",
        "message": "Token 已过期"
    }
}
```

---

## 三、网络请求实现

### 3.1 基础请求类

```swift
import Foundation

/// 网络请求管理器
class NetworkManager {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let decoder = JSONDecoder()
    
    init() {
        // ✅ 配置 URLSession
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        config.httpShouldSetCookies = true
        config.httpMaximumConnectionsPerHost = 5
        
        self.session = URLSession(configuration: config)
    }
    
    /// 发送 JSON 请求
    func sendJSONRequest<T: Codable>(
        url: String,
        method: String = "POST",
        headers: [String: String] = [:],
        body: [String: Any]? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let apiURL = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加自定义 headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 添加 body
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        // 发送请求
        let (data, response) = try await session.data(for: request)
        
        // 验证响应
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // 处理错误状态码
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 500...599:
            throw NetworkError.serverError(httpResponse.statusCode)
        default:
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        // 解析响应
        return try decoder.decode(T.self, from: data)
    }
}

/// 网络错误枚举
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case httpError(Int)
    case timeout
    case noNetwork
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 URL"
        case .invalidResponse: return "无效的响应"
        case .unauthorized: return "未授权，请重新登录"
        case .forbidden: return "权限不足"
        case .notFound: return "资源不存在"
        case .serverError(let code): return "服务器错误 (\(code))"
        case .httpError(let code): return "HTTP 错误 (\(code))"
        case .timeout: return "请求超时"
        case .noNetwork: return "无网络连接"
        }
    }
}
```

### 3.2 Token 管理

```swift
import Foundation

/// Token 管理器
class TokenManager {
    static let shared = TokenManager()
    
    private let tokenKey = "userToken"
    private let tokenExpiryKey = "tokenExpiry"
    private let refreshTokenKey = "refreshToken"
    
    // ✅ 检查 Token 是否有效
    var isTokenValid: Bool {
        guard let token = currentToken, !token.isEmpty else {
            return false
        }
        
        // 检查是否过期
        if let expiry = UserDefaults.standard.object(forKey: tokenExpiryKey) as? Date {
            return expiry > Date()
        }
        
        return true
    }
    
    // ✅ 获取当前 Token
    var currentToken: String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
    
    // ✅ 保存 Token
    func saveToken(_ token: String, expiresAt: Date?) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        if let expiry = expiresAt {
            UserDefaults.standard.set(expiry, forKey: tokenExpiryKey)
        }
    }
    
    // ✅ 清除 Token
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: tokenExpiryKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
    }
    
    // ✅ 解析 JWT Token 过期时间
    func decodeTokenExpiry(from token: String) -> Date? {
        let components = token.split(separator: ".")
        guard components.count == 3 else { return nil }
        
        // 解析 payload
        guard let payloadData = Data(base64Encoded: padBase64(String(components[1]))),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval else {
            return nil
        }
        
        return Date(timeIntervalSince1970: exp)
    }
    
    private func padBase64(_ string: String) -> String {
        var padded = string
        while padded.count % 4 != 0 {
            padded += "="
        }
        return padded
    }
}
```

---

## 四、安全性

### 4.1 HTTPS 强制

```swift
// ✅ Info.plist 配置
/*
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>8.136.41.211</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
        </dict>
    </dict>
</dict>
*/

// ⚠️ 当前问题：使用 HTTP 而非 HTTPS
// 建议：部署 SSL 证书，使用 HTTPS
```

### 4.2 Token 安全存储

```swift
import Security

/// 安全存储管理器
class SecureStorage {
    static let shared = SecureStorage()
    
    // ✅ 使用 Keychain 存储敏感数据
    func saveToken(_ token: String, forKey key: String) -> OSStatus {
        let tokenData = Data(token.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: tokenData
        ]
        
        // 先删除旧的
        SecItemDelete(query as CFDictionary)
        
        // 添加新的
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    func getToken(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func deleteToken(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

### 4.3 请求签名

```swift
import CryptoKit

/// 请求签名
class RequestSigner {
    static let shared = RequestSigner()
    
    private let secretKey = "your-secret-key" // ⚠️ 应该从安全位置获取
    
    // ✅ 生成请求签名
    func signRequest(_ body: [String: Any], timestamp: Date = Date()) -> String {
        let sortedBody = body.sorted { $0.key < $1.key }
        let bodyString = sortedBody.compactMap { "\($0.key)=\($0.value)" }.joined(separator: "&")
        let timestampString = "\(Int(timestamp.timeIntervalSince1970))"
        
        let message = bodyString + timestampString + secretKey
        let digest = SHA256.hash(data: Data(message.utf8))
        
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // ✅ 验证签名
    func verifySignature(_ signature: String, body: [String: Any], timestamp: Date) -> Bool {
        let expectedSignature = signRequest(body, timestamp: timestamp)
        return signature == expectedSignature
    }
}
```

---

## 五、大文件分片上传

### 5.1 分片上传策略

```swift
import Foundation

/// 分片上传管理器
class ChunkedUploadManager {
    static let shared = ChunkedUploadManager()
    
    // 分片大小：5MB
    private let chunkSize: Int = 5 * 1024 * 1024
    
    /// 上传大文件
    func uploadLargeFile(
        fileURL: URL,
        to uploadURL: String,
        token: String,
        progressHandler: @escaping (Double) -> Void,
        completionHandler: @escaping (Result<String, Error>) -> Void
    ) {
        // 1. 获取文件大小
        guard let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            completionHandler(.failure(UploadError.fileNotFound))
            return
        }
        
        // 2. 计算分片数量
        let chunkCount = (fileSize + chunkSize - 1) / chunkSize
        
        // 3. 初始化上传会话
        initUploadSession(fileURL: fileURL, totalChunks: chunkCount, token: token) { result in
            switch result {
            case .success(let sessionId):
                // 4. 上传分片
                self.uploadChunks(
                    fileURL: fileURL,
                    sessionId: sessionId,
                    chunkCount: chunkCount,
                    uploadURL: uploadURL,
                    token: token,
                    progressHandler: progressHandler,
                    completionHandler: completionHandler
                )
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    private func initUploadSession(
        fileURL: URL,
        totalChunks: Int,
        token: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        var request = URLRequest(url: URL(string: "\(uploadURL)/init")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "filename": fileURL.lastPathComponent,
            "filesize": (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0,
            "chunks": totalChunks
        ]
        
        // 发送初始化请求...
    }
    
    private func uploadChunks(
        fileURL: URL,
        sessionId: String,
        chunkCount: Int,
        uploadURL: String,
        token: String,
        progressHandler: @escaping (Double) -> Void,
        completionHandler: @escaping (Result<String, Error>) -> Void
    ) {
        // 实现分片上传逻辑
        // 支持并发上传（最多 3 个分片同时上传）
        // 支持失败重试
    }
}

enum UploadError: LocalizedError {
    case fileNotFound
    case readError
    case uploadFailed
    case mergeFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "文件不存在"
        case .readError: return "读取文件失败"
        case .uploadFailed: return "上传失败"
        case .mergeFailed: return "合并分片失败"
        }
    }
}
```

### 5.2 断点续传

```swift
/// 断点续传管理器
class ResumeUploadManager {
    static let shared = ResumeUploadManager()
    
    // ✅ 记录已上传的分片
    private var uploadedChunks: [String: Set<Int>] = [:]  // [sessionId: Set<chunkIndex>]
    
    /// 恢复上传
    func resumeUpload(sessionId: String) async throws -> String {
        // 1. 查询已上传的分片
        let uploaded = try await queryUploadedChunks(sessionId: sessionId)
        
        // 2. 计算需要上传的分片
        let remaining = allChunks.subtracting(uploaded)
        
        // 3. 上传剩余分片
        for chunkIndex in remaining {
            try await uploadChunk(sessionId: sessionId, index: chunkIndex)
        }
        
        // 4. 合并分片
        return try await mergeChunks(sessionId: sessionId)
    }
    
    /// 查询已上传的分片
    private func queryUploadedChunks(sessionId: String) async throws -> Set<Int> {
        // 调用后端 API 查询
        // GET /upload.php?action=query&session_id=xxx
    }
}
```

---

## 六、后台上传

### 6.1 后台上传会话

```swift
import Foundation

/// 后台上传管理器
class BackgroundUploadManager {
    static let shared = BackgroundUploadManager()
    
    private var backgroundSession: URLSession?
    private var completionHandlers: [String: (Result<String, Error>) -> Void] = [:]
    
    init() {
        // ✅ 配置后台上传会话
        let config = URLSessionConfiguration.background(withIdentifier: "com.zhonghuo.app.upload")
        config.isDiscretionary = false  // 立即上传
        config.sessionSendsLaunchEvents = true  // 完成后唤醒 App
        config.waitsForConnectivity = true  // 等待网络
        
        backgroundSession = URLSession(
            configuration: config,
            delegate: self,
            delegateQueue: nil
        )
    }
    
    /// 后台上传文件
    func uploadInBackground(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let session = backgroundSession else {
            completion(.failure(UploadError.uploadFailed))
            return
        }
        
        var request = URLRequest(url: URL(string: "http://8.136.41.211:3395/api/upload.php")!)
        request.httpMethod = "POST"
        
        let task = session.uploadTask(with: request, fromFile: fileURL)
        task.taskDescription = fileURL.lastPathComponent
        task.resume()
        
        // 保存 completion handler
        completionHandlers[task.taskIdentifier] = completion
    }
}

// MARK: - URLSessionDelegate
extension BackgroundUploadManager: URLSessionDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let completion = completionHandlers.removeValue(forKey: task.taskIdentifier) else {
            return
        }
        
        if let error = error {
            completion(.failure(error))
        } else if let response = task.response as? HTTPURLResponse,
                  (200...299).contains(response.statusCode) {
            completion(.success("上传成功"))
        } else {
            completion(.failure(UploadError.uploadFailed))
        }
    }
}
```

---

## 七、性能优化

### 7.1 请求合并

```swift
/// 请求合并管理器
class RequestBatcher {
    static let shared = RequestBatcher()
    
    private var pendingRequests: [String: () async -> Void] = [:]
    private var batchTimer: Timer?
    private let batchInterval: TimeInterval = 2.0  // 2 秒合并一次
    
    /// 添加请求到批次
    func enqueue(_ request: @escaping () async -> Void, for type: String) {
        pendingRequests[type] = request
        
        // 重置定时器
        batchTimer?.invalidate()
        batchTimer = Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: false) { [weak self] _ in
            Task {
                await self?.flushBatch()
            }
        }
    }
    
    /// 执行批次请求
    private func flushBatch() async {
        let requests = pendingRequests.values
        pendingRequests.removeAll()
        
        // 并发执行所有请求
        await withTaskGroup(of: Void.self) { group in
            for request in requests {
                group.addTask {
                    await request()
                }
            }
        }
    }
}
```

### 7.2 缓存策略

```swift
/// 缓存管理器
class CacheManager {
    static let shared = CacheManager()
    
    private let cache = NSCache<NSString, NSData>()
    private let diskCachePath: String
    
    init() {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        diskCachePath = paths[0].path
    }
    
    // ✅ 内存缓存
    func set(_ data: Data, forKey key: String) {
        cache.setObject(data as NSData, forKey: key as NSString)
    }
    
    func get(forKey key: String) -> Data? {
        cache.object(forKey: key as NSString) as Data?
    }
    
    // ✅ 磁盘缓存
    func setToDisk(_ data: Data, forKey key: String) {
        let path = (diskCachePath as NSString).appendingPathComponent(key)
        try? data.write(to: URL(fileURLWithPath: path))
    }
    
    func getFromDisk(forKey key: String) -> Data? {
        let path = (diskCachePath as NSString).appendingPathComponent(key)
        return try? Data(contentsOf: URL(fileURLWithPath: path))
    }
}
```

---

## 八、错误处理

### 8.1 完整错误处理

```swift
/// 上传错误处理
enum UploadError: LocalizedError {
    // 网络错误
    case noNetwork
    case timeout
    case serverError(Int)
    
    // 认证错误
    case invalidToken
    case tokenExpired
    case insufficientPermissions
    
    // 文件错误
    case fileNotFound
    case fileTooLarge
    case invalidFileType
    
    // 上传错误
    case uploadFailed
    case mergeFailed
    case checksumMismatch
    
    var errorDescription: String? {
        switch self {
        case .noNetwork:
            return "无网络连接，请检查网络设置"
        case .timeout:
            return "请求超时，请重试"
        case .serverError(let code):
            return "服务器错误 (\(code))"
        case .invalidToken:
            return "Token 无效，请重新登录"
        case .tokenExpired:
            return "Token 已过期，请重新登录"
        case .insufficientPermissions:
            return "权限不足"
        case .fileNotFound:
            return "文件不存在"
        case .fileTooLarge:
            return "文件太大（最大 50MB）"
        case .invalidFileType:
            return "不支持的文件类型"
        case .uploadFailed:
            return "上传失败"
        case .mergeFailed:
            return "合并分片失败"
        case .checksumMismatch:
            return "文件校验失败"
        }
    }
    
    // ✅ 错误恢复建议
    var recoverySuggestion: String? {
        switch self {
        case .noNetwork:
            return "请连接 Wi-Fi 或移动数据后重试"
        case .timeout:
            return "请检查网络连接后重试"
        case .invalidToken, .tokenExpired:
            return "请退出登录后重新登录"
        case .insufficientPermissions:
            return "请联系管理员获取权限"
        default:
            return nil
        }
    }
    
    // ✅ 是否可自动重试
    var isRetryable: Bool {
        switch self {
        case .noNetwork, .timeout, .serverError:
            return true
        case .invalidToken, .tokenExpired, .insufficientPermissions:
            return false  // 需要用户干预
        default:
            return true
        }
    }
}
```

### 8.2 错误日志

```swift
/// 错误日志记录器
class ErrorLogger {
    static let shared = ErrorLogger()
    
    private let logFile: URL
    
    init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        logFile = paths[0].appendingPathComponent("error_log.jsonl")
    }
    
    /// 记录错误
    func log(_ error: Error, context: [String: Any] = [:]) {
        let entry: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "error_type": String(describing: type(of: error)),
            "error_message": error.localizedDescription,
            "context": context
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: entry),
           let line = String(data: data, encoding: .utf8) {
            try? line.write(to: logFile, atomically: true, encoding: .utf8)
        }
    }
    
    /// 获取错误日志
    func getLogs(limit: Int = 100) -> [String] {
        guard let content = try? String(contentsOf: logFile) else {
            return []
        }
        
        return content.components(separatedBy: "\n").suffix(limit)
    }
}
```

---

## 九、当前问题清单

### 9.1 已识别问题

| 问题 | 严重程度 | 状态 | 解决方案 |
|------|---------|------|---------|
| HTTP 而非 HTTPS | 🔴 高 | ⏳ 待修复 | 部署 SSL 证书 |
| Token 未验证过期 | 🟡 中 | ⏳ 待修复 | 添加 Token 过期检查 |
| 无后台上传 | 🟡 中 | ⏳ 待修复 | 实现 BackgroundUploadManager |
| 无分片上传 | 🟢 低 | ⏳ 待修复 | 实现 ChunkedUploadManager |
| 错误处理不完整 | 🟡 中 | ✅ 已修复 | 添加完整错误处理 |
| 无请求合并 | 🟢 低 | ⏳ 待修复 | 实现 RequestBatcher |

### 9.2 Token 问题排查

```swift
/// Token 问题诊断
func diagnoseTokenIssue() async -> TokenDiagnosis {
    // 1. 检查 Token 是否存在
    guard let token = TokenManager.shared.currentToken else {
        return .missing
    }
    
    // 2. 检查 Token 格式
    if !isValidJWT(token) {
        return .invalidFormat
    }
    
    // 3. 检查 Token 是否过期
    if let expiry = TokenManager.shared.decodeTokenExpiry(from: token),
       expiry < Date() {
        return .expired
    }
    
    // 4. 测试 Token 是否有效
    do {
        try await testToken(token)
        return .valid
    } catch {
        return .serverRejected
    }
}

enum TokenDiagnosis {
    case valid
    case missing
    case invalidFormat
    case expired
    case serverRejected
}
```

---

## 十、实施计划

### Phase 1: 基础修复 (已完成)
- [x] 添加详细日志
- [x] 修复数据下载覆盖问题
- [x] 实现自动同步

### Phase 2: 安全性提升 (进行中)
- [ ] 使用 Keychain 存储 Token
- [ ] 添加 Token 过期检查
- [ ] 部署 HTTPS

### Phase 3: 性能优化 (计划中)
- [ ] 实现请求合并
- [ ] 实现缓存策略
- [ ] 实现后台上传

### Phase 4: 高级功能 (计划中)
- [ ] 实现分片上传
- [ ] 实现断点续传
- [ ] 实现离线队列

---

**下一步**: 逐步实施 Phase 2 安全性提升！🔒
