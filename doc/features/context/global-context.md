# globalContext Getter

## Signature

```dart
BuildContext? get globalContext
```

## Type

Returns a nullable `BuildContext?` - the global BuildContext initialized via `ReactiveNotifier.initContext()`, or `null` if not initialized.

## Description

The `globalContext` getter provides direct access to the persistent global BuildContext, bypassing any specific ViewModel context. This context remains available throughout the application lifecycle and is particularly useful for migration scenarios from Riverpod or Provider.

### Source Implementation

```dart
// From lib/src/context/viewmodel_context_notifier.dart (lines 281-282)
BuildContext? get globalContext =>
    ViewModelContextNotifier.getGlobalContext();
```

### Key Characteristics

- **Persistent**: Remains constant throughout the app lifecycle
- **Direct Access**: Bypasses specific ViewModel context lookup
- **Migration-Friendly**: Ideal for accessing Riverpod/Provider containers
- **Global Scope**: Same context for all ViewModels

## Usage Example

### Riverpod Migration Pattern

```dart
class RiverpodMigrationViewModel extends ViewModel<UserState> {
  RiverpodMigrationViewModel() : super(UserState.initial());

  @override
  void init() {
    if (hasGlobalContext) {
      // Global context persists throughout app lifecycle
      final container = ProviderScope.containerOf(globalContext!);
      final userData = container.read(userProvider);
      updateSilently(UserState.fromRiverpod(userData));
    }
  }

  void refreshFromRiverpod() {
    if (hasGlobalContext) {
      // Always available after initContext, never loses reference
      final container = ProviderScope.containerOf(globalContext!);
      final userData = container.read(userProvider);
      updateState(UserState.fromRiverpod(userData));
    }
  }
}
```

### Provider Migration Pattern

```dart
class ProviderMigrationViewModel extends ViewModel<SettingsState> {
  ProviderMigrationViewModel() : super(SettingsState.defaults());

  @override
  void init() {
    if (hasGlobalContext) {
      // Access existing Provider data during migration
      final settings = Provider.of<SettingsModel>(
        globalContext!,
        listen: false,
      );
      updateSilently(SettingsState.fromProvider(settings));
    }
  }
}
```

### Stable Context Access

```dart
class NavigationViewModel extends ViewModel<NavigationState> {
  NavigationViewModel() : super(NavigationState.initial());

  void navigateGlobally(String route) {
    if (hasGlobalContext) {
      // Global context is stable across navigation changes
      Navigator.of(globalContext!).pushNamed(route);
    }
  }

  void showGlobalDialog() {
    if (hasGlobalContext) {
      showDialog(
        context: globalContext!,
        builder: (_) => GlobalDialog(),
      );
    }
  }
}
```

## Difference from context

| Feature | `context` | `globalContext` |
|---------|-----------|-----------------|
| **Source** | Specific ViewModel context -> Global fallback | Always global context only |
| **Persistence** | May change when builders mount/unmount | Remains constant throughout app lifecycle |
| **Availability** | After any builder mounts OR global init | Only after `ReactiveNotifier.initContext()` |
| **Primary Use Case** | General widget operations | Riverpod/Provider migration |
| **Fallback Behavior** | Falls back to global context automatically | No fallback (null if not initialized) |

### Resolution Comparison

```
context getter:
  1. Check for specific ViewModel context (registered by builder)
  2. Fall back to global context (if available)
  3. Return null if neither available

globalContext getter:
  1. Return global context directly
  2. Return null if not initialized (no fallback)
```

## When to Use globalContext vs context

### Use globalContext for:

- **Riverpod Migration**: Accessing `ProviderScope.containerOf()`
- **Provider Migration**: Using `Provider.of()` without `listen`
- **Context Stability**: When you need context that persists across navigation
- **App-Level Operations**: Actions that should use the root app context

```dart
// Riverpod migration - use globalContext
if (hasGlobalContext) {
  final container = ProviderScope.containerOf(globalContext!);
  final data = container.read(myProvider);
}
```

### Use context for:

- **Theme Access**: Reading current theme
- **MediaQuery**: Getting screen dimensions
- **Localizations**: Accessing translated strings
- **General Widget Operations**: Most everyday context needs

```dart
// General operations - use context
if (hasContext) {
  final theme = Theme.of(context!);
  final mediaQuery = MediaQuery.of(context!);
}
```

## Best Practices

### 1. Initialize Global Context Early

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Initialize in app root before MaterialApp
    ReactiveNotifier.initContext(context);

    return MaterialApp(
      home: HomePage(),
    );
  }
}
```

### 2. Check Availability Before Use

```dart
void syncFromRiverpod() {
  if (hasGlobalContext) {
    final container = ProviderScope.containerOf(globalContext!);
    // Use container...
  }
}
```

### 3. Use for Migration, Not General Access

```dart
// CORRECT - Migration use case
class MigrationVM extends ViewModel<State> {
  @override
  void init() {
    if (hasGlobalContext) {
      // Read from existing Riverpod provider
      final container = ProviderScope.containerOf(globalContext!);
    }
  }
}

// PREFER context for general use
class GeneralVM extends ViewModel<State> {
  void updateTheme() {
    if (hasContext) {
      final theme = Theme.of(context!);
    }
  }
}
```

### 4. Keep ProviderScope Above initContext

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Builder(
        builder: (innerContext) {
          // Initialize with context that has access to ProviderScope
          ReactiveNotifier.initContext(innerContext);
          return MaterialApp(home: HomePage());
        },
      ),
    );
  }
}
```

## Common Migration Pattern

```dart
// Step 1: Initialize global context with ProviderScope access
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ReactiveNotifier.initContext(context);
    return ProviderScope(
      child: MaterialApp(home: HomePage()),
    );
  }
}

// Step 2: Create hybrid ViewModels that can read from Riverpod
class HybridViewModel extends ViewModel<UserState> {
  @override
  void init() {
    if (hasGlobalContext) {
      // Read initial data from Riverpod
      final container = ProviderScope.containerOf(globalContext!);
      final riverpodUser = container.read(userProvider);
      updateSilently(UserState.fromRiverpod(riverpodUser));
    } else {
      // Pure ReactiveNotifier initialization
      updateSilently(UserState.empty());
    }
  }
}

// Step 3: Eventually remove Riverpod dependency
class FinalViewModel extends ViewModel<UserState> {
  @override
  void init() {
    // No more Riverpod access needed
    updateSilently(UserState.empty());
  }
}
```

## Related

- [hasGlobalContext](has-global-context.md) - Check global context availability
- [requireGlobalContext()](require-global-context.md) - Required global context with errors
- [context](context.md) - General context getter with fallback
- [init-context](init-context.md) - Global context initialization method
