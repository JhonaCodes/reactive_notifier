# Context Access in ViewModels

BuildContext access within ViewModels for theme, MediaQuery, localizations, and migration from other state managers.

## Overview

ReactiveNotifier provides automatic BuildContext access within ViewModels through the `ViewModelContextService` mixin. This enables ViewModels to access context-dependent Flutter services and facilitates gradual migration from Riverpod or Provider.

### Why ViewModels Need BuildContext

1. **Theme-Aware Logic**: Decisions based on dark/light mode
2. **Responsive Design**: Logic depending on screen dimensions
3. **Localization**: Accessing translated strings in business logic
4. **Migration**: Gradual migration from Riverpod/Provider
5. **Platform Services**: Accessing InheritedWidgets in the tree

### Architecture

```
+------------------+     +---------------------------+     +------------------+
|                  |     |                           |     |                  |
|  ReactiveBuilder |---->| ViewModelContextNotifier  |<----| ViewModel<T>     |
|  Widgets         |     | (Context Registry)        |     | AsyncViewModelImpl|
|                  |     |                           |     |                  |
+------------------+     +---------------------------+     +------------------+
        |                          ^                              |
        v                          |                              v
   Registers context         Stores contexts            Accesses context via
   when mounting             per ViewModel              ViewModelContextService
```

## API Reference

### Global Initialization

| Method | Description | Details |
|--------|-------------|---------|
| `ReactiveNotifier.initContext(context)` | Initialize global context | [View details](context/init-context.md) |

### Context Access (ViewModel Instance)

| Property/Method | Type | Description | Details |
|-----------------|------|-------------|---------|
| `context` | `BuildContext?` | Nullable context getter (falls back to global) | [View details](context/context.md) |
| `hasContext` | `bool` | Check if any context is available | [View details](context/has-context.md) |
| `requireContext([operation])` | `BuildContext` | Required context with errors | [View details](context/require-context.md) |

### Global Context Access (Direct)

| Property/Method | Type | Description | Details |
|-----------------|------|-------------|---------|
| `globalContext` | `BuildContext?` | Direct global context access | [View details](context/global-context.md) |
| `hasGlobalContext` | `bool` | Check if global context initialized | [View details](context/has-global-context.md) |
| `requireGlobalContext([operation])` | `BuildContext` | Required global context with errors | [View details](context/require-global-context.md) |

### AsyncViewModelImpl Parameters

| Parameter | Type | Description | Details |
|-----------|------|-------------|---------|
| `waitForContext` | `bool` | Wait for context before init() | [View details](context/wait-for-context.md) |

### Related Widgets

| Widget | Description | Details |
|--------|-------------|---------|
| `ReactiveContextBuilder` | Force InheritedWidget strategy | [View details](builders/reactive-context-builder.md) |

## Quick Comparison: context vs globalContext

| Feature | `context` | `globalContext` |
|---------|-----------|-----------------|
| **Source** | Specific VM context -> Global fallback | Always global only |
| **Persistence** | May change with builder lifecycle | Constant throughout app |
| **Availability** | After any builder mounts OR global init | Only after `initContext()` |
| **Primary Use** | General widget operations | Riverpod/Provider migration |
| **Fallback** | Falls back to global automatically | No fallback |

## Basic Usage

### 1. Global Context Setup (Recommended)

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Initialize global context for all ViewModels
    ReactiveNotifier.initContext(context);

    return MaterialApp(
      home: HomePage(),
    );
  }
}
```

### 2. Context Access in ViewModel

```dart
class ThemeAwareViewModel extends ViewModel<ThemeState> {
  ThemeAwareViewModel() : super(ThemeState.initial());

  @override
  void init() {
    if (hasContext) {
      final theme = Theme.of(context!);
      updateSilently(ThemeState(
        isDarkMode: theme.brightness == Brightness.dark,
      ));
    }
  }
}
```

### 3. AsyncViewModel with waitForContext

```dart
class DataViewModel extends AsyncViewModelImpl<AppData> {
  DataViewModel() : super(
    AsyncState.initial(),
    waitForContext: true,  // Wait for context before init()
  );

  @override
  Future<AppData> init() async {
    // Context guaranteed to be available
    final theme = Theme.of(requireContext('data initialization'));
    return await loadData(isDark: theme.brightness == Brightness.dark);
  }
}
```

## Migration Patterns

### Riverpod Migration

```dart
class MigrationViewModel extends ViewModel<UserState> {
  @override
  void init() {
    if (hasGlobalContext) {
      final container = ProviderScope.containerOf(globalContext!);
      final userData = container.read(userProvider);
      updateSilently(UserState.fromRiverpod(userData));
    }
  }
}
```

### Provider Migration

```dart
class ProviderMigrationViewModel extends ViewModel<SettingsState> {
  @override
  void init() {
    if (hasGlobalContext) {
      final settings = Provider.of<SettingsModel>(
        globalContext!,
        listen: false,
      );
      updateSilently(SettingsState.fromProvider(settings));
    }
  }
}
```

## Context Lifecycle

```
+-------------------+     +---------------------+     +------------------+
| App Starts        |     | Builder Mounts      |     | Builder Disposes |
| initContext()     |     | registerForVM()     |     | unregisterFromVM()|
+-------------------+     +---------------------+     +------------------+
        |                          |                          |
        v                          v                          v
+-------------------+     +---------------------+     +------------------+
| Global context    |     | Specific VM context |     | Context cleared  |
| available for all |     | available for VM    |     | if no builders   |
| ViewModels        |     |                     |     | remain active    |
+-------------------+     +---------------------+     +------------------+
```

## Best Practices

### 1. Always Check Availability

```dart
if (hasContext) {
  final theme = Theme.of(context!);
}
```

### 2. Use postFrameCallback for MediaQuery

```dart
if (hasContext) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!isDisposed && hasContext) {
      final mediaQuery = MediaQuery.of(context!);
    }
  });
}
```

### 3. Provide Fallbacks

```dart
@override
void init() {
  if (hasContext) {
    _initWithContext();
  } else {
    _initWithDefaults();
  }
}
```

### 4. Use Descriptive Operation Names

```dart
final ctx = requireContext('user preferences dialog');
final ctx = requireContext('theme initialization');
```

## Related Documentation

- [Context Pattern Guide](../guides/context-pattern.md) - Detailed patterns and examples
- [ViewModel](viewmodel.md) - ViewModel reference
- [AsyncViewModelImpl](async-viewmodel.md) - AsyncViewModel reference
- [Builders](builders.md) - Builder widgets reference
