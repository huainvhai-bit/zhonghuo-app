//
//  UserTests.swift
//  ZhonghuoTests
//
//  用户模型单元测试
//

import XCTest
@testable import 终活

final class UserTests: XCTestCase {
    
    func testUserInitialization() {
        // 测试用户初始化
        let user = User(
            id: "test_id",
            name: "测试用户",
            phone: "13800138000",
            createdAt: Date(),
            emergencyContacts: [],
            checkInInterval: .oneDay,
            notificationsEnabled: true,
            cloudSyncEnabled: true
        )
        
        XCTAssertEqual(user.id, "test_id")
        XCTAssertEqual(user.name, "测试用户")
        XCTAssertEqual(user.phone, "13800138000")
    }
    
    func testUserCodable() {
        // 测试用户 Codable
        let user = User(
            id: "test_id",
            name: "测试用户",
            phone: "13800138000",
            createdAt: Date(),
            emergencyContacts: [],
            checkInInterval: .oneDay,
            notificationsEnabled: true,
            cloudSyncEnabled: true
        )
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(user)
        XCTAssertNotNil(data)
        
        let decoder = JSONDecoder()
        let decodedUser = try? decoder.decode(User.self, from: data!)
        XCTAssertNotNil(decodedUser)
    }
}
