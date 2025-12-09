# context Getter

## Signature

```dart
BuildContext? get context
```

## Type

Returns a nullable `BuildContext?` - the current BuildContext if available, otherwise `null`.

## Description

The `context` getter provides access to the BuildContext associated with the ViewModel. It first checks for a specific ViewModel context (registered by builders), then falls back to the global context if available.

### Source Implementation

```dart
// From lib/src/context/viewmodel_context_notifier.dart (lines 217-218)
BuildContext? get context =>
    ViewModelContextNotifier.getContextForViewModel(this);
```

### Resolution Order

1. Check for specific ViewModel context (registered by builder)
2. Fall back to global context (set via `ReactiveNotifier.initContext()`)
3. Return `null` if neither available

## Usage Example

### Basic Usage

```dart
class ThemeAwareViewModel extends ViewModel<ThemeState> {
  ThemeAwareViewModel() : super(ThemeState.initial());

  @override
  void init() {
    // Safely access context with null check
    final ctx = context;
    if (ctx != null) {
      final theme = Theme.of(ctx);
      updateSilently(ThemeState(
        isDarkMode: theme.brightness == Brightness.dark,
        primaryColor: theme.primaryColor,
      ));
    }
  }
}
```

### With postFrameCallback (Recommended for MediaQuery/Theme)

```dart
class ResponsiveViewModel extends ViewModel<ResponsiveState> {
  ResponsiveViewModel() : super(ResponsiveState.initial());

  @override
  void init() {
    updateSilently(ResponsiveState.initial());

    if (context != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isDisposed && context != null) {
          final mediaQuery = MediaQuery.of(context!);
          updateState(ResponsiveState(
            screenWidth: mediaQuery.size.width,
            isTablet: mediaQuery.size.width > 600,
          ));
        }
      });
    }
  }
}
```

## When Context is Available

| Scenario | Available |
|----------|-----------|
| After `ReactiveNotifier.initContext()` | Yes |
| After any ReactiveBuilder mounts | Yes |
| Before any builder mounts (no global init) | No |
| After all builders dispose (no global init) | No |
| During ViewModel constructor | Depends on timing |

## Best Practices

### 1. Always Use Null Check

```dart
// CORRECT - Safe access
final ctx = context;
if (ctx != null) {
  final theme = Theme.of(ctx);
}

// INCORRECT - May throw
final theme = Theme.of(context!); // Unsafe!
```

### 2. Prefer hasContext for Conditional Logic

```dart
// RECOMMENDED - More readable
if (hasContext) {
  final theme = Theme.of(context!);
}

// ALSO VALID - Direct null check
if (context != null) {
  final theme = Theme.of(context!);
}
```

### 3. Use postFrameCallback for Theme/MediaQuery

```dart
@override
void init() {
  if (context != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isDisposed && context != null) {
        // Safe to access Theme/MediaQuery here
      }
    });
  }
}
```

## Common Mistakes

### 1. Accessing Without Check

```dart
// WRONG - Will throw if context is null
@override
void init() {
  final theme = Theme.of(context!);
}

// CORRECT - Check availability first
@override
void init() {
  if (hasContext) {
    final theme = Theme.of(context!);
  }
}
```

### 2. Caching Context Reference

```dart
// WRONG - Context may become invalid
late final BuildContext _cachedContext;

@override
void init() {
  _cachedContext = context!; // Don't cache!
}

// CORRECT - Always access fresh
void someMethod() {
  if (hasContext) {
    final ctx = context!; // Fresh reference
  }
}
```

## Difference from globalContext

| Feature | `context` | `globalContext` |
|---------|-----------|-----------------|
| Source | Specific VM context -> Global fallback | Always global only |
| Persistence | May change with builder lifecycle | Constant throughout app |
| Use Case | General operations | Riverpod/Provider migration |

See [globalContext](global-context.md) for direct global context access.

## Related

- [hasContext](has-context.md) - Check context availability
- [requireContext()](require-context.md) - Required context with descriptive errors
- [globalContext](global-context.md) - Direct global context access
- [init-context](init-context.md) - Global context initialization
