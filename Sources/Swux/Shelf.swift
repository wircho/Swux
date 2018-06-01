//
//  Shelf.swift
//
//  Created by Adolfo Rodriguez on 2018-05-31.
//  Copyright © 2018 Wircho. All rights reserved.
//

/*
 Types Item, Box, Shelf are experimental
 */

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
    public subscript(_ key: Key) -> Box<Value> {
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



