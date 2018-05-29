//
//  Store.swift
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

public enum DispatchMode {
    case sync, async
}

public final class Store<State> {
    internal var subscribers: Atomic<[ObjectIdentifier: (State) -> Void]> = Atomic([:])
    private let state: Atomic<State>
    public init(_ state: State) {
        self.state = Atomic(state)
    }
}

public extension Store {
    private static func closure<Subscriber: SubscriberProtocol>(for subscriber: Subscriber, on queue: DispatchQueue?) -> (State) -> Void where Subscriber.State == State {
        guard let queue = queue else { return { [weak subscriber] in subscriber?.stateChanged(to: $0) } }
        return { [weak subscriber] (state: State) in queue.async { subscriber?.stateChanged(to: state) } }
    }
    
    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber, on queue: DispatchQueue? = nil) -> Disposable where Subscriber.State == State {
        let disposable = SubscriberDisposable(store: self)
        let closure = Store.closure(for: subscriber, on: queue)
        subscribers.access { $0[ObjectIdentifier(disposable)] = closure }
        return disposable
    }
}

public extension Store {
    public func dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode = .sync) where Action.State == State {
        let closure = { (state: inout State) in
            action.mutate(&state)
            for (_, callback) in self.subscribers.value { callback(state) }
        }
        switch dispatchMode {
        case .async: state.accessAsync(closure)
        case .sync: state.access(closure)
        }
    }
}
