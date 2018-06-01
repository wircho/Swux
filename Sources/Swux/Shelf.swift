//
//  Shelf.swift
//
//  Created by Adolfo Rodriguez on 2018-05-31.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

public final class Shelver<Value>: SubscribableProtocolBase {
    internal weak var shelf: Shelf<Value>? = nil {
        didSet {
            oldValue?.shelver = nil
            changed(shelf?._value.value)
        }
    }
    internal var subscribers: Atomic<[ObjectIdentifier: (Value?) -> Void]> = Atomic([:])
    
    public init() { }
}

public extension Shelver {
    public var value: Value? { return shelf?._value.value }
}

public extension Shelver {
    public func shelf(_ value: Value) -> Shelf<Value> {
        let shelf = Shelf(value, shelver: self)
        self.shelf = shelf
        return shelf
    }
}

internal extension Shelver {
    func shelfWillDeinit(_ shelf: Shelf<Value>) {
        guard shelf === self.shelf else { return }
        changed(nil)
    }
}

internal extension Shelver {
    func changed(_ value: Value?) {
        notifySubscribers(value)
    }
}

public extension Shelver {
    public func subscribe(on queue: DispatchQueue? = nil, closure: @escaping (Value?) -> Void) -> Disposable {
        let closure = wrap(on: queue, closure: closure)
        return _subscribe(closure)
    }
}

public final class Shelf<Value> {
    internal weak var shelver: Shelver<Value>?
    internal let _value: Atomic<Value>
    
    public func access(_ closure: (inout Value) -> Void) {
        _value.access(closure)
    }
    
    internal init(_ value: Value, shelver: Shelver<Value>) {
        self._value = Atomic(value)
        self.shelver = shelver
    }
    
    deinit {
        guard let shelver = shelver else { return }
        shelver.shelfWillDeinit(self)
    }
}

public extension Shelf {
    public var value: Value { return _value.value }
}

