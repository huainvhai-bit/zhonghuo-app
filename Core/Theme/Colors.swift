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
    static let appBackground = Color(hex: "F2F2F7")
    static let appCardBackground = Color.white
}

// MARK: - 胶囊类型颜色
extension TimeCapsule.CapsuleType {
    var swiftUIColor: Color {
        Color(hex: color)
    }
}

// MARK: - 遗嘱类型颜色
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
