//
//  DataManagerTests.swift
//  ZhonghuoTests
//
//  数据管理器单元测试
//

import XCTest
@testable import 终活

final class DataManagerTests: XCTestCase {
    
    var dataManager: DataManager!
    
    override func setUp() {
        super.setUp()
        dataManager = DataManager.shared
    }
    
    override func tearDown() {
        dataManager = nil
        super.tearDown()
    }
    
    func testSingleton() {
        // 测试单例模式
        let instance1 = DataManager.shared
        let instance2 = DataManager.shared
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testCapsuleCRUD() {
        // 测试胶囊 CRUD
        let capsule = TimeCapsule(
            id: "test_id",
            title: "测试胶囊",
            content: "测试内容",
            type: .text,
            sendDate: Date().addingTimeInterval(86400),
            isSent: false,
            createdAt: Date()
        )
        
        dataManager.addCapsule(capsule)
        XCTAssertEqual(dataManager.capsules.count, 1)
        
        dataManager.deleteCapsule(capsule)
        XCTAssertEqual(dataManager.capsules.count, 0)
    }
}
