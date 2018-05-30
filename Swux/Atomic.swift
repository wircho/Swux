//
//  Atomic.swift
//
//  Created by Tim Vermeulen.
//
//  CREDIT: Tim Vermeulen

import Foundation

final internal class Atomic<Value> {
    fileprivate var _value: Value
    fileprivate let queue: DispatchQueue
    
    init(_ value: Value, queue: DispatchQueue = DispatchQueue(label: "\(Value.self)", qos: DispatchQoS.userInteractive)) {
        self._value = value
        self.queue = queue
    }
}

extension Atomic {
    func accessAsync(_ block: @escaping (inout Value) -> Void) {
        return queue.async { block(&self._value) }
    }
    
    func access<T>(_ block: (inout Value) -> T) -> T {
        return queue.sync { block(&_value) }
    }
    
    var value: Value {
        return access{ $0 }
    }
}
