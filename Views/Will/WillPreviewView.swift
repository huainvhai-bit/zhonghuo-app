//
//  WillPreviewView.swift
//  终活
//
//  遗嘱预览页面
//

import SwiftUI

struct WillPreviewView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 遗嘱标题
                    VStack(spacing: 8) {
                        Text("遗嘱文档预览")
                            .font(.system(size: 20, weight: .bold))
                        
                        Text("生成时间：\(formatDate(Date()))")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 20)
                    
                    // 个人信息
                    infoSection(
                        title: "立遗嘱人信息",
                        content: """
                        姓名：\(dataManager.settings.name)
                        身份证号：[待填写]
                        联系电话：[待填写]
                        """
                    )
                    
                    // 遗嘱模块
                    ForEach(dataManager.willModules.filter { $0.isCompleted }) { module in
                        infoSection(
                            title: module.type.rawValue,
                            content: module.content.isEmpty ? "暂无内容" : module.content
                        )
                    }
                    
                    // 见证人信息
                    if !dataManager.witnesses.isEmpty {
                        infoSection(
                            title: "见证人信息",
                            content: dataManager.witnesses.map { "\($0.name) - \($0.role) - \($0.phone)" }.joined(separator: "\n")
                        )
                    }
                    
                    // 资产信息
                    if !dataManager.assets.isEmpty {
                        infoSection(
                            title: "资产清单",
                            content: dataManager.assets.map { "\($0.type.rawValue)：\($0.name) - \($0.institution)" }.joined(separator: "\n")
                        )
                    }
                    
                    // 法律说明
                    VStack(alignment: .leading, spacing: 12) {
                        Text("⚖️ 法律说明")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "AF52DE"))
                        
                        Text("""
                        1. 本遗嘱为自书遗嘱，根据《中华人民共和国民法典》规定，需满足以下条件才具有法律效力：
                           - 立遗嘱人亲笔书写
                           - 立遗嘱人亲笔签名
                           - 注明年、月、日
                        
                        2. 建议有 2 名以上无利害关系的见证人在场见证，或前往公证处办理公证。
                        
                        3. 本预览仅供参考，正式遗嘱请以纸质手写版本为准。
                        """)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // 导出按钮
                    Button(action: {
                        // 触发 PDF 导出
                        exportWillToPDF()
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.gearshape.fill")
                            Text("导出 PDF 版本")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "AF52DE"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .background(Color(hex: "F6F6F8"))
            .navigationTitle("遗嘱预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
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
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    WillPreviewView()
}
// MARK: -遗嘱 PDF 导出（WillPreviewView 扩展）

extension WillPreviewView {
    /// 导出遗嘱为 PDF
    func exportWillToPDF() {
        print("🔵 WillPreviewView.exportWillToPDF 开始...")
        
        // 收集遗嘱内容
        var pdfContent = "遗嘱文档\n"
        pdfContent += "生成时间：\(Date().formatted())\n"
        pdfContent += String(repeating: "-", count: 50) + "\n\n"
        
        // 个人信息
        pdfContent += "### 立遗嘱人信息\n"
        pdfContent += "姓名：\(dataManager.settings.name)\n"
        pdfContent += "身份证号：[待填写]\n"
        pdfContent += "联系电话：[待填写]\n\n"
        
        // 遗嘱模块
        for module in dataManager.willModules.filter({ $0.isCompleted }) {
            pdfContent += "### \(module.type.rawValue)\n"
            pdfContent += module.content.isEmpty ? "暂无内容\n" : module.content + "\n\n"
        }
        
        // 见证人信息
        if !dataManager.witnesses.isEmpty {
            pdfContent += "### 见证人信息\n"
            for witness in dataManager.witnesses {
                pdfContent += "- \(witness.name)（身份证：\(witness.idNumber)）\n"
            }
            pdfContent += "\n"
        }
        
        // 附注
        pdfContent += "### 法律声明\n"
        pdfContent += "本遗嘱文件需经合法见证人签署方可生效。\n"
        pdfContent += "建议携带本人身份证件前往公证处办理正式遗嘱公证。\n\n"
        pdfContent += "生成时间：\(Date().formatted())\n"
        
        print("✅ 遗嘱内容收集完成")
        
        // 保存为 PDF（模拟实现）
        // 在实际应用中，应使用 PDFKit 创建真实的 PDF 文件
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let pdfPath = documentsPath.appendingPathComponent("遺囑_\(Date().formatted(.iso8601)).pdf")
            print("PDF 保存路径：\(pdfPath.path)")
            
            // TODO: 使用 PDFKit 创建真实 PDF
            // let pdfData = createPDF(from: pdfContent)
            // try? pdfData.write(to: pdfPath)
            
            print("⚠️ WillPreviewView: PDF 导出功能需使用 PDFKit 实现（当前为占位）")
            
            // 临时实现：保存为 Markdown 文件
            let mdPath = documentsPath.appendingPathComponent("遺囑_\(Date().formatted(.iso8601)).md")
            do {
                try pdfContent.write(to: mdPath, atomically: true, encoding: .utf8)
                print("✅ 临时 Markdown 文件已保存到：\(mdPath.path)")
            } catch {
                print("❌ 保存失败：\(error.localizedDescription)")
            }
        }
    }
}
