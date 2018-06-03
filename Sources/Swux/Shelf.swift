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
}

public extension Shelf {
    internal subscript(_ key: Key) -> Box<Value> {
        get {
            guard let box = dictionary[key] else {
                let box = Box<Value>()
                dictionary[key] = box
                return box
            }
            return box
        }
    }
    
    public func item(at key: Key) -> Item<Value>? {
        return dictionary[key]?.item
    }
}

public extension Shelf {
    public func subscribe(at key: Key, on queue: DispatchQueue? = nil, triggerNow: Bool = false, closure: @escaping (Value?) -> Void) -> Subscription {
        return self[key].subscribe(on: queue, triggerNow: triggerNow, closure: closure)
    }
}



