//
//  ReadStore.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-06.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

public final class ReadStore<InputState, State> {
    internal let inputStore: AnyReadStore<InputState>
    internal let keyPath: KeyPath<InputState, State>
    internal let upstream: (() -> Void)?
    var actionSubscribers: Atomic<[ObjectIdentifier : (State) -> Void]> = .init([:])
    var upstreamSubscribers: Atomic<[ObjectIdentifier : (State) -> Void]> = .init([:])
    
    internal init(_ inputStore: AnyReadStore<InputState>, keyPath: KeyPath<InputState, State>) {
        self.inputStore = inputStore
        self.keyPath = keyPath
        upstream = inputStore.notifyUpstream
    }
}

internal extension ReadStore {
    internal convenience init<InputStore: _ReadStoreProtocol>(_ inputStore: InputStore, keyPath: KeyPath<InputState, State>) where InputStore.State == InputState {
        self.init(AnyReadStore(inputStore), keyPath: keyPath)
    }
}

extension ReadStore: _ReadStoreProtocol {
    public var state: State { return inputStore.state[keyPath: keyPath] }
}

public extension ReadStore {
    public func subscribe(on queue: DispatchQueue? = nil, triggerNow: Bool = false, _ closure: @escaping (State) -> Void) -> Subscription {
        return _subscribe(on: queue, triggerNow: triggerNow, subscribers: \.actionSubscribers, closure)
    }
}
