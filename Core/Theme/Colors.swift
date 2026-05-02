//
//  Colors.swift
//  终活
//
//  颜色定义
//

import SwiftUI

// MARK: - 主题色
extension Color {
    static let appPrimary = Color(hex: "AF52DE")
    static let appSecondary = Color(hex: "007AFF")
    static let appSuccess = Color(hex: "34C759")
    static let appWarning = Color(hex: "FF9500")
    static let appDanger = Color(hex: "FF3B30")
    static var appBackground: Color {
        Color(uiColor: .systemGroupedBackground)
    }
    static var appCardBackground: Color {
        Color(.secondarySystemBackground)
    }
    static var appCardElevatedBackground: Color {
        Color(.tertiarySystemBackground)
    }
    static var appDivider: Color {
        Color(.separator)
    }
}

// MARK: - 留言类型颜色
extension TimeCapsule.CapsuleType {
    var swiftUIColor: Color {
        Color(hex: color)
    }
}

// MARK: - 重要事项类型颜色
extension WillModule.WillType {
    var swiftUIColor: Color {
        Color(hex: color)
    }
}

// MARK: - 资产类型颜色
extension Asset.AssetType {
    var swiftUIColor: Color {
        Color(hex: color)
    }
}
