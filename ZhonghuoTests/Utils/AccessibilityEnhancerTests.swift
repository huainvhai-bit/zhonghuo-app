//
//  AccessibilityEnhancerTests.swift
//  ZhonghuoTests
//
//  无障碍功能单元测试
//

import XCTest
@testable import 终活

final class AccessibilityEnhancerTests: XCTestCase {
    
    func testAccessibilityEnhancer() {
        let enhancer = AccessibilityEnhancer.shared
        XCTAssertNotNil(enhancer)
    }
    
    func testVoiceOverStatus() {
        let enhancer = AccessibilityEnhancer.shared
        let isRunning = enhancer.isVoiceOverEnabled
        XCTAssertFalse(isRunning) // 测试环境应为 false
    }
    
    func testReduceMotionStatus() {
        let enhancer = AccessibilityEnhancer.shared
        let isEnabled = enhancer.isReduceMotionEnabled
        XCTAssertFalse(isEnabled) // 测试环境应为 false
    }
    
    func testAccessibilityMode() {
        let enhancer = AccessibilityEnhancer.shared
        let isMode = enhancer.isAccessibilityMode
        XCTAssertFalse(isMode) // 测试环境应为 false
    }
    
    func testDynamicFontSize() {
        let enhancer = AccessibilityEnhancer.shared
        let size = enhancer.getDynamicFontSize(for: .body)
        XCTAssertGreaterThan(size, 0)
    }
}
