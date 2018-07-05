//
//  WrappedSubstore.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-06.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

internal enum AnyOptionalStore<State> {
    case wrapped(AnyStore<State?, State>)
    case optional(AnyStore<State?, State?>)
}

internal extension AnyOptionalStore {
    internal func notifyUpstream() {
        switch self {
        case .wrapped(let store): store.notifyUpstream()
        case .optional(let store): store.notifyUpstream()
        }
    }
    
    internal var queue: DispatchQueue {
        switch self {
        case .wrapped(let store): return store.queue
        case .optional(let store): return store.queue
        }
    }
    
    internal var _state: State? {
        switch self {
        case .wrapped(let store): return store._state
        case .optional(let store): return store._state
        }
    }
    
    internal var state: State? {
        switch self {
        case .wrapped(let store): return store.state
        case .optional(let store): return store.state
        }
    }
}

public final class WrappedSubstore<InputState, WrappedState> {
    internal let inputStore: AnyOptionalStore<InputState>
    internal let keyPath: WritableKeyPath<InputState, WrappedState>
    internal let upstream: (() -> Void)?
    var actionSubscribers: Atomic<[ObjectIdentifier : (WrappedState?) -> Void]> = .init([:])
    var upstreamSubscribers: Atomic<[ObjectIdentifier : (WrappedState?) -> Void]> = .init([:])
    
    internal init(_ inputStore: AnyOptionalStore<InputState>, keyPath: WritableKeyPath<InputState, WrappedState>) {
        self.inputStore = inputStore
        self.keyPath = keyPath
        upstream = inputStore.notifyUpstream
    }
}

internal extension WrappedSubstore {
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: WritableKeyPath<InputState, WrappedState>) where InputStore.State == InputState?, InputStore.MutatingState == InputState {
        self.init(.wrapped(AnyStore(inputStore)), keyPath: keyPath)
    }
    
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: WritableKeyPath<InputState, WrappedState>) where InputStore.State == InputState?, InputStore.MutatingState == InputState? {
        self.init(.optional(AnyStore(inputStore)), keyPath: keyPath)
    }
}

extension WrappedSubstore: _StoreProtocol, _OptionalAtomicProtocol {
    public typealias State = WrappedState?
    public typealias MutatingState = WrappedState
    var queue: DispatchQueue { return inputStore.queue }
    internal var _state: WrappedState? { return inputStore._state?[keyPath: keyPath] }
    public var state: WrappedState? { return inputStore.state?[keyPath: keyPath] }
    
    func perform(_ closure: Mutator<WrappedState>) {
        switch inputStore {
        case .wrapped(let inputStore): inputStore.perform { closure(&$0[keyPath: keyPath]) }
        case .optional(let inputStore):
            inputStore.perform {
                inputState in
                guard var unwrappedInputState = inputState else { return }
                inputState = nil
                closure(&unwrappedInputState[keyPath: keyPath])
                inputState = unwrappedInputState
            }
        }
    }
    
    public func dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode) where Action.State == WrappedState {
        _dispatch(action, dispatchMode: dispatchMode)
    }
}

public extension WrappedSubstore {
    public func subscribeToDownstreamStateChanges(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, subscribers: \.upstreamSubscribers, closure)
    }
    
    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, subscribers: \.actionSubscribers, closure)
    }
}
