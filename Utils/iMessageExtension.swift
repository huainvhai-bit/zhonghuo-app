//
//  iMessageExtension.swift
//  终活 iMessage Extension
//
//  跨设备同步 - iMessage 集成（V2.0.0 核心功能）
//  功能：Family Sharing、消息同步、设备发现
//

import Foundation
import Messages
import CloudKit

// MARK: - iMessage Extension 主入口

class MessagesExtension: MSMessagesAppViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 检查是否登录
        if UserManager.shared.isLoggedIn {
            loadSessions()
        } else {
            showLoginView()
        }
    }
    
    override func willBecomeActive(with conversation: MSConversation) {
        // 应用被激活时刷新数据
        if UserManager.shared.isLoggedIn {
            loadSessions()
        }
    }
    
    override func didTransition(to state: MSCollectionViewLayoutState) {
        // 布局变化时调整 UI
    }
}

// MARK: - 会话加载

extension MessagesExtension {
    func loadSessions() {
        guard let conversation = activeConversation else { return }
        
        // 获取家族成员的 iMessage 联系人
        fetchFamilyContacts { [weak self] contacts in
            DispatchQueue.main.async {
                self?.updateSessionList(with: contacts)
            }
        }
    }
    
    func fetchFamilyContacts(completion: @escaping ([MSMessageTemplateLayout]) -> Void) {
        let layout = MSMessageTemplateLayout()
        layout.backgroundColor = .white
        
        // ✅ 从 DataManager 获取紧急联系人
        let contacts = UserManager.shared.currentUser?.emergencyContacts ?? []
        
        // 生成会话消息模板
        var layouts: [MSMessageTemplateLayout] = []
        
        for contact in contacts {
            let contactLayout = MSMessageTemplateLayout()
            contactLayout.image = nil
            contactLayout.caption = contact.name
            contactLayout.subcaption = contact.phone
            layouts.append(contactLayout)
        }
        
        completion(layouts)
    }
    
    func updateSessionList(with layouts: [MSMessageTemplateLayout]) {
        guard let conversation = activeConversation else { return }
        
        // 添加会话消息
        for layout in layouts {
            let session = MSSession()
            conversation.insert(session) { [weak self] error in
                if let error = error {
                    print("Failed to insert session: \(error)")
                } else {
                    self?.sendMessage(for: session, with: layout)
                }
            }
        }
    }
    
    func sendMessage(for session: MSSession, with layout: MSMessageTemplateLayout) {
        guard let conversation = activeConversation else { return }
        
        let message = MSMessage()
        message.layout = layout
        message.session = session
        
        conversation.insert(message) { error in
            if let error = error {
                print("Failed to send message: \(error)")
            }
        }
    }
}

// MARK: - Family Sharing 支持

class FamilySharingManager {
    static let shared = FamilySharingManager()
    
    // CloudKit 数据库
    private let database = CKContainer.default().publicCloudDatabase
    
    //Family Sharing 应用组标识
    private let appGroupIdentifier = "group.zhonghuo.app"
    
    // Family Sharing 数据容器
    private let container: CKContainer
    
    init() {
        container = CKContainer(identifier: "iCloud.com.zhonghuo.app")
    }
    
    // MARK: - 家族成员同步
    
    /// 获取家族成员列表
    func fetchFamilyMembers(completion: @escaping ([CKRecord]) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "FamilyMember", predicate: predicate)
        
        database.perform(query, in: .shared) { records, error in
            if let error = error {
                print("Fetch family members error: \(error)")
                completion([])
                return
            }
            
            completion(records ?? [])
        }
    }
    
    /// 同步家族成员
    func syncFamilyMembers(_ members: [FamilyMember]) {
        for member in members {
            let record = CKRecord(recordType: "FamilyMember")
            record["userId"] = member.userId as CKRecordValue
            record["name"] = member.name as CKRecordValue
            record["phone"] = member.phone as CKRecordValue
            record["relation"] = member.relation as CKRecordValue
            record["createdAt"] = member.createdAt as CKRecordValue
            
            database.save(record) { record, error in
                if let error = error {
                    print("Sync family member error: \(error)")
                }
            }
        }
    }
    
    // MARK: - 消息同步
    
    /// 发送同步消息
    func sendSyncMessage(_ message: SyncMessage, to recipient: String) {
        // ✅ 实现 iMessage 消息发送
        let messageBody: [String: Any] = [
            "type": message.type,
            "data": message.data,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // 通过后端 API 发送通知
        Task {
            do {
                let result = try await DataManager.shared.sendSmsNotification(
                    phone: recipient,
                    message: "终活 App: \(message.type) 已更新"
                )
                print("✅ 消息发送\(result ? "成功" : "失败")")
            } catch {
                print("❌ 消息发送失败：\(error)")
            }
        }
    }
    
    /// 接收同步消息
    func receiveSyncMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }
        
        switch type {
        case "capsuleCreated":
            handleCapsuleCreated(message)
        case "willUpdated":
            handleWillUpdated(message)
        case "familyMemberAdded":
            handleFamilyMemberAdded(message)
        default:
            break
        }
    }
    
    private func handleCapsuleCreated(_ message: [String: Any]) {
        guard let data = message["data"] as? [String: Any] else { return }
        
        // 创建时光胶囊
        let capsule = TimeCapsule(
            id: data["id"] as? String ?? UUID().uuidString,
            title: data["title"] as? String ?? "",
            content: data["content"] as? String ?? "",
            type: .text,
            sendDate: Date(),
            isSent: false,
            createdAt: Date()
        )
        
        DataManager.shared.capsules.append(capsule)
        DataManager.shared.saveCapsules()
    }
    
    private func handleWillUpdated(_ message: [String: Any]) {
        guard let data = message["data"] as? [String: Any] else { return }
        
        // 更新遗嘱
        guard let willId = data["id"] as? String else { return }
        
        if let willIndex = DataManager.shared.wills.firstIndex(where: { $0.id == willId }) {
            DataManager.shared.wills[willIndex].content = data["content"] as? String ?? ""
            DataManager.shared.wills[willIndex].updatedAt = Date()
            DataManager.shared.saveWills()
        }
    }
    
    private func handleFamilyMemberAdded(_ message: [String: Any]) {
        guard let data = message["data"] as? [String: Any] else { return }
        
        // 添加 FamilyMember
        // 略...
    }
}

// MARK: - 同步消息结构

struct SyncMessage {
    let type: String
    let data: [String: Any]
    let timestamp: Date
}

// MARK: - 隐私与安全

extension FamilySharingManager {
    /// 加密同步数据
    func encryptData(_ data: [String: Any]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let encrypted = try? data.encrypt(using: "AES256") else {
            return nil
        }
        
        return encrypted.base64EncodedString()
    }
    
    /// 解密同步数据
    func decryptData(_ encryptedString: String) -> [String: Any]? {
        guard let data = Data(base64Encoded: encryptedString),
              let decrypted = try? data.decrypt(using: "AES256"),
              let json = try? JSONSerialization.jsonObject(with: decrypted) as? [String: Any] else {
            return nil
        }
        
        return json
    }
}

// MARK: - 预览

struct iMessageExtension_Previews: PreviewProvider {
    static var previews: some View {
        MessagesExtension()
    }
}
