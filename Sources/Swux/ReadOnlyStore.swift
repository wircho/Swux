//
//  ReadOnlyStore.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-06.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

public final class ReadOnlyStore<InputState, State> {
    internal let inputStore: AnyStore<InputState, InputState>
    internal let keyPath: KeyPath<InputState, State>
    internal var downstream: [() -> Void] = []
    var subscribers: Atomic<[ObjectIdentifier : (State) -> Void]> = .init([:])
    
    internal init(_ inputStore: AnyStore<InputState, InputState>, keyPath: KeyPath<InputState, State>) {
        self.inputStore = inputStore
        self.keyPath = keyPath
        inputStore.appendDownstream { [weak self] in self?.notifyDownstream() }
    }
}

internal extension ReadOnlyStore {
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: KeyPath<InputState, State>) where InputStore.State == InputState, InputStore.MutatingState == InputState {
        self.init(AnyStore(inputStore), keyPath: keyPath)
    }
}

extension ReadOnlyStore: _ReadOnlyStoreProtocol {
    public var state: State { return inputStore.state[keyPath: keyPath] }
}

public extension ReadOnlyStore {
    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber, on queue: DispatchQueue? = nil, triggerNow: Bool = false) -> Subscription where Subscriber.State == State {
        return _subscribe(on: queue, triggerNow: triggerNow) { [weak subscriber] in subscriber?.stateChanged(to: $0) }
    }
    
    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, closure)
    }
}
