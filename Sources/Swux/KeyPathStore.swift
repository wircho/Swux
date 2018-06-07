//
//  KeyPathStore.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-06.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

public final class KeyPathStore<InputState, State> {
    internal let inputStore: AnyStore<InputState, InputState>
    internal let keyPath: WritableKeyPath<InputState, State>
    internal var downstream: [() -> Void] = []
    var subscribers: Atomic<[ObjectIdentifier : (State) -> Void]> = .init([:])
    
    internal init(_ inputStore: AnyStore<InputState, InputState>, keyPath: WritableKeyPath<InputState, State>) {
        self.inputStore = inputStore
        self.keyPath = keyPath
        inputStore.appendDownstream { [weak self] in self?.notifyDownstream() }
    }
}

internal extension KeyPathStore {
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: WritableKeyPath<InputState, State>) where InputStore.State == InputState, InputStore.MutatingState == InputState {
        self.init(AnyStore(inputStore), keyPath: keyPath)
    }
}

extension KeyPathStore: _StoreProtocol, _SimpleAtomicProtocol {
    var queue: DispatchQueue { return inputStore.queue }
    public var state: State { return inputStore.state[keyPath: keyPath] }
    func perform(_ closure: (inout State) -> Void) { inputStore.perform { closure(&$0[keyPath: keyPath]) } }
}

public extension KeyPathStore {
    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber, on queue: DispatchQueue? = nil, triggerNow: Bool = false) -> Subscription where Subscriber.State == State {
        return _subscribe(on: queue, triggerNow: triggerNow) { [weak subscriber] in subscriber?.stateChanged(to: $0) }
    }
    
    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, closure)
    }
}

public extension KeyPathStore {
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

