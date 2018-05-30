//
//  SwuxModel.swift
//  SwuxExample
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//  Copyright © 2018 Wircho. All rights reserved.
//

import UIKit

// MARK: - Operators and Globals

func +(lhs: CGPoint, rhs: CGVector) -> CGPoint { return CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy) }

func -(lhs: CGPoint, rhs: CGPoint) -> CGVector { return CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y) }

func -(lhs: CGSize, rhs: CGSize) -> CGVector { return CGVector(dx: lhs.width - rhs.width, dy: lhs.height - rhs.height) }

func abs(_ vector: CGVector) -> CGFloat { return sqrt(vector.dx * vector.dx + vector.dy * vector.dy) }

private let bounceDecreaseX: CGFloat = 0.8
private let bounceDecreaseY: CGFloat = 0.7
private let otherBounceDecreaseX: CGFloat = 0.98
private let otherBounceDecreaseY: CGFloat = 0.95
private let dragDistance: CGFloat = 1
private let dragSpeed: CGFloat = 0.2
private let gravity: CGFloat = 0.1
private let minimumSpeed: CGFloat = 0.2
private let importantSizeChange: CGFloat = 0.5

// MARK: - App State

internal struct AppState {
    var canvasSize: CGSize
    var ballRadius: CGFloat
    var ballCenter: CGPoint
    var ballSpeed: CGVector?
    var onFloor: Bool
}

internal extension AppState {
    var adjustedBallCenter: CGPoint {
        var ballCenter = self.ballCenter
        guard onFloor else { return ballCenter }
        ballCenter.y = canvasSize.height - ballRadius
        return ballCenter
    }
}

// MARK: - Actions

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
            ballSpeed: nil,
            onFloor: true
        )
    }
}

internal struct Jump: WrappedStateActionProtocol {
    typealias State = AppState?
    func mutateWrapped(_ state: inout AppState) {
        guard state.ballSpeed == nil else { return }
        let r = 2 * drand48() - 1
        state.onFloor = false
        state.ballSpeed = CGVector(dx: CGFloat(r > 0 ? 8 + r * 5 : -8 + r * 5), dy: -20)
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
            ballSpeed.dx = -ballSpeed.dx * bounceDecreaseX
            ballSpeed.dy *= otherBounceDecreaseY
        }
        // Reflect top bounce
        if targetCenter.y - state.ballRadius < 0 {
            targetCenter.y = 2 * state.ballRadius - targetCenter.y
            ballSpeed.dy = -ballSpeed.dy * bounceDecreaseY
            ballSpeed.dx *= otherBounceDecreaseX
        }
        // Reflect right bounce
        if targetCenter.x + state.ballRadius > state.canvasSize.width {
            targetCenter.x = 2 * (state.canvasSize.width - state.ballRadius) - targetCenter.x
            ballSpeed.dx = -ballSpeed.dx * bounceDecreaseX
            ballSpeed.dy *= otherBounceDecreaseY
        }
        // Reflect bottom bounce
        if targetCenter.y + state.ballRadius > state.canvasSize.height {
            targetCenter.y = 2 * (state.canvasSize.height - state.ballRadius) - targetCenter.y
            ballSpeed.dy = -ballSpeed.dy * bounceDecreaseY
            ballSpeed.dx *= otherBounceDecreaseX
        }
        // Stopping if needed
        let floorDistance = abs(state.ballCenter.y + state.ballRadius - state.canvasSize.height)
        state.ballCenter = targetCenter
        state.ballSpeed = abs(ballSpeed) < minimumSpeed && floorDistance < dragDistance ? nil : ballSpeed
        // Setting onFloor
        if (!state.onFloor && floorDistance < dragDistance && abs(state.ballSpeed?.dy ?? 0) < dragSpeed) {
            state.onFloor = true
        }
    }
}

internal struct ChangeCanvasSize: WrappedStateActionProtocol {
    typealias State = AppState?
    let size: CGSize
    func mutateWrapped(_ state: inout AppState) {
        let oldSize = state.canvasSize
        state.canvasSize = size
        guard abs(size - oldSize) > importantSizeChange else { return }
        // Keep relation between leading and trailing spacing
        let left = state.ballCenter.x - state.ballRadius
        let top = state.ballCenter.y - state.ballRadius
        let right = oldSize.width - state.ballCenter.x - state.ballRadius
        let bottom = oldSize.height - state.ballCenter.y - state.ballRadius
        let newX = (state.canvasSize.width - 2 * state.ballRadius) * left / (left + right) + state.ballRadius
        let newY = (state.canvasSize.height - 2 * state.ballRadius) * top / (top + bottom) + state.ballRadius
        state.ballCenter = CGPoint(x: newX, y: newY)
    }
}

// MARK: - Store

internal let store = Store<AppState?>(nil)
