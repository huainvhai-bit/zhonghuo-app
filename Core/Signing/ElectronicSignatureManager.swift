//
//  ElectronicSignatureManager.swift
//  安伴助手
//
//  电子签章管理器（简化版）
//  功能：电子签名、见证人签署
//

import SwiftUI

class ElectronicSignatureManager: ObservableObject {
    static let shared = ElectronicSignatureManager()
    
    @Published var signatures: [String: Data] = [:]  // documentId -> signatureData
    
    private init() {}
    
    // MARK: - 签章类型
    
    enum SignatureType: String, Codable {
        case handwritten = "handwritten"   // 手写签名
        case typed = "typed"               // 打字签名
        case witness = "witness"           // 见证人签署
    }
    
    // MARK: - Witness 类型
    
    struct Witness: Codable, Identifiable {
        var id = UUID()
        var name: String
        var phone: String
        var relationship: String
        var idNumber: String?
        var isQualified: Bool = true
    }
    
    // MARK: - 签名方法
    
    /// 添加签名
    func addSignature(documentId: String, signatureData: Data) {
        signatures[documentId] = signatureData
        print("✅ ElectronicSignatureManager: 签名已保存")
    }
    
    /// 获取签名
    func getSignature(documentId: String) -> Data? {
        return signatures[documentId]
    }
    
    /// 删除签名
    func removeSignature(documentId: String) {
        signatures.removeValue(forKey: documentId)
        print("✅ ElectronicSignatureManager: 签名已删除")
    }
    
    // MARK: - 见证人验证
    
    /// 检查见证人资格
    func checkWitnessQualification(witness: Witness) -> (qualified: Bool, message: String) {
        // 简单验证：姓名和电话不能为空
        if witness.name.isEmpty || witness.phone.isEmpty {
            return (false, "姓名和电话不能为空")
        }
        
        // 电话号码验证
        if witness.phone.count < 11 {
            return (false, "电话号码格式不正确")
        }
        
        return (true, "验证通过")
    }
}

// MARK: - 预览（已注释）

// struct ElectronicSignaturePreviewView: View {
//     @StateObject private var manager = ElectronicSignatureManager.shared
//     
//     var body: some View {
//         Text("电子签名管理器")
//     }
// }
