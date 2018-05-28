//
//  Store.swift
//  SwuxExample
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

public final class Store<State> {
    internal var subscribers: Atomic<[ObjectIdentifier: (State) -> Void]> = Atomic([:])
    private var _state: Atomic<State>
    
    fileprivate var state: State {
        get { return _state.access{ $0 } }
        set {
            _state.access{ $0 = newValue }
            for (_, callback) in subscribers.value { callback(state) }
        }
    }
    
    public init(_ state: State) { _state = Atomic(state) }
}

public extension Store {
    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber) -> Disposable where Subscriber.State == State {
        let disposable = SubscriberDisposable(store: self)
        subscribers.access { [weak subscriber] in $0[ObjectIdentifier(disposable)] = { subscriber?.stateChanged(to: $0) } }
        return disposable
    }
}

public extension Store {
    public func dispatch<Action: ActionProtocol>(_ action: Action) where Action.State == State {
        action.mutate(&self.state)
    }
}
