//
//  CapsuleListViewModel.swift
//  终活
//
//  胶囊列表状态与同步
//

import Foundation
import SwiftUI

@MainActor
final class CapsuleListViewModel: ObservableObject {
    private let dataManager = DataManager.shared

    func onAppear() {
        if dataManager.capsules.isEmpty {
            print("📂 本地胶囊为空，从文件加载...")
            let loadedCapsules = dataManager.loadCapsulesFromFile()
            dataManager.capsules = loadedCapsules
            print("📂 已加载胶囊：\(loadedCapsules.count) 个")
        } else {
            print("📂 本地已有胶囊：\(dataManager.capsules.count) 个，优先使用本地数据")
        }

        Task {
            _ = await dataManager.batchSyncCapsules()
        }
    }

    func refresh() async {
        _ = await dataManager.batchSyncCapsules()
    }

    func deleteCapsules(at offsets: IndexSet, filteredCapsules: [TimeCapsule]) {
        for index in offsets {
            let capsule = filteredCapsules[index]
            dataManager.capsules.removeAll { $0.id == capsule.id }
            dataManager.saveCapsulesToFile()
        }

        Task {
            _ = await dataManager.batchSyncCapsules()
        }
    }
}
