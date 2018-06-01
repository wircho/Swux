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
    var subscribers: Atomic<[ObjectIdentifier: (SubscriptionValue) -> Void]> { get set }
}

public protocol Disposable: AnyObject {}

internal final class SubscriberDisposable<Subscribable: SubscribableProtocolBase>: Disposable {
    weak var subscribable: Subscribable?
    
    init(subscribable: Subscribable) { self.subscribable = subscribable }
    
    deinit {
        guard let subscribable = subscribable else { return }
        subscribable.subscribers.access { $0[ObjectIdentifier(self)] = nil }
    }
}

internal extension SubscribableProtocolBase {
    internal func _subscribe(_ closure: @escaping (SubscriptionValue) -> Void) -> Disposable {
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
