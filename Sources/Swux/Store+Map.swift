//
//  Store+Map.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-06.
//  Copyright © 2018 Wircho. All rights reserved.
//

public extension Store {
    public subscript<OutputState>(keyPath: WritableKeyPath<State, OutputState>) -> KeyPathStore<State, OutputState> {
        return .init(self, keyPath: keyPath)
    }
}

public extension KeyPathStore {
    public subscript<OutputState>(keyPath: WritableKeyPath<State, OutputState>) -> KeyPathStore<InputState, OutputState> {
        return .init(self.inputStore, keyPath: self.keyPath.appending(path: keyPath))
    }
}
