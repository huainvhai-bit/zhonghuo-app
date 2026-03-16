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
                        NotificationCenter.default.post(name: NSNotification.Name("ExportPDF"), object: nil)
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
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    WillPreviewView()
}
