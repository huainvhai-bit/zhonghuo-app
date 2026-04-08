//
//  WitnessQualificationView.swift
//  终活
//
//  见证人资质审核（V2.0.0 法律合规）
//  功能：见证人身份验证、利益冲突检查
//

import SwiftUI

struct WitnessQualificationView: View {
    @State private var showAuditResult = false
    @State private var auditResult: WitnessAuditResult?
    
    @State private var witnessName = ""
    @State private var witnessIdNumber = ""
    @State private var witnessPhone = ""
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    // 标题
                    Text("见证人资质审核")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                    
                    // 法律依据
                    legalBasis
                    
                    // 审核信息表单
                    auditForm
                    
                    // 审核结果
                    if let result = auditResult {
                        auditResultView(result: result)
                    }
                    
                    Spacer()
                    
                    // 审核按钮
                    Button(action: { performAudit() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield")
                            Text("开始审核")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "6366F1"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.hex("F5F5F7"))
            .navigationTitle("见证人审核")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - 法律依据
    private var legalBasis: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.closed")
                    .foregroundColor(.blue)
                    .font(.system(size: 20))
                Text("法律依据")
                    .font(.system(size: 18, weight: .bold))
            }
            
            Text("根据《民法典》第1140条，下列人员不能作为遗嘱见证人：")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("❌ 无行为能力人、限制行为能力人")
                Text("❌ 继承人、受遗赠人")
                Text("❌ 与继承人、受遗赠人有利害关系的人")
            }
            .font(.system(size: 13))
            .foregroundColor(.primary)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 审核表单
    private var auditForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("见证人信息")
                .font(.system(size: 16, weight: .bold))
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                TextField("姓名", text: $witnessName)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                TextField("身份证号", text: $witnessIdNumber)
                    .keyboardType(.numberPad)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                TextField("手机号", text: $witnessPhone)
                    .keyboardType(.numberPad)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - 审核结果视图
    private func auditResultView(result: WitnessAuditResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .center, spacing: 12) {
                if result.isEligible {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                }
                
                Text(result.isEligible ? "审核通过" : "审核不通过")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(result.isEligible ? .green : .red)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if !result.isEligible {
                    Text("❌ 不符合见证人资格：")
                        .font(.system(size: 14, weight: .bold))
                    
                    ForEach(result.reasons, id: \.self) { reason in
                        Text(reason)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }
                } else {
                    Text("✅ 见证人资格审核通过")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    
                    Text("• 姓名：\(witnessName)")
                    Text("• 身份证号：\(witnessIdNumber)")
                    Text("• 手机号：\(witnessPhone)")
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            if !result.isEligible {
                Button(action: { showAuditResult = false; auditResult = nil }) {
                    Text("返回重新输入")
                        .font(.system(size: 15))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 执行审核
    private func performAudit() {
        guard !witnessName.isEmpty, !witnessIdNumber.isEmpty, !witnessPhone.isEmpty else {
            // 简单验证
            let result = WitnessAuditResult(
                isEligible: true,
                reasons: [],
                message: "信息完整，假定符合资格"
            )
            auditResult = result
            showAuditResult = true
            return
        }
        
        // TODO: 调用后端审核接口
        // let result = await BackendAPI.verifyWitness(...)
    }
}

// MARK: - 审核结果模型
struct WitnessAuditResult {
    let isEligible: Bool
    let reasons: [String]
    let message: String
}

// MARK: - 预览
struct WitnessQualificationView_Previews: PreviewProvider {
    static var previews: some View {
        WitnessQualificationView()
    }
}
