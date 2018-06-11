//
//  AnyReadStore.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-07.
//  Copyright © 2018 Wircho. All rights reserved.
//

internal class AnyReadStore<State> {
    fileprivate let getState: () -> State
    internal let appendDownstream: (@escaping () -> Void) -> Void
    
    internal init<S: _ReadStoreProtocol>(_ store: S) where S.State == State {
        getState = { store.state }
        appendDownstream = { store.downstream.append($0) }
    }
}

internal extension AnyReadStore {
    var state: State { return getState() }
}
