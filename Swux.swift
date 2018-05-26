//
//  Swux.swift
//  
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//

import Foundation

// MARK: - State.swift

public protocol StateProtocol { }

// MARK: - Action.swift

public protocol ActionProtocol {
    associatedtype State: StateProtocol
    func mutate(_ state: inout State) -> Void
}

// MARK: - Atomic.swift

final internal class Atomic<Value> {
    private var _value: Value
    private let queue: DispatchQueue
    
    init(_ value: Value, queue: DispatchQueue = DispatchQueue(label: "\(Value.self)")) {
        self._value = value
        self.queue = queue
    }
}

extension Atomic {
    func access<T>(_ block: (inout Value) -> T) -> T {
        return queue.sync { block(&_value) }
    }
    var value: Value {
        return access{ $0 }
    }
}

// MARK: - Store.swift

public final class Store<State: StateProtocol> {
    internal var subscribers: Atomic<[AnySubscriber<State>]> = Atomic([])
    private var _state: Atomic<State>
    internal var state: State {
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

// MARK: - Subscriber.swift

public protocol SubscriberProtocol: AnyObject {
    associatedtype State: StateProtocol
    func stateChanged(to newState: State)
}

internal final class AnySubscriber<State: StateProtocol> {
    let stateChanged: ((State) -> Void)
    let compare: ((AnyObject) -> Bool)
    let released: () -> Bool
    
    init<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber) where Subscriber.State == State {
        stateChanged = { [weak subscriber] in subscriber?.stateChanged(to: $0) }
        compare = { [weak subscriber] in subscriber === $0 }
        released = { [weak subscriber] in subscriber == nil }
    }
}

// MARK: - Example.swift

struct AppState: StateProtocol {
    var counter: Int = 0
}

struct IncrementCounter: ActionProtocol {
    func mutate(_ state: inout AppState) { state.counter += 1 }
}
struct DecrementCounter: ActionProtocol {
    func mutate(_ state: inout AppState) { state.counter -= 1 }
}

let store = Store(AppState())
store.dispatch(IncrementCounter())
store.dispatch(DecrementCounter())

