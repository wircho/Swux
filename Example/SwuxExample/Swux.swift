//
//  Swux.swift
//  SwuxExample
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//  Copyright © 2018 Wircho. All rights reserved.
//

import UIKit

func +(lhs: CGPoint, rhs: CGVector) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
}

func abs(_ vector: CGVector) -> CGFloat {
    return sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
}

private let bounceDecrease: CGFloat = 0.8
private let dragDecrease: CGFloat = 0.95
private let dragDistance: CGFloat = 1
private let gravity: CGFloat = 0.1
private let minimumSpeed: CGFloat = 0.1

internal struct AppState {
    var canvasSize: CGSize
    var ballRadius: CGFloat
    var ballCenter: CGPoint
    var ballSpeed: CGVector?
}

internal struct Start: ActionProtocol {
    let canvasSize: CGSize
    let ballRadius: CGFloat
    func mutate(_ state: inout AppState?) {
        guard state == nil else { return }
        let ballCenter = CGPoint(x: canvasSize.width / 2, y: canvasSize.height - ballRadius)
        state = AppState(
            canvasSize: canvasSize,
            ballRadius: ballRadius,
            ballCenter: ballCenter,
            ballSpeed: nil
        )
    }
}

internal struct Jump: WrappedStateActionProtocol {
    typealias State = AppState?
    func mutateWrapped(_ state: inout AppState) {
        guard state.ballSpeed == nil else { return }
        let r = drand48()
        state.ballSpeed = CGVector(dx: CGFloat(r > 0 ? 15 + r * 10 : -15 + r * 10), dy: -20)
    }
}

internal struct NextFrame: WrappedStateActionProtocol {
    typealias State = AppState?
    func mutateWrapped(_ state: inout AppState) {
        guard var ballSpeed = state.ballSpeed else { return }
        // Apply gravity
        ballSpeed.dy += gravity
        // Apply initial movement
        var targetCenter = state.ballCenter + ballSpeed
        // Reflect left bounce
        if targetCenter.x - state.ballRadius < 0 {
            targetCenter.x = 2 * state.ballRadius - targetCenter.x
            ballSpeed.dx = -ballSpeed.dx * bounceDecrease
        }
        // Reflect top bounce
        if targetCenter.y - state.ballRadius < 0 {
            targetCenter.y = 2 * state.ballRadius - targetCenter.y
            ballSpeed.dy = -ballSpeed.dy * bounceDecrease
        }
        // Reflect right bounce
        if targetCenter.x + state.ballRadius > state.canvasSize.width {
            targetCenter.x = 2 * (state.canvasSize.width - state.ballRadius) - targetCenter.x
            ballSpeed.dx = -ballSpeed.dx * bounceDecrease
        }
        // Reflect bottom bounce
        if targetCenter.y + state.ballRadius > state.canvasSize.height {
            targetCenter.y = 2 * (state.canvasSize.height - state.ballRadius) - targetCenter.y
            ballSpeed.dy = -ballSpeed.dy * bounceDecrease
        }
        let floorDistance = abs(state.ballCenter.y + state.ballRadius - state.canvasSize.height)
        if (floorDistance < dragDistance) {
            ballSpeed.dx *= dragDecrease
        }
        state.ballCenter = targetCenter
        state.ballSpeed = abs(ballSpeed) < minimumSpeed && floorDistance < dragDistance ? nil : ballSpeed
    }
}

internal let store = Store<AppState?>(nil)
