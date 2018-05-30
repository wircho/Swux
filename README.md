# Swux - A Swiftier Redux

Swux is a Swiftier implementation of Redux inspired by [ReSwift](https://github.com/ReSwift/ReSwift).

[Read the Medium post here](https://medium.com/@wircho/a-swift-ier-redux-implementation-f66741ec5e82).

# Table of Contents

- [Installation](#installation)
- [Usage](#usage)
  - [Step 1: Define your application state](#step_1)
  - [Step 2: Define actions and implement their mutators](#step_2)
  - [Step 3: Initialize your store](#step_3)
  - [Step 4: Dispatch actions to the store and receive state updates](#step_4)
- [Best Practices](#best-practices)
  - [Optional States](#optional-states)
  - [Enum States](#enum-states)
  - [Sync/Async Subscribers And Dispatch](#syncasync-subscribers-and-dispatch)

# Installation

## Cocoapods

Add this to your Podfile:

```
pod 'Swux', :git => 'https://github.com/wircho/Swux.git'
```

# Usage

<h2 id="step_1">Step 1: Define your application state</h2>

The *application state* is a structure that should uniquely define the state of your app's UI at any point in time. For example, an app that displays a single integer counter could have the following state:

```swift
struct AppState {
  var counter: Int
}
```

<h2 id="step_2">Step 2: Define actions and implement their mutators</h2>

The `AppState` above may be mutated by incrementing or decrementing the counter, for example, so we could define those actions as follows:

```swift
struct IncrementCounter: ActionProtocol {
  func mutate(_ state: inout AppState) { state.counter += 1 }
}

struct DecrementCounter: ActionProtocol {
  func mutate(_ state: inout AppState) { state.counter -= 1 }
}
```

You could also add an action that sets the counter to a specific value, for example:

```swift
struct SetCounter: ActionProtocol {
  let value: Int
  func mutate(_ state: inout AppState) { state.counter = value }
}
```

<h2 id="step_3">Step 3: Initialize your store</h2>

The *store* is responsible for storing the application state and queuing up actions. You must initialize it with an initial state:

```swift
let store = Store(AppState(counter: 0))
```

<h2 id="step_4">Step 4: Dispatch actions to the store and receive state updates</h2>

You may submit actions to the store using the `dispatch` method as follows:

```swift
store.dispatch(IncrementCounter())
```

```swift
store.dispatch(SetCounter(value: 5))
```

You can subscribe objects implementing `SubscriberProtocol` to receive state change updates from the `stateChanged(to newState: AppState)` method. Use `let disposable = store.subscribe(self)` and retain the returned `Disposable` object until you no longer need to listen to state updates. From a view controller you could do:

```swift
class ViewController: UIViewController, SubscriberProtocol {
    var disposable: Disposable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        disposable = store.subscribe(self)
    }
    
    func stateChanged(to newState: AppState) {
        /* Use newState to update the UI */
    }
}
```

# Best Practices

## Optional States

If your application state is optional, for example,

```swift
struct AppState {
  /* some properties */
}

let store = Store<AppState?>(nil)
```

then you may need to unwrap it before mutating it in an action mutator:

```swift
/* BAD WAY */
struct SomeAction: ActionProtocol {
  func mutate(_ state: inout AppState?) {
    guard var unwrappedState = state else { return }
    /* mutate unwrappedState */
    state = unwrappedState
  }
}
```

Unfortunately this means that at some point at runtime, there are two identical instances of `State` before only one of them gets mutated. This forces the Swift compiler to create a whole other copy of `state`, which could slow down your application. One way to prevent that is to temporarily "delete" one of the copies:

```swift
/* GOOD WAY (UNFORTUNATELY) */
struct SomeAction: ActionProtocol {
  func mutate(_ state: inout AppState?) {
    guard var unwrappedState = state else { return }
    state = nil
    /* mutate unwrappedState */
    state = unwrappedState
  }
}
```

To prevent you from having to do this every time, Swux provides another protocol that inherits from `ActionProtocol`:

```swift
/* BEST WAY */
struct SomeAction: WrappedStateActionProtocol {
  typealias State = AppState?
  func mutateWrapped(_ state: inout AppState) {
    /* mutate state */
  }
}
```

## Enum States

You can implement a similar solution as the one above for `enum` states, since Swift does not currently provide [in-place mutation of `enum` types](https://forums.swift.org/t/in-place-mutation-of-an-enum-associated-value/11747). You may define and extend one helper protocol for each case that has associated values. For example:

```swift
/* STATE */

enum AppState {
  case uninitialized
  case point(CGPoint)
  case segment(CGPoint, CGPoint)
}

/* HELPER PROTOCOLS */

protocol PointActionProtocol: ActionProtocol where State == AppState {
  func mutatePoint(_ point: inout CGPoint)
}

extension PointActionProtocol {
  func mutate(_ state: inout AppState) {
    switch state {
    case .point(var point):
      state = .uninitialized
      mutatePoint(point)
      state = .point(point)
    default: return
    }
  }
}

protocol SegmentActionProtocol: ActionProtocol where State == AppState {
  func mutateSegment(_ first: inout CGPoint, _ second: inout CGPoint)
}

extension SegmentActionProtocol {
  func mutate(_ state: inout AppState) {
    switch state {
    case var .segment(first, second):
      state = .uninitialized
      mutateSegment(first, second)
      state = .segment(first, second)
    default: return
    }
  }
}

/* USAGE */

struct MovePoint: PointActionProtocol {
  let by: CGVector
  func mutatePoint(_ point: inout CGPoint) {
    point.x += by.dx
    point.y += by.dy
  }
}

struct MoveSegment: SegmentActionProtocol {
  let by: CGVector
  func mutateSegment(_ first: inout CGPoint, _ second: inout CGPoint) {
    first.x += by.dx
    first.y += by.dy
    second.x += by.dx
    second.y += by.dy
  }
}
```

## Sync/Async Subscribers And Dispatch

### Async Subscribers

When you subscribe to the store's state updates, you may specify an optional `DispatchQueue` as follows:

```swift
disposable = store.subscribe(self, on: DispatchQueue.global(qos: .background))
```

This way, the `stateChanged` method is asynchronously dispatched to the specified queue. If you do not speficy a queue, the `stateChanged` method is called on the main thread.

### Async Dispatch

You may dispatch actions asynchronously (to the store's action queue) by specifying a `DispatchMode` as follows:

```swift
store.dispatch(SomeAction(), dispatchMode: .async)
```

By default all actions are performed synchronously.
