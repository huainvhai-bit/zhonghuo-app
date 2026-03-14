//
//  DataManager.swift
//  终活 - 数据管理
//

import Foundation
import SwiftUI

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var currentUser: User?
    @Published var timeCapsules: [TimeCapsule] = []
    @Published var checklistItems: [ChecklistItem] = []
    @Published var emergencyContacts: [EmergencyContact] = []
    @Published var assets: [Asset] = []
    
    private init() {
        loadSampleData()
    }
    
    func loadSampleData() {
        // 示例数据
        timeCapsules = [
            TimeCapsule(title: "给十年后的自己", content: "希望你还记得今天的梦想...", openDate: Date().addingTimeInterval(365*24*3600*10), isLocked: true),
            TimeCapsule(title: "给孩子的信", content: "亲爱的宝贝...", openDate: Date().addingTimeInterval(365*24*3600*18), isLocked: true, recipient: "孩子")
        ]
        
        checklistItems = [
            ChecklistItem(title: "整理照片", isCompleted: false, category: "数字资产"),
            ChecklistItem(title: "更新遗嘱", isCompleted: false, category: "法律文件"),
            ChecklistItem(title: "通知家人", isCompleted: true, category: "联系人")
        ]
        
        emergencyContacts = [
            EmergencyContact(name: "张三", relationship: "配偶", phone: "138****1234"),
            EmergencyContact(name: "李四", relationship: "子女", phone: "139****5678")
        ]
    }
}
