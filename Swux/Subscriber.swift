//
//  Subscriber.swift
//  SwuxExample
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//  Copyright © 2018 Wircho. All rights reserved.
//

public protocol SubscriberProtocol: AnyObject {
    associatedtype State
    func stateChanged(to newState: State)
}

internal final class AnySubscriber<State> {
    let stateChanged: ((State) -> Void)
    let compare: ((AnyObject) -> Bool)
    let released: () -> Bool
    
    init<Subscriber: SubscriberProtocol>(_ subscriber: Subscriber) where Subscriber.State == State {
        stateChanged = { [weak subscriber] in subscriber?.stateChanged(to: $0) }
        compare = { [weak subscriber] in subscriber === $0 }
        released = { [weak subscriber] in subscriber == nil }
    }
}
