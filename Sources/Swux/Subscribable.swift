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
    var actionSubscribers: Atomic<[ObjectIdentifier: (State) -> Void]> { get set }
    var upstreamSubscribers: Atomic<[ObjectIdentifier: (State) -> Void]> { get set }
}

internal extension _SubscribableProtocol {
    internal func _subscribe(on queue: DispatchQueue?, triggerNow: Bool, subscribers: WritableKeyPath<Self, Atomic<[ObjectIdentifier: (State) -> Void]>>, _ closure: @escaping (State) -> Void) -> Subscription {
        let closure = wrap(on: queue, closure: closure)
        let subscription = _Subscription(subscribable: self)
        if triggerNow { closure(state) }
        self[keyPath: subscribers].access { $0[ObjectIdentifier(subscription)] = closure }
        return subscription
    }
}

internal extension _SubscribableProtocol {
    internal func notify(subscribers: WritableKeyPath<Self, Atomic<[ObjectIdentifier: (State) -> Void]>>) {
        notify(_state, subscribers: subscribers)
    }
    
    internal func notify(_ state: State, subscribers: WritableKeyPath<Self, Atomic<[ObjectIdentifier: (State) -> Void]>>) {
        for callback in self[keyPath: subscribers].state.values { callback(state) }
    }
}
