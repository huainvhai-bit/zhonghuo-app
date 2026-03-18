//
//  UserManager.swift
//  终活
//
//  用户管理 - 注册、登录、紧急联系人、定位
//

import Foundation
import Combine
import CoreLocation

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
    
    private var userFileURL: URL {
        URL(fileURLWithPath: documentsPath).appendingPathComponent("user.json")
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
            
            // 📱 安排推送提醒（倒计时剩余 12 小时时开始提醒）
            let hoursRemaining = Double(user.checkInInterval.hours)
            scheduleCheckInReminder(hoursRemaining: hoursRemaining)
            writeLog("🔔 已安排推送提醒：剩余 \(Int(hoursRemaining)) 小时")
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
    private func sendSmsToContact(_ phone: String, message: String) {
        // TODO: 实现短信发送功能
        // 方案 1: 使用 Message Framework (需要用户授权)
        // 方案 2: 调用第三方短信 API（如阿里云短信）
        print("📲 准备发送短信到：\(phone)")
        print("   内容：\(message)")
        
        // 目前仅记录日志，实际部署时需要实现短信发送
        // 可以使用 MessageUI framework 或第三方短信服务
    }
    
    func recordCheckIn(isAuto: Bool = false) -> Result<Void, Error> {
        guard var user = currentUser else {
            return .failure(Error.userNotLoggedIn)
        }
        
        user.lastCheckInDate = Date()
        self.currentUser = user
        self.lastCheckInDate = user.lastCheckInDate
        
        // 记录签到位置
        if let locationStr = getCurrentLocation() {
            print("📍 签到位置：\(locationStr)")
        }
        
        print("✅ 记录签到：\(isAuto ? "自动" : "手动")")
        
        if saveUser(user) {
            // 同步到服务器
            Task {
                await syncCheckInToServer(isAuto: isAuto)
            }
            
            // 🚨 检查是否需要通知紧急联系人（如果之前已过期）
            notifyEmergencyContactsIfNeeded()
            
            return .success(())
        } else {
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
        
        let url = URL(string: "\(DataManager.apiURL)/checkin.php")!
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
        print("   currentUser: \(self.currentUser ?? nil)")
        print("   isLoggedIn: \(self.isLoggedIn)")
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
        if let user = loadUserFromFile() {
            self.currentUser = user
            self.isLoggedIn = true
            self.checkInInterval = user.checkInInterval  // ✅ 修复：加载签到间隔
            self.lastCheckInDate = user.lastCheckInDate
            self.checkEmergencyContacts()
            print("✅ UserManager 加载用户：\(user.name), 签到间隔：\(user.checkInInterval.rawValue)")
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
