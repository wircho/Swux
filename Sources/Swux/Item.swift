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
        guard self.stamp == nil else { fatalError("Clerks may not access a box's content more than once per action.") }
        _value.access(closure)
        let value = self.value
        box?.changed(value)
        sealedBox?.changed(value)
    }
}

public extension Item {
    public var value: Value { return _value.value }
}
