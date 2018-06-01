//
//  Shelf.swift
//
//  Created by Adolfo Rodriguez on 2018-05-31.
//  Copyright © 2018 Wircho. All rights reserved.
//

/*
 Types Item, Box, Shelf are experimental
 */

import Foundation

public final class Box<Value>: SubscribableProtocolBase {
    internal weak var item: Item<Value>? = nil {
        didSet {
            oldValue?.box = nil
            changed(item?._value.value)
        }
    }
    internal var subscribers: Atomic<[ObjectIdentifier: (Value?) -> Void]> = Atomic([:])
    
    public init() { }
}

public extension Box {
    public var value: Value? { return item?._value.value }
}

public extension Box {
    public func item(_ value: Value) -> Item<Value> {
        let item = Item(value, box: self)
        self.item = item
        return item
    }
}

internal extension Box {
    func itemWillDeinit(_ item: Item<Value>) {
        guard item === self.item else { return }
        changed(nil)
    }
}

internal extension Box {
    func changed(_ value: Value?) {
        notifySubscribers(value)
    }
}

public extension Box {
    public func subscribe(on queue: DispatchQueue? = nil, closure: @escaping (Value?) -> Void) -> Disposable {
        let closure = wrap(on: queue, closure: closure)
        return _subscribe(closure)
    }
}

public final class Item<Value> {
    internal weak var box: Box<Value>?
    internal let _value: Atomic<Value>
    
    public func access(_ closure: (inout Value) -> Void) {
        _value.access(closure)
    }
    
    internal init(_ value: Value, box: Box<Value>) {
        self._value = Atomic(value)
        self.box = box
    }
    
    deinit {
        guard let box = box else { return }
        box.itemWillDeinit(self)
    }
}

public extension Item {
    public var value: Value { return _value.value }
}

public protocol Shelved {
    associatedtype Key: Hashable
    var key: Key { get }
}

public final class Shelf<Value: Shelved> {
    fileprivate var dictionary: [Key: Box<Value>] = [:]
    public init() { }
}

public extension Shelf {
    typealias Key = Value.Key
    subscript(_ key: Key) -> Box<Value> {
        get {
            guard let box = dictionary[key] else {
                let box = Box<Value>()
                dictionary[key] = box
                return box
            }
            return box
        }
    }
    
    public func item(_ value: Value) -> Item<Value> {
        return self[value.key].item(value)
    }
}



