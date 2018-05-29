# Swux - A Swiftier Redux

Swux is a simpler and Swiftier implementation of Redux inspired by [ReSwift](https://github.com/ReSwift/ReSwift).

# Table of Contents

- [Usage](#usage)
- [Best Practices](#best-practices)

# Usage

## Step 1: Define your application state

The *application state* is a structure that should uniquely define the state of your app's UI at any point in time. For example, an app that displays a single integer counter could have the following state:

```swift
struct AppState {
  var counter: Int
}
```

## Step 2: Define actions and implement their mutators

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

## Step 3: Initialize your store

The *store* is responsible for storing the application state and queuing up actions. You must initialize it with an initial state:

```swift
let store = Store(AppState(counter: 0))
```

## Step 4: Dispatch actions to the store and receive state updates

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

Unfortunately this means that at some point in your code, there are two identical instances of `State` before only one of them gets mutated. This forces the Swift compiler to create a whole other copy of `state`, which could slow down your application. One way to prevent that is to temporarily "delete" one of the copies:

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
```
