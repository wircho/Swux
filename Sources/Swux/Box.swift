//
//  Box.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-01.
//  Copyright © 2018 Wircho. All rights reserved.
//

/*
 Types Item, Box, Shelf, and Clerk are experimental
 */

import Foundation

internal protocol BoxProtocol: SubscribableProtocolBase { }

public final class Box<Value>: BoxProtocol {
    public internal(set) weak var item: Item<Value>? = nil {
        didSet { oldValue?.box = nil }
    }
    internal var subscriptionValue: Value? { return item?._value.value }
    internal var subscribers: Atomic<[ObjectIdentifier: (Value?) -> Void]> = Atomic([:])
    internal weak var stamp: ClerkStamp? = nil
    
    public init() { }
}

internal extension Box {
    internal func item(_ value: Value, stamp: ClerkStamp) -> Item<Value> {
        guard self.stamp == nil || self.stamp === stamp else { fatalError("Two different clerks may not access an box at the same time.") }
        self.stamp = stamp
        let item = Item(value, box: self, sealedBox: nil)
        self.item = item
        return item
    }
}

internal extension Box {
    func itemWillDeinit(_ item: Item<Value>) {
        guard item === self.item else { return }
        notifySubscribers(nil)
    }
}

public extension Box {
    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, closure: @escaping (Value?) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, closure)
    }
}


