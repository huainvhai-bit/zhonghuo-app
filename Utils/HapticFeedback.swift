//
//  HapticFeedback.swift
//  终活
//
//  触觉反馈工具类
//

import UIKit

/// 触觉反馈管理器
class HapticFeedback {
    
    static let shared = HapticFeedback()
    
    private init() {}
    
    /// 成功反馈
    func success() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// 警告反馈
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// 错误反馈
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// 轻触反馈
    func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// 中等反馈
    func mediumTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// 重击反馈
    func heavyTap() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// 选择反馈
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

/// View 扩展 - 添加触觉反馈
extension View {
    func hapticOnTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.impactOccurred()
            }
        )
    }
}
