//
//  WillPreviewView.swift
//  安伴助手
//
//  重要事项预览页面
//

import SwiftUI
import UIKit
import PDFKit

struct WillPreviewView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var exportSuccess = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 事项标题
                    VStack(spacing: 8) {
                        Text(L10n.text(
                            "重要事项预览",
                            en: "Important Notes Preview",
                            ja: "重要事項プレビュー",
                            ko: "중요 사항 미리보기"
                        ))
                            .font(.system(size: 20, weight: .bold))
                        
                        Text("\(L10n.text("生成时间：", en: "Generated at: ", ja: "生成日時: ", ko: "생성 시간: "))\(formatDate(Date()))")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 20)
                    
                    // 个人信息
                    infoSection(
                        title: L10n.text("记录人信息", en: "Recorder Info", ja: "記録者情報", ko: "기록자 정보"),
                        content: """
                        \(L10n.text("姓名：", en: "Name: ", ja: "氏名: ", ko: "이름: "))\(dataManager.settings.name)
                        \(L10n.text("身份证号：", en: "ID No.: ", ja: "本人確認番号: ", ko: "주민등록번호: "))\(L10n.text("[待填写]", en: "[To be filled]", ja: "[未記入]", ko: "[미입력]"))
                        \(L10n.text("联系电话：", en: "Phone: ", ja: "連絡先: ", ko: "연락처: "))\(L10n.text("[待填写]", en: "[To be filled]", ja: "[未記入]", ko: "[미입력]"))
                        """
                    )
                    
                    // 重要事项
                    ForEach(dataManager.willModules.filter { $0.isCompleted }) { module in
                        infoSection(
                            title: localizedModuleTitle(module.type),
                            content: module.content.isEmpty ? L10n.text("暂无内容", en: "No content", ja: "内容なし", ko: "내용 없음") : module.content
                        )
                    }
                    
                    // 资产信息
                    if !dataManager.assets.isEmpty {
                        infoSection(
                            title: L10n.text("资产清单", en: "Assets List", ja: "資産一覧", ko: "자산 목록"),
                            content: dataManager.assets.map {
                                "\($0.type.rawValue)\(L10n.text("：", en: ": ", ja: "：", ko: ": "))\($0.name) - \($0.institution)"
                            }.joined(separator: "\n")
                        )
                    }
                    
                    // 说明
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.text("📝 重要事项说明", en: "📝 Important Notes", ja: "📝 重要事項", ko: "📝 중요 사항"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "AF52DE"))
                        
                        Text(L10n.text("""
                        1. 本页面内容仅用于个人整理和信息参考，不构成法律意见或法律文书。

                        2. App 不会根据未签到、未操作或关闭签到状态自动发送任何内容。

                        3. 如涉及法律、财产处分或其他专业事项，请咨询具备资质的专业人士。
                        """, en: """
                        1. This page is for personal organization and reference only. It is not legal advice or a legal document.

                        2. The app does not automatically send any content based on missed check-ins, inactivity, or disabled status.

                        3. For legal, property, or other professional matters, please consult a qualified professional.
                        """, ja: """
                        1. このページは個人整理と参考用であり、法的助言や法的文書ではありません。

                        2. 未チェックイン、未操作、無効状態などを条件に内容を自動送信することはありません。

                        3. 法律、財産、その他専門的な事項については、資格を有する専門家にご相談ください。
                        """, ko: """
                        1. 이 페이지는 개인 정리와 참고용이며, 법률 자문이나 법적 문서가 아닙니다.

                        2. 체크인 누락, 미사용, 비활성 상태를 기준으로 내용을 자동 전송하지 않습니다.

                        3. 법률, 재산 또는 기타 전문 사항은 자격 있는 전문가와 상담하세요.
                        """))
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color(hex: "F6F6F8"))
            .navigationTitle(L10n.text("事项预览", en: "Notes Preview", ja: "項目プレビュー", ko: "항목 미리보기"))
            .navigationBarTitleDisplayMode(.inline)
        .alert("导出成功", isPresented: $exportSuccess) {
            Button(L10n.string(.confirm), role: .cancel) { }
        } message: {
            Text(L10n.text("事项 PDF 已导出到文档目录", en: "The notes PDF has been exported to the Documents folder.", ja: "項目 PDF は書類フォルダに保存されました。", ko: "항목 PDF가 문서 폴더에 내보내졌습니다."))
        }
        .alert(L10n.string(.exportFailed), isPresented: $showError) {
            Button(L10n.string(.confirm), role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.string(.done)) {
                        dismiss()
                    }
                }
            }
        }
        .stackNavigationStyle()
    }
    
    private func infoSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "AF52DE"))
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        date.localizedDateTimeString()
    }

    private func localizedModuleTitle(_ type: WillModule.WillType) -> String {
        switch type {
        case .property:
            return L10n.text("资产记录", en: "Asset Notes", ja: "資産メモ", ko: "자산 기록")
        case .heirs:
            return L10n.text("添加用户", en: "Added Users", ja: "追加したユーザー", ko: "추가된 사용자")
        case .specialItems:
            return L10n.text("特殊物品", en: "Special Items", ja: "特別品", ko: "특별 물품")
        case .funeral:
            return L10n.text("个人偏好", en: "Personal Preferences", ja: "個人設定", ko: "개인 선호")
        case .otherInstructions:
            return L10n.text("其他事项", en: "Other Notes", ja: "その他の項目", ko: "기타 항목")
        }
    }
}

#Preview {
    WillPreviewView()
}
// MARK: - 事项 PDF 导出（WillPreviewView 扩展）

extension WillPreviewView {
    /// 导出重要事项为 PDF
    func exportWillToPDF() async {
        print("🔵 WillPreviewView.exportWillToPDF 开始...")
        
        // 收集事项内容
        var pdfContent = L10n.text("重要事项记录\n", en: "Important Notes\n", ja: "重要事項記録\n", ko: "중요 사항 기록\n")
        pdfContent += "\(L10n.text("生成时间：", en: "Generated at: ", ja: "生成日時: ", ko: "생성 시간: "))\(Date().localizedDateTimeString())\n"
        pdfContent += String(repeating: "-", count: 50) + "\n\n"
        
        // 个人信息
        pdfContent += L10n.text("### 记录人信息\n", en: "### Recorder Info\n", ja: "### 記録者情報\n", ko: "### 기록자 정보\n")
        pdfContent += "\(L10n.text("姓名：", en: "Name: ", ja: "氏名: ", ko: "이름: "))\(dataManager.settings.name)\n"
        pdfContent += "\(L10n.text("身份证号：", en: "ID No.: ", ja: "本人確認番号: ", ko: "주민등록번호: "))\(L10n.text("[待填写]", en: "[To be filled]", ja: "[未記入]", ko: "[미입력]"))\n"
        pdfContent += "\(L10n.text("联系电话：", en: "Phone: ", ja: "連絡先: ", ko: "연락先: "))\(L10n.text("[待填写]", en: "[To be filled]", ja: "[未記入]", ko: "[미입력]"))\n\n"
        
        // 重要事项
        for module in dataManager.willModules.filter({ $0.isCompleted }) {
            pdfContent += "### \(localizedModuleTitle(module.type))\n"
            pdfContent += module.content.isEmpty ? L10n.text("暂无内容\n", en: "No content\n", ja: "内容なし\n", ko: "내용 없음\n") : module.content + "\n\n"
        }
        
        // 附注
        pdfContent += L10n.text("### 说明\n", en: "### Notice\n", ja: "### 注意事項\n", ko: "### 안내\n")
        pdfContent += L10n.text("本文件仅用于个人整理和信息参考，不构成法律意见或法律文书。\n", en: "This document is for personal organization and reference only. It is not legal advice or a legal document.\n", ja: "この文書は個人整理と参考用であり、法的助言や法的文書ではありません。\n", ko: "이 문서는 개인 정리와 참고용이며 법률 자문이나 법적 문서가 아닙니다.\n")
        pdfContent += L10n.text("App 不会自动发送本文件中的任何内容。\n\n", en: "The app does not automatically send any content in this document.\n\n", ja: "アプリがこの文書内の内容を自動送信することはありません。\n\n", ko: "앱은 이 문서의 내용을 자동 전송하지 않습니다.\n\n")
        pdfContent += "\(L10n.text("生成时间：", en: "Generated at: ", ja: "生成日時: ", ko: "생성 시간: "))\(Date().localizedDateTimeString())\n"
        
        print("✅ 事项内容收集完成")
        
        // 保存为 PDF（模拟实现）
        // 在实际应用中，应使用 PDFKit 创建真实的 PDF 文件
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let pdfPath = documentsPath.appendingPathComponent("重要事项_\(Date().chineseFileNameString()).pdf")
            print("PDF 保存路径：\(pdfPath.path)")
            
            // ✅ 使用 PDFKit 创建真实 PDF
            do {
                let pdfData = try createPDF(from: pdfContent)
                try pdfData.write(to: pdfPath)
                print("✅ PDF 文件已保存到：\(pdfPath.path)")
                
                await MainActor.run {
                    exportSuccess = true
                }
            } catch {
                print("❌ PDF 创建失败：\(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = "PDF 导出失败：\(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    // ✅ PDF 创建函数
    private func createPDF(from content: String) throws -> Data {
        // 临时方案：将文本内容转换为 PDF
        let attributedString = NSAttributedString(string: content, attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ])
        
        // 创建 PDF 数据
        let paperSize = CGSize(width: 595, height: 842)
        let pdfData = NSMutableData()
        
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(origin: .zero, size: paperSize), nil)
        UIGraphicsBeginPDFPage()
        
        // context 自动获取，不需要显式赋值
        attributedString.draw(in: CGRect(origin: CGPoint(x: 50, y: 50), size: CGSize(width: 495, height: 742)))
        
        UIGraphicsEndPDFContext()
        
        return pdfData as Data
    }
}
