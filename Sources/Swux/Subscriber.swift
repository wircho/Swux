//
//  Subscriber.swift
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

public protocol SubscriberProtocol: AnyObject {
    associatedtype State
    func stateChanged(to newState: State)
}

internal protocol SubscribableProtocolBase: AnyObject {
    associatedtype SubscriptionValue
    var subscriptionValue: SubscriptionValue { get }
    var subscribers: Atomic<[ObjectIdentifier: (SubscriptionValue) -> Void]> { get set }
}

public protocol Subscription: AnyObject {
    func trigger()
    func end()
}

internal final class SubscriberDisposable<Subscribable: SubscribableProtocolBase>: Subscription {
    weak var subscribable: Subscribable?
    
    init(subscribable: Subscribable) { self.subscribable = subscribable }
    
    func end() {
        guard let subscribable = subscribable else { return }
        subscribable.subscribers.access { $0[ObjectIdentifier(self)] = nil }
    }
    
    func trigger() {
        guard let subscribable = subscribable else { return }
        subscribable.notifySubscribers(subscribable.subscriptionValue)
    }
    
    deinit {
        end()
    }
}

internal extension SubscribableProtocolBase {
    internal func _subscribe(_ closure: @escaping (SubscriptionValue) -> Void) -> Subscription {
        let disposable = SubscriberDisposable(subscribable: self)
        subscribers.access { $0[ObjectIdentifier(disposable)] = closure }
        return disposable
    }
}

internal extension SubscribableProtocolBase {
    internal func notifySubscribers(_ value: SubscriptionValue) {
        for callback in self.subscribers.value.values { callback(value) }
    }
}
