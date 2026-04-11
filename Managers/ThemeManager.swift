//
//  ThemeManager.swift
//  终活
//
//  主题管理器 - 简化版
//

import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    enum Theme: String, CaseIterable, Codable {
        case auto    // 跟随系统（默认）
        case light   // 浅色模式
        case dark    // 深色模式
    }
    
    @Published var theme: Theme = .auto
    
    private init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "theme"),
           let theme = Theme(rawValue: savedTheme) {
            self.theme = theme
        }
    }
    
    func setTheme(_ newTheme: Theme) {
        theme = newTheme
        UserDefaults.standard.set(newTheme.rawValue, forKey: "theme")
    }
    
    var isDarkMode: Bool {
        switch theme {
        case .auto:
            return UIScreen.main.traitCollection.userInterfaceStyle == .dark
        case .light:
            return false
        case .dark:
            return true
        }
    }
}
