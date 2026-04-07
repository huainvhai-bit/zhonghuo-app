//
//  PDFExporter.swift
//  终活
//
//  PDF 导出器（V1.1.0 P1 重要）
//  功能：使用 PDFKit 生成专业遗嘱文档
//

import UIKit
import PDFKit

class PDFExporter {
    static let shared = PDFExporter()
    
    private init() {}
    
    // MARK: - PDF 生成
    
    /// 导出遗嘱为专业 PDF
    func exportWillToPDF(will: WillModule) -> Data? {
        print("🔵 PDFExporter.exportWillToPDF 开始...")
        
        // 创建 PDF 文档
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFInfoTitle as String: "遗嘱 - \(will.type)",
            kCGPDFInfoAuthor as String: UserManager.shared.currentUser?.name ?? "未知用户",
        ]
        
        // 定义页面尺寸（A4）
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // 绘制页面
            drawWillPage(context: context, pageRect: pageRect, will: will)
        }
        
        print("✅ PDFExporter:遗嘱 PDF 已生成")
        return data
    }
    
    /// 绘制遗嘱页面
    private func drawWillPage(context: UIGraphicsPDFRendererContext, pageRect: CGRect, will: WillModule) {
        let margin: CGFloat = 40
        let contentRect = pageRect.insetBy(dx: margin, dy: margin)
        
        // 绘制背景色
        UIColor.white.setFill()
        context.goToPage(pageRect)
        UIRectFill(pageRect)
        
        // 绘制标题
        drawTitle(context: context, contentRect: contentRect)
        
        // 绘制遗嘱类型
        drawWillType(context: context, contentRect: contentRect, will: will)
        
        // 绘制遗嘱内容
        drawWillContent(context: context, contentRect: contentRect, will: will)
        
        // 绘制法律声明
        drawLegalNotice(context: context, contentRect: contentRect)
        
        // 绘制页脚
        drawFooter(context: context, pageRect: pageRect)
    }
    
    /// 绘制标题
    private func drawTitle(context: UIGraphicsPDFRendererContext, contentRect: CGRect) {
        let title = "遗嘱"
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: UIColor(hex: "AF52DE"),
            .paragraphStyle: para
        ]
        
        let titleStr = NSAttributedString(string: title, attributes: attrs)
        let titleRect = CGRect(x: contentRect.origin.x, y: contentRect.origin.y, width: contentRect.width, height: 40)
        titleStr.draw(in: titleRect)
    }
    
    /// 绘制遗嘱类型
    private func drawWillType(context: UIGraphicsPDFRendererContext, contentRect: CGRect, will: WillModule) {
        let typeText = "类型：\(will.type)"
        let para = NSMutableParagraphStyle()
        para.alignment = .left
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: para
        ]
        
        let typeStr = NSAttributedString(string: typeText, attributes: attrs)
        let typeRect = CGRect(x: contentRect.origin.x, y: contentRect.origin.y + 50, width: contentRect.width, height: 20)
        typeStr.draw(in: typeRect)
    }
    
    /// 绘制遗嘱内容
    private func drawWillContent(context: UIGraphicsPDFRendererContext, contentRect: CGRect, will: WillModule) {
        let content = will.content.isEmpty ? "暂无内容" : will.content
        let attributedString = NSMutableAttributedString(
            string: content,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .paragraphStyle: {
                    let para = NSMutableParagraphStyle()
                    para.lineHeightMultiple = 1.5
                    return para
                }(),
                .foregroundColor: UIColor.black
            ]
        )
        
        // 计算内容高度
        let rect = CGRect(x: contentRect.origin.x, y: contentRect.origin.y + 90, width: contentRect.width, height: 1000)
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let path = CGPath(rect: rect, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributedString.length), path, nil)
        
        // 绘制内容
        context.drawPDFPage(with: UIGraphicsGetCurrentContext()!.currentState.cgContext, at: rect.origin)
    }
    
    /// 绘制法律声明
    private func drawLegalNotice(context: UIGraphicsPDFRendererContext, contentRect: CGRect) {
        let notice = """
        法律声明：
        本遗嘱文件需经合法见证人签署方可生效。
        建议携带本人身份证件前往公证处办理正式遗嘱公证。
        """
        
        let para = NSMutableParagraphStyle()
        para.alignment = .left
        para.lineHeightMultiple = 1.4
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.gray,
            .paragraphStyle: para
        ]
        
        let noticeRect = CGRect(x: contentRect.origin.x, y: contentRect.origin.y + 600, width: contentRect.width, height: 60)
        (notice as NSString).draw(in: noticeRect, withAttributes: attrs)
    }
    
    /// 绘制页脚
    private func drawFooter(context: UIGraphicsPDFRendererContext, pageRect: CGRect) {
        let footerText = "生成时间：\(Date().formatted()) | 终活 App"
        
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.lightGray,
            .paragraphStyle: para
        ]
        
        let footerRect = CGRect(x: pageRect.origin.x, y: pageRect.height - 30, width: pageRect.width, height: 20)
        (footerText as NSString).draw(in: footerRect, withAttributes: attrs)
    }
    
    // MARK: - PDF 保存
    
    /// 保存 PDF 到_documents 目录
    func savePDF(data: Data, filename: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let pdfPath = documentsPath.appendingPathComponent(filename)
        
        do {
            try data.write(to: pdfPath, options: .atomicWrite)
            print("✅ PDFExporter: PDF 已保存到：\(pdfPath.path)")
            return pdfPath
        } catch {
            print("❌ PDFExporter: 保存 PDF 失败：\(error.localizedDescription)")
            return nil
        }
    }
    
    /// 导出并保存遗嘱 PDF
    func exportAndSaveWillPDF(will: WillModule) -> URL? {
        guard let pdfData = exportWillToPDF(will: will) else {
            return nil
        }
        
        let filename = "遗嘱_\(will.type)_\(Date().formatted(.iso8601)).pdf"
        return savePDF(data: pdfData, filename: filename)
    }
    
    // MARK: - 预览 PDF
    
    /// 预览 PDF（打开系统预览）
    func previewPDF(url: URL) {
        let documentInteractionController = UIDocumentInteractionController(url: url)
        documentInteractionController.delegate = UIApplication.shared.delegate as? UIDocumentInteractionControllerDelegate
        
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            documentInteractionController.presentPreview(animated: true)
        }
    }
}

// MARK: - 遗嘱类型扩展

extension WillModule {
    /// 获取遗嘱类型的中文名称
    var typeNameDisplay: String {
        switch type {
        case .full:
            return "完整遗嘱"
        case .digital:
            return "数字遗嘱"
        case .oral:
            return "口头遗嘱"
        case .secret:
            return "密封遗嘱"
        case .proxy:
            return "代书遗嘱"
        @unknown default:
            return "遗嘱"
        }
    }
}

// MARK: - Color 扩展

extension UIColor {
    /// 从十六进制字符串创建颜色
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        
        guard hex.count >= 6 else { return nil }
        
        let scanner = Scanner(string: hex)
        var hexValue: UInt64 = 0
        scanner.scanHexInt64(&hexValue)
        
        let rValue = (hexValue & 0xFF0000) >> 16
        let gValue = (hexValue & 0x00FF00) >> 8
        let bValue = hexValue & 0x0000FF
        
        r = CGFloat(rValue) / 255
        g = CGFloat(gValue) / 255
        b = CGFloat(bValue) / 255
        a = 1.0
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
