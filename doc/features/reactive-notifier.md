# ReactiveNotifier<T> - Complete Reference

## Overview

`ReactiveNotifier<T>` is the foundational class in the ReactiveNotifier state management library. It provides a singleton-based state holder that follows the **"Create Once, Reuse Always"** philosophy.

### What is ReactiveNotifier?

ReactiveNotifier is a reactive state container that:

- **Creates singleton instances** - Each notifier is created once and reused throughout your app
- **Manages state reactively** - Automatically notifies listeners when state changes
- **Supports related states** - Can combine multiple states with automatic notification propagation
- **Provides lifecycle management** - Includes auto-dispose capabilities for memory efficiency
- **Extends ChangeNotifier** - Integrates seamlessly with Flutter's existing patterns

### When to Use ReactiveNotifier<T>

Use `ReactiveNotifier<T>` when you need:

- Simple state values (primitives, settings, flags, counters)
- State that doesn't require complex initialization logic
- Shared state across multiple widgets
- State that should persist throughout the app lifecycle

For more complex scenarios:
- Use `ViewModel<T>` for state requiring synchronous initialization and business logic
- Use `AsyncViewModelImpl<T>` for async operations with loading/error states

---

## Constructor

```dart
factory ReactiveNotifier<T>(
  T Function() create, {
  List<ReactiveNotifier>? related,
  Key? key,
  bool autoDispose = false,
})
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `create` | `T Function()` | Yes | - | Factory function that creates the initial state value |
| `related` | `List<ReactiveNotifier>?` | No | `null` | List of related ReactiveNotifier instances. When any related state changes, this notifier's listeners are also notified |
| `key` | `Key?` | No | `UniqueKey()` | Unique identifier for the instance. Auto-generated if not provided |
| `autoDispose` | `bool` | No | `false` | When `true`, the instance will be automatically disposed when no widgets are using it |

### Parameter Details

#### create

The `create` parameter is a factory function that returns the initial state. This function is called once when the ReactiveNotifier is first created.

```dart
// Simple value
ReactiveNotifier<int>(() => 0)

// Complex object
ReactiveNotifier<UserModel>(() => UserModel.guest())

// ViewModel instance
ReactiveNotifier<CartViewModel>(() => CartViewModel())
```

#### related

The `related` parameter establishes parent-child relationships between ReactiveNotifier instances. When a child notifier updates, the parent is automatically notified.

```dart
mixin ShopService {
  static final userState = ReactiveNotifier<UserModel>(() => UserModel.guest());
  static final cartState = ReactiveNotifier<CartModel>(() => CartModel.empty());

  // Combined state - automatically notified when userState or cartState change
  static final shopState = ReactiveNotifier<ShopModel>(
    () => ShopModel.initial(),
    related: [userState, cartState],
  );
}
```

**Important**: Related states must form a directed acyclic graph (DAG). Circular references are detected and will throw a `StateError`.

#### key

The `key` parameter provides a unique identifier for the instance. If not provided, a `UniqueKey()` is automatically generated.

```dart
// With explicit key
final counter = ReactiveNotifier<int>(
  () => 0,
  key: const ValueKey('counter'),
);

// Access by key later
final retrieved = ReactiveNotifier.getInstanceByKey<int>(const ValueKey('counter'));
```

#### autoDispose

When `autoDispose` is `true`, the ReactiveNotifier tracks widget references and automatically disposes itself after a timeout when no widgets are using it.

```dart
mixin SessionService {
  static final sessionState = ReactiveNotifier<SessionModel>(
    () => SessionModel.initial(),
    autoDispose: true, // Will auto-dispose when not in use
  );
}
```

---

## Properties

### notifier

```dart
T get notifier
```

Returns the current state value. This is the primary way to read the state.

```dart
final count = CounterService.counter.notifier; // Returns int
final user = UserService.userState.notifier;   // Returns UserModel
```

**Note**: Accessing `.notifier` outside of a builder widget will not receive updates. Always use builders for reactive UI.

### keyNotifier

```dart
final Key keyNotifier
```

Returns the unique key identifying this ReactiveNotifier instance.

```dart
final key = CounterService.counter.keyNotifier;
log('Instance key: $key');
```

### referenceCount

```dart
int get referenceCount
```

Returns the number of active widget references. Useful for debugging lifecycle management.

```dart
final refs = CounterService.counter.referenceCount;
log('Active references: $refs');
```

### isScheduledForDispose

```dart
bool get isScheduledForDispose
```

Returns `true` if the instance is scheduled for automatic disposal.

```dart
if (CounterService.counter.isScheduledForDispose) {
  log('Will be disposed soon');
}
```

### activeReferences

```dart
Set<String> get activeReferences
```

Returns a set of reference identifiers for debugging purposes.

```dart
final refs = CounterService.counter.activeReferences;
log('Active refs: $refs');
```

### hasListeners

```dart
bool get hasListeners
```

Returns `true` if any listeners are currently registered.

---

## Methods

### State Update Methods

#### updateState

```dart
void updateState(T newState)
```

Updates the state and notifies all listeners if the value has changed.

```dart
// Update primitive value
CounterService.counter.updateState(10);

// Update object (must be different reference for change detection)
final newUser = currentUser.copyWith(name: 'New Name');
UserService.userState.updateState(newUser);
```

#### updateSilently

```dart
void updateSilently(T newState)
```

Updates the state without notifying listeners. Use for background updates or batch operations.

```dart
// Update without triggering rebuilds
DataService.cache.updateSilently(newCacheData);

// Batch updates - only notify once at the end
items.forEach((item) {
  ItemService.items.updateSilently(updatedList);
});
ItemService.items.notifyListeners(); // Manual notification
```

#### transformState

```dart
void transformState(T Function(T data) transform)
```

Transforms the current state using a transformation function and notifies listeners.

```dart
// Increment counter
CounterService.counter.transformState((count) => count + 1);

// Add item to list
ItemService.items.transformState((items) => [...items, newItem]);

// Update nested property
UserService.userState.transformState((user) =>
  user.copyWith(lastLogin: DateTime.now())
);
```

#### transformStateSilently

```dart
void transformStateSilently(T Function(T data) transform)
```

Transforms the state without notifying listeners.

```dart
// Background transformation
DataService.cache.transformStateSilently((cache) =>
  cache.copyWith(lastUpdated: DateTime.now())
);
```

### Listener Methods

#### listen

```dart
T listen(void Function(T data) callback)
```

Registers a listener and returns the current value. Only one listener can be active at a time through this method.

```dart
final currentValue = CounterService.counter.listen((count) {
  print('Counter changed to: $count');
});
```

#### stopListening

```dart
void stopListening()
```

Removes the currently registered listener.

```dart
CounterService.counter.stopListening();
```

### Related State Methods

#### from<R>

```dart
R from<R>([Key? key])
```

Gets a related state by type (and optionally by key).

```dart
mixin ShopService {
  static final userState = ReactiveNotifier<UserModel>(() => UserModel.guest());
  static final cartState = ReactiveNotifier<CartModel>(() => CartModel.empty());

  static final shopState = ReactiveNotifier<ShopModel>(
    () => ShopModel.initial(),
    related: [userState, cartState],
  );

  // Access related states
  static UserModel get user => shopState.from<UserModel>();
  static CartModel get cart => shopState.from<CartModel>();
}
```

With key for multiple instances of same type:

```dart
static final shopState = ReactiveNotifier<ShopModel>(
  () => ShopModel.initial(),
  related: [primaryUser, secondaryUser], // Both are ReactiveNotifier<UserModel>
);

// Get specific instance by key
final primary = shopState.from<UserModel>(primaryUserKey);
final secondary = shopState.from<UserModel>(secondaryUserKey);
```

### Reference Management Methods

#### addReference

```dart
void addReference(String referenceId)
```

Manually adds a reference. Called automatically by builder widgets.

#### removeReference

```dart
void removeReference(String referenceId)
```

Manually removes a reference. Called automatically when builder widgets dispose.

#### enableAutoDispose

```dart
void enableAutoDispose({Duration? timeout})
```

Configures auto-dispose with an optional custom timeout.

```dart
UserService.userState.enableAutoDispose(
  timeout: Duration(minutes: 5),
);
```

### Cleanup Methods

#### cleanCurrentNotifier

```dart
bool cleanCurrentNotifier({bool forceCleanup = false})
```

Attempts to remove this instance from the global registry. Returns `true` if successful.

```dart
// Cleanup if safe (no listeners or parents)
final cleaned = UserService.userState.cleanCurrentNotifier();

// Force cleanup regardless of state
UserService.userState.cleanCurrentNotifier(forceCleanup: true);
```

#### dispose

```dart
void dispose()
```

Disposes the notifier and cleans up resources. Note: This does not remove from the global registry.

---

## Static Methods

### cleanup

```dart
static void cleanup()
```

Clears all ReactiveNotifier instances. Primarily used in testing.

```dart
setUp(() {
  ReactiveNotifier.cleanup();
});
```

### cleanupInstance

```dart
static bool cleanupInstance(Key key)
```

Removes a specific instance by key.

```dart
ReactiveNotifier.cleanupInstance(const ValueKey('counter'));
```

### cleanupByType<T>

```dart
static int cleanupByType<T>()
```

Removes all instances of a specific type. Returns the count of removed instances.

```dart
final removed = ReactiveNotifier.cleanupByType<UserModel>();
log('Removed $removed UserModel instances');
```

### reinitializeInstance<T>

```dart
static T reinitializeInstance<T>(Key key, T Function() creator)
```

Reinitializes an existing instance with fresh state. Useful after logout or state reset.

```dart
mixin UserService {
  static final userState = ReactiveNotifier<UserViewModel>(() => UserViewModel());

  static void logout() {
    ReactiveNotifier.reinitializeInstance<UserViewModel>(
      userState.keyNotifier,
      () => UserViewModel(), // Fresh ViewModel
    );
  }
}
```

### isInstanceActive<T>

```dart
static bool isInstanceActive<T>(Key key)
```

Checks if an instance exists and is not disposed.

```dart
if (ReactiveNotifier.isInstanceActive<UserViewModel>(userKey)) {
  // Safe to use
}
```

### initContext

```dart
static void initContext(BuildContext context)
```

Initializes global BuildContext for all ViewModels. Call early in your app.

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ReactiveNotifier.initContext(context);
    return MaterialApp(...);
  }
}
```

### instanceCount

```dart
static int get instanceCount
```

Returns the total number of active instances.

### instanceCountByType<S>

```dart
static int instanceCountByType<S>()
```

Returns the count of instances of a specific type.

### getInstances

```dart
static List<ReactiveNotifier> get getInstances
```

Returns all active instances. Useful for debugging.

### getInstanceByKey<T>

```dart
static ReactiveNotifier<T> getInstanceByKey<T>(Key key)
```

Retrieves an instance by its key.

---

## Usage Examples

### Basic Counter

```dart
// Define in a mixin for namespacing
mixin CounterService {
  static final counter = ReactiveNotifier<int>(() => 0);

  static void increment() {
    counter.transformState((count) => count + 1);
  }

  static void decrement() {
    counter.transformState((count) => count - 1);
  }

  static void reset() {
    counter.updateState(0);
  }
}

// Use in widget
class CounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<int>(
      notifier: CounterService.counter,
      build: (count, notifier, keep) {
        return Column(
          children: [
            Text('Count: $count'),
            keep(ElevatedButton(
              onPressed: CounterService.increment,
              child: Text('Increment'),
            )),
          ],
        );
      },
    );
  }
}
```

### User Settings with Related States

```dart
// Theme settings
mixin ThemeService {
  static final isDarkMode = ReactiveNotifier<bool>(() => false);
  static final primaryColor = ReactiveNotifier<Color>(() => Colors.blue);

  // Combined theme state
  static final theme = ReactiveNotifier<ThemeData>(
    () => ThemeData.light(),
    related: [isDarkMode, primaryColor],
  );

  static void toggleDarkMode() {
    isDarkMode.transformState((dark) => !dark);
    _updateTheme();
  }

  static void setPrimaryColor(Color color) {
    primaryColor.updateState(color);
    _updateTheme();
  }

  static void _updateTheme() {
    final dark = isDarkMode.notifier;
    final color = primaryColor.notifier;
    theme.updateState(
      dark
        ? ThemeData.dark().copyWith(primaryColor: color)
        : ThemeData.light().copyWith(primaryColor: color),
    );
  }
}
```

### ViewModel with ReactiveNotifier

```dart
// User ViewModel
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel.guest());

  @override
  void init() {
    // Initialization logic
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    final stored = await storage.getUser();
    if (stored != null) {
      updateState(stored);
    }
  }

  void updateName(String name) {
    transformState((user) => user.copyWith(name: name));
  }
}

// Service mixin
mixin UserService {
  static final userState = ReactiveNotifier<UserViewModel>(() => UserViewModel());

  // Convenience getters
  static UserModel get user => userState.notifier.data;
  static UserViewModel get viewModel => userState.notifier;
}

// Widget usage
class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveViewModelBuilder<UserViewModel, UserModel>(
      viewmodel: UserService.userState.notifier,
      build: (user, viewModel, keep) {
        return Column(
          children: [
            Text('Hello, ${user.name}'),
            keep(ElevatedButton(
              onPressed: () => viewModel.updateName('New Name'),
              child: Text('Update Name'),
            )),
          ],
        );
      },
    );
  }
}
```

### Auto-Dispose for Memory Efficiency

```dart
mixin SessionService {
  static final sessionState = ReactiveNotifier<SessionModel>(
    () => SessionModel.initial(),
    autoDispose: true,
  );

  static void configure() {
    // Set custom timeout
    sessionState.enableAutoDispose(timeout: Duration(minutes: 10));
  }

  static void debugLifecycle() {
    log('References: ${sessionState.referenceCount}');
    log('Scheduled for dispose: ${sessionState.isScheduledForDispose}');
  }
}
```

---

## Best Practices

### 1. Always Use Mixins for Organization

```dart
// GOOD: Organized in mixin
mixin UserService {
  static final userState = ReactiveNotifier<UserModel>(() => UserModel.guest());
}

// BAD: Global variable
final userState = ReactiveNotifier<UserModel>(() => UserModel.guest());
```

### 2. Access State Inside Builders

```dart
// GOOD: Reactive updates
ReactiveBuilder<UserModel>(
  notifier: UserService.userState,
  build: (user, notifier, keep) => Text(user.name),
)

// BAD: No reactive updates
Text(UserService.userState.notifier.name) // Won't update when state changes
```

### 3. Use transformState for Immutable Updates

```dart
// GOOD: Immutable transformation
UserService.userState.transformState((user) => user.copyWith(name: 'New'));

// BAD: Mutating state directly
UserService.userState.notifier.name = 'New'; // May not trigger updates
```

### 4. Use updateSilently for Batch Operations

```dart
// GOOD: Single notification for multiple updates
for (var i = 0; i < 100; i++) {
  DataService.items.updateSilently(computeNewList(i));
}
DataService.items.notifyListeners(); // One notification

// BAD: 100 notifications
for (var i = 0; i < 100; i++) {
  DataService.items.updateState(computeNewList(i)); // Notifies each time
}
```

### 5. Use keep() for Expensive Widgets

```dart
ReactiveBuilder<UserModel>(
  notifier: UserService.userState,
  build: (user, notifier, keep) {
    return Column(
      children: [
        Text(user.name), // Rebuilds when user changes
        keep(ExpensiveChart()), // Never rebuilds
        keep(StaticNavigation()), // Never rebuilds
      ],
    );
  },
)
```

---

## Common Mistakes to Avoid

### 1. Creating Instances in Widgets

```dart
// WRONG: Creates new instance every build
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counter = ReactiveNotifier<int>(() => 0); // New instance every build!
    return Text('${counter.notifier}');
  }
}

// CORRECT: Use static mixin
mixin CounterService {
  static final counter = ReactiveNotifier<int>(() => 0);
}

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<int>(
      notifier: CounterService.counter,
      build: (count, _, __) => Text('$count'),
    );
  }
}
```

### 2. Circular References in Related States

```dart
// WRONG: Circular reference - will throw error
final stateA = ReactiveNotifier<String>(() => 'A', related: [stateB]);
final stateB = ReactiveNotifier<String>(() => 'B', related: [stateA]);

// CORRECT: Directed acyclic graph
final stateA = ReactiveNotifier<String>(() => 'A');
final stateB = ReactiveNotifier<String>(() => 'B');
final combined = ReactiveNotifier<CombinedModel>(
  () => CombinedModel.initial(),
  related: [stateA, stateB], // A and B don't reference each other
);
```

### 3. Ignoring Listener Cleanup

```dart
// WRONG: Listener never removed
class BadWidget extends StatefulWidget {
  @override
  _BadWidgetState createState() => _BadWidgetState();
}

class _BadWidgetState extends State<BadWidget> {
  @override
  void initState() {
    super.initState();
    UserService.userState.listen((user) {
      // Memory leak - listener never removed
    });
  }
}

// CORRECT: Use builders which handle cleanup automatically
class GoodWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      notifier: UserService.userState,
      build: (user, _, __) => Text(user.name),
    );
  }
}
```

### 4. Using forceCleanup Unnecessarily

```dart
// WRONG: Force cleanup while widgets are still using it
void badCleanup() {
  UserService.userState.cleanCurrentNotifier(forceCleanup: true);
  // Widgets still listening will crash!
}

// CORRECT: Let auto-dispose handle cleanup or ensure no active listeners
void goodCleanup() {
  if (!UserService.userState.hasListeners) {
    UserService.userState.cleanCurrentNotifier();
  }
}
```

### 5. Not Using copyWith for Object State

```dart
// WRONG: Objects may not trigger updates properly
UserService.userState.updateState(user); // Same reference, no update

// CORRECT: Create new reference with copyWith
UserService.userState.transformState((user) =>
  user.copyWith(name: 'New Name')
);
```

---

## Related Documentation

- [Quick Start Guide](../getting-started/quick-start.md)
- [Memory Management](../guides/memory-management.md)
- [Dispose and Recreation](../guides/dispose-and-recreation.md)
- [Context Pattern](../guides/context-pattern.md)
- [Testing Guide](../testing/testing-guide.md)
