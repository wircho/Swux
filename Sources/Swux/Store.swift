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
    var upstream: (() -> Void)? { get }
}

internal protocol _StoreProtocol: StoreProtocol, _AtomicProtocol, _ReadStoreProtocol {}

internal extension _ReadStoreProtocol {
    internal func notifyUpstream() {
        notify(subscribers: \.upstreamSubscribers)
        upstream?()
    }
}

internal extension _StoreProtocol {
    internal func _dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode) where Action.State == MutatingState {
        let notifyClosure = { (state: State) -> Void in
            self.notify(state, subscribers: \.actionSubscribers)
            self.notify(state, subscribers: \.upstreamSubscribers)
            self.upstream?()
        }
        switch dispatchMode {
        case .async:
            accessAsync(action.mutate) {
                state in
                DispatchQueue.main.async { notifyClosure(state) }
            }
        case .sync: notifyClosure(access(action.mutate))
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
    internal var actionSubscribers: Atomic<[ObjectIdentifier: (State) -> Void]> = .init([:])
    internal var upstreamSubscribers: Atomic<[ObjectIdentifier: (State) -> Void]> = .init([:])
    internal var _state: State
    internal let queue: DispatchQueue
    internal let upstream: (() -> Void)? = nil
    internal var onStateChangeSubscription: Subscription?
    
    public init(_ state: State, queue: DispatchQueue = DispatchQueue(label: "\(State.self)", qos: DispatchQoS.userInteractive), onStateChange stateChangeSubscriber: ((State) -> Void)? = nil) {
        _state = state
        self.queue = queue
        guard let stateChangeSubscriber = stateChangeSubscriber else { return }
        onStateChangeSubscription = subscribeToStateChanges(stateChangeSubscriber)
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
    public func subscribeToStateChanges<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber, on queue: DispatchQueue? = nil, triggerNow: Bool = false) -> Subscription where Subscriber.State == State {
        return _subscribe(on: queue, triggerNow: triggerNow, subscribers: \.upstreamSubscribers) { [weak subscriber] in subscriber?.stateChanged(to: $0) }
    }
    
    public func subscribeToStateChanges(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, subscribers: \.upstreamSubscribers, closure)
    }

    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, subscribers: \.actionSubscribers, closure)
    }
}
