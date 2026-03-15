//
//  UserManager.swift
//  终活
//
//  用户管理 - 注册、登录、紧急联系人
//

import Foundation
import Combine

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var needsEmergencyContactCheck: Bool = false
    
    private let fileManager = FileManager.default
    private var documentsPath: String {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].path
    }
    
    private var userFileURL: URL {
        URL(fileURLWithPath: documentsPath).appendingPathComponent("user.json")
    }
    
    private init() {
        loadUser()
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
            self.needsEmergencyContactCheck = true
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
        self.checkEmergencyContacts()
        return .success(user)
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
    
    private func saveUser(_ user: User) -> Bool {
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
