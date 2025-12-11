# ViewModel<T>

Complex state management with synchronous initialization, extending ChangeNotifier.

## Overview

`ViewModel<T>` is designed for complex state that requires:
- Synchronous initialization
- Business logic encapsulation
- Cross-ViewModel communication
- State change hooks

## When to Use

| Scenario | Use ViewModel<T> |
|----------|------------------|
| Complex state objects | Yes |
| Business logic needed | Yes |
| Synchronous init | Yes |
| Cross-VM communication | Yes |
| Simple primitives | No (use ReactiveNotifier) |
| Async data loading | No (use AsyncViewModelImpl) |

## Basic Usage

```dart
// 1. Define your model
class UserModel {
  final String name;
  final String email;

  UserModel({required this.name, required this.email});

  UserModel copyWith({String? name, String? email}) =>
    UserModel(name: name ?? this.name, email: email ?? this.email);
}

// 2. Create ViewModel
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel(name: '', email: ''));

  @override
  void init() {
    // Synchronous initialization
    updateSilently(UserModel(name: 'Guest', email: ''));
  }

  void updateName(String name) {
    transformState((user) => user.copyWith(name: name));
  }
}

// 3. Organize in service mixin
mixin UserService {
  static final ReactiveNotifier<UserViewModel> userState =
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

// 4. Use in UI
ReactiveViewModelBuilder<UserViewModel, UserModel>(
  viewmodel: UserService.userState.notifier,
  build: (user, viewModel, keep) => Text(user.name),
)
```

## API Reference

### Properties

| Property | Type | Description | Details |
|----------|------|-------------|---------|
| `data` | `T` | Current state | [View details](viewmodel/data.md) |
| `isDisposed` | `bool` | Disposal status | [View details](viewmodel/is-disposed.md) |
| `hasInitializedListenerExecution` | `bool` | Init cycle complete | [View details](viewmodel/has-initialized-listener-execution.md) |
| `activeListenerCount` | `int` | Active listeners count | [View details](viewmodel/active-listener-count.md) |

### Lifecycle Methods

| Method | Description | Details |
|--------|-------------|---------|
| `init()` | Synchronous initialization | [View details](viewmodel/init.md) |
| `dispose()` | Cleanup and disposal | [View details](viewmodel/dispose.md) |
| `reload()` | Reinitialize ViewModel | [View details](viewmodel/reload.md) |
| `loadNotifier()` | Ensure availability | [View details](viewmodel/load-notifier.md) |
| `onResume(data)` | Post-initialization hook | [View details](viewmodel/on-resume.md) |
| `setupListeners()` | Register external listeners | [View details](viewmodel/setup-listeners.md) |
| `removeListeners()` | Remove external listeners | [View details](viewmodel/remove-listeners.md) |

### State Update Methods

| Method | Notifies | Hook | Details |
|--------|----------|------|---------|
| `updateState(newState)` | Yes | Yes | [View details](viewmodel/update-state.md) |
| `updateSilently(newState)` | No | Yes | [View details](viewmodel/update-silently.md) |
| `transformState(fn)` | Yes | Yes | [View details](viewmodel/transform-state.md) |
| `transformStateSilently(fn)` | No | Yes | [View details](viewmodel/transform-state-silently.md) |
| `cleanState()` | Yes | Yes | [View details](viewmodel/clean-state.md) |

### Communication Methods

| Method | Description | Details |
|--------|-------------|---------|
| `listenVM(callback, callOnInit)` | Cross-VM communication | [View details](viewmodel/listen-vm.md) |
| `stopListeningVM()` | Stop all listeners | [View details](viewmodel/stop-listening-vm.md) |
| `stopSpecificListener(key)` | Stop specific listener | [View details](viewmodel/stop-specific-listener.md) |

### Hooks

| Hook | Description | Details |
|------|-------------|---------|
| `onStateChanged(previous, next)` | State change hook | [View details](viewmodel/on-state-changed.md) |

### Helper Methods

| Method | Description | Details |
|--------|-------------|---------|
| `isEmptyData(value)` | Check if value is empty | [View details](viewmodel/is-empty-data.md) |

### Context Access

| Property/Method | Description | Details |
|-----------------|-------------|---------|
| `context` | Nullable BuildContext | [View details](context/context.md) |
| `hasContext` | Context availability | [View details](context/has-context.md) |
| `requireContext()` | Required context | [View details](context/require-context.md) |
| `globalContext` | Global context | [View details](context/global-context.md) |
| `hasGlobalContext` | Global context availability | [View details](context/has-global-context.md) |
| `requireGlobalContext()` | Required global context | [View details](context/require-global-context.md) |

## Lifecycle Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    ViewModel Lifecycle                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Constructor ──► init() ──► setupListeners() ──► onResume()
│                                                         │
│       │              │              │              │    │
│       ▼              ▼              ▼              ▼    │
│   Create with    Sync init     Register      Post-init │
│   initial state  logic here    listeners     tasks     │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  State Updates: updateState / transformState            │
│       │                                                 │
│       ▼                                                 │
│  onStateChanged(previous, next) ──► notifyListeners()   │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  reload() ──► removeListeners() ──► init() ──► ...      │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  dispose() ──► removeListeners() ──► cleanup ──► done   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Related Documentation

- [AsyncViewModelImpl](async-viewmodel.md) - For async operations
- [ReactiveNotifier](reactive-notifier.md) - For simple state
- [Builders](builders.md) - UI integration
- [Communication](communication.md) - Cross-service patterns
- [Hooks](hooks.md) - State change hooks
- [Testing](testing.md) - Testing patterns
