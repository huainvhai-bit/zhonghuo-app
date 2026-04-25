//
//  WillPreviewView.swift
//  终活
//
//  遗嘱预览页面
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
                    // 遗嘱标题
                    VStack(spacing: 8) {
                        Text(L10n.text(
                            "遗嘱文档预览",
                            en: "Will Document Preview",
                            ja: "遺言書プレビュー",
                            ko: "유언장 미리보기"
                        ))
                            .font(.system(size: 20, weight: .bold))
                        
                        Text("\(L10n.text("生成时间：", en: "Generated at: ", ja: "生成日時: ", ko: "생성 시간: "))\(formatDate(Date()))")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 20)
                    
                    // 个人信息
                    infoSection(
                        title: L10n.text("立遗嘱人信息", en: "Testator Info", ja: "遺言者情報", ko: "유언자 정보"),
                        content: """
                        \(L10n.text("姓名：", en: "Name: ", ja: "氏名: ", ko: "이름: "))\(dataManager.settings.name)
                        \(L10n.text("身份证号：", en: "ID No.: ", ja: "本人確認番号: ", ko: "주민등록번호: "))\(L10n.text("[待填写]", en: "[To be filled]", ja: "[未記入]", ko: "[미입력]"))
                        \(L10n.text("联系电话：", en: "Phone: ", ja: "連絡先: ", ko: "연락처: "))\(L10n.text("[待填写]", en: "[To be filled]", ja: "[未記入]", ko: "[미입력]"))
                        """
                    )
                    
                    // 遗嘱模块
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
                    
                    // 法律说明
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.text("⚖️ 法律说明", en: "⚖️ Legal Notice", ja: "⚖️ 法的注意事項", ko: "⚖️ 법적 안내"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "AF52DE"))
                        
                        Text(L10n.text("""
                        1. 本遗嘱为自书遗嘱，根据《中华人民共和国民法典》规定，需满足以下条件才具有法律效力：
                           - 立遗嘱人亲笔书写
                           - 立遗嘱人亲笔签名
                           - 注明年、月、日

                        2. 建议前往公证处办理正式遗嘱公证以确保法律效力。

                        3. 本预览仅供参考，正式遗嘱请以纸质手写版本为准。
                        """, en: """
                        1. This will is a handwritten will. Under applicable law, it should meet the following conditions:
                           - Written by the testator
                           - Signed by the testator
                           - Dated with year, month, and day

                        2. It is recommended to notarize the will for stronger legal validity.

                        3. This preview is for reference only. The handwritten original prevails.
                        """, ja: """
                        1. この遺言は自筆証書遺言です。法律上の効力を持つには、以下の条件を満たす必要があります。
                           - 遺言者本人が自筆で記載すること
                           - 遺言者本人が署名すること
                           - 年月日を記載すること

                        2. 法的効力を高めるため、公証役場での公正証書化を推奨します。

                        3. このプレビューは参考用です。正式な遺言は手書き原本を優先してください。
                        """, ko: """
                        1. 이 유언장은 자필 유언장입니다. 법적 효력을 가지려면 다음 조건을 충족해야 합니다.
                           - 유언자 본인이 직접 작성
                           - 유언자 본인 서명
                           - 연, 월, 일을 기재

                        2. 법적 효력을 위해 공증을 받는 것을 권장합니다.

                        3. 이 미리보기는 참고용입니다. 정식 유언장은 손글씨 원본을 우선합니다.
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
            .navigationTitle(L10n.text("嘱托预览", en: "Will Preview", ja: "遺言プレビュー", ko: "유언 미리보기"))
            .navigationBarTitleDisplayMode(.inline)
        .alert("导出成功", isPresented: $exportSuccess) {
            Button(L10n.string(.confirm), role: .cancel) { }
        } message: {
            Text(L10n.text("遗嘱 PDF 已导出到文档目录", en: "The will PDF has been exported to the Documents folder.", ja: "遺言 PDF は書類フォルダに保存されました。", ko: "유언 PDF가 문서 폴더에 내보내졌습니다."))
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
            return L10n.text("财产分配", en: "Asset Distribution", ja: "財産分配", ko: "재산 분배")
        case .heirs:
            return L10n.text("继承人指定", en: "Heir Designation", ja: "相続人指定", ko: "상속인 지정")
        case .specialItems:
            return L10n.text("特殊物品", en: "Special Items", ja: "特別品", ko: "특별 물품")
        case .funeral:
            return L10n.text("丧葬意愿", en: "Funeral Wishes", ja: "葬儀の希望", ko: "장례 희망")
        case .otherInstructions:
            return L10n.text("其他嘱托", en: "Other Instructions", ja: "その他の遺言", ko: "기타 유언")
        }
    }
}

#Preview {
    WillPreviewView()
}
// MARK: -遗嘱 PDF 导出（WillPreviewView 扩展）

extension WillPreviewView {
    /// 导出遗嘱为 PDF
    func exportWillToPDF() async {
        print("🔵 WillPreviewView.exportWillToPDF 开始...")
        
        // 收集遗嘱内容
        var pdfContent = L10n.text("遗嘱文档\n", en: "Will Document\n", ja: "遺言書\n", ko: "유언장 문서\n")
        pdfContent += "\(L10n.text("生成时间：", en: "Generated at: ", ja: "生成日時: ", ko: "생성 시간: "))\(Date().localizedDateTimeString())\n"
        pdfContent += String(repeating: "-", count: 50) + "\n\n"
        
        // 个人信息
        pdfContent += L10n.text("### 立遗嘱人信息\n", en: "### Testator Info\n", ja: "### 遺言者情報\n", ko: "### 유언자 정보\n")
        pdfContent += "\(L10n.text("姓名：", en: "Name: ", ja: "氏名: ", ko: "이름: "))\(dataManager.settings.name)\n"
        pdfContent += "\(L10n.text("身份证号：", en: "ID No.: ", ja: "本人確認番号: ", ko: "주민등록번호: "))\(L10n.text("[待填写]", en: "[To be filled]", ja: "[未記入]", ko: "[미입력]"))\n"
        pdfContent += "\(L10n.text("联系电话：", en: "Phone: ", ja: "連絡先: ", ko: "연락先: "))\(L10n.text("[待填写]", en: "[To be filled]", ja: "[未記入]", ko: "[미입력]"))\n\n"
        
        // 遗嘱模块
        for module in dataManager.willModules.filter({ $0.isCompleted }) {
            pdfContent += "### \(localizedModuleTitle(module.type))\n"
            pdfContent += module.content.isEmpty ? L10n.text("暂无内容\n", en: "No content\n", ja: "内容なし\n", ko: "내용 없음\n") : module.content + "\n\n"
        }
        
        // 附注
        pdfContent += L10n.text("### 法律声明\n", en: "### Legal Notice\n", ja: "### 法的注意事項\n", ko: "### 법적 안내\n")
        pdfContent += L10n.text("本遗嘱文件仅供参考，建议前往公证处办理正式遗嘱公证。\n", en: "This document is for reference only. It is recommended to notarize the will.\n", ja: "この文書は参考用です。公証役場での正式な公証を推奨します。\n", ko: "이 문서는 참고용입니다. 공증을 받는 것을 권장합니다.\n")
        pdfContent += L10n.text("携带本人身份证件前往公证处办理正式遗嘱公证。\n\n", en: "Bring valid identification to the notary office for formal notarization.\n\n", ja: "本人確認書類を持参して公証役場で正式に公証してください。\n\n", ko: "신분증을 지참하고 공증사무소에서 공식 공증을 받으세요.\n\n")
        pdfContent += "\(L10n.text("生成时间：", en: "Generated at: ", ja: "生成日時: ", ko: "생성 시간: "))\(Date().localizedDateTimeString())\n"
        
        print("✅ 遗嘱内容收集完成")
        
        // 保存为 PDF（模拟实现）
        // 在实际应用中，应使用 PDFKit 创建真实的 PDF 文件
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let pdfPath = documentsPath.appendingPathComponent("遺囑_\(Date().chineseFileNameString()).pdf")
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
