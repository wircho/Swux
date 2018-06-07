//
//  Store+Subscript.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-06.
//  Copyright © 2018 Wircho. All rights reserved.
//

public extension Store {
    public subscript<OutputState>(_ keyPath: KeyPath<State, OutputState>) -> ReadOnlyStore<State, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<OutputState>(_ keyPath: KeyPath<State, OutputState?>) -> OptionalReadOnlyStore<State, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedInputState, OutputState>(_ keyPath: KeyPath<State, OutputState>) -> OptionalReadOnlyStore<State, OutputState> where State == WrappedInputState? {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedInputState, OutputState>(_ keyPath: KeyPath<State, OutputState?>) -> OptionalReadOnlyStore<State, OutputState> where State == WrappedInputState? {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<OutputState>(_ keyPath: WritableKeyPath<State, OutputState>) -> KeyPathStore<State, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedState, OutputState>(_ keyPath: WritableKeyPath<WrappedState, OutputState>) -> WrappedKeyPathStore<WrappedState, OutputState> where State == WrappedState? {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedState, OutputState>(_ keyPath: WritableKeyPath<WrappedState, OutputState?>) -> OptionalKeyPathStore<WrappedState, OutputState> where State == WrappedState? {
        return .init(self, keyPath: keyPath)
    }
}

public extension KeyPathStore {
    public subscript<OutputState>(_ keyPath: KeyPath<State, OutputState>) -> ReadOnlyStore<State, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<OutputState>(_ keyPath: KeyPath<State, OutputState?>) -> OptionalReadOnlyStore<State, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedInputState, OutputState>(_ keyPath: KeyPath<State, OutputState>) -> OptionalReadOnlyStore<State, OutputState> where State == WrappedInputState? {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedInputState, OutputState>(_ keyPath: KeyPath<State, OutputState?>) -> OptionalReadOnlyStore<State, OutputState> where State == WrappedInputState? {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<OutputState>(_ keyPath: WritableKeyPath<State, OutputState>) -> KeyPathStore<InputState, OutputState> {
        return .init(self.inputStore, keyPath: self.keyPath.appending(path: keyPath))
    }
    
    public subscript<WrappedState, OutputState>(_ keyPath: WritableKeyPath<WrappedState, OutputState>) -> WrappedKeyPathStore<WrappedState, OutputState> where State == WrappedState? {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedState, OutputState>(_ keyPath: WritableKeyPath<WrappedState, OutputState?>) -> OptionalKeyPathStore<WrappedState, OutputState> where State == WrappedState? {
        return .init(self, keyPath: keyPath)
    }
}

public extension WrappedKeyPathStore {
    public subscript<OutputState>(_ keyPath: KeyPath<WrappedState, OutputState>) -> OptionalReadOnlyStore<WrappedState, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<OutputState>(_ keyPath: KeyPath<WrappedState, OutputState?>) -> OptionalReadOnlyStore<WrappedState, OutputState> {
        return .init(self, keyPath: keyPath)
    }

    public subscript<OutputState>(_ keyPath: WritableKeyPath<WrappedState, OutputState>) -> WrappedKeyPathStore<InputState, OutputState> {
        return .init(self.inputStore, keyPath: self.keyPath.appending(path: keyPath))
    }
    
    public subscript<OutputState>(_ keyPath: WritableKeyPath<WrappedState, OutputState?>) -> OptionalKeyPathStore<InputState, OutputState> {
        return .init(self.inputStore, keyPath: self.keyPath.appending(path: keyPath))
    }
}

public extension OptionalKeyPathStore {
    public subscript<OutputState>(_ keyPath: KeyPath<WrappedState, OutputState>) -> OptionalReadOnlyStore<WrappedState, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<OutputState>(_ keyPath: KeyPath<WrappedState, OutputState?>) -> OptionalReadOnlyStore<WrappedState, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<OutputState>(_ keyPath: WritableKeyPath<WrappedState, OutputState>) -> WrappedKeyPathStore<WrappedState, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<OutputState>(_ keyPath: WritableKeyPath<WrappedState, OutputState?>) -> OptionalKeyPathStore<WrappedState, OutputState> {
        return .init(self, keyPath: keyPath)
    }
}

