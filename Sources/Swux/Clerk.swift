//
//  Clerk.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-03.
//  Copyright © 2018 Wircho. All rights reserved.
//

/*
 Types Item, Box, Shelf, and Clerk are experimental
 */

internal class ClerkStamp {
    
}

public class Clerk {
    internal weak var stamp: ClerkStamp?
    internal init() { }
}

public extension Clerk {
    public func item<T>(_ value: T, in box: Box<T>) -> Item<T> {
        guard let stamp = stamp else { fatalError("Clerk is inactive") }
        return box.item(value, stamp: stamp)
    }
    
    public func item<T>(_ value: T, in sealedBox: SealedBox<T>) -> Item<T> {
        guard let stamp = stamp else { fatalError("Clerk is inactive") }
        return sealedBox.item(value, stamp: stamp)
    }
    
    public func item<T: Shelved>(_ value: T, in shelf: Shelf<T>) -> Item<T> {
        guard let stamp = stamp else { fatalError("Clerk is inactive") }
        return shelf[value.key].item(value, stamp: stamp)
    }
    
    public func access<T>(_ item: Item<T>, closure: (inout T) -> Void) {
        guard let stamp = stamp else { fatalError("Clerk is inactive") }
        item.access(stamp: stamp, closure)
    }
}
