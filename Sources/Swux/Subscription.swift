//
//  Subscription.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-06.
//  Copyright © 2018 Wircho. All rights reserved.
//

public protocol Subscription: AnyObject {
    func trigger()
    func end()
}

internal final class _Subscription<Subscribable: _SubscribableProtocol>: Subscription {
    weak var subscribable: Subscribable?
    
    init(subscribable: Subscribable) { self.subscribable = subscribable }
    
    func end() {
        guard let subscribable = subscribable else { return }
        subscribable.subscribers.access { $0[ObjectIdentifier(self)] = nil }
    }
    
    func trigger() {
        guard let subscribable = subscribable else { return }
        subscribable.subscribers.state[ObjectIdentifier(self)]?(subscribable.state)
    }
    
    deinit {
        end()
    }
}
