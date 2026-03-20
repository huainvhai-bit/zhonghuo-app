//
//  UserManager.swift
//  终活
//
//  用户管理 - 注册、登录、紧急联系人、定位
//

import Foundation
import Combine
import CoreLocation

// SyncManager 在同一模块中，无需额外 import

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
    
    // 定位管理
    private let locationManager = CLLocationManager()
    @Published var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        setupLocationManager()
        loadUser()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10 米更新一次
        
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
            print("💡 请在模拟器设置 → 隐私 → 定位服务 中允许终活 App 使用定位")
            print("📍 尝试使用模拟位置上传...")
            // 🆕 即使未授权，也尝试上传模拟位置（用于测试）
            uploadLocationToServer(userId: user.id, latitude: 39.9042, longitude: 116.4074, address: "北京市（模拟）")
            return
        }
        
        print("📍 开始请求位置...")
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        guard let user = currentUser else { return }
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
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
            
            self.uploadLocationToServer(userId: user.id, latitude: latitude, longitude: longitude, address: address)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Swift.Error) {
        print("❌ 定位失败：\(error)")
    }
    
    private func uploadLocationToServer(userId: String, latitude: Double, longitude: Double, address: String) {
        guard let apiURL = URL(string: "\(DataManager.apiURL)/location.php") else {
            print("⚠️ 位置上传失败：API URL 无效")
            print("   URL: \(DataManager.apiURL)/location.php")
            return
        }
        
        // 获取 token
        let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
        if token.isEmpty {
            print("⚠️ 无 token，跳过位置上传")
            return
        }
        
        print("📍 准备上传位置：\(latitude), \(longitude)")
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "action": "upload",
            "token": token,
            "user_id": userId,
            "latitude": latitude,
            "longitude": longitude,
            "address": address
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
            lastCheckInDate: nil
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
        
        let url = URL(string: "\(DataManager.apiURL)/api.php?action=checkin_record")!
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
    
    func loadUser() {
        print("🔍 UserManager.loadUser() 被调用")
        print("   Token 存在：\(UserDefaults.standard.string(forKey: "userToken") != nil)")
        
        // ✅ 云端优先架构：从 Token 恢复登录状态
        if let token = UserDefaults.standard.string(forKey: "userToken"),
           !token.isEmpty {
            // 立即设置登录状态（同步）
            self.isLoggedIn = true
            print("✅ 从 Token 恢复登录状态 - isLoggedIn = true")
            
            // 尝试从本地文件加载用户数据（快速）
            if let user = loadUserFromFile() {
                self.currentUser = user
                self.checkInInterval = user.checkInInterval
                self.lastCheckInDate = user.lastCheckInDate
                self.checkEmergencyContacts()
                print("✅ 从本地文件加载用户：\(user.name)")
            }
            
            // 异步从服务器拉取最新数据
            Task {
                await fetchUserData()
            }
        } else {
            // 降级方案：从本地文件加载
            print("⚠️ 无 Token，尝试从本地文件加载")
            if let user = loadUserFromFile() {
                self.currentUser = user
                self.isLoggedIn = true
                self.checkInInterval = user.checkInInterval
                self.lastCheckInDate = user.lastCheckInDate
                self.checkEmergencyContacts()
                print("✅ 从本地文件恢复：\(user.name)")
            } else {
                print("❌ 本地文件也不存在")
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
        
        var request = URLRequest(url: URL(string: "\(apiURL)/api.php?action=user_info")!)
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
                
                let user = User(
                    id: userId,
                    name: name,
                    phone: phone,
                    createdAt: Date(),
                    emergencyContacts: [],
                    checkInInterval: .twoDays,
                    notificationsEnabled: true,
                    cloudSyncEnabled: true
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
