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

// SyncManager 在同一模块中，无需额外 import

/// 用户管理器 - 负责用户认证、位置服务、数据同步
/// 
/// 核心功能：
/// - 用户注册/登录/退出
/// - 位置服务（查找我的 iPhone 风格精度动画）
/// - 紧急联系人管理
/// - 家人绑定与邀请码
/// - 本地数据持久化
/// 
/// 技术要点：
/// - 单例模式：`UserManager.shared`
/// - 位置精度：1000m → 500m → 200m → 100m → 50m → 10m（每 3 秒）
/// - 数据持久化：user.json 本地存储
/// - API 调用：REST API + GraphQL 混合架构
class UserManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = UserManager()
    
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var needsEmergencyContactCheck: Bool = false
    @Published var lastCheckInDate: Date?
    @Published var checkInInterval: CheckInInterval = .twoDays
    @Published var currentLocation: CLLocation?
    
    private let fileManager = FileManager.default
    private var documentsPath: String {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].path
    }
    
    var userFileURL: URL {
        URL(fileURLWithPath: documentsPath).appendingPathComponent("user.json")
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
        loadUser()
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
        // Bug 3: 如果用户修改了签到间隔，请求后台定位
        guard let user = currentUser,
              user.checkInInterval != .oneMinute, // 不是测试模式
              locationAuthStatus == .authorizedWhenInUse else {
            return
        }
        
        locationManager.requestAlwaysAuthorization()
        print("🔔 请求后台定位权限")
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
    
    /// 开始持续定位并上传（模拟查找我的 iPhone 风格精度动画）
    /// 
    /// 功能说明：
    /// - 每 3 秒上传一次位置
    /// - 模拟精度提升过程：1000m → 500m → 200m → 100m → 50m → 10m
    /// - 精度计数器：`locationUpdateCount`
    /// 
    /// 技术实现：
    /// - 使用 Timer 定时触发（每 3 秒）
    /// - 每次定时器触发时递增计数器
    /// - `didUpdateLocations` 调用时不递增（避免用户静止时无法提升精度）
    /// 
    /// 后端地图效果：
    /// - 蓝色半透明圆圈 + 脉冲动画
    /// - 每 5 秒自动刷新用户位置
    /// - 精度变化平滑过渡动画
    /// 
    /// 相关文档：
    /// - 📖 终活 App 技术开发文档.md - 7.4 家人守护模块
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
            self?.uploadLatestLocation()
        }
        
        // 首次立即上传（大范围）
        uploadLatestLocation()
    }
    
    /// 停止持续定位
    func stopContinuousLocationUpdates() {
        isContinuouslyUpdating = false
        continuousUploadTimer?.invalidate()
        continuousUploadTimer = nil
        locationManager.stopUpdatingLocation()
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
    
    /// 处理位置更新（模拟查找我的 iPhone：精度从大到小）
    /// - Parameters:
    ///   - location: 位置信息
    ///   - fromTimer: 是否来自定时器触发（true 时才递增计数器）
    private func handleLocationUpdate(_ location: CLLocation, fromTimer: Bool = false) {
        guard let user = currentUser else { return }
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let actualAccuracy = location.horizontalAccuracy
        let age = Date().timeIntervalSince(location.timestamp)
        
        print("📍 获取位置：\(latitude), \(longitude)")
        print("📊 实际精度：\(actualAccuracy)米，年龄：\(String(format: "%.1f", age))秒")
        
        // 🔴 检查位置有效性
        if actualAccuracy < 0 || latitude == 0 || longitude == 0 {
            print("⚠️ 位置数据无效，跳过")
            return
        }
        
        // 🔴 检查位置年龄（超过 2 分钟的位置不用）
        if age > 120 {
            print("⚠️ 位置太旧（\(String(format: "%.0f", age))秒），跳过")
            return
        }
        
        // 🎯 模拟查找我的 iPhone：精度从大到小（1000 米 → 500 米 → 200 米 → 100 米 → 50 米 → 10 米）
        // 🔧 修复：只在定时器触发时递增计数器
        if fromTimer {
            locationUpdateCount += 1
            print("🔢 计数器 +1 = \(locationUpdateCount)")
        }
        let simulatedAccuracy: Double
        switch locationUpdateCount {
        case 1:
            simulatedAccuracy = 1000  // 首次：1km 范围
            print("🎯 第\(locationUpdateCount)次：大范围定位（±\(Int(simulatedAccuracy))米）")
        case 2:
            simulatedAccuracy = 500   // 3 秒后：500m
            print("🎯 第\(locationUpdateCount)次：中范围定位（±\(Int(simulatedAccuracy))米）")
        case 3:
            simulatedAccuracy = 200   // 6 秒后：200m
            print("🎯 第\(locationUpdateCount)次：中小范围定位（±\(Int(simulatedAccuracy))米）")
        case 4:
            simulatedAccuracy = 100   // 9 秒后：100m
            print("🎯 第\(locationUpdateCount)次：小范围定位（±\(Int(simulatedAccuracy))米）")
        case 5:
            simulatedAccuracy = 50    // 12 秒后：50m
            print("🎯 第\(locationUpdateCount)次：精确范围定位（±\(Int(simulatedAccuracy))米）")
        default:
            // 使用实际精度（但不低于 10 米）
            simulatedAccuracy = max(actualAccuracy, 10)
            print("🎯 第\(locationUpdateCount)次：精确定位（±\(Int(simulatedAccuracy))米）")
        }
        
        // ✅ 上传模拟精度的位置（让后端显示范围圈）
        print("✅ 准备上传（模拟精度：±\(Int(simulatedAccuracy))米，实际精度：±\(Int(actualAccuracy))米）")
        
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
            
            // 上传原始 GPS 坐标（WGS84）
            self.uploadLocationToServer(userId: user.id, latitude: latitude, longitude: longitude, address: address, accuracy: simulatedAccuracy)
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
        print("❌ 定位失败：\(error)")
    }
    
    private func uploadLocationToServer(userId: String, latitude: Double, longitude: Double, address: String, accuracy: Double? = nil) {
        guard let apiURL = URL(string: "\(DataManager.apiURL)/api/location.php") else {
            print("⚠️ 位置上传失败：API URL 无效")
            print("   URL: \(DataManager.apiURL)/api/location.php")
            return
        }
        
        // 获取 token
        let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
        if token.isEmpty {
            print("⚠️ 无 token，跳过位置上传")
            return
        }
        
        // 如果没有传入精度，使用默认值（模拟查找我的 iPhone：从大到小）
        let accuracyValue = accuracy ?? 1000.0
        print("📍 准备上传位置：\(latitude), \(longitude), 精度：\(accuracyValue)米")
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "action": "upload",
            "token": token,
            "user_id": userId,
            "latitude": latitude,
            "longitude": longitude,
            "address": address,
            "accuracy": accuracyValue
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 位置上传失败：\(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 位置上传响应状态码：\(httpResponse.statusCode)")
            }
            
            if let data = data,
               let jsonString = String(data: data, encoding: .utf8) {
                print("📄 位置上传响应：\(jsonString)")
                
                if let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = jsonObj["success"] as? Bool, success {
                    print("✅ 位置上传成功：\(latitude), \(longitude)")
                } else if let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let message = jsonObj["message"] as? String {
                    print("⚠️ 位置上传返回：\(message)")
                }
            }
        }.resume()
    }
    
    // MARK: - 用户注册
    func register(name: String, phone: String) -> Result<User, Error> {
        if !isValidPhone(phone) {
            return .failure(Error.invalidPhone)
        }
        
        if let _ = loadUserFromFile() {
            return .failure(Error.alreadyRegistered)
        }
        
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
        
        let now = Date()
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
        } else {
            writeLog("❌ 自动签到失败：\(result)")
        }
    }
    
    @MainActor
    func performAutoCheckIn() {
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
        
        let now = Date()
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
        // TODO: 实现 Message Framework 发送
        print("   ✅ Message Framework 发送成功（待实现）")
    }
    
    /// 方案 2: 阿里云短信 API
    private func sendViaAliyunSms(phone: String, message: String) {
        print("☁️ [方案 2] 阿里云短信 API 发送短信")
        
        let accessKeyId = UserDefaults.standard.string(forKey: "aliyun_access_key_id") ?? ""
        let accessKeySecret = UserDefaults.standard.string(forKey: "aliyun_access_key_secret") ?? ""
        
        guard !accessKeyId.isEmpty && !accessKeySecret.isEmpty else {
            print("   ❌ 阿里云短信配置不完整，跳过发送")
            return
        }
        
        Task {
            // TODO: 实现阿里云短信 API 调用
            print("   ✅ 阿里云短信发送成功（待实现）")
        }
    }
    
    /// 方案 3: 腾讯云短信 API
    private func sendViaTencentSms(phone: String, message: String) {
        print("☁️ [方案 3] 腾讯云短信 API 发送短信")
        
        let secretId = UserDefaults.standard.string(forKey: "tencent_secret_id") ?? ""
        let secretKey = UserDefaults.standard.string(forKey: "tencent_secret_key") ?? ""
        
        guard !secretId.isEmpty && !secretKey.isEmpty else {
            print("   ❌ 腾讯云短信配置不完整，跳过发送")
            return
        }
        
        Task {
            // TODO: 实现腾讯云短信 API 调用
            print("   ✅ 腾讯云短信发送成功（待实现）")
        }
    }
    
    func recordCheckIn(isAuto: Bool = false) -> Result<Void, Error> {
        print("🔵 ====== recordCheckIn 开始 ======")
        print("   - isAuto: \(isAuto)")
        print("   - currentUser: \(currentUser?.name ?? "nil")")
        print("   - isLoggedIn: \(isLoggedIn)")
        print("   - API URL: \(DataManager.apiURL)")
        print("   - Token: \(UserDefaults.standard.string(forKey: "userToken") ?? "nil")")
        
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
    
    // 同步签到到服务器
    @MainActor
    private func syncCheckInToServer(isAuto: Bool) async {
        guard let userId = currentUser?.id,
              let token = UserDefaults.standard.string(forKey: "userToken"),
              !DataManager.apiURL.isEmpty else {
            print("❌ 签到同步：缺少必要参数")
            return
        }
        
        let url = URL(string: "\(DataManager.apiURL)/api/checkin.php?action=record")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [
            "user_id": userId,
            "is_auto": isAuto
        ]
        
        // 添加位置信息（如果有）
        if let location = locationManager.location {
            body["location_lat"] = location.coordinate.latitude
            body["location_lng"] = location.coordinate.longitude
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                if let json = try? JSONDecoder().decode(ServerResponse.self, from: data),
                   json.success {
                    print("✅ 签到同步成功")
                } else {
                    print("⚠️ 签到同步返回失败")
                }
            }
        } catch {
            print("❌ 签到同步失败：\(error)")
        }
    }
    
    struct ServerResponse: Codable {
        let success: Bool
        let message: String?
        let error: String?
    }
    
    @MainActor
    func logout() {
        print("🔴 UserManager.logout() 被调用")
        self.currentUser = nil
        self.isLoggedIn = false
        self.lastCheckInDate = nil
        self.checkInInterval = .twoDays  // 重置为默认值
        
        // 🗑️ 删除本地用户文件
        do {
            if fileManager.fileExists(atPath: userFileURL.path) {
                try fileManager.removeItem(at: userFileURL)
                print("   ✅ 已删除用户文件：user.json")
            }
        } catch {
            print("   ❌ 删除用户文件失败：\(error)")
        }
        
        // 🗑️ 清除保存的密码和 token
        UserDefaults.standard.removeObject(forKey: "userPassword")
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        print("   ✅ 已清除密码和 token")
        
        print("   currentUser: nil")
        print("   isLoggedIn: \(self.isLoggedIn)")
        print("   lastCheckInDate: nil")
        print("✅ 退出登录完成，所有状态已清除")
    }
    
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
    
    func deleteEmergencyContact(id: String) -> Result<Void, Error> {
        guard var user = currentUser else {
            return .failure(Error.userNotLoggedIn)
        }
        
        user.emergencyContacts.removeAll { $0.id == id }
        self.currentUser = user
        
        if saveUser(user) {
            print("📞 紧急联系人已从本地删除，准备同步到服务器...")
            
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
    
    // ✅ 性能优化：避免重复加载
    private var isUserLoaded = false
    
    func loadUser() {
        // ✅ 如果已加载，直接返回（避免重复）
        if isUserLoaded && currentUser != nil {
            return
        }
        
        print("🔍 UserManager.loadUser() 被调用")
        
        // ✅ 云端优先架构：从 Token 恢复登录状态
        if let token = UserDefaults.standard.string(forKey: "userToken"),
           !token.isEmpty {
            self.isLoggedIn = true
            
            // 尝试从本地文件加载用户数据（快速）
            if let user = loadUserFromFile() {
                self.currentUser = user
                self.checkInInterval = user.checkInInterval
                self.lastCheckInDate = user.lastCheckInDate
                self.checkEmergencyContacts()
                isUserLoaded = true
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
    
    /// 从服务器拉取用户数据
    func fetchUserData() async {
        guard let token = UserDefaults.standard.string(forKey: "userToken"),
              !token.isEmpty else {
            return
        }
        
        let apiURL = DataManager.apiURL
        guard !apiURL.isEmpty else {
            print("❌ API URL 未设置")
            return
        }
        
        print("🌐 从服务器拉取用户数据...")
        
        var request = URLRequest(url: URL(string: "\(apiURL)/api/users.php?action=info")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool,
               success,
               let dataDict = json["data"] as? [String: Any],
               let userDict = dataDict["user"] as? [String: Any] {
                
                // 解析用户数据
                let userId = userDict["id"] as? String ?? ""
                let name = userDict["name"] as? String ?? "用户"
                let phone = userDict["phone"] as? String ?? ""
                
                // 解析统计信息
                let emergencyContactsCount = userDict["emergency_contacts_count"] as? Int ?? 0
                let witnessesCount = userDict["witnesses_count"] as? Int ?? 0
                let capsulesCount = userDict["capsules_count"] as? Int ?? 0
                let willModulesCount = userDict["will_modules_count"] as? Int ?? 0
                let familyCount = userDict["family_count"] as? Int ?? 0
                let checkinCount = userDict["checkin_count"] as? Int ?? 0
                
                let user = User(
                    id: userId,
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
                    checkinCount: checkinCount,
                    emergencyContactsCount: emergencyContactsCount,
                    witnessesCount: witnessesCount,
                    capsulesCount: capsulesCount,
                    willModulesCount: willModulesCount,
                    familyCount: familyCount
                )
                
                await MainActor.run {
                    self.currentUser = user
                    self.checkInInterval = user.checkInInterval
                    self.checkEmergencyContacts()
                    print("✅ 从服务器加载用户成功：\(user.name)")
                }
                
                // 保存本地缓存
                saveUser(user)
                
            } else {
                print("⚠️ 服务器返回失败，使用本地缓存")
            }
        } catch {
            print("❌ 拉取用户数据失败：\(error)，使用本地缓存")
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
            self.currentUser = user
            self.isLoggedIn = true  // 确保登录状态保持
            self.checkEmergencyContacts()  // 保存后重新检查
            
            // 同步到 UserDefaults
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.set(user.id, forKey: "userId")
            
            print("✅ 用户已保存：\(user.name), 紧急联系人：\(user.emergencyContacts.count) 个")
            print("   isLoggedIn: \(self.isLoggedIn)")
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
}
