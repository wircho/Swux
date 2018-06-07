//
//  OptionalKeyPathStore.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-06.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

public final class OptionalKeyPathStore<InputState, WrappedState> {
    internal let inputStore: AnyOptionalStore<InputState>
    internal let keyPath: WritableKeyPath<InputState, WrappedState?>
    internal var downstream: [() -> Void] = []
    var subscribers: Atomic<[ObjectIdentifier : (WrappedState?) -> Void]> = .init([:])
    
    internal init(_ inputStore: AnyOptionalStore<InputState>, keyPath: WritableKeyPath<InputState, WrappedState?>) {
        self.inputStore = inputStore
        self.keyPath = keyPath
        inputStore.appendDownstream { [weak self] in self?.notifyDownstream() }
    }
}

internal extension OptionalKeyPathStore {
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: WritableKeyPath<InputState, WrappedState?>) where InputStore.State == InputState?, InputStore.MutatingState == InputState {
        self.init(.wrapped(AnyStore(inputStore)), keyPath: keyPath)
    }
    
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: WritableKeyPath<InputState, WrappedState?>) where InputStore.State == InputState?, InputStore.MutatingState == InputState? {
        self.init(.optional(AnyStore(inputStore)), keyPath: keyPath)
    }
}

extension OptionalKeyPathStore: _StoreProtocol, _SimpleAtomicProtocol {
    var queue: DispatchQueue { return inputStore.queue }
    public var state: WrappedState? { return inputStore.state?[keyPath: keyPath] }
    
    func perform(_ closure: (inout WrappedState?) -> Void) {
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

public extension OptionalKeyPathStore {
    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber, on queue: DispatchQueue? = nil, triggerNow: Bool = false) -> Subscription where Subscriber.State == State {
        return _subscribe(on: queue, triggerNow: triggerNow) { [weak subscriber] in subscriber?.stateChanged(to: $0) }
    }
    
    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, closure)
    }
}

public extension OptionalKeyPathStore {
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

