//
//  DesignPatterns.swift
//  终活
//
//  常用设计模式工具类
//

import Foundation

// MARK: - 单例模式
protocol Singleton {
    static var shared: Self { get }
}

// MARK: - 工厂模式
protocol Factory {
    associatedtype Product
    func create() -> Product
}

// MARK: - 构建器模式
protocol Builder {
    associatedtype Product
    func reset()
    func build() -> Product
}

// MARK: - 原型模式
protocol Prototype: AnyObject {
    func clone() -> Self
}

// MARK: - 适配器模式
class Adapter<Target, Adaptee> {
    private let adaptee: Adaptee
    
    init(_ adaptee: Adaptee) {
        self.adaptee = adaptee
    }
    
    func adapt() -> Target {
        fatalError("子类必须实现此方法")
    }
}

// MARK: - 代理模式
protocol ProxyProtocol {
    associatedtype Subject
    func request()
}

// MARK: - 责任链模式
class Handler {
    private var next: Handler?
    
    func setNext(_ handler: Handler) -> Handler {
        self.next = handler
        return handler
    }
    
    func handle(_ request: String) -> String? {
        if let next = next {
            return next.handle(request)
        }
        return nil
    }
}

// MARK: - 命令模式
protocol Command {
    func execute()
    func undo()
}

// MARK: - 迭代器模式
protocol IteratorProtocol {
    associatedtype Element
    func next() -> Element?
    func hasNext() -> Bool
}

// MARK: - 观察者模式
protocol Observer: AnyObject {
    func update(_ subject: SubjectProtocol)
}

protocol SubjectProtocol {
    func attach(_ observer: Observer)
    func detach(_ observer: Observer)
    func notify()
}

// MARK: - 状态模式
protocol State {
    associatedtype Context
    func handle(_ context: Context)
}

// MARK: - 策略模式
protocol Strategy {
    associatedtype Context
    func execute(_ context: Context)
}

// MARK: - 模板方法模式
protocol TemplateMethod {
    func templateMethod()
    func step1()
    func step2()
    func step3()
}

extension TemplateMethod {
    func templateMethod() {
        step1()
        step2()
        step3()
    }
}

// MARK: - 访问者模式
protocol Visitor {
    func visit(_ element: ElementA)
    func visit(_ element: ElementB)
}

protocol Element {
    func accept(_ visitor: Visitor)
}

// MARK: - 享元模式
class FlyweightFactory {
    private var flyweights: [String: AnyObject] = [:]
    
    func getFlyweight(key: String) -> AnyObject {
        if let flyweight = flyweights[key] {
            return flyweight
        }
        let flyweight = NSObject()
        flyweights[key] = flyweight
        return flyweight
    }
}

// MARK: - 组合模式
protocol Composite {
    func add(_ component: Composite)
    func remove(_ component: Composite)
    func getChild(_ index: Int) -> Composite?
    func operation()
}

// MARK: - 桥接模式
protocol Implementor {
    func operationImpl()
}

class Abstraction {
    private let implementor: Implementor
    
    init(_ implementor: Implementor) {
        self.implementor = implementor
    }
    
    func operation() {
        implementor.operationImpl()
    }
}

// MARK: - 装饰器模式
class Decorator {
    private var component: Component?
    
    init(_ component: Component) {
        self.component = component
    }
    
    func operation() {
        component?.operation()
    }
}

protocol Component {
    func operation()
}

// MARK: - 外观模式
class Facade {
    private let subsystem1: Subsystem1
    private let subsystem2: Subsystem2
    
    init() {
        self.subsystem1 = Subsystem1()
        self.subsystem2 = Subsystem2()
    }
    
    func operation() {
        subsystem1.operation1()
        subsystem2.operation2()
    }
}

class Subsystem1 {
    func operation1() {
        print("Subsystem1: operation1")
    }
}

class Subsystem2 {
    func operation2() {
        print("Subsystem2: operation2")
    }
}

// MARK: - 备忘录模式
class Memento {
    private let state: String
    
    init(state: String) {
        self.state = state
    }
    
    func getState() -> String {
        return state
    }
}

class Originator {
    private var state: String = ""
    
    func setState(_ state: String) {
        self.state = state
    }
    
    func createMemento() -> Memento {
        return Memento(state: state)
    }
    
    func restore(_ memento: Memento) {
        state = memento.getState()
    }
}

// MARK: - 中介者模式
protocol Mediator {
    func notify(_ sender: AnyObject, event: String)
}

class Colleague {
    private let mediator: Mediator
    
    init(mediator: Mediator) {
        self.mediator = mediator
    }
    
    func send(event: String) {
        mediator.notify(self, event: event)
    }
}
