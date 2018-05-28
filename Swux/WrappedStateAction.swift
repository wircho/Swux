//
//  WrappedStateAction.swift
//
//  Created by Adolfo Rodriguez on 2018-05-27.
//  Copyright © 2018 Wircho. All rights reserved.
//

public protocol WrappedStateActionProtocol: ActionProtocol {
    associatedtype WrappedState where State == WrappedState?
    func mutateWrapped(_ state: inout WrappedState)
}

public extension WrappedStateActionProtocol {
    public func mutate(_ state: inout State) {
        guard var wrapped = state else { return }
        state = nil
        mutateWrapped(&wrapped)
        state = wrapped
    }
}
