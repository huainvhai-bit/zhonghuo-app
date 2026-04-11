//
//  PerformanceTests.swift
//  ZhonghuoTests
//
//  性能单元测试
//

import XCTest
@testable import 终活

final class PerformanceTests: XCTestCase {
    
    func testMemoryManager() {
        let memoryManager = MemoryManager.shared
        let usage = memoryManager.getMemoryUsagePercentage()
        print("内存使用：\(usage)%")
        XCTAssertLessThan(usage, 100)
    }
    
    func testHapticFeedback() {
        let haptic = HapticFeedback.shared
        haptic.lightTap()
        haptic.mediumTap()
        haptic.heavyTap()
        // 触觉反馈无法断言，仅测试不崩溃
        XCTAssertNotNil(haptic)
    }
    
    func testPerformanceOptimizer() async {
        let optimizer = PerformanceOptimizer.shared
        
        // 测试异步加载
        let expectation = XCTestExpectation(description: "Async Load")
        optimizer.loadAsync(operation: {
            return "Test"
        }) { result in
            XCTAssertEqual(result, "Test")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testDebounce() async {
        let optimizer = PerformanceOptimizer.shared
        let expectation = XCTestExpectation(description: "Debounce")
        
        var count = 0
        let cancellable = optimizer.debounce(1, delay: 0.1) { _ in
            count += 1
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(count, 1)
    }
    
    func testBatchProcess() {
        let optimizer = PerformanceOptimizer.shared
        let items = Array(1...1000)
        var processedCount = 0
        
        optimizer.batchProcess(items: items, batchSize: 100) { batch in
            processedCount += batch.count
        }
        
        XCTAssertEqual(processedCount, 1000)
    }
}
