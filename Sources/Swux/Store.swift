//
//  Store.swift
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

public enum DispatchMode {
    case sync, async
}

internal protocol OneDirectional: AnyObject {
    var downstream: [() -> Void] { get set }
    func notifyDownstream()
}

internal protocol StoreProtocol: SubscribableProtocolBase, OneDirectional {
    associatedtype GetState
    associatedtype MutateState
    var _state: AnyAtomic<GetState, MutateState> { get }
    var downstream: [() -> Void] { get }
    func notifyMutateState(_ state: MutateState)
}

internal extension StoreProtocol {
    internal func notifyDownstream() {
        notify()
        downstream.forEach { $0() }
    }
}

internal extension StoreProtocol {
    internal func _dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode) where Action.State == MutateState {
        let closure = { (state: inout MutateState) in
            action.mutate(&state)
            self.notifyMutateState(state)
            self.downstream.forEach { $0() }
        }
        switch dispatchMode {
        case .async: _state.accessAsync(closure)
        case .sync: _state.access(closure)
        }
    }
    
    internal func _dispatch(_ state: MutateState, dispatchMode: DispatchMode) {
        _dispatch(SetAction(state), dispatchMode: dispatchMode)
    }
    
    internal func _dispatch(dispatchMode: DispatchMode, _ closure: @escaping Mutator<MutateState>) {
        _dispatch(MutateAction(closure), dispatchMode: dispatchMode)
    }
}

public final class Store<State>: StoreProtocol {
    internal var subscribers: Atomic<[ObjectIdentifier: (State) -> Void]> = Atomic([:])
    internal let _state: AnyAtomic<State, State>
    internal var downstream: [() -> Void]
    internal var subscriptionValue: State { return _state._value }
    
    internal init<A: AtomicProtocol>(_ atomic: A, downstream: [() -> Void]) where A.GetValue == State, A.MutateValue == State {
        _state = AnyAtomic(atomic)
        self.downstream = downstream
    }
    
    public init(_ state: State) {
        _state = AnyAtomic(Atomic(state))
        downstream = []
    }
    
    func notifyMutateState(_ state: State) { notify(state) }
}

public extension Store {
    public var state: State { return _state.value }
}

public extension Store {
    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber, on queue: DispatchQueue? = nil, triggerNow: Bool = false) -> Subscription where Subscriber.State == State {
        return _subscribe(on: queue, triggerNow: triggerNow) { [weak subscriber] in subscriber?.stateChanged(to: $0) }
    }
    
    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, closure)
    }
}

public extension Store {
    public func dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode = .sync) where Action.State == State {
        _dispatch(action, dispatchMode: dispatchMode)
    }
    
    public func dispatch(_ state: State, dispatchMode: DispatchMode = .sync) {
        _dispatch(state, dispatchMode: dispatchMode)
    }
    
    public func dispatch(dispatchMode: DispatchMode = .sync, _ closure: @escaping Mutator<State>) {
        _dispatch(dispatchMode: dispatchMode, closure)
    }
}

public typealias UMP = UnsafeMutablePointer

public extension Store {
    public func map<OtherState>(transform: @escaping (State) -> OtherState, traverse: @escaping MutatorMap<OtherState, State>) -> Store<OtherState> {
        let store = Store<OtherState>(
            AtomicMap(_state, transform: transform, traverse: traverse),
            downstream: []
        )
        downstream.append { [weak store] in store?.notifyDownstream() }
        return store
    }
    
    public func map<OtherState>(_ keyPath: WritableKeyPath<State, OtherState>) -> Store<OtherState> {
        let transform: (State) -> OtherState = { state in return state[keyPath: keyPath] }
        let traverse: MutatorMap<OtherState, State> = { mutator in return { (state: inout State) in mutator(&state[keyPath: keyPath]) } }
        return map(transform: transform, traverse: traverse)
    }
    
    public static func merge<S0, S1, State>(_ s0: Store<S0>, _ s1: Store<S1>, transform: @escaping (S0, S1) -> State, traverse: @escaping (Mutator<State>) -> (Mutator<S0>, Mutator<S1>)) -> Store<State> {
        let store = Store<State>(
            AtomicMerge2(s0._state, s1._state, transform: transform, traverse: traverse),
            downstream: [{ [weak s0, weak s1] in ([s0, s1] as [OneDirectional?]).forEach { $0?.notifyDownstream() } }]
        )
        return store
    }
    
    public static func merge<S0, S1, S2, State>(_ s0: Store<S0>, _ s1: Store<S1>, _ s2: Store<S2>, transform: @escaping (S0, S1, S2) -> State, traverse: @escaping (Mutator<State>) -> (Mutator<S0>, Mutator<S1>, Mutator<S2>)) -> Store<State> {
        let store = Store<State>(
            AtomicMerge3(s0._state, s1._state, s2._state, transform: transform, traverse: traverse),
            downstream: [{ [weak s0, weak s1, weak s2] in ([s0, s1, s2] as [OneDirectional?]).forEach { $0?.notifyDownstream() } }]
        )
        return store
    }
    
    public static func merge<S0, S1, S2, S3, State>(_ s0: Store<S0>, _ s1: Store<S1>, _ s2: Store<S2>, _ s3: Store<S3>, transform: @escaping (S0, S1, S2, S3) -> State, traverse: @escaping (Mutator<State>) -> (Mutator<S0>, Mutator<S1>, Mutator<S2>, Mutator<S3>)) -> Store<State> {
        let store = Store<State>(
            AtomicMerge4(s0._state, s1._state, s2._state, s3._state, transform: transform, traverse: traverse),
            downstream: [{ [weak s0, weak s1, weak s2, weak s3] in ([s0, s1, s2, s3] as [OneDirectional?]).forEach { $0?.notifyDownstream() } }]
        )
        return store
    }
}

public final class OptionalStore<State>: StoreProtocol {
    internal var subscribers: Atomic<[ObjectIdentifier: (State?) -> Void]> = Atomic([:])
    internal let _state: AnyAtomic<State?, State>
    internal var downstream: [() -> Void]
    internal var subscriptionValue: State? { return _state._value }
    
    internal init<A: AtomicProtocol>(_ atomic: A, downstream: [() -> Void]) where A.GetValue == State?, A.MutateValue == State {
        _state = AnyAtomic(atomic)
        self.downstream = downstream
    }
    
    public init(_ state: State? = nil) {
        _state = AnyAtomic(OptionalAtomic(state))
        downstream = []
    }
    
    func notifyMutateState(_ state: State) { notify(state) }
}

public extension OptionalStore {
    public var state: State? { return _state.value }
}

public extension OptionalStore {
    public func subscribe<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber, on queue: DispatchQueue? = nil, triggerNow: Bool = false) -> Subscription where Subscriber.State == State? {
        return _subscribe(on: queue, triggerNow: triggerNow) { [weak subscriber] in subscriber?.stateChanged(to: $0) }
    }
    
    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State?) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, closure)
    }
}

public extension OptionalStore {
    public func dispatch<Action: ActionProtocol>(_ action: Action, dispatchMode: DispatchMode = .sync) where Action.State == State {
        _dispatch(action, dispatchMode: dispatchMode)
    }
    
    public func dispatch(_ state: State, dispatchMode: DispatchMode = .sync) {
        _dispatch(state, dispatchMode: dispatchMode)
    }
    
    public func dispatch(dispatchMode: DispatchMode = .sync, _ closure: @escaping Mutator<State>) {
        _dispatch(dispatchMode: dispatchMode, closure)
    }
}

public extension Store {
    public func optionalMap<OtherState>(transform: @escaping (State) -> OtherState?, traverse: @escaping MutatorMap<OtherState, State>) -> OptionalStore<OtherState> {
        let store = OptionalStore<OtherState>(
            OptionalAtomicMap(_state, transform: transform, traverse: traverse),
            downstream: []
        )
        downstream.append { [weak store] in store?.notifyDownstream() }
        return store
    }
    
    public func optionalMap<OtherState>(_ keyPath: WritableKeyPath<State, OtherState?>) -> OptionalStore<OtherState> {
        let transform: (State) -> OtherState? = { state in return state[keyPath: keyPath] }
        let traverse: MutatorMap<OtherState, State> = {
            mutator in
            return {
                (state: inout State) in
                guard var otherState = state[keyPath: keyPath] else { return }
                state[keyPath: keyPath] = nil
                mutator(&otherState)
                state[keyPath: keyPath] = otherState
            }
        }
        return optionalMap(transform: transform, traverse: traverse)
    }
}
