//
//  Mall.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-06-05.
//  Copyright © 2018 Wircho. All rights reserved.
//

public final class Mall<Key: Hashable, Value> {
    internal let dictionaryStore: Store<[Key: Value]>
    internal var stores: [Key: OptionalStore<Value>] = [:]
    
    public init(_ dictionaryStore: Store<[Key: Value]>) {
        self.dictionaryStore = dictionaryStore
    }
    
    public subscript(_ key: Key) -> OptionalStore<Value> {
        guard let store = stores[key] else {
            let transform: ([Key: Value]) -> Value? = { $0[key] }
            let traverse: MutatorMap<Value, [Key: Value]> = {
                mutator in
                return {
                    dictionary in
                    guard var value = dictionary[key] else { return }
                    dictionary[key] = nil
                    mutator(&value)
                    dictionary[key] = value
                }
            }
            let store = OptionalStore(
                OptionalAtomicMap<[Key: Value], Value>(dictionaryStore._state, transform: transform, traverse: traverse),
                downstream: []
            )
            stores[key] = store
            return store
        }
        return store
    }
}
