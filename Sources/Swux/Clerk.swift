//
//  Clerk.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-03.
//  Copyright © 2018 Wircho. All rights reserved.
//

public class Clerk {
    internal var active: Bool = true
    internal init() { }
}

public extension Clerk {
    public func item<T>(_ value: T, in box: Box<T>) -> Item<T> {
        guard active else {
            fatalError("Clerk is inactive")
        }
        return box.item(value)
    }
    
    public func access<T>(_ item: Item<T>, closure: (inout T) -> Void) {
        guard active else {
            fatalError("Clerk is inactive")
        }
        item._value.access(closure)
        item.box?.changed(item.value)
    }
}
