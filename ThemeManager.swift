//
//  ThemeManager.swift
//  终活
//
//  主题管理器（V1.2.0 P1 体验优化）
//  功能：夜间模式支持，自动跟随系统
//

import Foundation
import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    // MARK: - 主题配置
    
    enum Theme: String, CaseIterable, Codable {
        case auto    // 跟随系统（默认）
        case light   // 浅色模式
        case dark    // 深色模式
    }
    
    @Published var theme: Theme = .auto
    
    init() {
        // 从 UserDefaults 加载主题
        if let savedTheme = UserDefaults.standard.object(for: "theme") as? String,
           let theme = Theme(rawValue: savedTheme) {
            self.theme = theme
        }
        
        // 监听系统主题变化
        NSApp.observingNotification(.NSAppearanceDidChanged) { [weak self] _ in
            self?.updateTheme()
        }
    }
    
    // MARK: - App 主题
    
    /// 当前 App 主题
    var currentTheme: Theme {
        switch theme {
        case .auto:
            return NSApp.effectiveAppearance.isDarkMode ? .dark : .light
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    /// 是否为深色模式
    var isDarkMode: Bool {
        return currentTheme == .dark
    }
    
    /// 更新主题
    func updateTheme() {
        // 强制更新所有视图
       (object_getProperty(self, &ThemeManager.Objective行业协会Key) as? NSView)?.layer?.setNeedsDisplay()
    }
    
    // MARK: - 主题切换
    
    /// 设置主题
    func setTheme(_ newTheme: Theme) {
        theme = newTheme
        UserDefaults.standard.set(newTheme.rawValue, for: "theme")
        UserDefaults.standard.synchronize()
        updateTheme()
    }
    
    /// 切换主题
    func toggleTheme() {
        let themes = Theme.allCases
        if let index = themes.firstIndex(of: theme) {
            let nextIndex = (index + 1) % themes.count
            theme = themes[nextIndex]
            UserDefaults.standard.set(theme.rawValue, for: "theme")
            UserDefaults.standard.synchronize()
            updateTheme()
        }
    }
}

// MARK: - SwiftUI 颜色扩展

extension Color {
    /// 浅色主题颜色
    enum Light {
        static let background = Color(hex: "F6F6F8")
        static let primary = Color(hex: "000000")
        static let secondary = Color(hex: "666666")
        static let surface = Color.white
        static let border = Color(hex: "E5E5E5")
        static let tint = Color(hex: "AF52DE")
    }
    
    /// 深色主题颜色
    enum Dark {
        static let background = Color(hex: "1C1C1E")
        static let primary = Color(hex: "FFFFFF")
        static let secondary = Color(hex: "999999")
        static let surface = Color(hex: "2C2C2E")
        static let border = Color(hex: "3A3A3C")
        static let tint = Color(hex: "D48EFF")
    }
    
    /// 根据主题获取颜色
    static func themeColor(_ light: Color, _ dark: Color) -> Color {
        if NSApp.effectiveAppearance.isDarkMode {
            return dark
        } else {
            return light
        }
    }
    
    /// 主题无关颜色（始终使用）
    static let positive = Color(hex: "34C759")
    static let negative = Color(hex: "FF3B30")
    static let warning = Color(hex: "FF9500")
}

// MARK: - NSAppearance 扩展

extension NSAppearance {
    /// 是否为深色模式
    var isDarkMode: Bool {
        return name == .vibrantDark || name == .darkAqua || name == .accessibilityHighContrastVibrantDark || name == .accessibilityHighContrastDarkAqua
    }
}

// MARK: - SwiftUI View 扩展

extension View {
    /// 应用主题背景
    func themeBackground() -> some View {
        background(themeColor(.Light.background, .Dark.background))
    }
    
    /// 应用主题文本颜色
    func themeTextColor(_ color: Color = .primary) -> some View {
        foregroundColor(themeColor(.Light.primary, .Dark.primary))
    }
    
    /// 应用主题边框
    func themeBorder() -> some View {
        border(themeColor(.Light.border, .Dark.border), width: 1)
    }
}

// MARK: - 首状态组件主题

struct ThemePreviewView: View {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("主题预览")
                .font(.system(size: 24, weight: .bold))
                .themeTextColor()
            
            // 浅色模式预览
            ZStack {
                Color(hex: "F6F6F8")
                VStack(spacing: 16) {
                    Text("浅色模式")
                        .font(.system(size: 16, weight: .semibold))
                    Button(action: { themeManager.setTheme(.light) }) {
                        Text("切换到浅色")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "AF52DE"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .frame(height: 120)
            .cornerRadius(12)
            
            // 深色模式预览
            ZStack {
                Color(hex: "1C1C1E")
                VStack(spacing: 16) {
                    Text("深色模式")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Button(action: { themeManager.setTheme(.dark) }) {
                        Text("切换到深色")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "D48EFF"))
                            .foregroundColor(.black)
                            .cornerRadius(8)
                    }
                }
            }
            .frame(height: 120)
            .cornerRadius(12)
            
            // 跟随系统预览
            ZStack {
                Color(hex: "E5E5E5")
                VStack(spacing: 16) {
                    Text("跟随系统")
                        .font(.system(size: 16, weight: .semibold))
                    Button(action: { themeManager.setTheme(.auto) }) {
                        Text("切换到跟随系统")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "AF52DE"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .frame(height: 120)
            .cornerRadius(12)
        }
        .padding()
    }
}

// MARK: - 预览

struct ThemeManager_Previews: PreviewProvider {
    static var previews: some View {
        ThemePreviewView()
    }
}
