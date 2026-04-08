//
//  PDFExportSheet.swift
//  终活
//
//  PDF 导出界面
//

import SwiftUI
import UniformTypeIdentifiers

struct PDFExportSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool
    let modules: [WillModule]
    let witnesses: [Witness]
    let assets: [Asset]
    let onSuccess: () -> Void
    
    @State private var isExporting = false
    @State private var exportSuccess = false
    @State private var exportedFileURL: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 图标
                ZStack {
                    Circle()
                        .fill(Color(hex: "AF52DE").opacity(0.12))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "doc.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: "AF52DE"))
                }
                .padding(.top, 40)
                
                // 标题
                VStack(spacing: 8) {
                    Text("导出遗嘱文档")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("生成 PDF 文件，可打印或分享给律师")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 内容预览
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundColor(Color(hex: "AF52DE"))
                        Text("包含内容")
                            .font(.headline)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ContentRow(icon: "doc.text.fill", text: "已完成的遗嘱模块", count: modules.filter { $0.isCompleted }.count)
                        ContentRow(icon: "person.2.fill", text: "见证人信息", count: witnesses.count)
                        ContentRow(icon: "yensign.circle.fill", text: "资产记录", count: assets.count)
                    }
                    .padding(16)
                    .background(Color(hex: "F2F2F7"))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // 导出按钮
                Button(action: exportPDF) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                        
                        Text(isExporting ? "生成中..." : "导出 PDF")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isExporting ? Color.gray : Color(hex: "AF52DE"))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(isExporting)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // 提示信息
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("文件仅保存在本地，安全加密")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 16)
            }
            .background(Color(hex: "F6F6F8"))
            .navigationTitle("导出 PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
            .fileExporter(
                isPresented: $exportSuccess,
                document: exportedFileURL.map { PDFDocument(url: $0) } ?? PDFDocument(),
                contentType: .pdf,
                defaultFilename: "终活 - 遗嘱文档_\(formatDate(Date())).pdf"
            ) { result in
                isExporting = false
                switch result {
                case .success(let url):
                    print("✅ PDF 导出成功：\(url)")
                    onSuccess()
                    isPresented = false
                case .failure(let error):
                    print("❌ PDF 导出失败：\(error)")
                    isExporting = false
                }
            }
        }
    }
    
    private func exportPDF() {
        isExporting = true
        
        // 生成 PDF
        guard let pdfData = PDFGenerator.exportWillModulesToPDF(modules: modules, witnesses: witnesses, assets: assets) else {
            print("❌ PDF 生成失败")
            isExporting = false
            return
        }
        
        // 保存到临时文件
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "终活_遗嘱文档_\(Date().timeIntervalSince1970).pdf"
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try pdfData.write(to: fileURL)
            exportedFileURL = fileURL
            exportSuccess = true
        } catch {
            print("❌ 保存 PDF 失败：\(error)")
            isExporting = false
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy 年 MM 月 dd 日_HHmm"
        return formatter.string(from: date)
    }
}

// MARK: - 内容行
struct ContentRow: View {
    let icon: String
    let text: String
    let count: Int
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "AF52DE"))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "AF52DE"))
        }
    }
}

// MARK: - PDF Document Wrapper
struct PDFDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    
    var data: Data
    
    init(data: Data = Data()) {
        self.data = data
    }
    
    init?(url: URL) {
        guard let data = try? Data(contentsOf: url) else { return nil }
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    PDFExportSheet(
        isPresented: .constant(true),
        modules: [],
        witnesses: [],
        assets: [],
        onSuccess: {}
    )
}
