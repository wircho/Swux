//
//  AnyStore.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-06.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

internal class AnyStore<State, MutatingState> {
    fileprivate let getQueue: () -> DispatchQueue
    fileprivate let getState: () -> State
    fileprivate let getInternalState: () -> State
    fileprivate let performMutator: (Mutator<MutatingState>) -> Void
    internal let notifyUpstream: () -> Void
    
    internal init<S: _StoreProtocol>(_ store: S) where S.State == State, S.MutatingState == MutatingState {
        getQueue = { store.queue }
        getState = { store.state }
        getInternalState = { store._state }
        performMutator = { store.perform($0) }
        notifyUpstream = { [weak store] in store?.notifyUpstream() }
    }
}

internal extension AnyStore {
    var queue: DispatchQueue { return getQueue() }
    var state: State { return getState() }
    var _state: State { return getInternalState() }
    func perform(_ closure: Mutator<MutatingState>) { performMutator(closure) }
}
