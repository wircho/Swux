//
//  Substore.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-06.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

public final class Substore<InputState, State> {
    internal let inputStore: AnyStore<InputState, InputState>
    internal let keyPath: WritableKeyPath<InputState, State>
    internal let upstream: (() -> Void)?
    var actionSubscribers: Atomic<[ObjectIdentifier : (State) -> Void]> = .init([:])
    var upstreamSubscribers: Atomic<[ObjectIdentifier : (State) -> Void]> = .init([:])
    
    internal init(_ inputStore: AnyStore<InputState, InputState>, keyPath: WritableKeyPath<InputState, State>) {
        self.inputStore = inputStore
        self.keyPath = keyPath
        upstream = inputStore.notifyUpstream
    }
}

internal extension Substore {
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: WritableKeyPath<InputState, State>) where InputStore.State == InputState, InputStore.MutatingState == InputState {
        self.init(AnyStore(inputStore), keyPath: keyPath)
    }
}

extension Substore: _StoreProtocol, _SimpleAtomicProtocol {
    public typealias MutatingState = State
    var queue: DispatchQueue { return inputStore.queue }
    public var _state: State { return inputStore._state[keyPath: keyPath] }
    public var state: State { return inputStore.state[keyPath: keyPath] }
    func perform(_ closure: (inout State) -> Void) { inputStore.perform { closure(&$0[keyPath: keyPath]) } }
    
    public func dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode) where Action.State == State {
        _dispatch(action, dispatchMode: dispatchMode)
    }
    
    public func trigger(upstream: Bool = true) {
        _trigger(upstream: upstream)
    }
}

public extension Substore {
    public func subscribeToDownstreamStateChanges(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, subscribers: \.upstreamSubscribers, closure)
    }
    
    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, subscribers: \.actionSubscribers, closure)
    }
}
