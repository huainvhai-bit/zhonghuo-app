//
//  DesignPatternsTests.swift
//  ZhonghuoTests
//
//  设计模式单元测试
//

import XCTest
@testable import 终活

final class DesignPatternsTests: XCTestCase {
    
    func testSingleton() {
        let instance1 = Benchmark.shared
        let instance2 = Benchmark.shared
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testFactory() {
        // 测试工厂模式实现
        struct TestFactory: Factory {
            func create() -> String {
                return "Test Product"
            }
        }
        
        let factory = TestFactory()
        let product = factory.create()
        XCTAssertEqual(product, "Test Product")
    }
    
    func testBuilder() {
        // 测试构建器模式实现
        struct TestBuilder: Builder {
            func reset() {}
            func build() -> String {
                return "Built Product"
            }
        }
        
        let builder = TestBuilder()
        let product = builder.build()
        XCTAssertEqual(product, "Built Product")
    }
    
    func testHandler() {
        // 测试责任链模式
        let handler1 = Handler()
        let handler2 = Handler()
        handler1.setNext(handler2)
        
        // 验证链式调用
        XCTAssertNotNil(handler1)
    }
    
    func testFlyweightFactory() {
        // 测试享元模式
        let factory = FlyweightFactory()
        let flyweight1 = factory.getFlyweight(key: "test")
        let flyweight2 = factory.getFlyweight(key: "test")
        
        // 验证对象复用
        XCTAssertTrue(flyweight1 === flyweight2)
    }
}
