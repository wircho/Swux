//
//  Swux.swift
//  SwuxExample
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//  Copyright © 2018 Wircho. All rights reserved.
//

import UIKit

// Work in progress...

internal struct AppState {
    var canvasBounds: CGRect
    var ballRadius: CGFloat
    var ballCenter: CGPoint
    var ballSpeed: CGVector?
}

internal let store = Store<AppState?>(nil)
