//
//  SealedBox.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-03.
//  Copyright © 2018 Wircho. All rights reserved.
//

/*
 Types Item, Box, Shelf, and Clerk are experimental
 */

import Foundation

public final class SealedBox<Value>: BoxProtocol {
    public internal(set) var item: Item<Value> {
        didSet {
            changed(item._value.value)
        }
    }
    internal var subscriptionValue: Value { return item._value.value }
    internal var subscribers: Atomic<[ObjectIdentifier: (Value) -> Void]> = Atomic([:])
    internal weak var stamp: ClerkStamp? = nil
    
    public init(_ value: Value) {
        item  = Item(value, box: nil, sealedBox: nil)
        item.sealedBox = self
    }
}

internal extension SealedBox {
    internal func item(_ value: Value, stamp: ClerkStamp) -> Item<Value> {
        guard self.stamp == nil else { fatalError("Clerks may not access a box's content more than once per action.") }
        self.stamp = stamp
        let item = Item(value, box: nil, sealedBox: self)
        self.item = item
        return item
    }
}

public extension SealedBox {
    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, closure: @escaping (Value) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, closure)
    }
}
