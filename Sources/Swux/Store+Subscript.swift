//
//  Store+Subscript.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-06.
//  Copyright © 2018 Wircho. All rights reserved.
//

public extension Store {
    public subscript<OutputState>(_ keyPath: KeyPath<State, OutputState>) -> ReadStore<State, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedInputState, OutputState>(_ keyPath: KeyPath<WrappedInputState, OutputState>) -> OptionalReadStore<WrappedInputState, OutputState> where State == WrappedInputState? {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedInputState, OutputState>(_ keyPath: KeyPath<WrappedInputState, OutputState?>) -> OptionalReadStore<WrappedInputState, OutputState> where State == WrappedInputState? {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<OutputState>(_ keyPath: WritableKeyPath<State, OutputState>) -> Substore<State, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedState, OutputState>(_ keyPath: WritableKeyPath<WrappedState, OutputState>) -> WrappedSubstore<WrappedState, OutputState> where State == WrappedState? {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedState, OutputState>(_ keyPath: WritableKeyPath<WrappedState, OutputState?>) -> OptionalSubstore<WrappedState, OutputState> where State == WrappedState? {
        return .init(self, keyPath: keyPath)
    }
}

public extension Substore {
    public subscript<OutputState>(_ keyPath: KeyPath<State, OutputState>) -> ReadStore<State, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedInputState, OutputState>(_ keyPath: KeyPath<WrappedInputState, OutputState>) -> OptionalReadStore<WrappedInputState, OutputState> where State == WrappedInputState? {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedInputState, OutputState>(_ keyPath: KeyPath<WrappedInputState, OutputState?>) -> OptionalReadStore<WrappedInputState, OutputState> where State == WrappedInputState? {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<OutputState>(_ keyPath: WritableKeyPath<State, OutputState>) -> Substore<State, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedState, OutputState>(_ keyPath: WritableKeyPath<WrappedState, OutputState>) -> WrappedSubstore<WrappedState, OutputState> where State == WrappedState? {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedState, OutputState>(_ keyPath: WritableKeyPath<WrappedState, OutputState?>) -> OptionalSubstore<WrappedState, OutputState> where State == WrappedState? {
        return .init(self, keyPath: keyPath)
    }
}

public extension WrappedSubstore {
    public subscript<OutputState>(_ keyPath: KeyPath<WrappedState, OutputState>) -> OptionalReadStore<WrappedState, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<OutputState>(_ keyPath: KeyPath<WrappedState, OutputState?>) -> OptionalReadStore<WrappedState, OutputState> {
        return .init(self, keyPath: keyPath)
    }

    public subscript<OutputState>(_ keyPath: WritableKeyPath<WrappedState, OutputState>) -> WrappedSubstore<WrappedState, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<OutputState>(_ keyPath: WritableKeyPath<WrappedState, OutputState?>) -> OptionalSubstore<WrappedState, OutputState> {
        return .init(self, keyPath: keyPath)
    }
}

public extension OptionalSubstore {
    public subscript<OutputState>(_ keyPath: KeyPath<WrappedState, OutputState>) -> OptionalReadStore<WrappedState, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<OutputState>(_ keyPath: KeyPath<WrappedState, OutputState?>) -> OptionalReadStore<WrappedState, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<OutputState>(_ keyPath: WritableKeyPath<WrappedState, OutputState>) -> WrappedSubstore<WrappedState, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<OutputState>(_ keyPath: WritableKeyPath<WrappedState, OutputState?>) -> OptionalSubstore<WrappedState, OutputState> {
        return .init(self, keyPath: keyPath)
    }
}

public extension ReadStore {
    public subscript<OutputState>(_ keyPath: KeyPath<State, OutputState>) -> ReadStore<State, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedInputState, OutputState>(_ keyPath: KeyPath<WrappedInputState, OutputState>) -> OptionalReadStore<WrappedInputState, OutputState> where State == WrappedInputState? {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<WrappedInputState, OutputState>(_ keyPath: KeyPath<WrappedInputState, OutputState?>) -> OptionalReadStore<WrappedInputState, OutputState> where State == WrappedInputState? {
        return .init(self, keyPath: keyPath)
    }
}

public extension OptionalReadStore {
    public subscript<OutputState>(_ keyPath: KeyPath<WrappedState, OutputState>) -> OptionalReadStore<WrappedState, OutputState> {
        return .init(self, keyPath: keyPath)
    }
    
    public subscript<OutputState>(_ keyPath: KeyPath<WrappedState, OutputState?>) -> OptionalReadStore<WrappedState, OutputState> {
        return .init(self, keyPath: keyPath)
    }
}

// TODO: Simplify all dispatch and subscribe calls into protocols
// TODO: Change to "Substore"

