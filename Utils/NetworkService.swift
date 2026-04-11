//
//  NetworkService.swift
//  终活
//
//  统一网络层 - 符合第 11 章 11.2 节、11.3 节规范
//

import Foundation

// MARK: - NetworkService 统一网络服务
/// 网络层规范 (第 11 章):
/// - 统一 HTTP 请求方法
/// - Token 自动附加
/// - 错误统一处理
/// - 重试机制
@MainActor
class NetworkService {
    static let shared = NetworkService()
    
    // MARK: - 配置
    
    /// 默认超时时间 (秒)
    private let defaultTimeout: TimeInterval = 30
    
    /// 最大重试次数
    private let maxRetries: Int = 3
    
    /// 重试延迟 (秒)
    private let retryDelay: TimeInterval = 1.0
    
    /// URL Session 配置
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = defaultTimeout
        config.timeoutIntervalForResource = defaultTimeout * 2
        config.httpMaximumConnectionsPerHost = 5
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()
    
    /// 请求拦截器 (可用于添加公共参数)
    var requestInterceptor: ((inout URLRequest) -> Void)?
    
    /// 响应拦截器 (可用于统一处理响应)
    var responseInterceptor: ((Data, URLResponse) -> (Data, URLResponse))?
    
    private init() {}
    
    // MARK: - HTTP 方法枚举
    
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
        case PATCH = "PATCH"
    }
    
    // MARK: - 核心请求方法
    
    /// 统一网络请求
    /// - Parameters:
    ///   - endpoint: API 端点路径
    ///   - method: HTTP 方法
    ///   - parameters: 请求参数
    ///   - requiresAuth: 是否需要认证 (自动附加 Token)
    ///   - timeout: 超时时间
    ///   - file: 调用源文件
    ///   - line: 调用源行号
    /// - Returns: 响应数据
    func request(
        endpoint: String,
        method: HTTPMethod = .GET,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true,
        timeout: TimeInterval? = nil,
        file: String = #file,
        line: Int = #line
    ) async throws -> Data {
        let startTime = Date()
        let fileName = (file as NSString).lastPathComponent
        
        // 1. 构建 URL
        guard var urlComponents = URLComponents(string: DataManager.apiURL + endpoint) else {
            let error = AppError.invalidParameter("URL 构建失败：\(endpoint)")
            Logger.error("[\(fileName):\(line)] \(error.userMessage)", file: fileName, line: line)
            throw error
        }
        
        // 2. 添加查询参数 (GET 请求)
        if method == .GET, let params = parameters {
            urlComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        }
        
        guard let url = urlComponents.url else {
            let error = AppError.invalidParameter("URL 无效")
            Logger.error("[\(fileName):\(line)] \(error.userMessage)", file: fileName, line: line)
            throw error
        }
        
        // 3. 创建请求
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 4. 添加 Token (第 13 章 13.1 节)
        if requiresAuth {
            if let token = KeychainManager.shared.getToken() {
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                Logger.debug("[\(fileName):\(line)] Token 已附加", file: fileName, line: line)
            } else {
                Logger.warning("[\(fileName):\(line)] 请求需要认证但未找到 Token", file: fileName, line: line)
                throw AppError.securityUnauthorized
            }
        }
        
        // 5. 添加请求体 (POST/PUT/PATCH)
        if method == .POST || method == .PUT || method == .PATCH {
            if let params = parameters {
                do {
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
                    Logger.debug("[\(fileName):\(line)] 请求体：\(params)", file: fileName, line: line)
                } catch {
                    let appError = AppError.invalidParameter("请求体序列化失败：\(error.localizedDescription)")
                    Logger.error("[\(fileName):\(line)] \(appError.userMessage)", file: fileName, line: line)
                    throw appError
                }
            }
        }
        
        // 6. 应用请求拦截器
        requestInterceptor?(&urlRequest)
        
        // 7. 发送请求
        Logger.network(method.rawValue, url: url.absoluteString, file: fileName, line: line)
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            let duration = Date().timeIntervalSince(startTime)
            
            // 8. 应用响应拦截器
            let processedData = responseInterceptor.map { $0(data, response) } ?? (data, response)
            
            // 9. 处理响应
            guard let httpResponse = processedData.1 as? HTTPURLResponse else {
                let error = AppError.network(NSError(domain: "Network", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "无效的 HTTP 响应"
                ]))
                Logger.error("[\(fileName):\(line)] \(error.userMessage)", file: fileName, line: line)
                throw error
            }
            
            // 10. 记录网络日志
            Logger.network(
                method.rawValue,
                url: url.absoluteString,
                statusCode: httpResponse.statusCode,
                duration: duration,
                file: fileName,
                line: line
            )
            
            // 11. 处理 HTTP 状态码
            switch httpResponse.statusCode {
            case 200...299:
                return processedData.0
                
            case 401:
                let error = AppError.securityUnauthorized
                Logger.error("[\(fileName):\(line)] \(error.userMessage)", file: fileName, line: line)
                throw error
                
            case 403:
                let error = AppError.securityForbidden
                Logger.error("[\(fileName):\(line)] \(error.userMessage)", file: fileName, line: line)
                throw error
                
            case 404:
                let error = AppError.dataNotFound
                Logger.error("[\(fileName):\(line)] \(error.userMessage)", file: fileName, line: line)
                throw error
                
            case 419:
                let error = AppError.securityTokenExpired
                Logger.error("[\(fileName):\(line)] \(error.userMessage)", file: fileName, line: line)
                throw error
                
            case 429:
                let error = AppError.securityRateLimitExceeded
                Logger.error("[\(fileName):\(line)] \(error.userMessage)", file: fileName, line: line)
                throw error
                
            case 500...599:
                let error = AppError.serverError(httpResponse.statusCode, "服务器错误 (\(httpResponse.statusCode))")
                Logger.error("[\(fileName):\(line)] \(error.userMessage)", file: fileName, line: line)
                throw error
                
            default:
                let error = AppError.serverError(httpResponse.statusCode, "未知响应状态码 (\(httpResponse.statusCode))")
                Logger.error("[\(fileName):\(line)] \(error.userMessage)", file: fileName, line: line)
                throw error
            }
            
        } catch let error as AppError {
            throw error
        } catch let error as NSError {
            // 网络错误处理
            if error.domain == NSURLErrorDomain {
                switch error.code {
                case NSURLErrorNotConnectedToInternet:
                    throw AppError.network(error)
                case NSURLErrorTimedOut:
                    throw AppError.network(error)
                case NSURLErrorServerCertificateUntrusted,
                     NSURLErrorSecureConnectionFailed:
                    throw AppError.securitySSLHandshakeFailed
                default:
                    throw AppError.network(error)
                }
            }
            throw error
        }
    }
    
    // MARK: - GraphQL 专用方法
    
    /// GraphQL 查询
    /// - Parameters:
    ///   - query: GraphQL 查询语句
    ///   - variables: GraphQL 变量
    ///   - requiresAuth: 是否需要认证
    ///   - file: 调用源文件
    ///   - line: 调用源行号
    /// - Returns: 解码后的响应数据
    func graphql<T: Decodable>(
        query: String,
        variables: [String: Any]? = nil,
        requiresAuth: Bool = true,
        file: String = #file,
        line: Int = #line
    ) async throws -> T {
        var params: [String: Any] = ["query": query]
        if let variables = variables {
            params["variables"] = variables
        }
        
        let data = try await request(
            endpoint: "/api/graphql.php",
            method: .POST,
            parameters: params,
            requiresAuth: requiresAuth,
            file: file,
            line: line
        )
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            let fileName = (file as NSString).lastPathComponent
            Logger.error("[\(fileName):\(line)] GraphQL 响应解码失败：\(error.localizedDescription)", file: fileName, line: line)
            throw AppError.dataParsingFailed("响应数据格式错误")
        }
    }
    
    // MARK: - 带重试的请求
    
    /// 带重试机制的网络请求 (第 11 章 11.3 节)
    /// - Parameters:
    ///   - endpoint: API 端点路径
    ///   - method: HTTP 方法
    ///   - parameters: 请求参数
    ///   - requiresAuth: 是否需要认证
    ///   - maxRetries: 最大重试次数
    ///   - delay: 重试延迟
    ///   - file: 调用源文件
    ///   - line: 调用源行号
    /// - Returns: 响应数据
    func requestWithRetry(
        endpoint: String,
        method: HTTPMethod = .GET,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true,
        maxRetries: Int? = nil,
        delay: TimeInterval? = nil,
        file: String = #file,
        line: Int = #line
    ) async throws -> Data {
        let retries = maxRetries ?? self.maxRetries
        let retryDelay = delay ?? self.retryDelay
        let fileName = (file as NSString).lastPathComponent
        var lastError: Error?
        
        for attempt in 1...retries {
            do {
                let data = try await request(
                    endpoint: endpoint,
                    method: method,
                    parameters: parameters,
                    requiresAuth: requiresAuth,
                    file: file,
                    line: line
                )
                
                if attempt > 1 {
                    Logger.info("[\(fileName):\(line)] 请求重试成功 (第 \(attempt) 次)", file: fileName, line: line)
                }
                
                return data
                
            } catch let error {
                lastError = error
                
                // 判断是否需要重试
                if shouldRetry(error: error, attempt: attempt, maxRetries: retries) {
                    Logger.warning(
                        "[\(fileName):\(line)] 请求失败，第 \(attempt) 次重试：\(error.localizedDescription)",
                        file: fileName,
                        line: line
                    )
                    
                    // 指数退避策略
                    let exponentialDelay = retryDelay * Double(attempt)
                    try await Task.sleep(nanoseconds: UInt64(exponentialDelay * 1_000_000_000))
                } else {
                    Logger.error("[\(fileName):\(line)] 请求失败，不再重试：\(error.localizedDescription)", file: fileName, line: line)
                    break
                }
            }
        }
        
        throw lastError ?? AppError.network(NSError(domain: "Retry", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "请求失败，已达最大重试次数"
        ]))
    }
    
    /// 判断是否需要重试
    private func shouldRetry(error: Error, attempt: Int, maxRetries: Int) -> Bool {
        // 已达最大重试次数
        if attempt >= maxRetries {
            return false
        }
        
        // 安全相关错误不重试
        if let appError = error as? AppError {
            switch appError {
            case .securityUnauthorized,
                 .securityForbidden,
                 .securityTokenExpired,
                 .securityTokenInvalid,
                 .dataNotFound,
                 .invalidParameter:
                return false
            default:
                break
            }
        }
        
        // 网络错误可以重试
        if let nsError = error as? NSError, nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorTimedOut,
                 NSURLErrorNetworkConnectionLost:
                return true
            default:
                break
            }
        }
        
        // 服务器错误可以重试
        if case .serverError(let code, _) = error as? AppError {
            return code >= 500
        }
        
        return false
    }
    
    // MARK: - 文件上传
    
    /// 上传文件
    /// - Parameters:
    ///   - endpoint: API 端点
    ///   - fileURL: 本地文件 URL
    ///   - parameterName: 表单参数名
    ///   - fileName: 文件名
    ///   - mimeType: MIME 类型
    ///   - parameters: 额外参数
    ///   - requiresAuth: 是否需要认证
    ///   - progress: 上传进度回调
    ///   - file: 调用源文件
    ///   - line: 调用源行号
    /// - Returns: 服务器响应数据
    func uploadFile(
        endpoint: String,
        fileURL: URL,
        parameterName: String = "file",
        fileName: String? = nil,
        mimeType: String = "application/octet-stream",
        parameters: [String: String]? = nil,
        requiresAuth: Bool = true,
        progress: ((Double) -> Void)? = nil,
        file: String = #file,
        line: Int = #line
    ) async throws -> Data {
        let fileName = (file as NSString).lastPathComponent
        Logger.info("[\(fileName):\(line)] 开始上传文件：\(fileURL.path)", file: fileName, line: line)
        
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let error = AppError.localDatabase(NSError(domain: "FileNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "文件不存在：\(fileURL.path)"]))
            Logger.error("[\(fileName):\(line)] \(error.userMessage)", file: fileName, line: line)
            throw error
        }
        
        // 获取文件大小
        let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int ?? 0
        Logger.debug("[\(fileName):\(line)] 文件大小：\(fileSize) bytes", file: fileName, line: line)
        
        // 构建 multipart/form-data 请求
        guard let url = URL(string: DataManager.apiURL + endpoint) else {
            let error = AppError.invalidParameter("URL 构建失败：\(endpoint)")
            Logger.error("[\(fileName):\(line)] \(error.userMessage)", file: fileName, line: line)
            throw error
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // 添加 Token
        if requiresAuth {
            if let token = KeychainManager.shared.getToken() {
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        
        // 构建请求体
        var body = Data()
        
        // 添加额外参数
        if let params = parameters {
            for (key, value) in params {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }
        
        // 添加文件
        let uploadFileName = fileURL.lastPathComponent
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(parameterName)\"; filename=\"\(uploadFileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        
        urlRequest.httpBody = body
        try urlRequest.httpBody?.append(Data(contentsOf: fileURL))
        urlRequest.httpBody?.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        // 发送请求
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = AppError.network(NSError(domain: "Upload", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "无效的 HTTP 响应"
            ]))
            Logger.error("[\(fileName):\(line)] \(error.userMessage)", file: fileName, line: line)
            throw error
        }
        
        if httpResponse.statusCode == 200 {
            Logger.info("[\(fileName):\(line)] 文件上传成功", file: fileName, line: line)
            return data
        } else {
            let error = AppError.serverError(httpResponse.statusCode, "上传失败 (\(httpResponse.statusCode))")
            Logger.error("[\(fileName):\(line)] \(error.userMessage)", file: fileName, line: line)
            throw error
        }
    }
    
    // MARK: - 工具方法
    
    /// 检查网络连接
    func isConnected() async -> Bool {
        // 简单检查：尝试访问一个可靠的 URL
        guard let url = URL(string: "https://www.apple.com") else {
            return false
        }
        
        do {
            let (_, response) = try await session.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    /// 清除缓存
    func clearCache() {
        URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
        URLSession.shared.configuration.urlCache = nil
        Logger.info("网络缓存已清除", file: #file, line: #line)
    }
}

// MARK: - GraphQL 响应包装器
// 注意：GraphQLResponse 和 GraphQLErrorItem 已在 Models.swift 中定义，此处不再重复定义

// MARK: - 使用示例
/*
 
 // 基础 GET 请求
 let data = try await NetworkService.shared.request(
     endpoint: "/api/user.php",
     method: .GET
 )
 
 // GraphQL 查询
 struct UserResponse: Decodable {
     let user: User
 }
 
 let response: UserResponse = try await NetworkService.shared.graphql(
     query: "query { user { id name phone } }"
 )
 
 // 带重试的请求
 let data = try await NetworkService.shared.requestWithRetry(
     endpoint: "/api/sync.php",
     method: .POST,
     parameters: ["data": jsonData]
 )
 
 // 文件上传
 let data = try await NetworkService.shared.uploadFile(
     endpoint: "/api/upload.php",
     fileURL: localFileURL,
     parameterName: "media",
     mimeType: "video/mp4"
 ) { progress in
     print("上传进度：\(progress * 100)%")
 }
 
 */
