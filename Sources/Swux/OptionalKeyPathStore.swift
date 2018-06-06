//
//  OptionalKeyPathStore.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-06.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

internal enum OptionalKeyPath<Root, Value> {
    case optional(WritableKeyPath<Root, Value?>)
    case compulsory(WritableKeyPath<Root, Value>)
}

public final class OptionalKeyPathStore<InputState, State> {
    internal let inputStore: AnyStore<InputState?>
    internal let keyPath: OptionalKeyPath<InputState, State>
    internal var downstream: [() -> Void] = []
    var subscribers: Atomic<[ObjectIdentifier : (State?) -> Void]> = .init([:])
    
    internal init(_ inputStore: AnyStore<InputState?>, keyPath: OptionalKeyPath<InputState, State>) {
        self.inputStore = inputStore
        self.keyPath = keyPath
        //        inputStore.appendDownstream { [weak self] in self?.notifyDownstream() }
    }
}

internal extension OptionalKeyPathStore {
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: WritableKeyPath<InputState, State?>) where InputStore.State == InputState? {
        self.init(AnyStore(inputStore), keyPath: .optional(keyPath))
    }
    
    internal convenience init<InputStore: _StoreProtocol>(_ inputStore: InputStore, keyPath: WritableKeyPath<InputState, State>) where InputStore.State == InputState? {
        self.init(AnyStore(inputStore), keyPath: .compulsory(keyPath))
    }
}

//extension OptionalKeyPathStore/*: _StoreProtocol*/ {
//    var queue: DispatchQueue { return inputStore.queue }
//
////    public var state: State? {
////        switch keyPath {
////        case .optional(let keyPath): return inputStore.state?[keyPath]
////        case .compulsory(let keyPath): return inputStore.state?[keyPath]
////        }
////    }
////
////    func perform(_ closure: (inout State) -> Void) { inputStore.perform { closure(&$0[keyPath: keyPath]) } }
//}

//public extension OptionalKeyPathStore {
//    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber, on queue: DispatchQueue? = nil, triggerNow: Bool = false) -> Subscription where Subscriber.State == State {
//        return _subscribe(on: queue, triggerNow: triggerNow) { [weak subscriber] in subscriber?.stateChanged(to: $0) }
//    }
//
//    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
//        return _subscribe(on: queue, triggerNow: triggerNow, closure)
//    }
//}
//
//public extension OptionalKeyPathStore {
//    public func dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode = .sync) where Action.State == State {
//        _dispatch(action, dispatchMode: dispatchMode)
//    }
//
//    public func dispatch(_ state: State, dispatchMode: DispatchMode = .sync) {
//        _dispatch(state, dispatchMode: dispatchMode)
//    }
//
//    public func dispatch(dispatchMode: DispatchMode = .sync, _ closure: @escaping Mutator<State>) {
//        _dispatch(dispatchMode: dispatchMode, closure)
//    }
//}
//
//public extension OptionalKeyPathStore where State: OptionalProtocol {
//    public func dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode = .sync) where Action.State == State.Wrapped {
//        _dispatch(action, dispatchMode: dispatchMode)
//    }
//
//    public func dispatch(dispatchMode: DispatchMode = .sync, _ closure: @escaping Mutator<State.Wrapped>) {
//        _dispatch(dispatchMode: dispatchMode, closure)
//    }
//}

