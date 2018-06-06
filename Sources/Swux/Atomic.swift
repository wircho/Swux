//
//  Atomic.swift
//
//  Created by Tim Vermeulen.
//
//  CREDIT: Tim Vermeulen

import Foundation

public typealias Mutator<T> = (inout T) -> Void

public protocol AtomicProtocol {
    associatedtype State
    var state: State { get }
}

internal protocol _AtomicProtocol: AtomicProtocol {
    var queue: DispatchQueue { get }
    func perform(_ closure: Mutator<State>)
}

internal extension _AtomicProtocol {
    internal func accessAsync(_ closure: @escaping Mutator<State>) { return queue.async { self.perform(closure) } }
    internal func access(_ closure: @escaping Mutator<State>) { return queue.sync { self.perform(closure) } }
}

final internal class Atomic<State> {
    internal let queue: DispatchQueue
    internal var _state: State

    init(_ state: State, queue: DispatchQueue = DispatchQueue(label: "\(State.self)", qos: DispatchQoS.userInteractive)) {
        self._state = state
        self.queue = queue
    }
}

extension Atomic: _AtomicProtocol {
    func perform(_ closure: Mutator<State>) { closure(&_state) }
    var state: State { return queue.sync { _state } }
}

//
//final internal class AtomicPath<Input, Value> {
//    internal let atomic: Atomic<Input>
//    internal let keyPath: WritableKeyPath<Input, Value>
//
//    internal init(_ atomic: Atomic<Input>, keyPath: WritableKeyPath<Input, Value>) {
//        self.atomic = atomic
//        self.keyPath = keyPath
//    }
//}
//
//extension AtomicPath: _AtomicProtocol {
//    var queue: DispatchQueue { return atomic.queue }
//    var _value: Value { return atomic._value[keyPath: keyPath] }
//
//    func perform(_ closure: (inout Value) -> Void) { closure(&atomic._value[keyPath: keyPath]) }
//
//    func map<OtherValue>(_ keyPath: WritableKeyPath<Value, OtherValue>) -> AtomicPath<Input, OtherValue> {
//        return .init(atomic, keyPath: self.keyPath.appending(path: keyPath))
//    }
//}
