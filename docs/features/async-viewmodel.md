# AsyncViewModelImpl<T>

Async operations with loading, success, error states management.

## Overview

`AsyncViewModelImpl<T>` is designed for asynchronous operations that require:
- Loading state handling
- Error state with stack trace
- Async initialization
- Pattern matching for state handling

## When to Use

| Scenario | Use AsyncViewModelImpl<T> |
|----------|---------------------------|
| API calls | Yes |
| Database operations | Yes |
| File I/O | Yes |
| Async initialization | Yes |
| Sync initialization | No (use ViewModel) |
| Simple state | No (use ReactiveNotifier) |

## Basic Usage

```dart
// 1. Create AsyncViewModel
class ProductsViewModel extends AsyncViewModelImpl<List<Product>> {
  ProductsViewModel() : super(AsyncState.initial());

  @override
  Future<List<Product>> init() async {
    return await ProductRepository.fetchAll();
  }
}

// 2. Organize in service mixin
mixin ProductService {
  static final ReactiveNotifier<ProductsViewModel> products =
    ReactiveNotifier<ProductsViewModel>(() => ProductsViewModel());
}

// 3. Use in UI
ReactiveAsyncBuilder<ProductsViewModel, List<Product>>(
  notifier: ProductService.products.notifier,
  onData: (products, viewModel, keep) => ListView.builder(
    itemCount: products.length,
    itemBuilder: (_, i) => Text(products[i].name),
  ),
  onLoading: () => CircularProgressIndicator(),
  onError: (error, stack) => Text('Error: $error'),
)
```

## API Reference

### Constructor

| Parameter | Type | Default | Description | Details |
|-----------|------|---------|-------------|---------|
| `loadOnInit` | `bool` | `true` | Auto-initialize on creation | [View details](async-viewmodel/constructor.md) |
| `waitForContext` | `bool` | `false` | Wait for BuildContext | [View details](async-viewmodel/constructor.md) |

### Async Properties

| Property | Type | Description | Details |
|----------|------|-------------|---------|
| `isLoading` | `bool` | Loading state check | [View details](async-viewmodel/async-properties.md) |
| `hasData` | `bool` | Success state check | [View details](async-viewmodel/async-properties.md) |
| `error` | `Object?` | Current error | [View details](async-viewmodel/async-properties.md) |
| `stackTrace` | `StackTrace?` | Error stack trace | [View details](async-viewmodel/async-properties.md) |
| `data` | `T` | Current data (throws if error) | [View details](async-viewmodel/async-properties.md) |

### Inherited Properties (from ViewModel)

| Property | Type | Description | Details |
|----------|------|-------------|---------|
| `isDisposed` | `bool` | Disposal status | [View details](viewmodel/is-disposed.md) |
| `hasInitializedListenerExecution` | `bool` | Init cycle complete | [View details](viewmodel/has-initialized-listener-execution.md) |
| `activeListenerCount` | `int` | Active listeners count | [View details](viewmodel/active-listener-count.md) |

### Lifecycle Methods

| Method | Description | Details |
|--------|-------------|---------|
| `init()` | **Async** initialization | [View details](viewmodel/init.md) |
| `dispose()` | Cleanup and disposal | [View details](viewmodel/dispose.md) |
| `reload()` | Reinitialize ViewModel | [View details](viewmodel/reload.md) |
| `loadNotifier()` | Ensure availability | [View details](viewmodel/load-notifier.md) |
| `onResume(data)` | Post-initialization hook | [View details](viewmodel/on-resume.md) |
| `setupListeners()` | Register external listeners | [View details](viewmodel/setup-listeners.md) |
| `removeListeners()` | Remove external listeners | [View details](viewmodel/remove-listeners.md) |

### Async-Specific State Methods

| Method | Description | Details |
|--------|-------------|---------|
| `transformDataState(fn)` | Transform only data | [View details](async-viewmodel/transform-data-state.md) |
| `transformDataStateSilently(fn)` | Transform data silently | [View details](async-viewmodel/transform-data-state-silently.md) |
| `loadingState()` | Set loading state | [View details](async-viewmodel/loading-state.md) |
| `errorState(error, stack)` | Set error state | [View details](async-viewmodel/error-state.md) |

### Inherited State Methods (from ViewModel)

| Method | Notifies | Hook | Details |
|--------|----------|------|---------|
| `updateState(data)` | Yes | Yes | [View details](viewmodel/update-state.md) |
| `updateSilently(data)` | No | Yes | [View details](viewmodel/update-silently.md) |
| `transformState(fn)` | Yes | Yes | [View details](viewmodel/transform-state.md) |
| `transformStateSilently(fn)` | No | Yes | [View details](viewmodel/transform-state-silently.md) |
| `cleanState()` | Yes | Yes | [View details](viewmodel/clean-state.md) |

### Pattern Matching

| Method | Description | Details |
|--------|-------------|---------|
| `match()` | Exhaustive (5 states) | [View details](async-viewmodel/pattern-matching.md) |
| `when()` | Simplified (4 states) | [View details](async-viewmodel/pattern-matching.md) |

### Communication Methods

| Method | Return Type | Description | Details |
|--------|-------------|-------------|---------|
| `listenVM(callback, callOnInit)` | `Future<AsyncState<T>>` | Cross-VM communication | [View details](viewmodel/listen-vm.md) |
| `stopListeningVM()` | `void` | Stop all listeners | [View details](viewmodel/stop-listening-vm.md) |
| `stopSpecificListener(key)` | `void` | Stop specific listener | [View details](viewmodel/stop-specific-listener.md) |

### Hooks

| Hook | Description | Details |
|------|-------------|---------|
| `onAsyncStateChanged(previous, next)` | Async state change hook | [View details](async-viewmodel/on-async-state-changed.md) |

### Context Access

| Property/Method | Description | Details |
|-----------------|-------------|---------|
| `context` | Nullable BuildContext | [View details](context/context.md) |
| `hasContext` | Context availability | [View details](context/has-context.md) |
| `requireContext()` | Required context | [View details](context/require-context.md) |
| `globalContext` | Global context | [View details](context/global-context.md) |
| `hasGlobalContext` | Global context availability | [View details](context/has-global-context.md) |
| `requireGlobalContext()` | Required global context | [View details](context/require-global-context.md) |
| `waitForContext` | Wait for context before init() | [View details](context/wait-for-context.md) |

See [Context Access Overview](context-access.md) for complete context system documentation.

## Lifecycle Diagram

```
┌─────────────────────────────────────────────────────────┐
│                AsyncViewModelImpl Lifecycle              │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Constructor ──► loadOnInit? ──► init() (async)         │
│       │              │              │                   │
│       ▼              ▼              ▼                   │
│   AsyncState     If true:      Returns T               │
│   .initial()     auto-load     (success state)         │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  waitForContext? ──► Wait for BuildContext ──► init()   │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  State Flow:                                            │
│  initial ──► loading ──► success OR error               │
│                │                                        │
│                ▼                                        │
│  onAsyncStateChanged(previous, next)                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## AsyncState Reference

| State | Constructor | Description |
|-------|-------------|-------------|
| Initial | `AsyncState.initial()` | Not yet started |
| Loading | `AsyncState.loading()` | In progress |
| Success | `AsyncState.success(data)` | Completed with data |
| Empty | `AsyncState.empty()` | Completed, no data |
| Error | `AsyncState.error(e, stack)` | Failed |

See [State Types](state-types.md) for complete AsyncState documentation.

## Related Documentation

- [ViewModel](viewmodel.md) - For sync operations
- [ReactiveNotifier](reactive-notifier.md) - For simple state
- [State Types](state-types.md) - AsyncState reference
- [Builders](builders.md) - ReactiveAsyncBuilder
- [Hooks](hooks.md) - onAsyncStateChanged
- [Testing](testing.md) - Testing async ViewModels
