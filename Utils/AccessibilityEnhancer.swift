//
//  AccessibilityEnhancer.swift
//  终活
//
//  无障碍功能增强工具类
//

import SwiftUI

/// 无障碍功能增强器
class AccessibilityEnhancer {
    
    static let shared = AccessibilityEnhancer()
    
    private init() {}
    
    /// 检查是否启用 VoiceOver
    var isVoiceOverEnabled: Bool {
        return UIAccessibility.isVoiceOverRunning
    }
    
    /// 检查是否启用辅助触控
    var isAssistiveTouchEnabled: Bool {
        return UIAccessibility.isAssistiveTouchRunning
    }
    
    /// 检查是否减少动态效果
    var isReduceMotionEnabled: Bool {
        return UIAccessibility.isReduceMotionEnabled
    }
    
    /// 检查是否增加对比度
    var isIncreaseContrastEnabled: Bool {
        return UIAccessibility.isIncreaseContrastEnabled
    }
    
    /// 检查是否启用粗体文本
    var isBoldTextEnabled: Bool {
        return UIAccessibility.isBoldTextEnabled
    }
    
    /// 获取动态字体大小
    func getDynamicFontSize(for textStyle: UIFont.TextStyle) -> CGFloat {
        let font = UIFont.preferredFont(forTextStyle: textStyle)
        return font.pointSize
    }
    
    /// 检查是否是无障碍模式
    var isAccessibilityMode: Bool {
        return UIAccessibility.isVoiceOverRunning ||
               UIAccessibility.isAssistiveTouchRunning ||
               UIAccessibility.isReduceMotionEnabled
    }
}

/// View 扩展 - 无障碍修饰符
extension View {
    /// 添加无障碍标签
    func accessibilityLabel(_ label: String) -> some View {
        self.accessibilityLabel(Text(label))
    }
    
    /// 添加无障碍提示
    func accessibilityHint(_ hint: String) -> some View {
        self.accessibilityHint(Text(hint))
    }
    
    /// 添加无障碍值
    func accessibilityValue(_ value: String) -> some View {
        self.accessibilityValue(Text(value))
    }
    
    /// 添加无障碍特性
    func accessibilityTraits(_ traits: AccessibilityTraits) -> some View {
        self.accessibilityTraits(traits)
    }
    
    /// 无障碍按钮
    func accessibilityButton() -> some View {
        self.accessibilityTraits(.button)
    }
    
    /// 无障碍标题
    func accessibilityHeader() -> some View {
        self.accessibilityTraits(.header)
    }
    
    /// 无障碍图像
    func accessibilityImage(label: String) -> some View {
        self.accessibilityLabel(label)
            .accessibilityTraits(.image)
    }
}

/// 无障碍通知
extension Notification.Name {
    static let accessibilityStatusChanged = Notification.Name("accessibilityStatusChanged")
}
