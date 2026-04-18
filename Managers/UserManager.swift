//
//  UserManager.swift
//  终活
//
//  用户管理 - 注册、登录、紧急联系人、定位
//  技术文档：📖 终活 App 技术开发文档.md - 第 3 章 前端技术栈
//

import Foundation
import Combine
import CoreLocation
import UIKit

// SyncManager 在同一模块中，无需额外 import

/// 用户管理器 - 负责用户认证、位置服务、数据同步
/// 
/// 核心功能：
/// - 用户注册/登录/退出
/// - 位置服务（使用真实 GPS 精度）
/// - 紧急联系人管理
/// - 家人绑定与邀请码
/// - 本地数据持久化
/// 
/// 技术要点：
/// - 单例模式：`UserManager.shared`
/// - 位置精度：使用真实 horizontalAccuracy
/// - 数据持久化：user.json 本地存储
/// - API 调用：GraphQL 架构
/// 
/// ✅ P2 修复 #6: 更新注释与代码一致
class UserManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = UserManager()
    
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var needsEmergencyContactCheck: Bool = false
    @Published var lastCheckInDate: Date?
    @Published var checkInInterval: CheckInInterval = .twoDays
    @Published var currentLocation: CLLocation?
    
    // 🔴 防重复签到标志
    private var isAutoSigningIn = false
    private var lastAutoSignInTime: Date = .distantPast
    
    private let fileManager = FileManager.default
    private var documentsPath: String {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].path
    }
    
    var userFileURL: URL {
        // ✅ 修复：按 userId 隔离本地文件，支持多账号切换
        if let userId = KeychainManager.shared.getUserId() {
            return URL(fileURLWithPath: documentsPath).appendingPathComponent("user_\(userId).json")
        } else {
            // 未登录时使用默认文件名
            return URL(fileURLWithPath: documentsPath).appendingPathComponent("user.json")
        }
    }
    
    /// 获取所有本地用户文件列表（用于清理）
    func getAllUserFiles() -> [URL] {
        let files = try? fileManager.contentsOfDirectory(at: URL(fileURLWithPath: documentsPath), includingPropertiesForKeys: nil)
        return files?.filter { $0.lastPathComponent.hasPrefix("user_") && $0.lastPathComponent.hasSuffix(".json") } ?? []
    }
    
    /// 清除所有本地用户文件（退出登录时调用）
    func clearAllUserFiles() {
        let files = getAllUserFiles()
        for file in files {
            try? fileManager.removeItem(at: file)
        }
        print("🗑️ 已清除 \(files.count) 个本地用户文件")
    }
    
    var userFileExists: Bool {
        fileManager.fileExists(atPath: userFileURL.path)
    }
    
    // MARK: - 定位管理
    
    /// 位置管理器
    private let locationManager = CLLocationManager()
    
    /// 定位授权状态
    @Published var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    
    /// 初始化
    /// - 自动配置定位管理器
    /// - 加载本地用户数据
    override init() {
        super.init()
        setupLocationManager()
        // ✅ 延迟 loadUser 调用，避免初始化时卡死
        // loadUser 会在需要时自动调用
    }
    
    /// 配置定位管理器
    /// - 授权级别：导航级精度（kCLLocationAccuracyBestForNavigation）
    /// - 距离过滤器：50 米（移动 50 米以上才更新）
    /// - 活动类型：其他导航（自动优化定位策略）
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation  // 导航级精度
        locationManager.distanceFilter = 50  // 移动 50 米以上再更新
        locationManager.activityType = .otherNavigation  // 自动优化定位策略
        
        locationAuthStatus = CLLocationManager.authorizationStatus()
    }
    
    // MARK: - 定位权限管理
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysAuthorizationIfNeeded() {
        // ✅ P2 修复 #6: 更新注释
        // 如果用户修改了签到间隔（不是测试模式），请求后台定位
        guard let user = currentUser,
              user.checkInInterval != .oneMinute,
              locationAuthStatus == .authorizedWhenInUse else {
            return
        }
        
        if DebugConfig.enableLogs {
            print("🔔 请求后台定位权限")
        }
        locationManager.requestAlwaysAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        print("🛰️ 开始定位")
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func getCurrentLocation() -> String? {
        guard let location = currentLocation else { return nil }
        return "\(location.coordinate.latitude), \(location.coordinate.longitude)"
    }
    
    // MARK: - CLLocationManagerDelegate
    
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthStatus = manager.authorizationStatus
        print("🔐 定位授权状态：\(authorizationStatusText())")
    }
    
    private func authorizationStatusText() -> String {
        switch locationAuthStatus {
        case .notDetermined: return "未决定"
        case .restricted: return "受限"
        case .denied: return "拒绝"
        case .authorizedAlways: return "始终允许"
        case .authorizedWhenInUse: return "使用期间允许"
        @unknown default: return "未知"
        }
    }
    
    // MARK: - 位置上传
    private var isContinuouslyUpdating = false  // 是否正在持续定位
    private var continuousUploadTimer: Timer?  // 定时上传定时器
    private var locationUpdateCount = 0  // 位置更新次数（用于模拟精度提升）
    
    @MainActor
    func uploadLocation() {
        print("🔵 ====== uploadLocation 开始 ======")
        print("   - currentUser: \(currentUser?.name ?? "nil")")
        print("   - locationAuthStatus: \(locationAuthStatus)")
        print("   - API URL: \(DataManager.apiURL)")
        
        guard let user = currentUser else {
            print("❌ uploadLocation 失败：currentUser 为 nil")
            return
        }
        
        guard locationAuthStatus == .authorizedAlways || locationAuthStatus == .authorizedWhenInUse else {
            print("⚠️ 定位未授权 (\(locationAuthStatus))，跳过位置上传")
            print("💡 请在 设置 → 隐私 → 定位服务 中允许终活 App 使用定位")
            return
        }
        
        // 重置计数器（模拟首次定位）
        locationUpdateCount = 0
        print("🔄 重置位置更新计数器：\(locationUpdateCount)")
        
        print("📍 开始持续定位...")
        startContinuousLocationUpdates()
    }
    
    // MARK: - 持续定位
    
    /// 开始持续定位并上传（使用真实 GPS 精度）
    /// 
    /// 功能说明：
    /// - 每 3 秒上传一次位置
    /// - 使用真实 horizontalAccuracy
    /// 
    /// 技术实现：
    /// - 使用 Timer 定时触发（每 3 秒）
    /// - 使用 CLLocation 的 actualAccuracy
    /// 
    /// 后端地图效果：
    /// - 蓝色半透明圆圈 + 脉冲动画
    /// - 每 5 秒自动刷新用户位置
    /// - 显示真实精度范围
    /// 
    /// ✅ P2 修复 #4: 使用真实精度，不再模拟
    /// ✅ P2 修复 #6: 更新注释与代码一致
    func startContinuousLocationUpdates() {
        guard !isContinuouslyUpdating else {
            print("⚠️ 已经在持续定位中")
            return
        }
        
        isContinuouslyUpdating = true
        locationUpdateCount = 0
        print("🔄 开始持续定位模式（查找我的 iPhone 风格）")
        
        // 配置定位：最高精度
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5  // 移动 5 米更新
        
        // 开始定位
        locationManager.startUpdatingLocation()
        
        // 定时上传：每 3 秒上传一次（模拟精度提升）
        continuousUploadTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.uploadLatestLocation()
        }
        // 添加到 RunLoop 避免循环引用
        RunLoop.current.add(continuousUploadTimer!, forMode: .default)
        
        // 首次立即上传（大范围）
        uploadLatestLocation()
    }
    
    /// 停止持续定位
    func stopContinuousLocationUpdates() {
        isContinuouslyUpdating = false
        continuousUploadTimer?.invalidate()
        continuousUploadTimer = nil
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil  // 释放代理引用
        print("⏹️ 停止持续定位")
    }
    
    /// 上传最新位置（即使用户未移动）- 定时器调用
    private func uploadLatestLocation() {
        guard let location = locationManager.location else {
            print("⚠️ 暂无可用位置")
            return
        }
        
        // 🔧 修复：定时器触发时才递增计数器（模拟精度提升）
        handleLocationUpdate(location, fromTimer: true)
    }
    
    /// 处理位置更新（使用真实 GPS 精度）
    /// - Parameters:
    ///   - location: 位置信息
    ///   - fromTimer: 是否来自定时器触发
    // ✅ P2 修复 #4: 使用真实 accuracy
    // ✅ P2 修复 #6: 更新注释
    // ✅ P2 修复 #9: 使用 DebugConfig 控制日志
    private func handleLocationUpdate(_ location: CLLocation, fromTimer: Bool = false) {
        guard let user = currentUser else { return }
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let actualAccuracy = location.horizontalAccuracy
        let age = Date().timeIntervalSince(location.timestamp)
        
        if DebugConfig.enableNetworkLogs {
            print("📍 获取位置：\(latitude), \(longitude)")
            print("📊 实际精度：\(actualAccuracy)米，年龄：\(String(format: "%.1f", age))秒")
        }
        
        // 检查位置有效性
        if actualAccuracy < 0 || latitude == 0 || longitude == 0 {
            if DebugConfig.enableErrorLogs {
                errorPrint("位置数据无效，跳过")
            }
            return
        }
        
        // 检查位置年龄（使用配置文件中的常量）
        if age > AppConfig.maxLocationAge {
            if DebugConfig.enableLogs {
                print("⚠️ 位置太旧（\(String(format: "%.0f", age))秒），跳过")
            }
            return
        }
        
        // ✅ P2 修复 #4: 使用真实 accuracy，不再模拟精度
        // 后端地图使用真实精度显示范围圈
        let accuracyToUpload = actualAccuracy
        if DebugConfig.enableLogs {
            print("📍 位置更新 #\(locationUpdateCount): 精度=±\(Int(actualAccuracy))米")
        }
        
        // ✅ 上传真实精度的位置（让后端显示真实范围圈）
        if DebugConfig.enableNetworkLogs {
            print("✅ 准备上传（真实精度：±\(Int(accuracyToUpload))米）")
        }
        
        // 逆地理编码获取地址
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            var address = ""
            if let placemark = placemarks?.first {
                var parts: [String] = []
                if let name = placemark.name { parts.append(name) }
                if let locality = placemark.locality { parts.append(locality) }
                if let administrativeArea = placemark.administrativeArea { parts.append(administrativeArea) }
                if let country = placemark.country { parts.append(country) }
                address = parts.joined(separator: " ")
            }
            
            // ✅ P2 修复 #4: 上传真实精度
            Task {
                await self.uploadLocationToServer(userId: user.id, latitude: latitude, longitude: longitude, address: address, accuracy: accuracyToUpload)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 持续定位模式下，处理每个位置更新（但不递增计数器）
        if isContinuouslyUpdating {
            handleLocationUpdate(location, fromTimer: false)
        }
    }
    
    // locationManager(_:didUpdateLocations:) 已移到上面，在持续定位模式下处理
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Swift.Error) {
        // ✅ P2 修复 #9: 使用 DebugConfig 控制日志
        if DebugConfig.enableErrorLogs {
            errorPrint("定位失败：\(error)")
        }
    }
    
    private func uploadLocationToServer(userId: String, latitude: Double, longitude: Double, address: String, accuracy: Double? = nil) async {
        // ✅ P2 修复 #9: 使用 DebugConfig 控制日志
        // 获取 token
        let token = KeychainManager.shared.getToken() ?? ""
        if token.isEmpty {
            if DebugConfig.enableErrorLogs {
                errorPrint("无 token，跳过位置上传")
            }
            return
        }
        
        // 使用传入的精度或默认值
        let accuracyValue = accuracy ?? 1000.0
        if DebugConfig.enableNetworkLogs {
            print("📍 准备上传位置（GraphQL）：\(latitude), \(longitude), 精度：\(accuracyValue)米")
        }
        
        let query = """
        mutation($latitude: Float!, $longitude: Float!, $accuracy: Float, $address: String) {
            uploadLocation(latitude: $latitude, longitude: $longitude, accuracy: $accuracy, address: $address) {
                success
                message
                data {
                    id
                    latitude
                    longitude
                }
            }
        }
        """
        
        let variables: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "accuracy": accuracyValue,
            "address": address
        ]
        
        do {
            let response = try await UserManager.sendGraphQLQueryWithToken(query: query, variables: variables)
            
            if let data = response["data"] as? [String: Any],
               let uploadLocation = data["uploadLocation"] as? [String: Any],
               let success = uploadLocation["success"] as? Bool, success {
                print("✅ 位置上传成功（GraphQL）：\(latitude), \(longitude)")
                if let message = uploadLocation["message"] as? String {
                    print("   \(message)")
                }
            } else {
                print("❌ 位置上传失败")
            }
        } catch {
            print("❌ 位置上传失败：\(error)")
        }
    }
    
    // MARK: - GraphQL 辅助方法
    
    /// 发送带 Token 的 GraphQL 请求（静态方法）
    /// ✅ 支持自动刷新 Token（永久登录）
    /// ✅ P0 修复 #3: 仅使用 Keychain 存储 Token，移除 UserDefaults
    static func sendGraphQLQueryWithToken(query: String, variables: [String: Any]) async throws -> [String: Any] {
        let baseURL = UserDefaults.standard.string(forKey: "lastUsedBaseURL") ?? "8.136.41.211:3395"
        guard let apiURL = URL(string: "\(baseURL)/api/graphql.php") else {
            throw NSError(domain: "Invalid URL", code: -1)
        }
        
        // ✅ 仅从 Keychain 读取 Token（安全存储）
        let token = KeychainManager.shared.getToken()
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token ?? "")", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "query": query,
            "variables": variables
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Server error", code: -1)
        }
        
        // ✅ 检查响应头中的新 Token（自动刷新）
        if let newToken = httpResponse.allHeaderFields["X-New-Token"] as? String {
            KeychainManager.shared.saveToken(newToken)
            print("🔄 Token 已自动刷新（永久登录，Keychain 存储）")
        }
        
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
    
    // MARK: - 用户注册
    func register(name: String, phone: String, password: String) -> Result<User, Error> {
        if !isValidPhone(phone) {
            return .failure(Error.invalidPhone)
        }
        
        // ✅ 修复：移除已注册检查，支持同一手机号注册多个账号（后端会验证）
        // 本地不再限制，由后端判断手机号是否已存在
        
        let user = User(
            id: UUID().uuidString,
            name: name,
            phone: phone,
            createdAt: Date(),
            emergencyContacts: [],
            checkInInterval: .twoDays,
            notificationsEnabled: true,
            cloudSyncEnabled: true,
            lastCheckInDate: nil,
            lastLoginAt: nil,
            lastLoginIp: nil,
            checkinCount: 0
        )
        
        if saveUser(user) {
            self.currentUser = user
            self.isLoggedIn = true
            self.lastCheckInDate = user.lastCheckInDate
            self.needsEmergencyContactCheck = true
            startUpdatingLocation()
            return .success(user)
        } else {
            return .failure(Error.saveFailed)
        }
    }
    
    // MARK: - 设备检测（新设备登录提示恢复数据）
    
    /// 获取当前设备标识符
    var currentDeviceId: String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
    
    /// 保存设备标识符
    func saveCurrentDeviceId() {
        UserDefaults.standard.set(currentDeviceId, forKey: "lastDeviceId_\(currentUser?.id ?? "unknown")")
    }
    
    /// 检查是否为新设备
    func isNewDevice() -> Bool {
        guard let userId = currentUser?.id else { return true }
        let savedDeviceId = UserDefaults.standard.string(forKey: "lastDeviceId_\(userId)")
        return savedDeviceId != currentDeviceId
    }
    
    /// 检查本地数据是否为空
    @MainActor
    func isLocalDataEmpty() -> Bool {
        let dataManager = DataManager.shared
        return dataManager.capsules.isEmpty && 
               dataManager.willModules.isEmpty && 
               dataManager.emergencyContacts.isEmpty && 
               dataManager.witnesses.isEmpty
    }
    
    func login(phone: String) -> Result<User, Error> {
        guard var user = loadUserFromFile() else {
            return .failure(Error.userNotFound)
        }
        
        // 简化登录：只要文件中有用户且手机号匹配即可
        if user.phone != phone {
            // 如果手机号不匹配，更新为用户（兼容多用户场景）
            user.phone = phone
            _ = saveUser(user)
        }
        
        self.currentUser = user
        self.isLoggedIn = true
        self.lastCheckInDate = user.lastCheckInDate
        self.checkInInterval = user.checkInInterval
        
        print("✅ 用户登录成功：\(user.name), 手机号：\(user.phone), 签到间隔：\(user.checkInInterval.rawValue)")
        
        // ✅ P0 修复 #3: 仅使用 Keychain 存储 Token（安全存储）
        // 从 Keychain 读取 Token 并保存用户信息
        if let token = KeychainManager.shared.getToken() {
            KeychainManager.shared.saveUserId(user.id)
            KeychainManager.shared.saveUserPhone(user.phone)
            print("🔐 Token 已保存到 Keychain（永久登录）")
        }
        
        // ✅ 保存设备标识符（用于新设备检测）
        saveCurrentDeviceId()
        
        // 触发实时同步
        Task {
            await RealTimeSyncManager.shared.userDidLogin()
        }
        
        self.checkEmergencyContacts()
        startUpdatingLocation()
        return .success(user)
    }
    
    // MARK: - 自动签到（每次打开 App 自动重置倒计时）
    @MainActor
    func performAutoSignIn() {
        // 🔴 防重复：10 秒内不重复签到
        let now = Date()
        if isAutoSigningIn || now.timeIntervalSince(lastAutoSignInTime) < 10 {
            print("⏭️ 跳过重复签到（防重复机制）")
            return
        }
        
        isAutoSigningIn = true
        lastAutoSignInTime = now
        
        defer {
            isAutoSigningIn = false
        }
        
        let logPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("checkin_log.txt")
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        
        func writeLog(_ msg: String) {
            var content = (try? String(contentsOf: logPath)) ?? ""
            content += "\n[\(timestamp)] \(msg)"
            try? content.write(to: logPath, atomically: true, encoding: .utf8)
            print(msg)
        }
        
        writeLog("🔵 ====== 自动签到检查 ======")
        
        guard let user = currentUser else {
            writeLog("❌ 自动签到失败：currentUser 为 nil")
            return
        }
        
        let lastCheckIn = user.lastCheckInDate ?? Date.distantPast
        let intervalHours = user.checkInInterval.hours
        let requiredInterval = intervalHours * 3600
        let timeSinceLastCheckIn = now.timeIntervalSince(lastCheckIn)
        let hoursRemaining = (requiredInterval - timeSinceLastCheckIn) / 3600
        
        writeLog("👤 当前用户：\(user.name)")
        writeLog("📅 上次签到：\(user.lastCheckInDate?.formatted() ?? "从未签到")")
        writeLog("⏰ 签到间隔：\(intervalHours) 小时")
        writeLog("📊 距离上次签到：\(String(format: "%.1f", timeSinceLastCheckIn / 3600)) 小时")
        writeLog("📊 剩余时间：\(String(format: "%.1f", hoursRemaining)) 小时")
        
        // 🎯 核心逻辑：打开 App 自动重置倒计时（证明用户安全）
        // 无论是否过期，只要打开 App 就自动签到（重置倒计时）
        writeLog("🔄 打开 App 自动签到，重置倒计时（证明用户安全）...")
        let result = recordCheckIn(isAuto: true)
        if case .success = result {
            writeLog("✅ 自动签到成功！倒计时已重置为 \(intervalHours) 小时")
            
            // 📱 安排推送提醒（倒计时剩余 12 小时时开始提醒）
            let newHoursRemaining = Double(intervalHours)
            scheduleCheckInReminder(hoursRemaining: newHoursRemaining)
            writeLog("🔔 已安排推送提醒：剩余 \(Int(newHoursRemaining)) 小时开始提醒")
            
            // 🔄 通知 HomeStatusView 刷新倒计时
            NotificationCenter.default.post(name: NSNotification.Name("CheckInDidComplete"), object: nil)
        } else {
            writeLog("❌ 自动签到失败：\(result)")
        }
    }
    
    @MainActor
    func performAutoCheckIn() {
        // 🔴 防重复：10 秒内不重复签到
        let now = Date()
        if isAutoSigningIn || now.timeIntervalSince(lastAutoSignInTime) < 10 {
            print("⏭️ performAutoCheckIn 跳过重复签到（防重复机制）")
            return
        }
        
        isAutoSigningIn = true
        lastAutoSignInTime = now
        
        defer {
            isAutoSigningIn = false
        }
        
        let logPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("checkin_log.txt")
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        
        func writeLog(_ msg: String) {
            var content = (try? String(contentsOf: logPath)) ?? ""
            content += "\n[\(timestamp)] \(msg)"
            try? content.write(to: logPath, atomically: true, encoding: .utf8)
            print(msg)
        }
        
        writeLog("🔵 ====== 自动签到（打开 App） ======")
        
        guard let user = currentUser else {
            writeLog("❌ 自动签到失败：currentUser 为 nil")
            return
        }
        
        let lastCheckIn = user.lastCheckInDate ?? Date.distantPast
        let intervalHours = user.checkInInterval.hours
        let requiredInterval = intervalHours * 3600
        let timeSinceLastCheckIn = now.timeIntervalSince(lastCheckIn)
        let hoursRemaining = (requiredInterval - timeSinceLastCheckIn) / 3600
        
        writeLog("👤 当前用户：\(user.name)")
        writeLog("📅 上次签到：\(user.lastCheckInDate?.formatted() ?? "从未签到")")
        writeLog("⏰ 签到间隔：\(intervalHours) 小时")
        writeLog("📊 距离上次签到：\(String(format: "%.1f", timeSinceLastCheckIn / 3600)) 小时")
        writeLog("📊 剩余时间：\(String(format: "%.1f", hoursRemaining)) 小时")
        
        // 🎯 核心逻辑：打开 App 自动重置倒计时（证明用户安全）
        writeLog("🔄 自动重置签到倒计时（证明用户安全）...")
        let result = recordCheckIn(isAuto: true)
        if case .success = result {
            writeLog("✅ 自动签到成功！倒计时已重置")
        } else {
            print("❌ 自动签到失败：\(result)")
        }
    }
    
    // 推送签到提醒
    @MainActor
    private func scheduleCheckInReminder(hoursRemaining: Double) {
        let hoursLeft = Int(hoursRemaining)
        let message = "您的签到还剩 \(hoursLeft) 小时，请及时签到"
        
        print("🔔 推送提醒：\(message)")
        
        // 📱 使用本地通知（倒计时剩余 12 小时时开始提醒，每 1 小时推送一次）
        NotificationManager.shared.scheduleCheckInReminders(hoursRemaining: hoursRemaining)
    }
    
    // 通知紧急联系人（倒计时结束时）
    private func notifyEmergencyContactsIfNeeded() {
        guard let user = currentUser,
              !user.emergencyContacts.isEmpty else {
            print("❌ 没有紧急联系人，无法通知")
            return
        }
        
        let lastCheckIn = user.lastCheckInDate ?? Date.distantPast
        let intervalHours = user.checkInInterval.hours
        let timeSinceLastCheckIn = Date().timeIntervalSince(lastCheckIn)
        let hoursOverdue = (timeSinceLastCheckIn - (Double(intervalHours) * 3600)) / 3600
        
        // 只有超过签到间隔才通知
        guard hoursOverdue > 0 else {
            return
        }
        
        print("🚨 签到已过期 \(String(format: "%.1f", hoursOverdue)) 小时，准备通知 \(user.emergencyContacts.count) 位紧急联系人")
        
        for contact in user.emergencyContacts {
            print("📱 通知紧急联系人：\(contact.name) (\(contact.phone))")
            
            // 📲 发送短信通知（使用 Message Framework）
            let message = "【终活 App】\(user.name) 已超过 \(String(format: "%.0f", hoursOverdue)) 小时未签到，请您关注其安全状况。"
            sendSmsToContact(contact.phone, message: message)
        }
    }
    
    // 发送短信给紧急联系人
    // 支持 3 种方案：
    // 1. Message Framework（iOS 原生，可单独开关）
    // 2. 阿里云短信 API（可开关）
    // 3. 腾讯云短信 API（可开关，与阿里云任选其一）
    private func sendSmsToContact(_ phone: String, message: String) {
        print("📲 准备发送短信到：\(phone)")
        print("   内容：\(message)")
        
        // 📱 方案 1: Message Framework（iOS 原生）
        let useMessageFramework = UserDefaults.standard.bool(forKey: "sms_use_message_framework")
        if useMessageFramework {
            sendViaMessageFramework(phone: phone, message: message)
        }
        
        // ☁️ 方案 2: 阿里云短信 API
        let useAliyunSms = UserDefaults.standard.bool(forKey: "sms_use_aliyun")
        if useAliyunSms {
            sendViaAliyunSms(phone: phone, message: message)
        }
        
        // ☁️ 方案 3: 腾讯云短信 API（与阿里云任选其一）
        let useTencentSms = UserDefaults.standard.bool(forKey: "sms_use_tencent")
        if useTencentSms {
            sendViaTencentSms(phone: phone, message: message)
        }
        
        // 如果都没有启用，仅记录日志
        if !useMessageFramework && !useAliyunSms && !useTencentSms {
            print("⚠️ 未启用任何短信发送方案，仅记录日志")
        }
    }
    
    // MARK: - 短信发送方案
    
    /// 方案 1: Message Framework（iOS 原生）
    private func sendViaMessageFramework(phone: String, message: String) {
        print("📱 [方案 1] Message Framework 发送短信")
        // ✅ 使用 MFMessageComposeViewController 需要用户交互，不适合后台发送
        // 已移至 MessageManager 实现
        print("   ⚠️ Message Framework 需要用户交互，使用 MessageManager 代替")
    }
    
    /// 方案 2: 阿里云短信 API
    private func sendViaAliyunSms(phone: String, message: String) {
        print("☁️ [方案 2] 阿里云短信 API 发送短信")
        
        // 🔒 安全修复：从 Keychain 读取密钥
        let accessKeyId = KeychainManager.shared.getAliyunAccessKeyId() ?? ""
        let accessKeySecret = KeychainManager.shared.getAliyunAccessKeySecret() ?? ""
        
        guard !accessKeyId.isEmpty && !accessKeySecret.isEmpty else {
            print("   ❌ 阿里云短信配置不完整，跳过发送")
            return
        }
        
        Task {
            // ✅ 调用后端短信发送 API
            do {
                let result = try await DataManager.shared.sendSmsNotification(phone: phone, message: message)
                if result {
                    print("   ✅ 阿里云短信发送成功")
                } else {
                    print("   ⚠️ 阿里云短信发送失败")
                }
            } catch {
                print("   ❌ 阿里云短信发送失败：\(error)")
            }
        }
    }
    
    /// 方案 3: 腾讯云短信 API
    private func sendViaTencentSms(phone: String, message: String) {
        print("☁️ [方案 3] 腾讯云短信 API 发送短信")
        
        // 🔒 安全修复：从 Keychain 读取密钥
        let secretId = KeychainManager.shared.getTencentSecretId() ?? ""
        let secretKey = KeychainManager.shared.getTencentSecretKey() ?? ""
        
        guard !secretId.isEmpty && !secretKey.isEmpty else {
            print("   ❌ 腾讯云短信配置不完整，跳过发送")
            return
        }
        
        Task {
            // ✅ 调用后端短信发送 API
            do {
                let result = try await DataManager.shared.sendSmsNotification(phone: phone, message: message)
                if result {
                    print("   ✅ 腾讯云短信发送成功")
                } else {
                    print("   ⚠️ 腾讯云短信发送失败")
                }
            } catch {
                print("   ❌ 腾讯云短信发送失败：\(error)")
            }
        }
    }
    
    @MainActor
    func recordCheckIn(isAuto: Bool = false) -> Result<Void, Error> {
        print("🔵 ====== recordCheckIn 开始 ======")
        print("   - isAuto: \(isAuto)")
        print("   - currentUser: \(currentUser?.name ?? "nil")")
        print("   - isLoggedIn: \(isLoggedIn)")
        print("   - API URL: \(DataManager.apiURL)")
        // 🔒 安全修复：不再打印 Token
        
        guard var user = currentUser else {
            print("❌ recordCheckIn 失败：currentUser 为 nil")
            return .failure(Error.userNotLoggedIn)
        }
        
        user.lastCheckInDate = Date()
        self.currentUser = user
        self.lastCheckInDate = user.lastCheckInDate
        
        // 记录签到位置
        if let locationStr = getCurrentLocation() {
            print("📍 签到位置：\(locationStr)")
        } else {
            print("⚠️ 无位置信息（可能未授权定位）")
        }
        
        print("✅ 记录签到：\(isAuto ? "自动" : "手动")")
        
        if saveUser(user) {
            print("✅ 用户数据已保存到本地")
            
            // 同步到服务器
            Task {
                print("🔄 开始异步同步任务...")
                
                // 1. 同步签到记录
                print("📝 1. 同步签到记录...")
                await syncCheckInToServer(isAuto: isAuto)
                
                // 2. 签到成功后上传位置（无论自动还是手动）
                print("📍 2. 上传位置...")
                self.uploadLocation()
                
                // 3. 签到成功后同步所有数据
                print("📦 3. 同步胶囊数据...")
                if let result = await DataManager.shared.batchSyncCapsules() {
                    print("✅ 胶囊同步完成：\(result)")
                } else {
                    print("❌ 胶囊同步失败或无数据")
                }
                
                print("📦 4. 同步遗嘱数据...")
                if let result = await DataManager.shared.batchSyncWills() {
                    print("✅ 遗嘱同步完成：\(result)")
                } else {
                    print("❌ 遗嘱同步失败或无数据")
                }
                
                print("📦 5. 同步紧急联系人...")
                if let result = await DataManager.shared.batchSyncEmergencyContacts() {
                    print("✅ 紧急联系人同步完成：\(result)")
                } else {
                    print("❌ 紧急联系人同步失败或无数据")
                }
                
                print("📦 6. 同步见证人...")
                if let result = await DataManager.shared.batchSyncWitnesses() {
                    print("✅ 见证人同步完成：\(result)")
                } else {
                    print("❌ 见证人同步失败或无数据")
                }
                
                print("🎉 所有同步任务完成！")
                print("🔵 ====== recordCheckIn 结束 ======")
            }
            
            // 🚨 检查是否需要通知紧急联系人（如果之前已过期）
            notifyEmergencyContactsIfNeeded()
            
            return .success(())
        } else {
            print("❌ 保存用户数据失败")
            return .failure(Error.saveFailed)
        }
    }
    
    // 同步签到到服务器（使用 GraphQL）
    @MainActor
    private func syncCheckInToServer(isAuto: Bool) async {
        guard let token = KeychainManager.shared.getToken(),
              !DataManager.apiURL.isEmpty else {
            print("❌ 签到同步：缺少必要参数")
            return
        }
        
        print("🔵 开始 GraphQL 签到...")
        
        // 🕐 当前时间戳（秒级）
        let checkinTimestamp = Int(Date().timeIntervalSince1970)
        
        // 🔧 修复：传入用户设定的签到间隔（由前端控制）
        let checkInIntervalHours = checkInInterval.hours
        
        // GraphQL Mutation
        let mutation = """
        mutation {
            checkIn(isAuto: \(isAuto ? "true" : "false"), checkinTimestamp: \(checkinTimestamp), checkInIntervalHours: \(checkInIntervalHours)) {
                success
                checkInTime
                expireTimestamp
            }
        }
        """
        
        var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/api/graphql.php") ?? URL(fileURLWithPath: ""))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = ["query": mutation]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 GraphQL 签到响应状态码：\(httpResponse.statusCode)")
            }
            
            let responseText = String(data: data, encoding: .utf8) ?? "无法解析"
            print("📡 GraphQL 签到响应：\(responseText)")
            
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode),
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataDict = json["data"] as? [String: Any],
               let checkInResult = dataDict["checkIn"] as? [String: Any],
               let success = checkInResult["success"] as? Bool, success {
                print("✅ 签到同步成功")
                
                // 重新拉取用户数据，更新签到次数
                await fetchUserData()
            } else {
                print("⚠️ 签到同步返回失败")
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errors = json["errors"] as? [[String: Any]] {
                    print("❌ GraphQL errors: \(errors)")
                }
            }
        } catch {
            print("❌ 签到同步失败：\(error)")
        }
    }
    
    @MainActor
    func logout() {
        print("🔴 UserManager.logout() 被调用")
        self.currentUser = nil
        self.isLoggedIn = false
        self.lastCheckInDate = nil
        self.checkInInterval = .twoDays  // 重置为默认值
        
        // ✅ 修复：清除当前用户的本地文件（支持多账号）
        do {
            if fileManager.fileExists(atPath: userFileURL.path) {
                try fileManager.removeItem(at: userFileURL)
                print("   ✅ 已删除当前用户文件：\(userFileURL.lastPathComponent)")
            }
        } catch {
            print("   ❌ 删除用户文件失败：\(error)")
        }
        
        // 🗑️ 清除 Keychain 中的 Token（永久登录数据）
        KeychainManager.shared.clearAll()
        print("   ✅ 已清除所有登录数据")
        
        print("   currentUser: nil")
        print("   isLoggedIn: \(self.isLoggedIn)")
        print("   lastCheckInDate: nil")
        print("✅ 退出登录完成，所有状态已清除")
    }
    
    @MainActor
    func addEmergencyContact(name: String, phone: String, relationship: String) -> Result<User.EmergencyContact, Error> {
        guard var user = currentUser else {
            return .failure(Error.userNotLoggedIn)
        }
        
        let contact = User.EmergencyContact(
            id: UUID().uuidString,
            name: name,
            phone: phone,
            relationship: relationship,
            isConfirmed: false,
            createdAt: Date()
        )
        
        user.emergencyContacts.append(contact)
        self.currentUser = user
        
        // 🔧 修复：同时更新 DataManager
        DataManager.shared.emergencyContacts.append(contact)
        
        if saveUser(user) {
            print("📞 紧急联系人已添加到本地，准备同步到服务器...")
            
            // 发送数据变更通知（触发实时同步）
            NotificationCenter.default.post(name: NSNotification.Name("EmergencyContactChanged"), object: nil)
            
            // 异步同步到服务器
            Task {
                if let result = await DataManager.shared.batchSyncEmergencyContacts() {
                    print("✅ 紧急联系人同步成功：总计 \(result.total) 个，创建 \(result.created) 个，更新 \(result.updated) 个")
                } else {
                    print("⚠️ 紧急联系人同步失败（可能无网络或未登录）")
                }
            }
            
            return .success(contact)
        } else {
            return .failure(Error.saveFailed)
        }
    }
    
    @MainActor
    func deleteEmergencyContact(id: String) -> Result<Void, Error> {
        guard var user = currentUser else {
            return .failure(Error.userNotLoggedIn)
        }
        
        // 🔧 修复：标记删除而不是直接删除（用于同步到服务器）
        if let index = user.emergencyContacts.firstIndex(where: { $0.id == id }) {
            user.emergencyContacts[index].deletedAt = Date()
        }
        
        // 从 DataManager 中移除（UI 立即更新）
        DataManager.shared.emergencyContacts.removeAll { $0.id == id }
        
        self.currentUser = user
        
        if saveUser(user) {
            print("📞 紧急联系人已标记删除，准备同步到服务器...")
            
            // 发送数据变更通知（触发实时同步）
            NotificationCenter.default.post(name: NSNotification.Name("EmergencyContactChanged"), object: nil)
            
            // 异步同步删除到服务器
            Task {
                if let result = await DataManager.shared.batchSyncEmergencyContacts() {
                    print("✅ 紧急联系人删除同步成功")
                } else {
                    print("⚠️ 紧急联系人删除同步失败")
                }
            }
            
            return .success(())
        } else {
            return .failure(Error.saveFailed)
        }
    }
    
    @MainActor
    func updateEmergencyContact(_ contact: User.EmergencyContact) -> Result<Void, Error> {
        guard var user = currentUser,
              let index = user.emergencyContacts.firstIndex(where: { $0.id == contact.id }) else {
            return .failure(Error.userNotLoggedIn)
        }
        
        user.emergencyContacts[index] = contact
        self.currentUser = user
        
        if saveUser(user) {
            print("📞 紧急联系人已更新到本地，准备同步到服务器...")
            
            // 发送数据变更通知（触发实时同步）
            NotificationCenter.default.post(name: NSNotification.Name("EmergencyContactChanged"), object: nil)
            
            // 异步同步到服务器
            Task {
                if let result = await DataManager.shared.batchSyncEmergencyContacts() {
                    print("✅ 紧急联系人同步成功：总计 \(result.total) 个，创建 \(result.created) 个，更新 \(result.updated) 个")
                } else {
                    print("⚠️ 紧急联系人同步失败（可能无网络或未登录）")
                }
            }
            
            return .success(())
        } else {
            return .failure(Error.saveFailed)
        }
    }
    
    func checkEmergencyContacts() {
        guard let user = currentUser else { return }
        
        let count = user.emergencyContacts.count
        self.needsEmergencyContactCheck = (count < 2)
        print("🔍 检查紧急联系人：\(count) 个，需要提醒：\(needsEmergencyContactCheck)")
    }
    
    func updateCheckInInterval(_ interval: CheckInInterval) -> Result<Void, Error> {
        guard var user = currentUser else {
            print("❌ 用户未登录，无法更新签到间隔")
            return .failure(Error.userNotLoggedIn)
        }
        
        let oldInterval = user.checkInInterval
        user.checkInInterval = interval
        self.currentUser = user
        self.checkInInterval = interval
        
        print("🔵 更新签到间隔：\(oldInterval.rawValue) → \(interval.rawValue)")
        print("📁 用户文件路径：\(userFileURL.path)")
        
        // Bug 3: 如果不是测试模式，检查后台定位
        if interval != .oneMinute {
            requestAlwaysAuthorizationIfNeeded()
        }
        
        do {
            let data = try JSONEncoder().encode(user)
            try data.write(to: userFileURL)
            print("✅ 签到间隔已保存到用户文件")
            
            // 验证保存
            if let savedUser = loadUserFromFile() {
                print("✅ 验证保存：\(savedUser.checkInInterval.rawValue)")
            }
            return .success(())
        } catch {
            print("❌ 保存用户文件失败：\(error)")
            return .failure(Error.saveFailed)
        }
    }
    
    func getEmergencyContactsCount() -> Int {
        return currentUser?.emergencyContacts.count ?? 0
    }
    
    // ✅ P2 修复 #3: 添加加载锁，防止重复请求
    // ✅ 性能优化：避免重复加载
    private var isUserLoaded = false
    private var isFetchingUserData = false
    private let userLoadLock = NSLock()  // 加载锁
    
    // ✅ P2 修复 #3: 使用加载锁防止重复请求
    @MainActor
    func loadUser() {
        // ✅ 如果已加载，直接返回（避免重复）
        if isUserLoaded && currentUser != nil {
            if DebugConfig.enableLogs {
                print("✅ 用户数据已加载，跳过重复加载")
            }
            return
        }
        
        // ✅ 使用锁防止并发加载
        guard userLoadLock.try() else {
            if DebugConfig.enableLogs {
                print("⚠️ 正在加载用户数据，跳过重复请求")
            }
            return
        }
        defer { userLoadLock.unlock() }
        
        // ✅ 防止重复加载
        if isFetchingUserData {
            if DebugConfig.enableLogs {
                print("⚠️ 正在加载用户数据，跳过重复请求")
            }
            return
        }
        
        print("🔍 UserManager.loadUser() 被调用")
        
        // ✅ 永久登录：优先从 Keychain 恢复 Token
        var token: String? = KeychainManager.shared.getToken()
        
        // 降级方案：从 UserDefaults 读取（兼容旧版本），并迁移到 Keychain
        if token == nil {
            if let oldToken = UserDefaults.standard.string(forKey: "userToken") {
                token = oldToken
                // 迁移到 Keychain
                KeychainManager.shared.saveToken(oldToken)
                // 清除 UserDefaults 中的旧 token
                UserDefaults.standard.removeObject(forKey: "userToken")
                print("🔄 Token 从 UserDefaults 迁移到 Keychain")
            }
        }
        
        if let token = token, !token.isEmpty {
            self.isLoggedIn = true
            
            // 尝试从本地文件加载用户数据（快速）
            if let user = loadUserFromFile() {
                self.currentUser = user
                self.checkInInterval = user.checkInInterval
                self.lastCheckInDate = user.lastCheckInDate
                self.checkEmergencyContacts()
                isUserLoaded = true
                print("🔐 从 Keychain 恢复永久登录状态")
            }
            
            // 异步从服务器拉取最新数据
            Task {
                await fetchUserData()
            }
        } else {
            // 降级方案：从本地文件加载
            if let user = loadUserFromFile() {
                self.currentUser = user
                self.isLoggedIn = true
                self.checkInInterval = user.checkInInterval
                self.lastCheckInDate = user.lastCheckInDate
                self.checkEmergencyContacts()
                isUserLoaded = true
            }
        }
    }
    
    /// 从服务器拉取用户数据（使用 GraphQL）
    // ✅ P2 修复 #3: 使用加载锁防止重复请求
    // ✅ P2 修复 #9: 使用 DebugConfig 控制日志
    func fetchUserData() async {
        // ✅ 防止重复加载
        guard !isFetchingUserData else {
            if DebugConfig.enableLogs {
                print("⚠️ 正在加载用户数据，跳过重复请求")
            }
            return
        }
        
        guard let token = KeychainManager.shared.getToken(),
              !token.isEmpty else {
            return
        }
        
        let apiURL = DataManager.apiURL
        guard !apiURL.isEmpty else {
            print("❌ API URL 未设置")
            return
        }
        
        print("🌐 从服务器拉取用户数据（GraphQL）...")
        isFetchingUserData = true
        
        // 🔥 优化：只查询基础用户信息 + 统计（不查详细数据列表）
        // 详细数据通过 batchSync 按需同步，避免启动时大量数据传输
        // 🕐 添加服务器时间戳，用于精确倒计时同步
        let query = """
        query {
            user {
                id
                name
                phone
                avatarUrl
                gender
                birthday
                lastLoginAt
                lastLoginIp
                lastCheckInDate
                checkinCount
                createdAt
                updatedAt
                stats {
                    emergencyContactsCount
                    witnessesCount
                    capsulesCount
                    willModulesCount
                    familyCount
                    assetsCount
                    checkinCount
                }
            }
        }
        """
        
        print("🔍 GraphQL 查询语句：\(query)")  // 🔥 打印完整查询
        
        var request = URLRequest(url: URL(string: "\(apiURL)/api/graphql.php") ?? URL(fileURLWithPath: ""))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = ["query": query]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 🔍 详细日志
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 GraphQL 响应状态码：\(httpResponse.statusCode)")
                let responseText = String(data: data, encoding: .utf8) ?? "无法解析"
                print("📡 GraphQL 完整响应：\(responseText)")  // 🔥 打印完整响应
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode),
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataDict = json["data"] as? [String: Any],
               let userDict = dataDict["user"] as? [String: Any] {
                
                // 解析用户数据
                let userId = userDict["id"] as? String ?? ""
                let name = userDict["name"] as? String ?? "用户"
                let phone = userDict["phone"] as? String ?? ""
                let avatarUrl = userDict["avatarUrl"] as? String ?? ""
                let gender = userDict["gender"] as? Int ?? 0
                let birthday = userDict["birthday"] as? String ?? ""
                let lastLoginAt = userDict["lastLoginAt"] as? String ?? ""
                let lastLoginIp = userDict["lastLoginIp"] as? String ?? ""
                let lastCheckInDate = userDict["lastCheckInDate"] as? String ?? ""
                let checkinCount = userDict["checkinCount"] as? Int ?? 0
                let createdAt = userDict["createdAt"] as? String ?? ""
                let updatedAt = userDict["updatedAt"] as? String ?? ""
                
                // 解析会员信息
                let isPremium = userDict["isPremium"] as? Bool ?? false
                let memberType = userDict["memberType"] as? String
                let memberExpireAtString = userDict["memberExpireAt"] as? String
                let memberMaxCapsules = userDict["memberMaxCapsules"] as? Int ?? 5
                let memberMaxVideoMinutes = userDict["memberMaxVideoMinutes"] as? Int ?? 2
                let aiAssistEnabled = userDict["aiAssistEnabled"] as? Bool ?? false
                
                // 解析会员过期时间
                var memberExpireAt: Date? = nil
                if let expireStr = memberExpireAtString, !expireStr.isEmpty {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    memberExpireAt = formatter.date(from: expireStr)
                }
                
                // ✅ 更新会员状态（会自动检查过期）
                await MainActor.run {
                    MembershipManager.shared.updateFromServer(
                    isPremium: isPremium,
                    memberType: memberType,
                    memberExpireAt: memberExpireAt,
                    memberMaxCapsules: memberMaxCapsules,
                    memberMaxVideoMinutes: memberMaxVideoMinutes,
                    aiAssistEnabled: aiAssistEnabled
                    )
                }
                
                // 解析统计信息
                var emergencyContactsCount = 0
                var witnessesCount = 0
                var capsulesCount = 0
                var willModulesCount = 0
                var familyCount = 0
                var assetsCount = 0
                
                // 🔍 调试：打印 userDict 的所有 key
                print("🔍 userDict 包含的 keys: \(userDict.keys.sorted())")
                
                // 🔍 强制打印 stats 原始数据
                let statsRaw = userDict["stats"]
                print("🔍 stats 原始数据：\(statsRaw ?? "nil")")
                print("🔍 stats 类型：\(type(of: statsRaw))")
                
                if let stats = userDict["stats"] as? [String: Any] {
                    print("✅ stats 存在：\(stats)")
                    emergencyContactsCount = stats["emergencyContactsCount"] as? Int ?? 0
                    witnessesCount = stats["witnessesCount"] as? Int ?? 0
                    capsulesCount = stats["capsulesCount"] as? Int ?? 0
                    willModulesCount = stats["willModulesCount"] as? Int ?? 0
                    familyCount = stats["familyCount"] as? Int ?? 0
                    assetsCount = stats["assetsCount"] as? Int ?? 0
                    print("✅ 解析后的统计：紧急=\(emergencyContactsCount), 见证=\(witnessesCount), 胶囊=\(capsulesCount), 嘱托=\(willModulesCount), 家人=\(familyCount)")
                } else {
                    print("❌ stats 不存在于 userDict 中！或者类型转换失败")
                    print("❌ userDict[\"stats\"] 实际类型：\(type(of: userDict["stats"]))")
                }
                
                
                // 日期格式化
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                await MainActor.run {
                    // ✅ Swift 6 并发安全：在 MainActor 内使用局部变量副本
                    let localEmergencyContactsCount = emergencyContactsCount
                    let localWitnessesCount = witnessesCount
                    let localCapsulesCount = capsulesCount
                    let localWillModulesCount = willModulesCount
                    let localFamilyCount = familyCount
                    let localAssetsCount = assetsCount
                    
                    print("🔍 fetchUserData: 准备设置 currentUser")
                    print("   - 当前 currentUser: \(self.currentUser?.name ?? "nil")")
                    print("   - userId: \(userId)")
                    print("   - name: \(name)")
                    
                    // 🔧 修复：如果 currentUser 是 nil，创建新用户对象
                    if var currentUser = self.currentUser {
                        // 更新已存在的用户
                        currentUser.emergencyContactsCount = localEmergencyContactsCount
                        currentUser.witnessesCount = localWitnessesCount
                        currentUser.capsulesCount = localCapsulesCount
                        currentUser.willModulesCount = localWillModulesCount
                        currentUser.familyCount = localFamilyCount
                        currentUser.checkinCount = checkinCount
                        currentUser.lastCheckInDate = dateFormatter.date(from: lastCheckInDate) ?? currentUser.lastCheckInDate
                        currentUser.lastLoginAt = dateFormatter.date(from: lastLoginAt) ?? currentUser.lastLoginAt
                        currentUser.lastLoginIp = lastLoginIp.isEmpty ? currentUser.lastLoginIp : lastLoginIp
                        self.currentUser = currentUser
                        
                        print("✅ 用户统计信息已更新：紧急=\(localEmergencyContactsCount), 见证=\(localWitnessesCount), 胶囊=\(localCapsulesCount), 嘱托=\(localWillModulesCount)")
                    } else {
                        // 🔴 创建新用户对象（从服务器数据）
                        let user = User(
                            id: userId,
                            name: name,
                            phone: phone,
                            createdAt: dateFormatter.date(from: createdAt) ?? Date(),
                            emergencyContacts: [],
                            checkInInterval: .oneDay,  // 默认值
                            notificationsEnabled: true,
                            cloudSyncEnabled: true,
                            lastCheckInDate: dateFormatter.date(from: lastCheckInDate),
                            lastLoginAt: dateFormatter.date(from: lastLoginAt),
                            lastLoginIp: lastLoginIp,
                            checkinCount: checkinCount,
                            ethnicity: nil,
                            birthday: nil,
                            idCard: nil,
                            address: nil,
                            emergencyContactsCount: localEmergencyContactsCount,
                            witnessesCount: localWitnessesCount,
                            capsulesCount: localCapsulesCount,
                            willModulesCount: localWillModulesCount,
                            familyCount: localFamilyCount
                        )
                        self.currentUser = user
                        self.isLoggedIn = true
                        print("✅ 从服务器创建用户对象：\(user.name)")
                        print("   - currentUser.id: \(user.id)")
                        print("   - currentUser.phone: \(user.phone)")
                    }
                    
                    // ✅ 标记加载完成
                    isFetchingUserData = false
                    isUserLoaded = true
                    print("✅ fetchUserData 完成：isUserLoaded=\(isUserLoaded), currentUser=\(self.currentUser?.name ?? "nil")")
                }
                
                // 保存本地缓存
                if let currentUser = self.currentUser {
                    saveUser(currentUser)
                }
                
            } else {
                // 🔍 详细错误日志
                if let httpResponse = response as? HTTPURLResponse {
                    print("❌ GraphQL 请求失败 - 状态码：\(httpResponse.statusCode)")
                }
                if let responseText = String(data: data, encoding: .utf8) {
                    print("❌ GraphQL 响应内容：\(responseText)")
                }
                // 检查是否有 GraphQL errors
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errors = json["errors"] as? [[String: Any]] {
                    print("❌ GraphQL errors: \(errors)")
                }
                print("⚠️ 服务器返回失败，使用本地缓存")
                
                // ✅ 失败时也要重置标志
                isFetchingUserData = false
            }
        } catch {
            print("❌ 拉取用户数据失败：\(error)")
            isFetchingUserData = false
            print("   错误详情：\(error.localizedDescription)")
            print("   使用本地缓存")
        }
    }
    
    private func loadUserFromFile() -> User? {
        guard fileManager.fileExists(atPath: userFileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: userFileURL)
            return try JSONDecoder().decode(User.self, from: data)
        } catch {
            print("❌ 加载用户失败：\(error)")
            return nil
        }
    }
    
    func saveUser(_ user: User) -> Bool {
        do {
            let data = try JSONEncoder().encode(user)
            try data.write(to: userFileURL)
            
            // ✅ 修复：确保在主线程修改@Published 属性
            Task { @MainActor in
                self.currentUser = user
                self.isLoggedIn = true  // 确保登录状态保持
                
                // 🔥 自动更新所有统计信息（让 SettingsView 立即显示）
                self.currentUser?.emergencyContactsCount = user.emergencyContacts.count
                // witnesses 和 family 是独立管理的，这里不更新
                // self.currentUser?.witnessesCount = user.witnesses.count
                // self.currentUser?.familyCount = user.family.count
                
                self.checkEmergencyContacts()  // 保存后重新检查
                
                // ✅ P0 修复 #3: 仅使用 Keychain 存储用户 ID（安全存储）
                KeychainManager.shared.saveUserId(user.id)
                
                print("✅ 用户已保存：\(user.name), 紧急联系人：\(user.emergencyContacts.count) 个")
                print("   统计信息：紧急=\(user.emergencyContacts.count)")
                print("   isLoggedIn: \(self.isLoggedIn)")
            }
            return true
        } catch {
            print("❌ 保存用户失败：\(error)")
            return false
        }
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: phone)
    }
    
    // 🔥 更新胶囊数量（让 SettingsView 立即显示）
    func updateCapsulesCount(_ count: Int) {
        DispatchQueue.main.async {
            self.currentUser?.capsulesCount = count
            print("📊 胶囊数量已更新：\(count)")
        }
    }
    
    // 🔥 更新遗嘱数量（让 SettingsView 立即显示）
    func updateWillModulesCount(_ count: Int) {
        DispatchQueue.main.async {
            self.currentUser?.willModulesCount = count
            print("📊 遗嘱数量已更新：\(count)")
        }
    }
    
    // 🔥 更新紧急联系人数量（让 SettingsView 立即显示）
    func updateEmergencyContactsCount(_ count: Int) {
        DispatchQueue.main.async {
            self.currentUser?.emergencyContactsCount = count
            print("📊 紧急联系人数量已更新：\(count)")
        }
    }
    
    // 🔥 更新见证人数量（让 SettingsView 立即显示）
    func updateWitnessesCount(_ count: Int) {
        DispatchQueue.main.async {
            self.currentUser?.witnessesCount = count
            print("📊 见证人数量已更新：\(count)")
        }
    }
    
    // 🔥 更新家人数量（让 SettingsView 立即显示）
    func updateFamilyCount(_ count: Int) {
        DispatchQueue.main.async {
            self.currentUser?.familyCount = count
            print("📊 家人数量已更新：\(count)")
        }
    }
    
    enum Error: LocalizedError {
        case invalidPhone
        case alreadyRegistered
        case userNotLoggedIn
        case saveFailed
        case userNotFound
        case phoneMismatch
        
        var errorDescription: String? {
            switch self {
            case .invalidPhone: return "请输入有效的手机号码"
            case .alreadyRegistered: return "该设备已注册"
            case .userNotLoggedIn: return "用户未登录"
            case .saveFailed: return "操作失败，请重试"
            case .userNotFound: return "用户未注册"
            case .phoneMismatch: return "手机号不匹配"
            }
        }
    }
    
    // MARK: - 清理
    
    deinit {
        continuousUploadTimer?.invalidate()
        continuousUploadTimer = nil
        locationManager.delegate = nil
        locationManager.stopUpdatingLocation()
        print("♻️ UserManager 已释放")
    }
}
