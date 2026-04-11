//
//  UserFriendlyErrorTests.swift
//  ZhonghuoTests
//
//  用户友好错误单元测试
//

import XCTest
@testable import 终活

final class UserFriendlyErrorTests: XCTestCase {
    
    func testNetworkError() {
        let error = UserFriendlyError.networkError(NSError(domain: "test", code: -1))
        XCTAssertEqual(error.title, "网络连接失败")
        XCTAssertFalse(error.message.isEmpty)
        XCTAssertFalse(error.suggestion.isEmpty)
    }
    
    func testAuthError() {
        let error = UserFriendlyError.authError()
        XCTAssertEqual(error.title, "登录已过期")
        XCTAssertEqual(error.errorCode, "AUTH_001")
    }
    
    func testDataError() {
        let error = UserFriendlyError.dataError("手机号")
        XCTAssertEqual(error.title, "数据格式错误")
        XCTAssertTrue(error.message.contains("手机号"))
    }
    
    func testServerError() {
        let error = UserFriendlyError.serverError()
        XCTAssertEqual(error.title, "服务器繁忙")
        XCTAssertEqual(error.errorCode, "SERVER_001")
    }
    
    func testPermissionError() {
        let error = UserFriendlyError.permissionError("相机")
        XCTAssertEqual(error.title, "需要授权")
        XCTAssertTrue(error.suggestion.contains("相机"))
    }
    
    func testStorageError() {
        let error = UserFriendlyError.storageError()
        XCTAssertEqual(error.title, "存储空间不足")
        XCTAssertFalse(error.suggestion.isEmpty)
    }
}
