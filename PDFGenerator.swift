//
//  PDFGenerator.swift
//  终活
//
//  遗嘱 PDF 导出功能
//

import UIKit
import PDFKit

class PDFGenerator {
    
    /// 导出遗嘱模块为 PDF
    static func exportWillModulesToPDF(modules: [WillModule], witnesses: [Witness], assets: [Asset]) -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842)) // A4 size
        
        let data = pdfRenderer.pdfData { ctx in
            ctx.beginPage()
            
            // 标题
            let title = "终活 - 遗嘱文档"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let titleSize = title.size(withAttributes: titleAttributes)
            title.draw(at: CGPoint(x: (595 - titleSize.width) / 2, y: 50))
            
            // 生成时间
            let dateStr = "生成时间：\(formatDate(Date()))"
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray
            ]
            dateStr.draw(at: CGPoint(x: (595 - dateStr.size(withAttributes: dateAttributes).width) / 2, y: 85))
            
            // 分隔线
            drawLine(ctx: ctx, from: CGPoint(x: 50, y: 100), to: CGPoint(x: 545, y: 100))
            
            var currentY: CGFloat = 130
            
            // 遗嘱模块内容
            for module in modules where module.isCompleted {
                currentY = drawModuleSection(ctx: ctx, module: module, startY: currentY)
                
                // 如果接近页面底部，开始新页面
                if currentY > 750 {
                    ctx.beginPage()
                    currentY = 50
                }
            }
            
            // 见证人信息
            currentY = drawWitnessSection(ctx: ctx, witnesses: witnesses, startY: currentY + 30)
            
            // 资产信息
            currentY = drawAssetSection(ctx: ctx, assets: assets, startY: currentY + 30)
            
            // 页脚
            drawFooter(ctx: ctx)
        }
        
        return data
    }
    
    private static func drawModuleSection(ctx: UIGraphicsPDFRendererContext, module: WillModule, startY: CGFloat) -> CGFloat {
        var currentY = startY
        
        // 模块标题
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor(hex: "AF52DE")
        ]
        let title = module.title
        title.draw(at: CGPoint(x: 50, y: currentY))
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
        
        let contentRect = CGRect(x: 50, y: currentY, width: 495, height: 0)
        let contentSize = module.content.boundingRect(with: CGSize(width: 495, height: CGFloat.greatestFiniteMagnitude),
                                                       options: .usesLineFragmentOrigin,
                                                       attributes: contentAttributes,
                                                       context: nil)
        
        module.content.draw(in: CGRect(x: 50, y: currentY, width: 495, height: contentSize.height), withAttributes: contentAttributes)
        currentY += contentSize.height + 20
        
        // 分隔线
        drawLine(ctx: ctx, from: CGPoint(x: 50, y: currentY), to: CGPoint(x: 545, y: currentY))
        currentY += 20
        
        return currentY
    }
    
    private static func drawWitnessSection(ctx: UIGraphicsPDFRendererContext, witnesses: [Witness], startY: CGFloat) -> CGFloat {
        var currentY = startY
        
        // 章节标题
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor(hex: "AF52DE")
        ]
        "见证人信息".draw(at: CGPoint(x: 50, y: currentY))
        currentY += 30
        
        if witnesses.isEmpty {
            let emptyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.gray
            ]
            "暂无见证人".draw(at: CGPoint(x: 50, y: currentY))
            currentY += 25
        } else {
            for witness in witnesses {
                let witnessStr = "• \(witness.name)（\(witness.role)）- \(witness.isConfirmed ? "已确认" : "待确认")"
                let witnessAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.black
                ]
                witnessStr.draw(at: CGPoint(x: 50, y: currentY))
                currentY += 22
            }
        }
        
        return currentY
    }
    
    private static func drawAssetSection(ctx: UIGraphicsPDFRendererContext, assets: [Asset], startY: CGFloat) -> CGFloat {
        var currentY = startY
        
        // 章节标题
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor(hex: "AF52DE")
        ]
        "资产信息".draw(at: CGPoint(x: 50, y: currentY))
        currentY += 30
        
        if assets.isEmpty {
            let emptyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.gray
            ]
            "暂无资产记录".draw(at: CGPoint(x: 50, y: currentY))
            currentY += 25
        } else {
            for asset in assets {
                let assetStr = "• \(asset.name) - ¥\(formatNumber(asset.balance))"
                let assetAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.black
                ]
                assetStr.draw(at: CGPoint(x: 50, y: currentY))
                currentY += 22
            }
        }
        
        return currentY
    }
    
    private static func drawLine(ctx: UIGraphicsPDFRendererContext, from: CGPoint, to: CGPoint) {
        let path = UIBezierPath()
        path.move(to: from)
        path.addLine(to: to)
        path.lineWidth = 0.5
        UIColor.gray.setStroke()
        path.stroke()
    }
    
    private static func drawFooter(ctx: UIGraphicsPDFRendererContext) {
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.lightGray
        ]
        
        let footerText = "本文件由终活 App 生成 • 仅供个人参考"
        let footerSize = footerText.size(withAttributes: footerAttributes)
        footerText.draw(at: CGPoint(x: (595 - footerSize.width) / 2, y: 800))
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
