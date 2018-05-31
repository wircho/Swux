//
//  Subscriber.swift
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//  Copyright © 2018 Wircho. All rights reserved.
//

public protocol SubscriberProtocol: AnyObject {
    associatedtype State
    func stateChanged(to newState: State)
}

public protocol Disposable: AnyObject {}

internal final class SubscriberDisposable<State>: Disposable {
    weak var store: Store<State>?
    
    init(store: Store<State>) { self.store = store }
    
    deinit {
        guard let store = store else { return }
        store.subscribers.access { $0[ObjectIdentifier(self)] = nil }
    }
}
