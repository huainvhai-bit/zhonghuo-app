//
//  ElectronicSignatureManager.swift
//  终活
//
//  电子签章管理器（V2.0.0 P0 关键）
//  功能：电子签名、见证人签署、法律效力保障
//

import Foundation
import UIKit
import Security

class ElectronicSignatureManager: ObservableObject {
    static let shared = ElectronicSignatureManager()
    
    private init() {}
    
    // MARK: - 签章类型
    
    /// 签章类型
    enum SignatureType: String, Codable {
        case handwritten = "handwritten"   // 手写签名
        case typed = "typed"               // 打字签名
        case witness = "witness"           // 见证人签署
        case notary = "notary"             // 公证签章
    }
    
    // MARK: - 签章记录
    
    /// 签章记录
    struct SignatureRecord: Codable, Identifiable {
        let id = UUID()
        let type: SignatureType
        let signerName: String
        let signerID: String?
        let timestamp: Date
        let contentHash: String
        let signatureData: String?  // Base64 编码的签名数据
        let location: String?
        let ip: String?
    }
    
    // MARK: - 签章生成
    
    /// 创建电子签章
    func createSignature(
        type: SignatureType,
        signerName: String,
        signerID: String? = nil,
        content: String,
        location: String? = nil,
        ip: String? = nil
    ) -> SignatureRecord {
        print("🔵 ElectronicSignatureManager: 创建签章 - \(type.rawValue)")
        
        // 计算内容哈希（SHA-256）
        let contentHash = content.sha256
        print("✅ 内容哈希：\(contentHash)")
        
        // 创建签章记录
        let record = SignatureRecord(
            type: type,
            signerName: signerName,
            signerID: signerID,
            timestamp: Date(),
            contentHash: contentHash,
            signatureData: nil,  // 暂时不生成实际签名数据
            location: location,
            ip: ip
        )
        
        // 保存签章
        saveSignature(record)
        
        print("✅ ElectronicSignatureManager: 签章已创建并保存")
        return record
    }
    
    /// 创建见证人签署
    func createWitnessSignature(
        witness: User.Witness,
        content: String
    ) -> SignatureRecord {
        return createSignature(
            type: .witness,
            signerName: witness.name,
            signerID: witness.idNumber,
            content: content,
            location: witness.location
        )
    }
    
    // MARK: - 签章验证
    
    /// 验证签章有效性
    func validateSignature(_ record: SignatureRecord, originalContent: String) -> Bool {
        // 验证内容哈希
        let contentHash = originalContent.sha256
        guard record.contentHash == contentHash else {
            print("❌ ElectronicSignatureManager: 内容哈希不匹配")
            return false
        }
        
        // 验证时间戳（签章应在内容创建后）
        // 暂略
        
        // 验证见证人资质（如果是见证人签章）
        // TODO: 调用 LegalConsultationManager.checkWitnessQualification()
        
        print("✅ ElectronicSignatureManager: 签章验证通过")
        return true
    }
    
    // MARK: - 签章存储
    
    /// 保存签章记录
    private func saveSignature(_ record: SignatureRecord) {
        // 读取现有签章
        var signatures = loadSignatures()
        
        // 添加新签章
        signatures.append(record)
        
        // 保存到 Keychain
        if let data = try? JSONEncoder().encode(signatures) {
            KeychainManager.shared.saveElectronicSignatures(data)
            print("✅ ElectronicSignatureManager: 签章已保存到 Keychain")
        } else {
            print("❌ ElectronicSignatureManager: 保存签章失败")
        }
    }
    
    /// 加载签章记录
    func loadSignatures() -> [SignatureRecord] {
        if let data = KeychainManager.shared.getElectronicSignatures() {
            if let signatures = try? JSONDecoder().decode([SignatureRecord].self, from: data) {
                return signatures
            }
        }
        return []
    }
    
    // MARK: - 签章展示
    
    /// 生成签章图片（用于 PDF/文档）
    func generateSignatureImage(type: SignatureType, signerName: String) -> UIImage? {
        let size = CGSize(width: 200, height: 60)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        // 绘制背景
        UIColor.systemGray4.setFill()
        context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        // 绘制文字
        let attribute: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.systemBlue,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                return style
            }()
        ]
        
        let text = "\(signerName)  \(type == .witness ? "见证人签署" : "电子签章")"
        text.draw(in: CGRect(x: 0, y: 10, width: size.width, height: 40), withAttributes: attribute)
        
        // 绘制签章边框
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(2)
        context.stroke(CGRect(x: 2, y: 2, width: size.width - 4, height: size.height - 4))
        
        // 绘制日期
        let dateStr = Date().formatted(.dateTime.year().month().day())
        dateStr.draw(in: CGRect(x: 0, y: 45, width: size.width, height: 15), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                return style
            }()
        ])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    // MARK: - 多人签署流程
    
    /// 多人签署状态
    struct MultiSignatureState: Codable {
        let documentId: String
        let totalSigners: Int
        var signedCount: Int
        var signatures: [String: SignatureRecord]  // signerID -> SignatureRecord
        let createdAt: Date
    }
    
    /// 开始多人签署流程
    func startMultiSignature(documentId: String, signers: [User.Witness]) -> MultiSignatureState {
        let state = MultiSignatureState(
            documentId: documentId,
            totalSigners: signers.count,
            signedCount: 0,
            signatures: [:],
            createdAt: Date()
        )
        
        // 保存签署状态
        saveMultiSignatureState(state)
        
        print("🔵 ElectronicSignatureManager: 开始多人签署 - \(documentId)")
        return state
    }
    
    /// 记录单个签署
    func recordSingleSignature(
        state: inout MultiSignatureState,
        signer: User.Witness,
        content: String
    ) -> Bool {
        // 创建签章
        let record = createSignature(
            type: .witness,
            signerName: signer.name,
            signerID: signer.idNumber,
            content: content
        )
        
        // 记录签署
        state.signatures[signer.idNumber] = record
        state.signedCount += 1
        
        // 保存状态
        saveMultiSignatureState(state)
        
        print("✅ ElectronicSignatureManager: 单个签署完成")
        return true
    }
    
    /// 检查是否已完成全部签署
    func isMultiSignatureComplete(_ state: MultiSignatureState) -> Bool {
        return state.signedCount >= state.totalSigners
    }
    
    // MARK: - 签章持久化辅助方法
    
    /// Keychain 管理器扩展
    extension KeychainManager {
        private let electronicSignaturesKey = "electronic_signatures"
        
        /// 保存电子签章
        func saveElectronicSignatures(_ data: Data) {
            save(data, for: electronicSignaturesKey)
        }
        
        /// 获取电子签章
        func getElectronicSignatures() -> Data? {
            return load(Data.self, for: electronicSignaturesKey)
        }
        
        /// 清除电子签章
        func clearElectronicSignatures() {
            delete(for: electronicSignaturesKey)
        }
    }
    
    // MARK: - 帮助方法
    
    /// 保存多人签署状态
    private func saveMultiSignatureState(_ state: MultiSignatureState) {
        if let data = try? JSONEncoder().encode(state) {
            KeychainManager.shared.save(data, for: "multi_signature_\(state.documentId)")
        }
    }
    
    /// 加载多人签署状态
    func loadMultiSignatureState(documentId: String) -> MultiSignatureState? {
        if let data = KeychainManager.shared.load(Data.self, for: "multi_signature_\(documentId)") {
            return try? JSONDecoder().decode(MultiSignatureState.self, from: data)
        }
        return nil
    }
}

// MARK: - String 扩展：SHA-256

extension String {
    /// SHA-256 哈希
    var sha256: String {
        guard let data = self.data(using: .utf8) else {
            return ""
        }
        
        var hash = [UInt8](repeating: 0, count: Int(SHA256_DIGEST_LENGTH))
        SHA256(data.bytes, data.count, &hash)
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Data 扩展

extension Data {
    /// bytes 指针
    var bytes: UnsafeRawPointer {
        return UnsafeRawPointer(self)
    }
}

// MARK: - 预览

struct ElectronicSignatureManager_Previews: PreviewProvider {
    static var previews: some View {
        ElectronicSignaturePreviewView()
    }
}

struct ElectronicSignaturePreviewView: View {
    @StateObject private var manager = ElectronicSignatureManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("电子签章预览")
                .font(.system(size: 24, weight: .bold))
            
            // 签章图片预览
            if let signatureImage = manager.generateSignatureImage(
                type: .witness,
                signerName: "张三"
            ) {
                Image(uiImage: signatureImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 60)
                    .padding()
            }
            
            // 签章类型按钮
            VStack(spacing: 10) {
                Button(action: { print("手写签名") }) {
                    Text("手写签名")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "AF52DE"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: { print("见证人签署") }) {
                    Text("见证人签署")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "34C759"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: { print("公证签章") }) {
                    Text("公证签章")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "FF9500"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            // 签章记录
            Text("签章记录：\(manager.loadSignatures().count) 个")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Button(action: { print("清除签章") }) {
                Text("清除所有签章")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}
