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
        guard let user = loadUserFromFile() else {
            return .failure(Error.userNotFound)
        }
        
        if user.phone != phone {
            return .failure(Error.phoneMismatch)
        }
        
        self.currentUser = user
        self.isLoggedIn = true
        self.lastCheckInDate = user.lastCheckInDate
        self.checkEmergencyContacts()
        startUpdatingLocation()
        return .success(user)
    }
    
    // Bug 2: 自动签到
    func performAutoCheckIn() {
        guard let user = currentUser else { return }
        
        let now = Date()
        let lastCheckIn = user.lastCheckInDate ?? Date.distantPast
        let intervalHours = user.checkInInterval.hours
        
        // 检查是否到了签到时间
        if now.timeIntervalSince(lastCheckIn) >= intervalHours * 3600 {
            // 执行签到
            let result = recordCheckIn()
            if case .success = result {
                print("✅ 自动签到成功")
            }
        } else {
            let remaining = intervalHours * 3600 - now.timeIntervalSince(lastCheckIn)
            let hours = Int(remaining / 3600)
            print("⏰ 距离下次签到还有 \(hours) 小时")
        }
    }
    
    func recordCheckIn() -> Result<Void, Error> {
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
        
        if saveUser(user) {
            return .success(())
        } else {
            return .failure(Error.saveFailed)
        }
    }
    
    func logout() {
        self.currentUser = nil
        self.isLoggedIn = false
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
        
        if user.emergencyContacts.count < 2 {
            self.needsEmergencyContactCheck = true
        } else {
            self.needsEmergencyContactCheck = false
        }
    }
    
    func updateCheckInInterval(_ interval: CheckInInterval) -> Result<Void, Error> {
        guard var user = currentUser else {
            return .failure(Error.userNotLoggedIn)
        }
        
        user.checkInInterval = interval
        self.currentUser = user
        
        // Bug 3: 如果不是测试模式，检查后台定位
        if interval != .oneMinute {
            requestAlwaysAuthorizationIfNeeded()
        }
        
        if saveUser(user) {
            return .success(())
        } else {
            return .failure(Error.saveFailed)
        }
    }
    
    func getEmergencyContactsCount() -> Int {
        return currentUser?.emergencyContacts.count ?? 0
    }
    
    private func loadUser() {
        if let user = loadUserFromFile() {
            self.currentUser = user
            self.isLoggedIn = true
            self.checkEmergencyContacts()
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
