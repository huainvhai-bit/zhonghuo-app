//
//  CapsuleListViewModel.swift
//  安心助手
//
//  留言列表状态与同步
//

import Foundation
import SwiftUI

@MainActor
final class CapsuleListViewModel: ObservableObject {
    private let dataManager = DataManager.shared
    private var didLoadLocalCapsules = false

    func onAppear() {
        guard !didLoadLocalCapsules else { return }
        didLoadLocalCapsules = true

        if dataManager.capsules.isEmpty {
            print("📂 本地留言为空，从文件加载...")
            let loadedCapsules = dataManager.loadCapsulesFromFile()
            dataManager.capsules = loadedCapsules
            print("📂 已加载留言：\(loadedCapsules.count) 个")
        } else {
            print("📂 本地已有留言：\(dataManager.capsules.count) 个，优先使用本地数据")
        }
    }

    func refresh() async {
        let loadedCapsules = dataManager.loadCapsulesFromFile()
        dataManager.capsules = loadedCapsules
        print("🔄 留言列表已刷新：\(loadedCapsules.count) 个")
    }

    func deleteCapsules(at offsets: IndexSet, filteredCapsules: [TimeCapsule]) {
        for index in offsets {
            let capsule = filteredCapsules[index]
            dataManager.capsules.removeAll { $0.id == capsule.id }
            dataManager.saveCapsulesToFile()
        }

        print("🗑️ 留言已从本地删除，未执行云端同步")
    }
}
