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
    internal var subscriptionValue: State { return _state.value }
    public init(_ state: State) {
        self._state = Atomic(state)
    }
}

public extension Store {
    public convenience init(_ closure: (Clerk) -> State) {
        var stamp: ClerkStamp? = ClerkStamp()
        let clerk = Clerk()
        clerk.stamp = stamp
        self.init(closure(clerk))
        stamp = nil
    }
}

public extension Store {
    public var state: State { return _state.value }
}

public extension Store {
    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber, on queue: DispatchQueue? = nil, triggerNow: Bool = false) -> Subscription where Subscriber.State == State {
        return _subscribe(on: queue, triggerNow: triggerNow) { [weak subscriber] in subscriber?.stateChanged(to: $0) }
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
    
    public func dispatch<Action: ClerkedActionProtocol>(_ action: Action, dispatchMode: DispatchMode = .sync) where Action.State == State {
        let closure = { (state: inout State) in
            var stamp: ClerkStamp? = ClerkStamp()
            let clerk = Clerk()
            clerk.stamp = stamp
            action.mutate(&state, clerk: clerk)
            stamp = nil
            for (_, callback) in clerk.callbacks { callback() }
            self.notifySubscribers(state)
        }
        switch dispatchMode {
        case .async: _state.accessAsync(closure)
        case .sync: _state.access(closure)
        }
    }
}
