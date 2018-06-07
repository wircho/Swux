//
//  WrappedKeyPathStore.swift
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
    internal func appendDownstream(_ closure: @escaping () -> Void) {
        switch self {
        case .wrapped(let store): store.appendDownstream(closure)
        case .optional(let store): store.appendDownstream(closure)
        }
    }
    
    internal var queue: DispatchQueue {
        switch self {
        case .wrapped(let store): return store.queue
        case .optional(let store): return store.queue
        }
    }
    
    internal var state: State? {
        switch self {
        case .wrapped(let store): return store.state
        case .optional(let store): return store.state
        }
    }
}

public final class WrappedKeyPathStore<InputState, WrappedState> {
    internal let inputStore: AnyOptionalStore<InputState>
    internal let keyPath: WritableKeyPath<InputState, WrappedState>
    internal var downstream: [() -> Void] = []
    var subscribers: Atomic<[ObjectIdentifier : (WrappedState?) -> Void]> = .init([:])
    
    internal init(_ inputStore: AnyOptionalStore<InputState>, keyPath: WritableKeyPath<InputState, WrappedState>) {
        self.inputStore = inputStore
        self.keyPath = keyPath
        inputStore.appendDownstream { [weak self] in self?.notifyDownstream() }
    }
}

internal extension WrappedKeyPathStore {
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: WritableKeyPath<InputState, WrappedState>) where InputStore.State == InputState?, InputStore.MutatingState == InputState {
        self.init(.wrapped(AnyStore(inputStore)), keyPath: keyPath)
    }
    
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: WritableKeyPath<InputState, WrappedState>) where InputStore.State == InputState?, InputStore.MutatingState == InputState? {
        self.init(.optional(AnyStore(inputStore)), keyPath: keyPath)
    }
}

extension WrappedKeyPathStore: _StoreProtocol, _OptionalAtomicProtocol {
    var queue: DispatchQueue { return inputStore.queue }
    public var state: WrappedState? { return inputStore.state?[keyPath: keyPath] }
    
    func perform(_ closure: (inout WrappedState) -> Void) {
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
}

public extension WrappedKeyPathStore {
    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber, on queue: DispatchQueue? = nil, triggerNow: Bool = false) -> Subscription where Subscriber.State == State {
        return _subscribe(on: queue, triggerNow: triggerNow) { [weak subscriber] in subscriber?.stateChanged(to: $0) }
    }
    
    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, closure)
    }
}

public extension WrappedKeyPathStore {
    public func dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode = .sync) where Action.State == WrappedState {
        _dispatch(action, dispatchMode: dispatchMode)
    }
    
    public func dispatch(_ state: WrappedState, dispatchMode: DispatchMode = .sync) {
        _dispatch(state, dispatchMode: dispatchMode)
    }
    
    public func dispatch(dispatchMode: DispatchMode = .sync, _ closure: @escaping Mutator<WrappedState>) {
        _dispatch(dispatchMode: dispatchMode, closure)
    }
}

