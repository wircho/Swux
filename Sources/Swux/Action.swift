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

internal struct MutateAction<State>: ActionProtocol {
    let value: State
    init(_ value: State) { self.value = value }
    func mutate(_ state: inout State) { state = value }
}
