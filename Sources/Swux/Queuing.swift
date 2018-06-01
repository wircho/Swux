//
//  Queuing.swift
//  Swux
//
//  Created by Adolfo Rodriguez on 2018-05-31.
//  Copyright © 2018 Wircho. All rights reserved.
//

import Foundation

internal func onQueue<T>(_ queue: DispatchQueue, _ closure: @escaping (T) -> Void) -> (T) -> Void  {
    return { t in queue.async { closure(t) } }
}

internal func onMain<T>(_ closure: @escaping (T) -> Void) -> (T) -> Void {
    guard Thread.current.isMainThread else { return onQueue(.main, closure) }
    return closure
}

internal func wrap<T>(on queue: DispatchQueue?, closure: @escaping (T) -> Void) -> (T) -> Void {
    guard let queue = queue else { return onMain(closure)  }
    return onQueue(queue, closure)
}
