//
//  LifeCheckStatusManager.swift
//  终活 - 生命签到管理
//

import Foundation

class LifeCheckStatusManager: ObservableObject {
    static let shared = LifeCheckStatusManager()
    
    @Published var lastCheckInDate: Date?
    @Published var countdownHours: Int = 24
    
    private init() {}
    
    func checkIn() {
        lastCheckInDate = Date()
        countdownHours = 24
    }
    
    func updateCountdown() {
        // TODO: 更新倒计时
    }
}
