//
//  InputValidatorTests.swift
//  ZhonghuoTests
//
//  输入验证器单元测试
//

import XCTest
@testable import 终活

final class InputValidatorTests: XCTestCase {
    
    func testValidatePhone() {
        XCTAssertTrue(InputValidator.validatePhone("13800138000"))
        XCTAssertFalse(InputValidator.validatePhone("12345678901"))
    }
    
    func testValidatePassword() {
        XCTAssertTrue(InputValidator.validatePassword("Password123"))
        XCTAssertFalse(InputValidator.validatePassword("12345678"))
    }
    
    func testValidateEmail() {
        XCTAssertTrue(InputValidator.validateEmail("test@example.com"))
        XCTAssertFalse(InputValidator.validateEmail("invalid"))
    }
    
    func testValidateLength() {
        XCTAssertTrue(InputValidator.validateLength("Hello", min: 1, max: 10))
        XCTAssertFalse(InputValidator.validateLength("Hi", min: 5, max: 10))
    }
    
    func testValidateNotEmpty() {
        XCTAssertTrue(InputValidator.validateNotEmpty("Hello"))
        XCTAssertFalse(InputValidator.validateNotEmpty(""))
        XCTAssertFalse(InputValidator.validateNotEmpty(nil))
    }
}
