//
//  Store.swift
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

public enum DispatchMode { case sync, async }

public protocol StoreProtocol: AtomicProtocol, SubscribableProtocol {
    associatedtype State
    var state: State { get }
}

internal protocol _GenericStoreProtocol: StoreProtocol, _SubscribableProtocol {
    var downstream: [() -> Void] { get set }
}

internal protocol _ReadOnlyStoreProtocol: _GenericStoreProtocol { }

internal protocol _StoreProtocol: _GenericStoreProtocol, _AtomicProtocol { }

internal extension _GenericStoreProtocol {
    internal func notifyDownstream() {
        notify()
        downstream.forEach { $0() }
    }
}

internal extension _StoreProtocol {
    internal func _dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode) where Action.State == MutatingState {
        let closure: Mutator<MutatingState> = { mutatingState in
            action.mutate(&mutatingState)
            self.notify(Self.state(mutatingState: mutatingState))
            self.downstream.forEach { $0() }
        }
        switch dispatchMode {
        case .async: accessAsync(closure)
        case .sync: access(closure)
        }
    }

    internal func _dispatch(_ value: MutatingState, dispatchMode: DispatchMode) {
        _dispatch(SetAction(value), dispatchMode: dispatchMode)
    }

    internal func _dispatch(dispatchMode: DispatchMode, _ closure: @escaping Mutator<MutatingState>) {
        _dispatch(MutateAction(closure), dispatchMode: dispatchMode)
    }
    
    internal func _dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode) where MutatingState == Action.State? {
        _dispatch(OptionalAction(action), dispatchMode: dispatchMode)
    }
    
    internal func _dispatch<WrappedState>(dispatchMode: DispatchMode, _ closure: @escaping Mutator<WrappedState>) where MutatingState == WrappedState? {
        _dispatch(MutateAction(closure), dispatchMode: dispatchMode)
    }
}

public final class Store<State> {
    internal var subscribers: Atomic<[ObjectIdentifier: (State) -> Void]> = .init([:])
    internal var _state: State
    internal let queue: DispatchQueue
    internal var downstream: [() -> Void] = []

    public init(_ state: State, queue: DispatchQueue = DispatchQueue(label: "\(State.self)", qos: DispatchQoS.userInteractive)) {
        _state = state
        self.queue = queue
    }
}

extension Store: _StoreProtocol, _SimpleAtomicProtocol {
    public var state: State { return queue.sync { _state } }
    func perform(_ closure: Mutator<State>) { closure(&_state) }
}

public extension Store {
    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber, on queue: DispatchQueue? = nil, triggerNow: Bool = false) -> Subscription where Subscriber.State == State {
        return _subscribe(on: queue, triggerNow: triggerNow) { [weak subscriber] in subscriber?.stateChanged(to: $0) }
    }

    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, closure)
    }
}

public extension Store {
    public func dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode = .sync) where Action.State == State {
        _dispatch(action, dispatchMode: dispatchMode)
    }

    public func dispatch(_ state: State, dispatchMode: DispatchMode = .sync) {
        _dispatch(state, dispatchMode: dispatchMode)
    }

    public func dispatch(dispatchMode: DispatchMode = .sync, _ closure: @escaping Mutator<State>) {
        _dispatch(dispatchMode: dispatchMode, closure)
    }
    
    public func dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode = .sync) where State == Action.State? {
        _dispatch(action, dispatchMode: dispatchMode)
    }

    public func dispatch<WrappedState>(dispatchMode: DispatchMode = .sync, _ closure: @escaping Mutator<WrappedState>) where State == WrappedState? {
        _dispatch(dispatchMode: dispatchMode, closure)
    }
}
