//
//  OptionalReadOnlyStore.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-06.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

internal enum AnyGenericStore<State> {
    case simple(AnyStore<State, State>)
    case optional(AnyOptionalStore<State>)
}

internal extension AnyGenericStore {
    internal var state: State? {
        switch self {
        case .simple(let store): return store.state
        case .optional(let store): return store.state
        }
    }
    
    internal func appendDownstream(_ closure: @escaping () -> Void) {
        switch self {
        case .simple(let store): store.appendDownstream(closure)
        case .optional(let store): store.appendDownstream(closure)
        }
    }
}

internal enum PossiblyOptionalKeyPath<Root, Value> {
    case simple(KeyPath<Root, Value>)
    case optional(KeyPath<Root, Value?>)
}

public final class OptionalReadOnlyStore<InputState, WrappedState> {
    internal let inputStore: AnyGenericStore<InputState>
    internal let keyPath: PossiblyOptionalKeyPath<InputState, WrappedState>
    internal var downstream: [() -> Void] = []
    var subscribers: Atomic<[ObjectIdentifier : (WrappedState?) -> Void]> = .init([:])
    
    internal init(_ inputStore: AnyGenericStore<InputState>, keyPath: PossiblyOptionalKeyPath<InputState, WrappedState>) {
        self.inputStore = inputStore
        self.keyPath = keyPath
        inputStore.appendDownstream { [weak self] in self?.notifyDownstream() }
    }
}

internal extension OptionalReadOnlyStore {
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: KeyPath<InputState, WrappedState>) where InputStore.State == InputState, InputStore.MutatingState == InputState {
        self.init(.simple(AnyStore(inputStore)), keyPath: .simple(keyPath))
    }
    
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: KeyPath<InputState, WrappedState>) where InputStore.State == InputState?, InputStore.MutatingState == InputState {
        self.init(.optional(.wrapped(AnyStore(inputStore))), keyPath: .simple(keyPath))
    }
    
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: KeyPath<InputState, WrappedState>) where InputStore.State == InputState?, InputStore.MutatingState == InputState? {
        self.init(.optional(.optional(AnyStore(inputStore))), keyPath: .simple(keyPath))
    }
    
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: KeyPath<InputState, WrappedState?>) where InputStore.State == InputState, InputStore.MutatingState == InputState {
        self.init(.simple(AnyStore(inputStore)), keyPath: .optional(keyPath))
    }
    
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: KeyPath<InputState, WrappedState?>) where InputStore.State == InputState?, InputStore.MutatingState == InputState {
        self.init(.optional(.wrapped(AnyStore(inputStore))), keyPath: .optional(keyPath))
    }
    
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: KeyPath<InputState, WrappedState?>) where InputStore.State == InputState?, InputStore.MutatingState == InputState? {
        self.init(.optional(.optional(AnyStore(inputStore))), keyPath: .optional(keyPath))
    }
}

extension OptionalReadOnlyStore: _ReadOnlyStoreProtocol {
    public var state: WrappedState? {
        switch keyPath {
        case .simple(let keyPath): return inputStore.state?[keyPath: keyPath]
        case .optional(let keyPath): return inputStore.state?[keyPath: keyPath]
        }
    }
}

public extension OptionalReadOnlyStore {
    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber, on queue: DispatchQueue? = nil, triggerNow: Bool = false) -> Subscription where Subscriber.State == State {
        return _subscribe(on: queue, triggerNow: triggerNow) { [weak subscriber] in subscriber?.stateChanged(to: $0) }
    }
    
    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, closure)
    }
}
