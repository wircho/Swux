//
//  Subscribable.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-06.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

public protocol SubscribableProtocol: AnyObject, ReadAtomicProtocol { }

internal protocol _SubscribableProtocol: SubscribableProtocol, _ReadAtomicProtocol {
    var subscribers: Atomic<[ObjectIdentifier: (State) -> Void]> { get set }
}

internal extension _SubscribableProtocol {
    internal func _subscribe(on queue: DispatchQueue?, triggerNow: Bool, _ closure: @escaping (State) -> Void) -> Subscription {
        let closure = wrap(on: queue, closure: closure)
        let subscription = _Subscription(subscribable: self)
        if triggerNow { closure(state) }
        subscribers.access { $0[ObjectIdentifier(subscription)] = closure }
        return subscription
    }
}

internal extension _SubscribableProtocol {
    internal func notify() {
        notify(self.state)
    }
    
    internal func notify(_ state: State) {
        for callback in self.subscribers.state.values { callback(state) }
    }
}
