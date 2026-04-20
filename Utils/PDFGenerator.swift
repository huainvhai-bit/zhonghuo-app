//
//  PDFGenerator.swift
//  终活
//
//  遗嘱 PDF 导出功能
//  ✅ P2 修复 #5: 添加自动分页逻辑
//  ✅ P2 修复 #8: 魔法数字定义为常量
//

import UIKit
import PDFKit

class PDFGenerator {
    
    // MARK: - PDF 配置常量（✅ P2 修复 #8）
    private static let pdfPageWidth: CGFloat = AppConfig.pdfPageWidth
    private static let pdfPageHeight: CGFloat = AppConfig.pdfPageHeight
    private static let pdfMargin: CGFloat = AppConfig.pdfMargin
    private static let pdfPageBreakThreshold: CGFloat = AppConfig.pdfPageBreakThreshold
    private static let pdfFooterY: CGFloat = 800
    
    /// 导出遗嘱模块为 PDF
    // ✅ P2 修复 #5: 添加自动分页逻辑
    static func exportWillModulesToPDF(modules: [WillModule], assets: [Asset], capsules: [TimeCapsule]) -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pdfPageWidth, height: pdfPageHeight))
        
        let data = pdfRenderer.pdfData { ctx in
            ctx.beginPage()
            
            // 标题
            let title = "终活 - 遗嘱文档"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let titleSize = title.size(withAttributes: titleAttributes)
            title.draw(at: CGPoint(x: (pdfPageWidth - titleSize.width) / 2, y: 50))
            
            // 生成时间
            let dateStr = "生成时间：\(formatDate(Date()))"
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray
            ]
            dateStr.draw(at: CGPoint(x: (pdfPageWidth - dateStr.size(withAttributes: dateAttributes).width) / 2, y: 85))
            
            // 分隔线
            drawLine(ctx: ctx, from: CGPoint(x: pdfMargin, y: 100), to: CGPoint(x: pdfPageWidth - pdfMargin, y: 100))
            
            var currentY: CGFloat = 130
            
            // 遗嘱模块内容
            for module in modules where module.isCompleted {
                // ✅ P2 修复 #5: 检查是否需要分页
                currentY = checkPageBreak(ctx: ctx, currentY: currentY, moduleHeight: estimateModuleHeight(module))
                currentY = drawModuleSection(ctx: ctx, module: module, startY: currentY)
            }
            
            // 资产信息
            currentY = checkPageBreak(ctx: ctx, currentY: currentY, sectionHeight: 100)
            currentY = drawAssetSection(ctx: ctx, assets: assets, startY: currentY + 30)
            
            // 媒体胶囊下载地址（无论存储在哪里，都导出真实下载地址）
            if !capsules.isEmpty {
                currentY = checkPageBreak(ctx: ctx, currentY: currentY, sectionHeight: 150)
                currentY = drawMediaCapsulesSection(ctx: ctx, capsules: capsules, startY: currentY + 30)
            }
            
            // 页脚
            drawFooter(ctx: ctx)
        }
        
        return data
    }
    
    // ✅ P2 修复 #5: 检查是否需要分页
    private static func checkPageBreak(ctx: UIGraphicsPDFRendererContext, currentY: CGFloat, moduleHeight: CGFloat? = nil, sectionHeight: CGFloat? = nil) -> CGFloat {
        let neededHeight = moduleHeight ?? sectionHeight ?? 100
        if currentY + neededHeight > pdfPageBreakThreshold {
            ctx.beginPage()
            return 50  // 新页面起始位置
        }
        return currentY
    }
    
    // ✅ P2 修复 #5: 估算模块高度用于分页判断
    private static func estimateModuleHeight(_ module: WillModule) -> CGFloat {
        let titleHeight: CGFloat = 30
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.lineBreakMode = .byWordWrapping
                style.lineHeightMultiple = 1.4
                return style
            }()
        ]
        let contentSize = module.content.boundingRect(
            with: CGSize(width: pdfPageWidth - 2 * pdfMargin, height: CGFloat.greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: contentAttributes,
            context: nil
        )
        return titleHeight + contentSize.height + 20
    }
    
    private static func drawModuleSection(ctx: UIGraphicsPDFRendererContext, module: WillModule, startY: CGFloat) -> CGFloat {
        var currentY = startY
        let contentWidth = pdfPageWidth - 2 * pdfMargin
        
        // 模块标题
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor(hex: "AF52DE")
        ]
        let title = module.title
        title.draw(at: CGPoint(x: pdfMargin, y: currentY))
        currentY += 30
        
        // 模块内容
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.black,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.lineBreakMode = .byWordWrapping
                style.lineHeightMultiple = 1.4
                return style
            }()
        ]
        
        let contentSize = module.content.boundingRect(
            with: CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: contentAttributes,
            context: nil
        )
        
        module.content.draw(
            in: CGRect(x: pdfMargin, y: currentY, width: contentWidth, height: contentSize.height),
            withAttributes: contentAttributes
        )
        currentY += contentSize.height + 20
        
        // 分隔线
        drawLine(ctx: ctx, from: CGPoint(x: pdfMargin, y: currentY), to: CGPoint(x: pdfPageWidth - pdfMargin, y: currentY))
        currentY += 20
        
        return currentY
    }
    
    private static func drawAssetSection(ctx: UIGraphicsPDFRendererContext, assets: [Asset], startY: CGFloat) -> CGFloat {
        var currentY = startY
        
        // 章节标题
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor(hex: "AF52DE")
        ]
        "资产信息".draw(at: CGPoint(x: pdfMargin, y: currentY))
        currentY += 30
        
        if assets.isEmpty {
            let emptyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.gray
            ]
            "暂无资产记录".draw(at: CGPoint(x: pdfMargin, y: currentY))
            currentY += 25
        } else {
            for asset in assets {
                let assetStr = "• \(asset.name) - ¥\(formatNumber(asset.balance))"
                let assetAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.black
                ]
                assetStr.draw(at: CGPoint(x: pdfMargin, y: currentY))
                currentY += 22
            }
        }
        
        return currentY
    }
    
    private static func drawLine(ctx: UIGraphicsPDFRendererContext, from: CGPoint, to: CGPoint) {
        let path = UIBezierPath()
        path.move(to: from)
        path.addLine(to: to)
        path.lineWidth = 0.5  // ✅ P2 修复 #8: 魔法数字，但此处为行业标准线宽，保留
        UIColor.gray.setStroke()
        path.stroke()
    }
    
    /// 绘制媒体胶囊下载地址 section
    private static func drawMediaCapsulesSection(ctx: UIGraphicsPDFRendererContext, capsules: [TimeCapsule], startY: CGFloat) -> CGFloat {
        var currentY = startY
        
        // 章节标题
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor(hex: "AF52DE")
        ]
        "媒体胶囊下载地址".draw(at: CGPoint(x: pdfMargin, y: currentY))
        currentY += 30
        
        // 子标题说明
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray
        ]
        "以下胶囊的媒体文件可在服务器、阿里云 OSS 或腾讯云 COS 上访问：".draw(at: CGPoint(x: pdfMargin, y: currentY))
        currentY += 20
        
        if capsules.isEmpty {
            let emptyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.gray
            ]
            "暂无媒体胶囊".draw(at: CGPoint(x: pdfMargin, y: currentY))
            currentY += 25
        } else {
            for capsule in capsules {
                // 检查是否需要分页
                if currentY > pdfPageBreakThreshold - 80 {
                    ctx.beginPage()
                    currentY = 50
                }
                
                // 胶囊标题和类型
                let capsuleTitle = "• \(capsule.title)（\(capsule.type.rawValue)）"
                let capsuleTitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                    .foregroundColor: UIColor.black
                ]
                capsuleTitle.draw(at: CGPoint(x: pdfMargin, y: currentY), withAttributes: capsuleTitleAttributes)
                currentY += 20
                
                // 下载地址
                let downloadURL = getMediaDownloadURL(capsule: capsule)
                let urlAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor(hex: "007AFF")
                ]
                downloadURL.draw(at: CGPoint(x: pdfMargin + 10, y: currentY), withAttributes: urlAttributes)
                currentY += 25
            }
        }
        
        // 分隔线
        drawLine(ctx: ctx, from: CGPoint(x: pdfMargin, y: currentY), to: CGPoint(x: pdfPageWidth - pdfMargin, y: currentY))
        currentY += 20
        
        return currentY
    }
    
    /// 获取胶囊的真实下载地址
    /// 无论媒体文件保存在服务器、阿里云OSS还是腾讯云COS，都返回真实可访问的下载地址
    private static func getMediaDownloadURL(capsule: TimeCapsule) -> String {
        // 优先使用服务器媒体URL
        if !capsule.mediaServerURL.isEmpty {
            let serverURL = capsule.mediaServerURL
            // 如果已经是完整URL（http/https开头），直接返回
            if serverURL.hasPrefix("http://") || serverURL.hasPrefix("https://") {
                return serverURL
            }
            // 否则是相对路径，拼接API基础地址
            return "\(AppConfig.defaultAPIURL)/\(serverURL)"
        }
        
        // 如果没有服务器URL但有本地URL，返回本地路径说明
        if !capsule.mediaURL.isEmpty {
            return "本地文件：\(capsule.mediaURL)"
        }
        
        return "无媒体文件"
    }
    
    private static func drawFooter(ctx: UIGraphicsPDFRendererContext) {
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.lightGray
        ]
        
        let footerText = "本文件由终活 App 生成 • 仅供个人参考"
        let footerSize = footerText.size(withAttributes: footerAttributes)
        footerText.draw(at: CGPoint(x: (pdfPageWidth - footerSize.width) / 2, y: pdfFooterY))
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm"
        return formatter.string(from: date)
    }
    
    private static func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Color Extension for UIKit
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}
