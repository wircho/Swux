//
//  AnyReadStore.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-07.
//  Copyright © 2018 Wircho. All rights reserved.
//

internal class AnyReadStore<State> {
    fileprivate let getState: () -> State
    fileprivate let getInternalState: () -> State
    internal let notifyUpstream: () -> Void
    
    internal init<S: _ReadStoreProtocol>(_ store: S) where S.State == State {
        getInternalState = { store._state }
        getState = { store.state }
        notifyUpstream = { [weak store] in store?.notifyUpstream() }
    }
}

internal extension AnyReadStore {
    var _state: State { return getInternalState() }
    var state: State { return getState() }
}
