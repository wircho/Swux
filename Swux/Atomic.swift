//
//  Atomic.swift
//  SwuxExample
//
//  Created by Tim Vermeulen.
//  Copyright © 2018 Wircho. All rights reserved.
//
//  CREDIT: Tim Vermeulen

import Foundation

final internal class Atomic<Value> {
    private var _value: Value
    private let queue: DispatchQueue
    
    init(_ value: Value, queue: DispatchQueue = DispatchQueue(label: "\(Value.self)")) {
        self._value = value
        self.queue = queue
    }
}

extension Atomic {
    func access<T>(_ block: (inout Value) -> T) -> T {
        return queue.sync { block(&_value) }
    }
    
    var value: Value {
        return access{ $0 }
    }
}
