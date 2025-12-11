# hasGlobalContext Getter

## Signature

```dart
bool get hasGlobalContext
```

## Type

Returns `bool` - `true` if the global BuildContext has been initialized via `ReactiveNotifier.initContext()`, `false` otherwise.

## Description

The `hasGlobalContext` getter provides a safe way to check whether the global BuildContext is available before attempting to access it. Unlike `hasContext` which checks both specific and global context, this getter specifically checks only the global context.

### Source Implementation

```dart
// From lib/src/context/viewmodel_context_notifier.dart (lines 287)
bool get hasGlobalContext => ViewModelContextNotifier.hasGlobalContext();
```

### Internal Check

```dart
// From ViewModelContextNotifier
static bool hasGlobalContext() => _globalContext != null;
```

## Usage Example

### Basic Pattern

```dart
class MigrationViewModel extends ViewModel<MigrationState> {
  MigrationViewModel() : super(MigrationState.initial());

  @override
  void init() {
    if (hasGlobalContext) {
      // Global context is available - can access Riverpod/Provider
      _initializeFromRiverpod();
    } else {
      // No global context - use pure ReactiveNotifier init
      _initializeStandalone();
    }
  }

  void _initializeFromRiverpod() {
    final container = ProviderScope.containerOf(globalContext!);
    final userData = container.read(userProvider);
    updateSilently(MigrationState.fromRiverpod(userData));
  }

  void _initializeStandalone() {
    updateSilently(MigrationState.empty());
  }
}
```

### Conditional Riverpod Access

```dart
class HybridViewModel extends ViewModel<HybridState> {
  HybridViewModel() : super(HybridState.initial());

  void syncFromLegacyState() {
    if (hasGlobalContext) {
      try {
        final container = ProviderScope.containerOf(globalContext!);
        final legacyData = container.read(legacyProvider);
        updateState(HybridState.fromLegacy(legacyData));
      } catch (e) {
        // Handle case where ProviderScope is not in tree
        _useFallbackState();
      }
    } else {
      _useFallbackState();
    }
  }

  void _useFallbackState() {
    updateState(HybridState.defaults());
  }
}
```

### Migration Guard Pattern

```dart
class SafeMigrationViewModel extends ViewModel<SafeState> {
  SafeMigrationViewModel() : super(SafeState.initial());

  bool get canAccessRiverpod => hasGlobalContext;

  void performMigrationAction() {
    if (!canAccessRiverpod) {
      throw StateError(
        'Migration action requires global context. '
        'Call ReactiveNotifier.initContext() in app root.'
      );
    }

    final container = ProviderScope.containerOf(globalContext!);
    // Perform migration...
  }
}
```

## Difference from hasContext

| Check | `hasContext` | `hasGlobalContext` |
|-------|--------------|-------------------|
| **Checks** | Specific VM context OR global | Only global context |
| **Returns true when** | Any builder mounted OR global init | Only after `initContext()` |
| **Use for** | General context operations | Riverpod/Provider migration |
| **False when** | No builders, no global init | No global init (even if builders exist) |

### Comparison Example

```dart
class ComparisonViewModel extends ViewModel<State> {
  void demonstrateDifference() {
    // hasContext: true if ANY context available
    // (specific builder context OR global context)
    if (hasContext) {
      // Can access Theme, MediaQuery, etc.
    }

    // hasGlobalContext: true ONLY if initContext() was called
    if (hasGlobalContext) {
      // Can access Riverpod/Provider containers
    }

    // Possible scenarios:
    // 1. hasContext=true, hasGlobalContext=false
    //    -> Builder mounted, but no initContext() called
    //
    // 2. hasContext=true, hasGlobalContext=true
    //    -> initContext() was called (hasContext falls back to global)
    //
    // 3. hasContext=false, hasGlobalContext=false
    //    -> No builder mounted, no initContext() called
  }
}
```

## Best Practices

### 1. Use for Migration-Specific Checks

```dart
// CORRECT - Checking for migration capability
if (hasGlobalContext) {
  final container = ProviderScope.containerOf(globalContext!);
}

// AVOID - Using hasGlobalContext for general context checks
if (hasGlobalContext) {
  final theme = Theme.of(globalContext!); // Use hasContext instead
}
```

### 2. Combine with hasContext for Hybrid Apps

```dart
@override
void init() {
  // Priority 1: Try Riverpod migration
  if (hasGlobalContext) {
    try {
      _initFromRiverpod();
      return;
    } catch (e) {
      // Fall through to next option
    }
  }

  // Priority 2: Try with any available context
  if (hasContext) {
    _initWithContext();
    return;
  }

  // Priority 3: Initialize without context
  _initStandalone();
}
```

### 3. Provide Clear Feedback

```dart
void verifyMigrationSetup() {
  if (!hasGlobalContext) {
    log('''
Warning: Global context not initialized.
To enable Riverpod/Provider migration, call:
  ReactiveNotifier.initContext(context)
in your app root widget.
    ''');
  }
}
```

## Common Scenarios

### Scenario 1: App Without initContext

```dart
// MyApp does NOT call initContext
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage());
  }
}

// In ViewModel
@override
void init() {
  print(hasGlobalContext); // false
  print(hasContext);       // false (until builder mounts)
}
```

### Scenario 2: App With initContext

```dart
// MyApp DOES call initContext
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ReactiveNotifier.initContext(context);
    return MaterialApp(home: HomePage());
  }
}

// In ViewModel
@override
void init() {
  print(hasGlobalContext); // true
  print(hasContext);       // true (falls back to global)
}
```

### Scenario 3: Builder Without Global Init

```dart
// No initContext, but builder mounted
ReactiveViewModelBuilder<MyVM, MyState>(
  viewmodel: MyService.state.notifier,
  build: (state, vm, keep) {
    // Inside this builder, vm has specific context
    print(vm.hasGlobalContext); // false
    print(vm.hasContext);       // true (specific builder context)
    return Text('$state');
  },
)
```

## Related

- [globalContext](global-context.md) - The actual global context getter
- [requireGlobalContext()](require-global-context.md) - Required global context with errors
- [hasContext](has-context.md) - Check any context availability
- [init-context](init-context.md) - Global context initialization method
