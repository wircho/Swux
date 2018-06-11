//
//  Store.swift
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

public enum DispatchMode { case sync, async }

public protocol ReadStoreProtocol: SubscribableProtocol { }

public protocol StoreProtocol: AtomicProtocol, ReadStoreProtocol {
    func dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode) where Action.State == MutatingState
}

internal protocol _ReadStoreProtocol: ReadStoreProtocol, _SubscribableProtocol {
    var downstream: [() -> Void] { get set }
}

internal protocol _StoreProtocol: StoreProtocol, _AtomicProtocol, _ReadStoreProtocol {}

internal extension _ReadStoreProtocol {
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
}

public extension StoreProtocol {
    func dispatch<Action: ActionProtocol>(_ action: Action) where Action.State == MutatingState {
        dispatch(action, dispatchMode: .sync)
    }
    
    public func dispatch(_ value: MutatingState, dispatchMode: DispatchMode = .sync) {
        dispatch(SetAction(value), dispatchMode: dispatchMode)
    }
    
    public func dispatch(dispatchMode: DispatchMode = .sync, _ closure: @escaping Mutator<MutatingState>) {
        dispatch(MutateAction(closure), dispatchMode: dispatchMode)
    }
    
    public func dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode = .sync) where MutatingState == Action.State? {
        dispatch(OptionalAction(action), dispatchMode: dispatchMode)
    }
    
    public func dispatch<WrappedState>(dispatchMode: DispatchMode = .sync, _ closure: @escaping Mutator<WrappedState>) where MutatingState == WrappedState? {
        dispatch(MutateAction(closure), dispatchMode: dispatchMode)
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
    public typealias MutatingState = State
    public var state: State { return queue.sync { _state } }
    internal func perform(_ closure: Mutator<State>) { closure(&_state) }
    
    public func dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode) where Action.State == State {
        _dispatch(action, dispatchMode: dispatchMode)
    }
}

public extension Store {
    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber, on queue: DispatchQueue? = nil, triggerNow: Bool = false) -> Subscription where Subscriber.State == State {
        return _subscribe(on: queue, triggerNow: triggerNow) { [weak subscriber] in subscriber?.stateChanged(to: $0) }
    }

    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, closure)
    }
}
