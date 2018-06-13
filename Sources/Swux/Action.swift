//
//  Action.swift
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//  Copyright © 2018 Wircho. All rights reserved.
//

public protocol ActionProtocol {
    associatedtype State
    func mutate(_ state: inout State) -> Void
}

internal struct SetAction<State>: ActionProtocol {
    let value: State
    init(_ value: State) { self.value = value }
    func mutate(_ state: inout State) { state = value }
}

internal struct MutateAction<State>: ActionProtocol {
    let mutator: Mutator<State>
    init(_ mutator: @escaping Mutator<State>) { self.mutator = mutator }
    func mutate(_ state: inout State) { mutator(&state) }
}

public struct OptionalAction<Action: ActionProtocol>: ActionProtocol {
    let innerAction: Action
    public init(_ innerAction: Action) { self.innerAction = innerAction }
    public func mutate(_ state: inout Action.State?) {
        guard var unwrappedState = state else { return }
        state = nil
        innerAction.mutate(&unwrappedState)
        state = State(unwrappedState)
    }
}
