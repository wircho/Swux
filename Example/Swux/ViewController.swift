//
//  ViewController.swift
//  Swux
//
//  Created by wircho on 05/30/2018.
//  Copyright (c) 2018 wircho. All rights reserved.
//

import UIKit
import Swux

class ViewController: UIViewController, SubscriberProtocol {
    @IBOutlet weak var canvasView: UIView?
    @IBOutlet weak var jumpButton: UIButton?
    @IBOutlet weak var ballView: UIView?
    var timer = Timer.scheduledTimer(withTimeInterval: 1/120, repeats: true) { _ in store.dispatch(NextFrame()) }
    var disposable: Disposable?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let canvasView = canvasView, let ballView = ballView else { return }
        disposable = disposable ?? store.subscribe(self)
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
        ballView?.isHidden = newState == nil
        jumpButton?.isEnabled = newState != nil && newState?.ballSpeed == nil
        guard let state = newState else { return }
        ballView?.center = state.adjustedBallCenter
    }
}


