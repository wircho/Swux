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

public protocol OptionalProtocol: ExpressibleByNilLiteral {
    associatedtype Wrapped
    func map<T>(_ transform: (Wrapped) throws -> T) rethrows -> T?
    init(_ some: Wrapped)
}
extension Optional: OptionalProtocol { }

internal struct OptionalAction<Action: ActionProtocol, State>: ActionProtocol where State: OptionalProtocol, State.Wrapped == Action.State {
    let innerAction: Action
    init(_ innerAction: Action) { self.innerAction = innerAction }
    func mutate(_ state: inout State) {
        guard var unwrappedState = state.map({ $0 }) else { return }
        state = nil
        innerAction.mutate(&unwrappedState)
        state = State(unwrappedState)
    }
}
