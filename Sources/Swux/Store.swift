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

public final class Store<State>: SubscribableProtocolBase {
    internal var subscribers: Atomic<[ObjectIdentifier: (State) -> Void]> = Atomic([:])
    fileprivate let _state: Atomic<State>
    public init(_ state: State) {
        self._state = Atomic(state)
    }
}

public extension Store {
    public var state: State { return _state.value }
}

public extension Store {
    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber, on queue: DispatchQueue? = nil) -> Disposable where Subscriber.State == State {
        let closure = wrap(on: queue) { [weak subscriber] in subscriber?.stateChanged(to: $0) }
        return _subscribe(closure)
    }
}

public extension Store {
    public func dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode = .sync) where Action.State == State {
        let closure = { (state: inout State) in
            action.mutate(&state)
            self.notifySubscribers(state)
        }
        switch dispatchMode {
        case .async: _state.accessAsync(closure)
        case .sync: _state.access(closure)
        }
    }
}
