//
//  ViewController.swift
//  SwuxExample
//
//  Created by Adolfo Rodriguez on 2018-05-26.
//  Copyright © 2018 Wircho. All rights reserved.
//

import UIKit

private let ballRadius: CGFloat = 20

class ViewController: UIViewController, SubscriberProtocol {
    @IBOutlet weak var canvasView: UIView?
    @IBOutlet weak var jumpButton: UIButton?
    weak var _ballView: UIView? = nil
    var timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in store.dispatch(NextFrame()) }
    var disposable: Disposable?
    var ballView: UIView {
        get {
            guard let _ballView = _ballView else {
                let _ballView = UIView(frame: CGRect(x: 0, y: 0, width: 2 * ballRadius, height: 2 * ballRadius))
                _ballView.backgroundColor = .red
                _ballView.layer.cornerRadius = ballRadius
                canvasView?.addSubview(_ballView)
                self._ballView = _ballView
                return _ballView
            }
            return _ballView
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let canvasView = canvasView else { return }
        disposable = store.subscribe(self)
        store.dispatch(Start(canvasSize: canvasView.bounds.size, ballRadius: ballRadius))
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
            _ballView?.removeFromSuperview()
            _ballView = nil
            jumpButton?.isEnabled = false
            return
        }
        jumpButton?.isEnabled = state.ballSpeed == nil
        ballView.center = state.onFloor ? CGPoint(x: state.ballCenter.x, y: state.canvasSize.height - state.ballRadius) : state.ballCenter
    }
}
