//
//  ThemeManager.swift
//  终活
//
//  主题管理器 - 支持深色模式
//

import SwiftUI

/// 主题管理器
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    /// 当前主题
    @Published var currentTheme: AppTheme = .system
    
    /// 是否深色模式
    var isDarkMode: Bool {
        switch currentTheme {
        case .system:
            return UITraitCollection.current.userInterfaceStyle == .dark
        case .light:
            return false
        case .dark:
            return true
        }
    }
    
    private init() {}
    
    /// 设置主题
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "appTheme")
    }
    
    /// 加载保存的主题
    func loadSavedTheme() {
        if let rawValue = UserDefaults.standard.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: rawValue) {
            currentTheme = theme
        }
    }
}

/// 应用主题枚举
enum AppTheme: String {
    case system = "system"  // 跟随系统
    case light = "light"    // 浅色模式
    case dark = "dark"      // 深色模式
}

/// Color 扩展 - 支持主题色
extension Color {
    static var primaryBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
            UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1) :
            UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1)
        })
    }
    
    static var secondaryBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
            UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1) :
            UIColor.white
        })
    }
    
    static var primaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
            UIColor.white :
            UIColor.black
        })
    }
    
    static var secondaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
            UIColor.lightGray :
            UIColor.gray
        })
    }
}
