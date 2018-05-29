//
//  Store.swift
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

public final class Store<State> {
    internal var subscribers: Atomic<[ObjectIdentifier: (State) -> Void]> = Atomic([:])
    private let state: Atomic<State>
    public init(_ state: State) { self.state = Atomic(state) }
}

public extension Store {
    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber, on queue: DispatchQueue = .main) -> Disposable where Subscriber.State == State {
        let disposable = SubscriberDisposable(store: self)
        subscribers.access { [weak subscriber] in $0[ObjectIdentifier(disposable)] = { s in queue.async { subscriber?.stateChanged(to: s) } } }
        return disposable
    }
}

public extension Store {
    public func dispatch<Action: ActionProtocol>(_ action: Action) where Action.State == State {
        state.accessAsync {
            action.mutate(&$0)
            for (_, callback) in self.subscribers.value { callback($0) }
        }
    }
}
