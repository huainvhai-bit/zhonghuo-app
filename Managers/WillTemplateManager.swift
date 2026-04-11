//
//  WillTemplateManager.swift
//  终活
//
//  遗嘱模板管理器（简化版）
//  功能：提供遗嘱模板
//

import Foundation

class WillTemplateManager: ObservableObject {
    static let shared = WillTemplateManager()
    
    private init() {}
    
    // MARK: - 遗嘱模板定义
    
    struct WillTemplate: Identifiable {
        let id = UUID()
        let name: String
        let type: WillModule.WillType
        let description: String
        let contentTemplate: String
    }
    
    /// 遗嘱模板列表
    var templates: [WillTemplate] = []  // 模板列表为空，待完善
}
