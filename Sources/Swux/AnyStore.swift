//
//  AnyStore.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-06.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

internal class AnyStore<State> {
    fileprivate let getQueue: () -> DispatchQueue
    fileprivate let getState: () -> State
    fileprivate let performMutator: (Mutator<State>) -> Void
    internal let appendDownstream: (@escaping () -> Void) -> Void
    
    internal init<S: _StoreProtocol>(_ store: S) where S.State == State {
        getQueue = { store.queue }
        getState = { store.state }
        performMutator = { store.perform($0) }
        appendDownstream = { store.downstream.append($0) }
    }
}

internal extension AnyStore {
    var queue: DispatchQueue { return getQueue() }
    var state: State { return getState() }
    func perform(_ closure: Mutator<State>) { performMutator(closure) }
}
