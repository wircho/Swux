# Swux - A Swiftier Redux

Swux is a simpler and Swiftier implementation of Redux inspired by [ReSwift](https://github.com/ReSwift/ReSwift).

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
        // Use newState to update the UI
    }
}
```
