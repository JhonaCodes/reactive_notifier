# requireGlobalContext() Method

## Signature

```dart
BuildContext requireGlobalContext([String? operation])
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `operation` | `String?` | No | Descriptive name for the operation requiring global context |

## Return Type

`BuildContext` - The global BuildContext, guaranteed to be non-null.

## Throws

`StateError` - If global context is not available, with:
- The operation name (if provided)
- The ViewModel type
- Clear explanation that `ReactiveNotifier.initContext()` needs to be called
- Example code showing how to initialize global context

## Description

The `requireGlobalContext()` method provides a safe way to access the global BuildContext when it is absolutely required. Unlike `requireContext()` which checks both specific and global context, this method specifically requires the global context initialized via `ReactiveNotifier.initContext()`.

### Source Implementation

```dart
// From lib/src/context/viewmodel_context_notifier.dart (lines 302-334)
BuildContext requireGlobalContext([String? operation]) {
  final ctx = globalContext;
  if (ctx == null) {
    throw StateError('''
Global BuildContext Not Available
Operation: ${operation ?? 'ViewModel operation'}
ViewModel: $runtimeType

Global context is not available because:
  ReactiveNotifier.initContext(context) has not been called yet

Solution - Initialize global context in your app root:
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

Use Case - Perfect for Riverpod/Provider migration:
  Global context remains available throughout app lifecycle,
  even when specific builders mount/unmount during navigation.
''');
  }
  return ctx;
}
```

## Usage Example

### Riverpod Migration

```dart
class RiverpodMigrationViewModel extends ViewModel<UserState> {
  RiverpodMigrationViewModel() : super(UserState.initial());

  @override
  void init() {
    final container = ProviderScope.containerOf(
      requireGlobalContext('Riverpod migration initialization')
    );
    final userData = container.read(userProvider);
    updateSilently(UserState.fromRiverpod(userData));
  }

  void refreshFromRiverpod() {
    final container = ProviderScope.containerOf(
      requireGlobalContext('Riverpod data refresh')
    );
    final userData = container.read(userProvider);
    updateState(UserState.fromRiverpod(userData));
  }
}
```

### Provider Migration

```dart
class ProviderMigrationViewModel extends ViewModel<SettingsState> {
  ProviderMigrationViewModel() : super(SettingsState.defaults());

  void syncSettings() {
    final ctx = requireGlobalContext('Provider settings sync');
    final settings = Provider.of<SettingsModel>(ctx, listen: false);
    updateState(SettingsState.fromProvider(settings));
  }
}
```

### With Error Handling

```dart
class SafeMigrationViewModel extends ViewModel<MigrationState> {
  void performMigration() {
    try {
      final ctx = requireGlobalContext('migration operation');
      final container = ProviderScope.containerOf(ctx);
      // Perform migration...
    } on StateError catch (e) {
      // Handle missing global context
      log('Migration failed: Global context not initialized');
      updateState(MigrationState.failed('Please restart the app'));
    }
  }
}
```

## Error Message Example

When `requireGlobalContext()` throws, the error provides helpful guidance:

```
StateError: Global BuildContext Not Available

Operation: Riverpod migration initialization
ViewModel: RiverpodMigrationViewModel

Global context is not available because:
  ReactiveNotifier.initContext(context) has not been called yet

Solution - Initialize global context in your app root:
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

Use Case - Perfect for Riverpod/Provider migration:
  Global context remains available throughout app lifecycle,
  even when specific builders mount/unmount during navigation.
```

## Difference from requireContext()

| Feature | `requireContext()` | `requireGlobalContext()` |
|---------|-------------------|-------------------------|
| **Checks** | Specific VM context, then global | Only global context |
| **Throws when** | Neither context available | Global not initialized |
| **Primary use** | General context operations | Riverpod/Provider migration |
| **Error message** | Lists builder options | Shows initContext() solution |

### When to Use Each

```dart
class ExampleViewModel extends ViewModel<State> {
  // Use requireContext for general Flutter operations
  void showDialog() {
    showDialog(
      context: requireContext('showing dialog'),
      builder: (_) => MyDialog(),
    );
  }

  // Use requireGlobalContext for migration operations
  void readFromRiverpod() {
    final container = ProviderScope.containerOf(
      requireGlobalContext('Riverpod read')
    );
    // Use container...
  }
}
```

## Best Practices

### 1. Use Descriptive Operation Names

```dart
// GOOD - Clear what failed
requireGlobalContext('user data migration from Riverpod')
requireGlobalContext('settings sync from Provider')
requireGlobalContext('initial state migration')

// BAD - Not helpful
requireGlobalContext()
requireGlobalContext('operation')
```

### 2. Use for Migration-Specific Operations

```dart
// CORRECT - Migration use case
void migrateFromRiverpod() {
  final container = ProviderScope.containerOf(
    requireGlobalContext('Riverpod migration')
  );
}

// AVOID - General operations should use requireContext
void showThemeDialog() {
  final theme = Theme.of(requireContext('theme dialog')); // Use this instead
}
```

### 3. Handle Errors Gracefully During Migration

```dart
void attemptMigration() {
  try {
    final container = ProviderScope.containerOf(
      requireGlobalContext('migration attempt')
    );
    _performMigration(container);
  } on StateError {
    // Migration not possible - use fallback
    _initializeWithoutMigration();
  }
}
```

### 4. Ensure Proper App Setup

```dart
// In your app root - REQUIRED for requireGlobalContext to work
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This must be called for requireGlobalContext to succeed
    ReactiveNotifier.initContext(context);

    return ProviderScope( // If using Riverpod
      child: MaterialApp(
        home: HomePage(),
      ),
    );
  }
}
```

## Common Migration Patterns

### Complete Riverpod Migration Setup

```dart
// 1. App setup with both systems
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Builder(
        builder: (innerContext) {
          // Initialize with context that has ProviderScope access
          ReactiveNotifier.initContext(innerContext);
          return MaterialApp(home: HomePage());
        },
      ),
    );
  }
}

// 2. ViewModel that reads from Riverpod
class MigrationViewModel extends ViewModel<UserState> {
  @override
  void init() {
    final container = ProviderScope.containerOf(
      requireGlobalContext('user state migration')
    );
    final riverpodUser = container.read(userProvider);
    updateSilently(UserState.fromRiverpod(riverpodUser));
  }
}
```

### Gradual Migration with Fallback

```dart
class GradualMigrationViewModel extends ViewModel<DataState> {
  @override
  void init() {
    if (hasGlobalContext) {
      try {
        final container = ProviderScope.containerOf(globalContext!);
        final data = container.read(dataProvider);
        updateSilently(DataState.fromRiverpod(data));
        return;
      } catch (e) {
        // ProviderScope not found - fall through
      }
    }
    // Fallback to standalone initialization
    updateSilently(DataState.empty());
  }
}
```

## Related

- [globalContext](global-context.md) - Nullable global context getter
- [hasGlobalContext](has-global-context.md) - Check global context availability
- [requireContext()](require-context.md) - Required context with fallback
- [init-context](init-context.md) - Global context initialization method
