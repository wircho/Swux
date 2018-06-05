//
//  Item.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-03.
//  Copyright © 2018 Wircho. All rights reserved.
//

/*
 Types Item, Box, Shelf, and Clerk are experimental
 */

public final class Item<Value> {
    internal weak var box: Box<Value>?
    internal weak var sealedBox: SealedBox<Value>?
    internal let _value: Atomic<Value>
    internal weak var stamp: ClerkStamp? = nil
    
    internal init(_ value: Value, box: Box<Value>?, sealedBox: SealedBox<Value>?) {
        self._value = Atomic(value)
        self.box = box
    }
    
    deinit {
        guard let box = box else { return }
        box.itemWillDeinit(self)
    }
}

internal extension Item {
    internal func access(stamp: ClerkStamp, _ closure: (inout Value) -> Void) {
        guard self.stamp == nil || self.stamp === stamp else { fatalError("Two different clerks may not access an item at the same time.") }
        _value.access(closure)
        self.stamp = stamp
    }
}

public extension Item {
    public var value: Value { return _value.value }
}
