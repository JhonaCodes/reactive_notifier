# ReactiveNotifier Architecture Overview

## Table of Contents

1. [Core Philosophy](#1-core-philosophy)
2. [Architecture Diagrams](#2-architecture-diagrams)
3. [Component Layers](#3-component-layers)
4. [Instance Management](#4-instance-management)
5. [Notification System](#5-notification-system)
6. [Memory Model](#6-memory-model)
7. [Context Injection](#7-context-injection)
8. [Communication Patterns](#8-communication-patterns)
9. [Design Decisions](#9-design-decisions)
10. [Data Flow Diagram](#10-data-flow-diagram)

---

> **Important Note on ViewModel Usage**
>
> This document shows simplified patterns using `ReactiveNotifier<ViewModel>` in diagrams for clarity.
> For ViewModels, the **recommended pattern** is to use `ReactiveNotifierViewModel<VM, T>`:
>
> ```dart
> // Recommended pattern for ViewModels
> mixin UserService {
>   static final ReactiveNotifierViewModel<UserViewModel, UserModel> userState =
>     ReactiveNotifierViewModel<UserViewModel, UserModel>(() => UserViewModel());
> }
>
> // For simple state (int, String, bool, etc.)
> mixin CounterService {
>   static final ReactiveNotifier<int> count = ReactiveNotifier<int>(() => 0);
> }
> ```
>
> `ReactiveNotifierViewModel` provides convenient `.notifier` and `.state` accessors.
> See [ViewModel documentation](../features/viewmodel.md) for detailed examples.

---

## 1. Core Philosophy

### "Create Once, Reuse Always"

ReactiveNotifier is built on a fundamental principle that distinguishes it from other state management solutions: **singleton instances with deterministic lifecycle management**. This philosophy stems from a critical observation about Flutter state management patterns and their real-world implications.

#### The Problem with Instance-Per-Build Patterns

Traditional state management approaches like Provider and Riverpod create new instances in the widget tree, leading to:

- **Memory overhead**: Multiple instances of the same state scattered across the widget tree
- **Synchronization complexity**: Keeping multiple instances in sync requires additional logic
- **Lifecycle ambiguity**: State lifecycle is tied to widget lifecycle, causing unexpected disposal
- **Dependency injection overhead**: Complex dependency resolution mechanisms needed

#### The Singleton Solution

ReactiveNotifier embraces a singleton pattern where:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SINGLETON REGISTRY                               │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Key: UserViewModel_key  -->  ReactiveNotifier<UserVM>      │   │
│  │  Key: CartViewModel_key  -->  ReactiveNotifier<CartVM>      │   │
│  │  Key: SettingsState_key  -->  ReactiveNotifier<Settings>    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  GUARANTEES:                                                        │
│  - One instance per key                                            │
│  - Deterministic access                                            │
│  - Explicit lifecycle control                                      │
│  - No widget tree dependency for existence                         │
└─────────────────────────────────────────────────────────────────────┘
```

#### Comparison with Other State Management

| Aspect | ReactiveNotifier | Riverpod | Provider | BLoC |
|--------|-----------------|----------|----------|------|
| Instance Lifecycle | Singleton (app-scoped) | Scoped to ProviderScope | Scoped to widget tree | Manual/scoped |
| State Access | Direct via mixin | Via ref.read/watch | Via context.read/watch | Via BlocProvider |
| Dependency Resolution | Explicit service references | Auto-resolved by type | InheritedWidget lookup | Manual injection |
| Memory Control | Reference counting + autoDispose | Auto-dispose by default | Manual disposal | Manual disposal |
| Communication | listenVM + explicit references | Provider dependencies | Change notifiers | Streams/Cubits |

#### Why Singleton Pattern for State Management?

1. **Predictability**: State exists independently of UI, making behavior predictable
2. **Performance**: No repeated instance creation, no garbage collection overhead
3. **Simplicity**: Direct access without context traversal or dependency injection
4. **Testability**: Easy to mock and reset via `ReactiveNotifier.cleanup()`
5. **Android Inspiration**: Follows Android's ViewModel architecture where ViewModels survive configuration changes

---

## 2. Architecture Diagrams

### High-Level System Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           APPLICATION                                     │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                        UI LAYER                                     │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐ │  │
│  │  │ ReactiveBuilder │  │ ReactiveVM      │  │ ReactiveAsyncBuilder│ │  │
│  │  │ <T>             │  │ Builder<VM,T>   │  │ <VM,T>              │ │  │
│  │  └────────┬────────┘  └────────┬────────┘  └──────────┬──────────┘ │  │
│  │           │                    │                      │            │  │
│  └───────────┼────────────────────┼──────────────────────┼────────────┘  │
│              │                    │                      │               │
│              │    Subscribes to   │     Subscribes to    │               │
│              │   (addListener)    │    (addListener)     │               │
│              ▼                    ▼                      ▼               │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                     VIEWMODEL LAYER                                 │  │
│  │  ┌──────────────────────────────────────────────────────────────┐  │  │
│  │  │              ChangeNotifier (Flutter Foundation)              │  │  │
│  │  │  ┌─────────────────────┐  ┌──────────────────────────────┐   │  │  │
│  │  │  │  ViewModel<T>       │  │  AsyncViewModelImpl<T>       │   │  │  │
│  │  │  │  ┌───────────────┐  │  │  ┌────────────────────────┐  │   │  │  │
│  │  │  │  │ HelperNotifier│  │  │  │ HelperNotifier         │  │   │  │  │
│  │  │  │  │ ContextService│  │  │  │ ContextService         │  │   │  │  │
│  │  │  │  └───────────────┘  │  │  │ AsyncState<T>          │  │   │  │  │
│  │  │  └─────────────────────┘  │  └────────────────────────┘  │   │  │  │
│  │  └──────────────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│              │                    │                      │               │
│              │ Contains/Wraps     │                      │               │
│              ▼                    ▼                      ▼               │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                       STATE LAYER                                   │  │
│  │  ┌──────────────────────────────────────────────────────────────┐  │  │
│  │  │                   ReactiveNotifier<T>                         │  │  │
│  │  │  ┌─────────────────┐  ┌─────────────────┐  ┌───────────────┐ │  │  │
│  │  │  │ NotifierImpl<T> │  │ Singleton       │  │ Related       │ │  │  │
│  │  │  │ (ChangeNotifier)│  │ Management      │  │ States        │ │  │  │
│  │  │  └─────────────────┘  └─────────────────┘  └───────────────┘ │  │  │
│  │  └──────────────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│              │                                                           │
│              │ Organized by                                              │
│              ▼                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                      SERVICE LAYER                                  │  │
│  │  ┌──────────────────────────────────────────────────────────────┐  │  │
│  │  │  mixin UserService {                                          │  │  │
│  │  │    static final ReactiveNotifier<UserVM> userState = ...      │  │  │
│  │  │  }                                                            │  │  │
│  │  │  mixin CartService {                                          │  │  │
│  │  │    static final ReactiveNotifier<CartVM> cartState = ...      │  │  │
│  │  │  }                                                            │  │  │
│  │  └──────────────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

### Component Inheritance Hierarchy

```
                        ChangeNotifier (Flutter)
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               │               │
       NotifierImpl<T>        │               │
              │               │               │
              ▼               │               │
      ReactiveNotifier<T>     │               │
                              │               │
                              ▼               ▼
                     ViewModel<T>    AsyncViewModelImpl<T>
                              │               │
                              │               │
                    with HelperNotifier       with HelperNotifier
                    with ViewModelContextService   with ViewModelContextService
```

### Builder to ViewModel to State Relationships

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      BUILDER WIDGET HIERARCHY                            │
└─────────────────────────────────────────────────────────────────────────┘

  ReactiveBuilder<T>                 ReactiveViewModelBuilder<VM,T>
  ┌────────────────────┐             ┌────────────────────────────┐
  │ - notifier: Notifier │             │ - viewmodel: ViewModel<T>   │
  │ - build: Function   │             │ - build: Function          │
  │ - keep: Function    │             │ - keep: Function           │
  └─────────┬──────────┘             └────────────┬───────────────┘
            │                                     │
            │ addListener()                       │ addListener()
            ▼                                     ▼
  ┌────────────────────┐             ┌────────────────────────────┐
  │ NotifierImpl<T>    │             │ ViewModel<T>               │
  │ ┌────────────────┐ │             │ ┌────────────────────────┐ │
  │ │ _notifier: T   │ │             │ │ _data: T               │ │
  │ │ updateState()  │ │             │ │ updateState()          │ │
  │ │ transformState()│ │             │ │ transformState()       │ │
  │ │ listen()       │ │             │ │ listenVM()             │ │
  │ └────────────────┘ │             │ │ init()                 │ │
  └────────────────────┘             │ │ onStateChanged()       │ │
                                     │ └────────────────────────┘ │
                                     └────────────────────────────┘

  ReactiveAsyncBuilder<VM,T>
  ┌────────────────────────────┐
  │ - notifier: AsyncVMImpl<T> │
  │ - onData: Function         │
  │ - onLoading: Function      │
  │ - onError: Function        │
  │ - keep: Function           │
  └─────────────┬──────────────┘
                │ addListener()
                ▼
  ┌────────────────────────────────┐
  │ AsyncViewModelImpl<T>          │
  │ ┌────────────────────────────┐ │
  │ │ _state: AsyncState<T>      │ │
  │ │ ├── initial()              │ │
  │ │ ├── loading()              │ │
  │ │ ├── success(data)          │ │
  │ │ └── error(error, stack)    │ │
  │ │ init(): Future<T>          │ │
  │ │ reload()                   │ │
  │ │ onAsyncStateChanged()      │ │
  │ └────────────────────────────┘ │
  └────────────────────────────────┘
```

---

## 3. Component Layers

### Layer Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           UI LAYER                                       │
│                  (ReactiveBuilder, Widgets)                              │
│  Purpose: Render state, handle user interactions                         │
│  Responsibilities:                                                       │
│    - Subscribe to state changes via addListener                          │
│    - Trigger rebuilds on notification                                    │
│    - Provide keep() function for widget preservation                     │
│    - Register/unregister context for ViewModels                          │
├─────────────────────────────────────────────────────────────────────────┤
│                        VIEWMODEL LAYER                                   │
│                (ViewModel, AsyncViewModelImpl)                           │
│  Purpose: Business logic, state transformation, cross-VM communication   │
│  Responsibilities:                                                       │
│    - Synchronous initialization (ViewModel)                              │
│    - Asynchronous initialization (AsyncViewModelImpl)                    │
│    - State mutations via updateState/transformState                      │
│    - Cross-ViewModel communication via listenVM()                        │
│    - Lifecycle hooks (init, onResume, onStateChanged)                    │
├─────────────────────────────────────────────────────────────────────────┤
│                         STATE LAYER                                      │
│                 (ReactiveNotifier, AsyncState)                           │
│  Purpose: State container with singleton management                      │
│  Responsibilities:                                                       │
│    - Singleton instance storage in global HashMap                        │
│    - Related states parent-child propagation                             │
│    - Reference counting for auto-dispose                                 │
│    - Circular reference detection                                        │
│    - Notification overflow protection                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                        SERVICE LAYER                                     │
│                   (Mixin-organized services)                             │
│  Purpose: Namespace organization, service boundaries                     │
│  Responsibilities:                                                       │
│    - Group related ReactiveNotifiers logically                           │
│    - Provide static access points for state                              │
│    - Define service boundaries (sandbox architecture)                    │
│    - Enable explicit cross-service communication                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Component Details

#### NotifierImpl<T> (Base Class)

```dart
// Location: lib/src/notifier/notifier_impl.dart
// Purpose: Foundation for all notifier types
abstract class NotifierImpl<T> extends ChangeNotifier {
  T _notifier;                    // Internal state value
  VoidCallback? _currentListener; // Single listener management

  // Core API:
  T get notifier;                        // Access current value
  void updateState(T newState);          // Update with notification
  void updateSilently(T newState);       // Update without notification
  void transformState(T Function(T));    // Transform with notification
  void transformStateSilently(T Function(T)); // Transform without notification
  T listen(void Function(T));            // Subscribe to changes
  void stopListening();                  // Unsubscribe
}
```

#### ReactiveNotifier<T> (Singleton Container)

```dart
// Location: lib/src/notifier/reactive_notifier.dart
// Purpose: Singleton management + related states + lifecycle
class ReactiveNotifier<T> extends NotifierImpl<T> {
  // Singleton registry
  static final HashMap<Key, dynamic> _instances = HashMap.from({});

  // Instance identity
  final Key keyNotifier;

  // Related states system
  final List<ReactiveNotifier>? related;
  final Set<ReactiveNotifier> _parents;

  // Widget-aware lifecycle
  int _referenceCount;
  bool autoDispose;
  Timer? _disposeTimer;

  // Notification overflow protection
  static const _notificationThreshold = 50;
  static const _thresholdTimeWindow = Duration(milliseconds: 500);
}
```

#### ViewModel<T> (Synchronous ViewModel)

```dart
// Location: lib/src/viewmodel/viewmodel_impl.dart
// Purpose: Complex state with synchronous initialization
abstract class ViewModel<T> extends ChangeNotifier
    with HelperNotifier, ViewModelContextService {
  T _data;                     // Internal state
  bool _initialized;           // Lifecycle flag
  bool _disposed;              // Disposal flag

  // Lifecycle:
  void init();                        // MUST be synchronous
  void onStateChanged(T prev, T next); // State change hook
  FutureOr<void> onResume(T data);    // Post-init hook

  // State mutations:
  void updateState(T newState);
  void updateSilently(T newState);
  void transformState(T Function(T));
  void transformStateSilently(T Function(T));

  // Cross-VM communication:
  T listenVM(void Function(T));
  void stopListeningVM();

  // External listeners:
  Future<void> setupListeners();
  Future<void> removeListeners();
}
```

#### AsyncViewModelImpl<T> (Asynchronous ViewModel)

```dart
// Location: lib/src/viewmodel/async_viewmodel_impl.dart
// Purpose: Async operations with loading/success/error states
abstract class AsyncViewModelImpl<T> extends ChangeNotifier
    with HelperNotifier, ViewModelContextService {
  AsyncState<T> _state;        // Current async state
  bool loadOnInit;             // Auto-load on construction
  bool waitForContext;         // Wait for BuildContext before init

  // Lifecycle:
  Future<T> init();            // MUST be asynchronous
  Future<void> reload();       // Re-execute init()
  void onAsyncStateChanged(AsyncState<T> prev, AsyncState<T> next);

  // State mutations:
  void updateState(T data);           // Set success state
  void updateSilently(T data);        // Set success silently
  void loadingState();                // Set loading state
  void errorState(Object, StackTrace?); // Set error state
  void transformDataState(T? Function(T?)); // Transform data only
  void transformState(AsyncState<T> Function(AsyncState<T>));

  // Pattern matching:
  R when<R>({initial, loading, success, error});
  R match<R>({initial, loading, success, empty, error});
}
```

#### AsyncState<T> (Async State Wrapper)

```dart
// Location: lib/src/handler/async_state.dart
// Purpose: Discriminated union for async operations
class AsyncState<T> {
  final AsyncStatus status;  // initial | loading | success | error | empty
  final T? data;
  final Object? error;
  final StackTrace? stackTrace;

  // Factories:
  factory AsyncState.initial();
  factory AsyncState.loading();
  factory AsyncState.success(T data);
  factory AsyncState.error(Object error, [StackTrace?]);
  factory AsyncState.empty();

  // State checks:
  bool get isInitial;
  bool get isLoading;
  bool get isSuccess;
  bool get isError;
  bool get isEmpty;
}
```

---

## 4. Instance Management

### Global Instances HashMap

ReactiveNotifier maintains a global registry of all instances using a key-based lookup system:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     GLOBAL INSTANCE REGISTRY                             │
│                                                                         │
│   static final HashMap<Key, dynamic> _instances = HashMap.from({});     │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │  Key                    │  Instance                             │   │
│   ├─────────────────────────┼───────────────────────────────────────┤   │
│   │  UniqueKey#12345        │  ReactiveNotifier<UserViewModel>      │   │
│   │  UniqueKey#67890        │  ReactiveNotifier<CartViewModel>      │   │
│   │  UniqueKey#11111        │  ReactiveNotifier<int> (counter)      │   │
│   │  ValueKey('settings')   │  ReactiveNotifier<SettingsModel>      │   │
│   └─────────────────────────┴───────────────────────────────────────┘   │
│                                                                         │
│   Additional Registries:                                                │
│   - _instanceRegistry: Key -> ReactiveNotifier (for reference tracking) │
│   - _updatingNotifiers: Set (circular update prevention)                │
└─────────────────────────────────────────────────────────────────────────┘
```

### Key-Based Singleton Lookup

```dart
// Factory constructor ensures singleton behavior
factory ReactiveNotifier(T Function() create, {
  List<ReactiveNotifier>? related,
  Key? key,
  bool autoDispose = false
}) {
  key ??= UniqueKey();  // Generate unique key if not provided

  // Check for duplicate key (prevents circular dependencies)
  if (_instances.containsKey(key)) {
    throw StateError('Invalid Reference Structure Detected!');
  }

  // Create and register instance
  final instance = ReactiveNotifier._(create, related, key, autoDispose);
  _instances[key] = instance;
  _instanceRegistry[key] = instance;

  return _instances[key] as ReactiveNotifier<T>;
}
```

### Instance Lifecycle States

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   CREATED    │────▶│    ACTIVE    │────▶│  SCHEDULED   │
│              │     │              │     │  FOR DISPOSE │
└──────────────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       │                    │                    │
       │    addReference    │   removeReference  │
       │◀───────────────────│◀───────────────────│
       │                    │                    │
       │                    │                    │
       │                    ▼                    │
       │             ┌──────────────┐            │
       │             │ referenceCount            │
       │             │     > 0      │            │
       │             └──────┬───────┘            │
       │                    │                    │
       │              No    │  Yes               │
       │        ┌───────────┴───────────┐        │
       │        ▼                       ▼        │
       │  ┌──────────────┐     ┌──────────────┐  │
       │  │ Schedule     │     │ Keep Active  │  │
       │  │ Auto-Dispose │     │              │──┘
       │  └──────────────┘     └──────────────┘
       │        │
       │        │ After timeout
       │        ▼
       │  ┌──────────────┐
       └──│   DISPOSED   │
          │              │
          └──────────────┘
```

### Instance Management API

```dart
// Static methods for instance management
class ReactiveNotifier<T> {
  // Cleanup all instances
  static void cleanup();

  // Cleanup specific instance by key
  static bool cleanupInstance(Key key);

  // Cleanup all instances of a type
  static int cleanupByType<T>();

  // Reinitialize a disposed instance
  static T reinitializeInstance<T>(Key key, T Function() creator);

  // Check if instance is active
  static bool isInstanceActive<T>(Key key);

  // Get instance count
  static int get instanceCount;
  static int instanceCountByType<S>();

  // Instance-level cleanup
  bool cleanCurrentNotifier({bool forceCleanup = false});
}
```

---

## 5. Notification System

### ChangeNotifier Inheritance Chain

```
                    ChangeNotifier (Flutter)
                           │
           notifyListeners() / addListener() / removeListener()
                           │
                           ▼
                    NotifierImpl<T>
                           │
         updateState() -> notifyListeners()
         transformState() -> notifyListeners()
                           │
                           ▼
                   ReactiveNotifier<T>
                           │
         updateState() with:
           - Circular update prevention
           - Notification overflow detection
           - Parent notification propagation
```

### Listener Management

```dart
// NotifierImpl base listener management
VoidCallback? _currentListener;

T listen(void Function(T data) value) {
  // Remove previous listener (ensures single listener)
  if (_currentListener != null) {
    removeListener(_currentListener!);
  }

  // Create and register new listener
  _currentListener = () => value(_notifier);
  addListener(_currentListener!);

  return _notifier;  // Return current value for immediate sync
}

void stopListening() {
  if (_currentListener != null) {
    removeListener(_currentListener!);
    _currentListener = null;
  }
}
```

### ViewModel Listener Management

```dart
// ViewModel multi-listener tracking
final Map<String, VoidCallback> _listeners = {};
final Map<String, int> _listeningTo = {};

T listenVM(void Function(T data) value, {bool callOnInit = false}) {
  // Generate unique key
  final listenerKey = 'vm_${hashCode}_${DateTime.now().microsecondsSinceEpoch}';

  // Create and store callback
  void callback() => value(_data);
  _listeners[listenerKey] = callback;
  _listeningTo[listenerKey] = hashCode;

  // Optional immediate invocation
  if (callOnInit) callback();

  // Register with ChangeNotifier
  addListener(callback);

  return _data;
}

void stopListeningVM() {
  for (final callback in _listeners.values) {
    removeListener(callback);
  }
  _listeners.clear();
  _listeningTo.clear();
}
```

### Parent-Child Propagation (Related States)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    RELATED STATES SYSTEM                                 │
│                                                                         │
│   When a child state updates, all parent states are notified            │
│                                                                         │
│   ┌──────────────────────┐                                              │
│   │   ShopState          │◀─── Parent notified when children change     │
│   │   (related: [user,   │                                              │
│   │             cart])   │                                              │
│   └──────────┬───────────┘                                              │
│              │                                                          │
│      ┌───────┴───────┐                                                  │
│      ▼               ▼                                                  │
│ ┌──────────┐   ┌──────────┐                                             │
│ │ UserState│   │ CartState│                                             │
│ └────┬─────┘   └────┬─────┘                                             │
│      │              │                                                   │
│      │ update       │ update                                            │
│      ▼              ▼                                                   │
│  _parents.add(ShopState)                                                │
│  On update: notify all parents                                          │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

```dart
// Parent-child setup in constructor
ReactiveNotifier._(...) {
  if (related != null) {
    _validateCircularReferences(this);
    related?.forEach((child) {
      child._parents.add(this);  // Register parent
    });
  }
}

// Notification propagation on update
void updateState(T newState) {
  if (notifier != newState) {
    if (_updatingNotifiers.contains(this)) return;  // Prevent circular

    _checkNotificationOverflow();
    _updatingNotifiers.add(this);

    try {
      super.updateState(newState);

      // Notify all parents
      for (var parent in _parents) {
        parent.notifyListeners();
      }
    } finally {
      _updatingNotifiers.remove(this);
    }
  }
}
```

### Notification Overflow Protection

```dart
// Protects against rapid notification loops
static const _notificationThreshold = 50;
static const _thresholdTimeWindow = Duration(milliseconds: 500);
DateTime? _firstNotificationTime;
int _notificationCount = 0;

void _checkNotificationOverflow() {
  final now = DateTime.now();

  if (_firstNotificationTime == null) {
    _firstNotificationTime = now;
    _notificationCount = 1;
    return;
  }

  if (now.difference(_firstNotificationTime!) < _thresholdTimeWindow) {
    _notificationCount++;

    if (_notificationCount >= _notificationThreshold) {
      // Log warning about possible infinite loop
      assert(() {
        log('Notification Overflow Detected!');
        return true;
      }());
    }
  } else {
    // Reset counter for new time window
    _firstNotificationTime = now;
    _notificationCount = 1;
  }
}
```

---

## 6. Memory Model

### Reference Counting System

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    REFERENCE COUNTING                                    │
│                                                                         │
│   Each ReactiveNotifier tracks active widget references                 │
│                                                                         │
│   ReactiveNotifier<UserVM>                                              │
│   ├── _referenceCount: 3                                                │
│   ├── _activeReferences: {                                              │
│   │     'ReactiveBuilder_12345',                                        │
│   │     'ReactiveViewModelBuilder_67890',                               │
│   │     'ReactiveAsyncBuilder_11111'                                    │
│   │   }                                                                 │
│   └── autoDispose: true                                                 │
│                                                                         │
│   Widget Mount:   addReference(uniqueId)    -> _referenceCount++        │
│   Widget Dispose: removeReference(uniqueId) -> _referenceCount--        │
│                                                                         │
│   When _referenceCount == 0 && autoDispose:                             │
│     Schedule disposal after _autoDisposeTimeout (default 30s)           │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Auto-Dispose Mechanism

```dart
void addReference(String referenceId) {
  if (_activeReferences.add(referenceId)) {
    _referenceCount++;
  }

  // Cancel pending dispose
  if (_isScheduledForDispose) {
    _disposeTimer?.cancel();
    _disposeTimer = null;
    _isScheduledForDispose = false;
  }
}

void removeReference(String referenceId) {
  if (_activeReferences.remove(referenceId)) {
    _referenceCount--;
  }

  // Schedule auto-dispose if no references and autoDispose enabled
  if (_referenceCount <= 0 && autoDispose && !_isScheduledForDispose) {
    _scheduleAutoDispose();
  }
}

void _scheduleAutoDispose() {
  _isScheduledForDispose = true;
  _disposeTimer = Timer(_autoDisposeTimeout, () {
    if (_referenceCount <= 0 && autoDispose && !_disposed) {
      cleanCurrentNotifier(forceCleanup: true);
    }
    _isScheduledForDispose = false;
  });
}
```

### Cleanup Strategies

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      CLEANUP STRATEGIES                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. AUTOMATIC (autoDispose: true)                                       │
│     - Reference counting tracks active widgets                          │
│     - Timer schedules disposal when refs reach 0                        │
│     - Configurable timeout (default 30 seconds)                         │
│                                                                         │
│  2. MANUAL (cleanCurrentNotifier)                                       │
│     - Explicit cleanup request                                          │
│     - Respects active listeners unless forceCleanup: true               │
│     - Disposes ViewModel, removes from registry                         │
│                                                                         │
│  3. GLOBAL (ReactiveNotifier.cleanup)                                   │
│     - Disposes ALL ViewModels and AsyncViewModels                       │
│     - Clears all registries (_instances, _instanceRegistry)             │
│     - Clears context registries                                         │
│     - Used primarily for testing                                        │
│                                                                         │
│  4. TYPE-BASED (cleanupByType<T>)                                       │
│     - Removes all instances of specific type                            │
│     - Useful for clearing domain-specific state                         │
│                                                                         │
│  5. KEY-BASED (cleanupInstance(key))                                    │
│     - Removes specific instance by key                                  │
│     - For targeted cleanup                                              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Memory Flow Diagram

```
 Widget Mount                                      Widget Dispose
      │                                                  │
      ▼                                                  ▼
┌───────────────┐                               ┌───────────────┐
│ initState()   │                               │ dispose()     │
│ ┌───────────┐ │                               │ ┌───────────┐ │
│ │addReference│ │                               │ │removeRef  │ │
│ │addListener │ │                               │ │removeList │ │
│ │registerCtx │ │                               │ │unregCtx   │ │
│ └───────────┘ │                               │ └───────────┘ │
└───────┬───────┘                               └───────┬───────┘
        │                                               │
        ▼                                               ▼
┌───────────────────────────────────────────────────────────────┐
│                   ReactiveNotifier                             │
│  _referenceCount++              _referenceCount--              │
│                                                               │
│  if (_referenceCount == 0 && autoDispose) {                   │
│    Timer(timeout, () => cleanCurrentNotifier())               │
│  }                                                            │
└───────────────────────────────────────────────────────────────┘
                              │
                              │ cleanCurrentNotifier()
                              ▼
┌───────────────────────────────────────────────────────────────┐
│  1. Stop all listeners                                        │
│  2. Clean parent-child relationships                          │
│  3. Dispose ViewModel (if applicable)                         │
│  4. Remove from _instances registry                           │
│  5. Mark as disposed                                          │
└───────────────────────────────────────────────────────────────┘
```

---

## 7. Context Injection

### ViewModelContextService Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                  CONTEXT INJECTION SYSTEM                                │
│                                                                         │
│  Problem: ViewModels need BuildContext for Theme, MediaQuery, etc.      │
│  Solution: Automatic context registration from builders                 │
│                                                                         │
│                    ViewModelContextNotifier                             │
│                    (Static Context Registry)                            │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  _contexts: Map<int, BuildContext>                                │  │
│  │  _viewModelBuilders: Map<int, Set<String>>                        │  │
│  │  _globalContext: BuildContext?                                    │  │
│  │  _lastRegisteredContext: BuildContext?                            │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                             ▲                                           │
│                             │                                           │
│                             │ Register/Unregister                       │
│                             │                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     BUILDERS                                     │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │ initState() {                                           │    │   │
│  │  │   context.registerForViewModels(builderType, viewModel);│    │   │
│  │  │ }                                                       │    │   │
│  │  │ dispose() {                                             │    │   │
│  │  │   context.unregisterFromViewModels(builderType, viewModel);  │   │
│  │  │ }                                                       │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                             │                                           │
│                             │ ViewModelContextService mixin             │
│                             ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    VIEWMODELS                                    │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │ BuildContext? get context;                              │    │   │
│  │  │ bool get hasContext;                                    │    │   │
│  │  │ BuildContext requireContext([String? operation]);       │    │   │
│  │  │ BuildContext? get globalContext;                        │    │   │
│  │  │ bool get hasGlobalContext;                              │    │   │
│  │  │ BuildContext requireGlobalContext([String? operation]); │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Global vs Instance Context

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CONTEXT TYPES                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  GLOBAL CONTEXT (via ReactiveNotifier.initContext())                    │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  - Set once at app startup                                        │  │
│  │  - Persists throughout app lifecycle                              │  │
│  │  - Available to ALL ViewModels                                    │  │
│  │  - Ideal for Riverpod/Provider migration                          │  │
│  │  - Access via: globalContext, hasGlobalContext                    │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  INSTANCE CONTEXT (via builder registration)                            │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  - Registered when builder mounts                                 │  │
│  │  - Cleared when all builders for ViewModel dispose                │  │
│  │  - Specific to each ViewModel instance                            │  │
│  │  - Falls back to global context if not available                  │  │
│  │  - Access via: context, hasContext                                │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  PRIORITY:                                                              │
│  context getter: Instance Context -> Global Context -> null             │
│  globalContext getter: Global Context only                              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Builder Registration Flow

```
                        App Startup
                            │
                            ▼
┌───────────────────────────────────────────────────────────────┐
│  ReactiveNotifier.initContext(context)                        │
│  └── ViewModelContextNotifier.registerGlobalContext(context)  │
│      └── _globalContext = context                             │
└───────────────────────────────────────────────────────────────┘
                            │
                            ▼
                     Widget Tree Build
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ReactiveBuilder│   │ReactiveVM    │   │ReactiveAsync │
│   initState  │   │Builder       │   │Builder       │
│              │   │   initState  │   │   initState  │
└──────┬───────┘   └──────┬───────┘   └──────┬───────┘
       │                  │                  │
       │ registerForViewModels(builderType, viewModel)
       │                  │                  │
       ▼                  ▼                  ▼
┌───────────────────────────────────────────────────────────────┐
│               ViewModelContextNotifier                         │
│  _contexts[viewModel.hashCode] = context                      │
│  _viewModelBuilders[vmKey].add(builderType)                   │
└───────────────────────────────────────────────────────────────┘
       │                  │                  │
       │ reinitializeWithContext()          │
       │                  │                  │
       ▼                  ▼                  ▼
┌───────────────────────────────────────────────────────────────┐
│  ViewModel/AsyncViewModelImpl                                  │
│  if (_initializedWithoutContext && hasContext) {              │
│    _initialized = false;                                      │
│    _safeInitialization();  // Re-run init() with context      │
│  }                                                            │
└───────────────────────────────────────────────────────────────┘
```

### waitForContext Parameter

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    waitForContext FLOW                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  AsyncViewModelImpl(AsyncState.initial(), waitForContext: true)         │
│                            │                                            │
│                            ▼                                            │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Constructor:                                                    │   │
│  │  if (loadOnInit) {                                               │   │
│  │    if (waitForContext && !hasContext) {                          │   │
│  │      // DON'T call _initializeAsync()                            │   │
│  │      // Stay in AsyncState.initial()                             │   │
│  │      hasInitializedListenerExecution = false;                    │   │
│  │    } else {                                                      │   │
│  │      _initializeAsync();                                         │   │
│  │    }                                                             │   │
│  │  }                                                               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                            │                                            │
│                            │ Later: Builder mounts                      │
│                            ▼                                            │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  reinitializeWithContext() called by builder:                    │   │
│  │  if (waitForContext && !_initialized && hasContext) {            │   │
│  │    _initializeAsync();  // NOW init() runs with context          │   │
│  │  }                                                               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 8. Communication Patterns

### Explicit Sandbox Architecture

ReactiveNotifier enforces explicit service references over implicit type-based lookups. This is a deliberate architectural decision.

```
┌─────────────────────────────────────────────────────────────────────────┐
│              WHY EXPLICIT REFERENCES?                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  IMPLICIT TYPE LOOKUP (What we DON'T do):                               │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  // Ambiguous - which UserViewModel?                              │  │
│  │  final user = context.read<UserViewModel>();                      │  │
│  │                                                                   │  │
│  │  Problems:                                                        │  │
│  │  - Multiple instances of same type cause ambiguity                │  │
│  │  - Magic type resolution hides dependencies                       │  │
│  │  - Testing requires complex mocking                               │  │
│  │  - Refactoring can break unrelated code                           │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  EXPLICIT SERVICE REFERENCES (What we DO):                              │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  // Clear and unambiguous                                         │  │
│  │  UserService.mainUser.notifier.listenVM((user) { ... });          │  │
│  │  AdminService.adminUser.notifier.listenVM((admin) { ... });       │  │
│  │                                                                   │  │
│  │  Benefits:                                                        │  │
│  │  - Dependencies are visible in code                               │  │
│  │  - Multiple instances of same type supported                      │  │
│  │  - IDE navigation works correctly                                 │  │
│  │  - Testing is straightforward                                     │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### listenVM Reactive Communication

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    listenVM PATTERN                                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  class SalesViewModel extends AsyncViewModelImpl<SaleModel> {           │
│    CartModel? currentCart;  // Instance variable for current state      │
│                                                                         │
│    @override                                                            │
│    void init() {                                                        │
│      // Explicit reference to CartService                               │
│      CartService.cart.notifier.listenVM((cartData) {                    │
│        currentCart = cartData;                                          │
│        if (cartData.readyForSale) {                                     │
│          processSale(cartData.products);                                │
│        }                                                                │
│      });                                                                │
│    }                                                                    │
│  }                                                                      │
│                                                                         │
│  Flow:                                                                  │
│  ┌───────────────┐     listenVM()      ┌───────────────┐               │
│  │ CartService   │────────────────────▶│ SalesViewModel│               │
│  │ .cart.notifier│                     │               │               │
│  └───────┬───────┘                     └───────────────┘               │
│          │                                     ▲                        │
│          │ Cart updates                        │                        │
│          ▼                                     │ Callback invoked       │
│  ┌───────────────┐                             │                        │
│  │ notifyListeners()─────────────────────────────                       │
│  └───────────────┘                                                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Multiple Instances per Type

```
┌─────────────────────────────────────────────────────────────────────────┐
│              MULTIPLE INSTANCES SUPPORT                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  mixin UserService {                                                    │
│    // Multiple ReactiveNotifiers with SAME generic type                 │
│    static final ReactiveNotifier<UserViewModel> mainUser =              │
│        ReactiveNotifier<UserViewModel>(() => UserViewModel());          │
│                                                                         │
│    static final ReactiveNotifier<UserViewModel> guestUser =             │
│        ReactiveNotifier<UserViewModel>(() => UserViewModel());          │
│  }                                                                      │
│                                                                         │
│  mixin AdminService {                                                   │
│    // Same type in different service                                    │
│    static final ReactiveNotifier<UserViewModel> adminUser =             │
│        ReactiveNotifier<UserViewModel>(() => UserViewModel());          │
│  }                                                                      │
│                                                                         │
│  Usage - No ambiguity:                                                  │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  UserService.mainUser.notifier   // Main user ViewModel           │  │
│  │  UserService.guestUser.notifier  // Guest user ViewModel          │  │
│  │  AdminService.adminUser.notifier // Admin user ViewModel          │  │
│  │                                                                   │  │
│  │  // All are UserViewModel type, but accessed explicitly           │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Cross-Service Communication Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│  ┌───────────────────┐         ┌───────────────────┐                   │
│  │   UserService     │         │  NotificationSvc  │                   │
│  │  (Sandbox A)      │         │  (Sandbox B)      │                   │
│  │                   │         │                   │                   │
│  │  ┌─────────────┐  │         │  ┌─────────────┐  │                   │
│  │  │ currentUser │──┼────────▶│  │ notifications│  │                   │
│  │  │ .notifier   │  │ listenVM│  │ .notifier   │  │                   │
│  │  └─────────────┘  │         │  └─────────────┘  │                   │
│  └───────────────────┘         └───────────────────┘                   │
│           │                              │                              │
│           │                              │                              │
│           ▼                              ▼                              │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                       CartService                                  │  │
│  │                      (Sandbox C)                                   │  │
│  │                                                                   │  │
│  │  class CartViewModel extends ViewModel<CartModel> {               │  │
│  │    UserModel? currentUser;                                        │  │
│  │    List<Notification>? userNotifications;                         │  │
│  │                                                                   │  │
│  │    @override                                                      │  │
│  │    void init() {                                                  │  │
│  │      // Explicit cross-service communication                      │  │
│  │      UserService.currentUser.notifier.listenVM((user) {           │  │
│  │        currentUser = user;                                        │  │
│  │        updateCartForUser(user);                                   │  │
│  │      });                                                          │  │
│  │                                                                   │  │
│  │      NotificationService.notifications.notifier.listenVM((notifs) {│  │
│  │        userNotifications = notifs;                                │  │
│  │        checkCartPromotions(notifs);                               │  │
│  │      });                                                          │  │
│  │    }                                                              │  │
│  │  }                                                                │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 9. Design Decisions

### Why Mixins for Services?

```
┌─────────────────────────────────────────────────────────────────────────┐
│              MIXIN PATTERN RATIONALE                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  WHAT WE AVOID - Global Variables:                                      │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  // ANTI-PATTERN: Pollutes global namespace                       │  │
│  │  final userState = ReactiveNotifier<UserVM>(() => UserVM());      │  │
│  │  final cartState = ReactiveNotifier<CartVM>(() => CartVM());      │  │
│  │                                                                   │  │
│  │  Problems:                                                        │  │
│  │  - No logical grouping                                            │  │
│  │  - Name collisions likely                                         │  │
│  │  - Hard to find related states                                    │  │
│  │  - No IDE organization benefits                                   │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  WHAT WE USE - Mixin Namespacing:                                       │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  // PATTERN: Logical namespace organization                       │  │
│  │  mixin UserService {                                              │  │
│  │    static final ReactiveNotifier<UserVM> userState = ...          │  │
│  │    static final ReactiveNotifier<UserPrefs> prefsState = ...      │  │
│  │  }                                                                │  │
│  │                                                                   │  │
│  │  mixin CartService {                                              │  │
│  │    static final ReactiveNotifier<CartVM> cartState = ...          │  │
│  │    static final ReactiveNotifier<CartHistory> historyState = ...  │  │
│  │  }                                                                │  │
│  │                                                                   │  │
│  │  Benefits:                                                        │  │
│  │  - Clear service boundaries                                       │  │
│  │  - IDE autocompletion: UserService. shows all user states         │  │
│  │  - Prevents name collisions                                       │  │
│  │  - Self-documenting code structure                                │  │
│  │  - Can add static helper methods to service mixin                 │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  WHY MIXIN AND NOT CLASS?                                               │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  - Mixins clearly signal "namespace only, not instantiable"       │  │
│  │  - Cannot be instantiated accidentally (unlike classes)           │  │
│  │  - Dart convention for utility/namespace groupings                │  │
│  │  - Future flexibility: can be mixed into other classes if needed  │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Why Not InheritedWidget by Default?

```
┌─────────────────────────────────────────────────────────────────────────┐
│              INHERITEDWIDGET DECISION                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  InheritedWidget Approach:                                              │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  - Requires widget tree wrapping                                  │  │
│  │  - State tied to widget hierarchy                                 │  │
│  │  - Context traversal for access                                   │  │
│  │  - Multiple providers needed for multiple states                  │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ReactiveNotifier Approach:                                             │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  - Direct singleton access                                        │  │
│  │  - State independent of widget tree                               │  │
│  │  - No context needed for state access                             │  │
│  │  - Single instance, multiple subscribers                          │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  HYBRID SUPPORT (ReactiveContextEnhanced):                              │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  ReactiveNotifier DOES support InheritedWidget when beneficial:   │  │
│  │                                                                   │  │
│  │  ReactiveContextBuilder(                                          │  │
│  │    forceInheritedFor: [UserService.userState],                    │  │
│  │    child: MyWidget(),                                             │  │
│  │  )                                                                │  │
│  │                                                                   │  │
│  │  This creates InheritedWidget wrappers for specified notifiers,   │  │
│  │  giving you context.dependOnInheritedWidgetOfExactType benefits   │  │
│  │  when needed for specific subtrees.                               │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  DECISION: Default to singleton, support InheritedWidget optionally    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Why Separated ViewModel Lifecycle from UI?

```
┌─────────────────────────────────────────────────────────────────────────┐
│              LIFECYCLE SEPARATION RATIONALE                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  PROBLEM WITH WIDGET-TIED LIFECYCLE:                                    │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                                                                   │  │
│  │  User navigates: Screen A -> Screen B -> Screen A                 │  │
│  │                                                                   │  │
│  │  With widget-tied lifecycle:                                      │  │
│  │  1. Screen A mounts, ViewModel created, data loaded               │  │
│  │  2. Navigate to B, Screen A disposed, ViewModel disposed          │  │
│  │  3. Navigate back to A, NEW ViewModel created, data reloaded      │  │
│  │                                                                   │  │
│  │  Issues:                                                          │  │
│  │  - Unnecessary API calls                                          │  │
│  │  - Lost user state (scroll position, form data)                   │  │
│  │  - Loading indicators on every navigation                         │  │
│  │  - Poor user experience                                           │  │
│  │                                                                   │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  SOLUTION WITH SEPARATED LIFECYCLE:                                     │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                                                                   │  │
│  │  User navigates: Screen A -> Screen B -> Screen A                 │  │
│  │                                                                   │  │
│  │  With singleton lifecycle:                                        │  │
│  │  1. Screen A mounts, ViewModel exists (singleton), shows data     │  │
│  │  2. Navigate to B, Screen A disposed, ViewModel PERSISTS          │  │
│  │  3. Navigate back to A, SAME ViewModel, instant data display      │  │
│  │                                                                   │  │
│  │  Benefits:                                                        │  │
│  │  - Data persists across navigation                                │  │
│  │  - No redundant API calls                                         │  │
│  │  - Instant screen restoration                                     │  │
│  │  - Matches Android ViewModel behavior                             │  │
│  │                                                                   │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ANDROID INSPIRATION:                                                   │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  Android's ViewModel architecture:                                │  │
│  │  - ViewModels survive configuration changes                       │  │
│  │  - Lifecycle tied to ViewModelStoreOwner, not View               │  │
│  │  - Data outlives individual Activities/Fragments                  │  │
│  │                                                                   │  │
│  │  ReactiveNotifier follows this pattern:                           │  │
│  │  - ViewModels survive widget rebuilds and navigation              │  │
│  │  - Lifecycle tied to app scope or explicit disposal               │  │
│  │  - Data outlives individual widgets                               │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  CONTROLLED CLEANUP OPTIONS:                                            │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  1. autoDispose: true - Dispose when no widgets using it          │  │
│  │  2. cleanCurrentNotifier() - Manual cleanup                       │  │
│  │  3. ReactiveNotifier.cleanup() - Global reset (testing)           │  │
│  │  4. reinitializeInstance() - Fresh state without full cleanup     │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 10. Data Flow Diagram

### Complete Flow from User Action to UI Update

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    COMPLETE DATA FLOW                                    │
└─────────────────────────────────────────────────────────────────────────┘

                              USER ACTION
                                  │
                                  │ (Button tap, form submit, etc.)
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         UI WIDGET                                        │
│  ReactiveBuilder/ReactiveViewModelBuilder/ReactiveAsyncBuilder           │
│                                                                         │
│  build: (state, viewmodel, keep) {                                      │
│    return ElevatedButton(                                               │
│      onPressed: () => viewmodel.addItem(newItem),  // User action       │
│      child: Text('Add'),                                                │
│    );                                                                   │
│  }                                                                      │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     │ Method call
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       VIEWMODEL                                          │
│                                                                         │
│  void addItem(Item item) {                                              │
│    // Business logic                                                    │
│    final validated = _validateItem(item);                               │
│    final newList = [...data.items, validated];                          │
│                                                                         │
│    // State mutation                                                    │
│    transformState((current) => current.copyWith(items: newList));       │
│  }                                                                      │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     │ transformState()
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       STATE MUTATION                                     │
│                                                                         │
│  void transformState(T Function(T) transformer) {                       │
│    final previous = _data;                                              │
│    _data = transformer(_data);  // Apply transformation                 │
│    _updateCount++;                                                      │
│                                                                         │
│    notifyListeners();           // Trigger rebuilds                     │
│                                                                         │
│    onStateChanged(previous, _data);  // State change hook               │
│  }                                                                      │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     │ notifyListeners()
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    NOTIFICATION DISPATCH                                 │
│                                                                         │
│  ChangeNotifier.notifyListeners():                                      │
│    for (final listener in _listeners) {                                 │
│      listener();  // Invoke all registered callbacks                    │
│    }                                                                    │
│                                                                         │
│  Who's listening?                                                       │
│  ├── ReactiveBuilder widgets (via addListener in initState)             │
│  ├── Other ViewModels (via listenVM)                                    │
│  ├── Parent ReactiveNotifiers (related states system)                   │
│  └── Any manual listeners                                               │
└───────────────────┬─────────────────┬───────────────────────────────────┘
                    │                 │
       ┌────────────┘                 └────────────┐
       ▼                                          ▼
┌──────────────────────────┐           ┌──────────────────────────┐
│    UI REBUILD            │           │  CROSS-VM COMMUNICATION  │
│                          │           │                          │
│  _valueChanged() {       │           │  // In another ViewModel │
│    if (mounted) {        │           │  UserService.userState   │
│      setState(() {       │           │    .notifier             │
│        value = viewmodel │           │    .listenVM((user) {    │
│          .data;          │           │      // React to change  │
│      });                 │           │      updateForUser(user);│
│    }                     │           │    });                   │
│  }                       │           │                          │
└──────────┬───────────────┘           └──────────────────────────┘
           │
           │ setState() triggers rebuild
           ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      WIDGET REBUILD                                      │
│                                                                         │
│  @override                                                              │
│  Widget build(BuildContext context) {                                   │
│    // Rebuild with new state                                            │
│    return widget.build?.call(                                           │
│      value,              // New state value                             │
│      widget.notifier,    // ViewModel reference                         │
│      _noRebuild,         // keep() function                             │
│    );                                                                   │
│  }                                                                      │
│                                                                         │
│  _noRebuild(Widget child) preserves expensive widgets from rebuilding   │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     │ Render
                                     ▼
                              UPDATED UI
                         (User sees the change)
```

### Async Data Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    ASYNC DATA FLOW                                       │
└─────────────────────────────────────────────────────────────────────────┘

                          SCREEN MOUNT
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  ReactiveAsyncBuilder<ProductsVM, List<Product>>(                       │
│    notifier: ProductService.products.notifier,                          │
│    onLoading: () => CircularProgressIndicator(),                        │
│    onData: (products, vm, keep) => ProductList(products),               │
│    onError: (error, stack) => ErrorWidget(error),                       │
│  )                                                                      │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 │ initState: addListener
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                  AsyncViewModelImpl<List<Product>>                       │
│                                                                         │
│  Constructor (loadOnInit: true):                                        │
│    └── _initializeAsync()                                               │
│        └── reload()                                                     │
│            ├── loadingState()  ──▶ UI shows onLoading                   │
│            ├── init()  ──────────▶ await fetchProducts()                │
│            ├── updateState(data) ▶ UI shows onData                      │
│            └── setupListeners()                                         │
│                                                                         │
│  State transitions:                                                     │
│  initial -> loading -> success (or error)                               │
│     │          │           │         │                                  │
│     ▼          ▼           ▼         ▼                                  │
│  onInitial  onLoading   onData    onError                               │
└─────────────────────────────────────────────────────────────────────────┘

                          RELOAD TRIGGER
                              │
                              │ User pulls to refresh
                              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  viewmodel.reload()                                                     │
│    │                                                                    │
│    ├── removeListeners()                                                │
│    ├── loadingState()      ──▶ AsyncState.loading() ──▶ notifyListeners │
│    │                                        │                           │
│    │                                        ▼                           │
│    │                               ┌─────────────────┐                  │
│    │                               │ UI: onLoading() │                  │
│    │                               └─────────────────┘                  │
│    │                                                                    │
│    ├── await init()        ──▶ API call / data fetch                    │
│    │                                                                    │
│    ├── updateState(result) ──▶ AsyncState.success(data) ──▶ notify      │
│    │                                        │                           │
│    │                                        ▼                           │
│    │                               ┌────────────────────┐               │
│    │                               │ UI: onData(data)   │               │
│    │                               └────────────────────┘               │
│    │                                                                    │
│    ├── setupListeners()                                                 │
│    └── onResume(data)                                                   │
│                                                                         │
│  Error path:                                                            │
│    └── catch: errorState(error, stack) ──▶ AsyncState.error()           │
│                                                     │                   │
│                                                     ▼                   │
│                                            ┌────────────────────┐       │
│                                            │ UI: onError(error) │       │
│                                            └────────────────────┘       │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Summary

ReactiveNotifier's architecture is built on these foundational principles:

1. **Singleton Pattern**: One instance per key, reused throughout app lifecycle
2. **Explicit Dependencies**: Service references over type-based lookups
3. **Separated Lifecycles**: ViewModel lifecycle independent from widget lifecycle
4. **Mixin Organization**: Clean namespacing without global variable pollution
5. **Reference Counting**: Automatic memory management with configurable auto-dispose
6. **Flutter Native**: Built on ChangeNotifier, no external dependencies
7. **Context Injection**: Automatic BuildContext availability for ViewModels
8. **Related States**: Parent-child notification propagation for computed states

This architecture enables:
- Predictable state management
- Optimal memory usage
- Easy testing with `ReactiveNotifier.cleanup()`
- Gradual migration from other state managers
- Cross-ViewModel reactive communication
- Android-like ViewModel persistence patterns
