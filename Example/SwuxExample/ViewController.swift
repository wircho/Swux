//
//  ViewController.swift
//  SwuxExample
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//  Copyright © 2018 Wircho. All rights reserved.
//

import UIKit

class ViewController: UIViewController, SubscriberProtocol {
    @IBOutlet weak var canvasView: UIView?
    @IBOutlet weak var jumpButton: UIButton?
    @IBOutlet weak var ballView: UIView?
    var timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in store.dispatch(NextFrame()) }
    var disposable: Disposable?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let canvasView = canvasView, let ballView = ballView else { return }
        disposable = store.subscribe(self)
        store.dispatch(Start(canvasSize: canvasView.bounds.size, ballRadius: ballView.frame.size.width / 2))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let canvasView = canvasView else { return }
        store.dispatch(ChangeCanvasSize(size: canvasView.bounds.size))
    }
    
    @IBAction func tapJump(_ sender: UIButton) {
        store.dispatch(Jump())
    }
    
    func stateChanged(to newState: AppState?) {
        guard let state = newState else {
            jumpButton?.isEnabled = false
            ballView?.isHidden = true
            return
        }
        jumpButton?.isEnabled = state.ballSpeed == nil
        ballView?.isHidden = false
        ballView?.center = state.onFloor ? CGPoint(x: state.ballCenter.x, y: state.canvasSize.height - state.ballRadius) : state.ballCenter
    }
}
