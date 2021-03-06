//
//  OptionalReadStore.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-06.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

internal enum PossiblyOptionalKeyPath<Root, Value> {
    case simple(KeyPath<Root, Value>)
    case optional(KeyPath<Root, Value?>)
}

public final class OptionalReadStore<InputState, WrappedState> {
    internal let inputStore: AnyReadStore<InputState?>
    internal let keyPath: PossiblyOptionalKeyPath<InputState, WrappedState>
    internal var downstream: [() -> Void] = []
    var subscribers: Atomic<[ObjectIdentifier : (WrappedState?) -> Void]> = .init([:])
    
    internal init(_ inputStore: AnyReadStore<InputState?>, keyPath: PossiblyOptionalKeyPath<InputState, WrappedState>) {
        self.inputStore = inputStore
        self.keyPath = keyPath
        inputStore.appendDownstream { [weak self] in self?.notifyDownstream() }
    }
}

internal extension OptionalReadStore {
    internal convenience init<InputStore: _ReadStoreProtocol>(_ inputStore: InputStore, keyPath: KeyPath<InputState, WrappedState>) where InputStore.State == InputState? {
        self.init(AnyReadStore(inputStore), keyPath: .simple(keyPath))
    }
    
    internal convenience init<InputStore: _ReadStoreProtocol>(_ inputStore: InputStore, keyPath: KeyPath<InputState, WrappedState?>) where InputStore.State == InputState? {
        self.init(AnyReadStore(inputStore), keyPath: .optional(keyPath))
    }
}

extension OptionalReadStore: _ReadStoreProtocol {
    public var state: WrappedState? {
        switch keyPath {
        case .simple(let keyPath): return inputStore.state?[keyPath: keyPath]
        case .optional(let keyPath): return inputStore.state?[keyPath: keyPath]
        }
    }
}

public extension OptionalReadStore {
    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber, on queue: DispatchQueue? = nil, triggerNow: Bool = false) -> Subscription where Subscriber.State == State {
        return _subscribe(on: queue, triggerNow: triggerNow) { [weak subscriber] in subscriber?.stateChanged(to: $0) }
    }
    
    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, closure)
    }
}
