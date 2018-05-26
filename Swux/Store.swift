//
//  Store.swift
//  SwuxExample
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//  Copyright © 2018 Wircho. All rights reserved.
//

public final class Store<State: StateProtocol> {
    fileprivate var subscribers: Atomic<[AnySubscriber<State>]> = Atomic([])
    private var _state: Atomic<State>
    
    fileprivate var state: State {
        get { return _state.access{ $0 } }
        set {
            _state.access{ $0 = newValue }
            for subscriber in subscribers.value { subscriber.stateChanged(state) }
        }
    }
    
    public init(_ state: State) { _state = Atomic(state) }
}

public extension Store {
    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber) where Subscriber.State == State {
        let newSubscribers = subscribers.value.filter { !$0.released() } + [AnySubscriber(subscriber)]
        subscribers.access{ $0 = newSubscribers }
    }
    
    public func unsubscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber) where Subscriber.State == State {
        let newSubscribers = subscribers.value.filter { !$0.released() && $0.compare(subscriber) }
        subscribers.access{ $0 = newSubscribers }
    }
}

public extension Store {
    public func dispatch<Action: ActionProtocol>(_ action: Action) where Action.State == State {
        action.mutate(&self.state)
    }
}
