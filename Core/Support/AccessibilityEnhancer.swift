//
//  AccessibilityEnhancer.swift
//  安伴助手
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
        return false // iOS 15+ 使用 traitCollection.accessibilityContrast
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



/// 无障碍通知
extension Notification.Name {
    static let accessibilityStatusChanged = Notification.Name("accessibilityStatusChanged")
}
