//
//  Atomic.swift
//
//  Created by Tim Vermeulen.
//
//  CREDIT: Tim Vermeulen

import Foundation

public typealias Mutator<T> = (inout T) -> Void
public typealias MutatorMap<T, S> = (@escaping Mutator<T>) -> Mutator<S>

internal protocol AtomicProtocol {
    associatedtype GetValue
    associatedtype MutateValue
    var _value: GetValue { get }
    var queue: DispatchQueue { get }
    func perform(_ block: @escaping Mutator<MutateValue>)
}

internal extension AtomicProtocol {
    internal func accessAsync(_ block: @escaping Mutator<MutateValue>) {
        return queue.async { self.perform(block) }
    }
    
    internal func access(_ block: @escaping Mutator<MutateValue>) {
        return queue.sync { perform(block) }
    }
    
    internal var value: GetValue {
        return queue.sync { _value }
    }
}

final internal class AnyAtomic<GetValue, MutateValue>: AtomicProtocol {
    internal let getValue: () -> GetValue
    internal let queue: DispatchQueue
    internal let performBlock: (@escaping Mutator<MutateValue>) -> Void
    
    internal var _value: GetValue { return getValue() }
    
    internal init<A: AtomicProtocol>(_ atomic: A) where A.GetValue == GetValue, A.MutateValue == MutateValue {
        getValue = { atomic._value }
        queue = atomic.queue
        performBlock = { atomic.perform($0) }
    }
    
    func perform(_ block: @escaping Mutator<MutateValue>) { performBlock(block) }
}

final internal class Atomic<Value>: AtomicProtocol {
    internal var _value: Value
    internal let queue: DispatchQueue
    
    init(_ value: Value, queue: DispatchQueue = DispatchQueue(label: "\(Value.self)", qos: DispatchQoS.userInteractive)) {
        self._value = value
        self.queue = queue
    }
    
    func perform(_ block: @escaping Mutator<Value>) { block(&_value) }
}

final internal class OptionalAtomic<Value>: AtomicProtocol {
    internal var _value: Value?
    internal let queue: DispatchQueue
    
    init(_ value: Value?, queue: DispatchQueue = DispatchQueue(label: "\(Value.self)", qos: DispatchQoS.userInteractive)) {
        self._value = value
        self.queue = queue
    }
    
    func perform(_ block: @escaping Mutator<Value>) {
        guard var value = _value else { return }
        _value = nil
        block(&value)
        _value = value
    }
}

final internal class AtomicMap<Input, Output>: AtomicProtocol {
    internal var atomic: AnyAtomic<Input, Input>
    internal var transform: (Input) -> Output
    internal var traverse: MutatorMap<Output, Input>
    internal var _value: Output { return transform(atomic._value) }
    internal var queue: DispatchQueue { return atomic.queue }
    
    internal init(_ atomic: AnyAtomic<Input, Input>, transform: @escaping (Input) -> Output, traverse: @escaping MutatorMap<Output, Input>) {
        self.atomic = atomic
        self.transform = transform
        self.traverse = traverse
    }
    
    internal func perform(_ block: @escaping Mutator<Output>) { atomic.perform(traverse(block)) }
}

final internal class OptionalAtomicMap<Input, Output>: AtomicProtocol {
    internal var atomic: AnyAtomic<Input, Input>
    internal var transform: (Input) -> Output?
    internal var traverse: MutatorMap<Output, Input>
    internal var _value: Output? { return transform(atomic._value) }
    internal var queue: DispatchQueue { return atomic.queue }
    
    internal init(_ atomic: AnyAtomic<Input, Input>, transform: @escaping (Input) -> Output?, traverse: @escaping MutatorMap<Output, Input>) {
        self.atomic = atomic
        self.transform = transform
        self.traverse = traverse
    }
    
    internal func perform(_ block: @escaping Mutator<Output>) {
        atomic.perform(traverse(block))
    }
}

final internal class AtomicMerge2<Input0, Input1, Output>: AtomicProtocol {
    internal var atomic0: AnyAtomic<Input0, Input0>
    internal var atomic1: AnyAtomic<Input1, Input1>
    internal var transform: (Input0, Input1) -> Output
    internal var traverse: (Mutator<Output>) -> (Mutator<Input0>, Mutator<Input1>)
    internal var _value: Output { return transform(atomic0._value, atomic1._value) }
    internal var queue: DispatchQueue { return atomic0.queue }
    
    internal init(_ atomic0: AnyAtomic<Input0, Input0>, _ atomic1: AnyAtomic<Input1, Input1>, transform: @escaping (Input0, Input1) -> Output, traverse: @escaping (Mutator<Output>) -> (Mutator<Input0>, Mutator<Input1>)) {
        guard atomic0.queue == atomic1.queue else { fatalError("You may not merge atomic values with different queues") }
        self.atomic0 = atomic0
        self.atomic1 = atomic1
        self.transform = transform
        self.traverse = traverse
    }
    
    internal func perform(_ block: @escaping Mutator<Output>) {
        let (block0, block1) = traverse(block)
        atomic0.perform(block0)
        atomic1.perform(block1)
    }
}

final internal class AtomicMerge3<Input0, Input1, Input2, Output>: AtomicProtocol {
    internal var atomic0: AnyAtomic<Input0, Input0>
    internal var atomic1: AnyAtomic<Input1, Input1>
    internal var atomic2: AnyAtomic<Input2, Input2>
    internal var transform: (Input0, Input1, Input2) -> Output
    internal var traverse: (Mutator<Output>) -> (Mutator<Input0>, Mutator<Input1>, Mutator<Input2>)
    internal var _value: Output { return transform(atomic0._value, atomic1._value, atomic2._value) }
    internal var queue: DispatchQueue { return atomic0.queue }
    
    internal init(_ atomic0: AnyAtomic<Input0, Input0>, _ atomic1: AnyAtomic<Input1, Input1>, _ atomic2: AnyAtomic<Input2, Input2>, transform: @escaping (Input0, Input1, Input2) -> Output, traverse: @escaping (Mutator<Output>) -> (Mutator<Input0>, Mutator<Input1>, Mutator<Input2>)) {
        guard atomic0.queue == atomic1.queue && atomic1.queue == atomic2.queue else { fatalError("You may not merge atomic values with different queues") }
        self.atomic0 = atomic0
        self.atomic1 = atomic1
        self.atomic2 = atomic2
        self.transform = transform
        self.traverse = traverse
    }
    
    internal func perform(_ block: @escaping Mutator<Output>) {
        let (block0, block1, block2) = traverse(block)
        atomic0.perform(block0)
        atomic1.perform(block1)
        atomic2.perform(block2)
    }
}

final internal class AtomicMerge4<Input0, Input1, Input2, Input3, Output>: AtomicProtocol {
    internal var atomic0: AnyAtomic<Input0, Input0>
    internal var atomic1: AnyAtomic<Input1, Input1>
    internal var atomic2: AnyAtomic<Input2, Input2>
    internal var atomic3: AnyAtomic<Input3, Input3>
    internal var transform: (Input0, Input1, Input2, Input3) -> Output
    internal var traverse: (Mutator<Output>) -> (Mutator<Input0>, Mutator<Input1>, Mutator<Input2>, Mutator<Input3>)
    internal var _value: Output { return transform(atomic0._value, atomic1._value, atomic2._value, atomic3._value) }
    internal var queue: DispatchQueue { return atomic0.queue }
    
    internal init(_ atomic0: AnyAtomic<Input0, Input0>, _ atomic1: AnyAtomic<Input1, Input1>, _ atomic2: AnyAtomic<Input2, Input2>, _ atomic3: AnyAtomic<Input3, Input3>, transform: @escaping (Input0, Input1, Input2, Input3) -> Output, traverse: @escaping (Mutator<Output>) -> (Mutator<Input0>, Mutator<Input1>, Mutator<Input2>, Mutator<Input3>)) {
        guard atomic0.queue == atomic1.queue && atomic1.queue == atomic2.queue else { fatalError("You may not merge atomic values with different queues") }
        self.atomic0 = atomic0
        self.atomic1 = atomic1
        self.atomic2 = atomic2
        self.atomic3 = atomic3
        self.transform = transform
        self.traverse = traverse
    }
    
    internal func perform(_ block: @escaping Mutator<Output>) {
        let (block0, block1, block2, block3) = traverse(block)
        atomic0.perform(block0)
        atomic1.perform(block1)
        atomic2.perform(block2)
        atomic3.perform(block3)
    }
}
