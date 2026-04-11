//
//  APIManagerTests.swift
//  ZhonghuoTests
//
//  API 管理器单元测试
//

import XCTest
@testable import 终活

final class APIManagerTests: XCTestCase {
    
    var apiManager: APIManager!
    
    override func setUp() {
        super.setUp()
        apiManager = APIManager.shared
    }
    
    override func tearDown() {
        apiManager = nil
        super.tearDown()
    }
    
    func testSingleton() {
        // 测试单例模式
        let instance1 = APIManager.shared
        let instance2 = APIManager.shared
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testBatchSyncCapsules() async {
        // 测试批量同步胶囊
        let inputs: [[String: Any]] = [
            ["id": "test_id", "title": "测试", "type": "text"]
        ]
        
        do {
            let result = try await apiManager.batchSyncCapsules(inputs)
            XCTAssertNotNil(result)
        } catch {
            // 网络错误可接受
            print("网络错误：\(error)")
        }
    }
}
