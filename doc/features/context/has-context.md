# hasContext Getter

## Signature

```dart
bool get hasContext
```

## Type

Returns `bool` - `true` if a BuildContext is available for this ViewModel, `false` otherwise.

## Description

The `hasContext` getter provides a safe way to check whether a BuildContext is available before attempting to access it. It checks both the specific ViewModel context and the global context.

### Source Implementation

```dart
// From lib/src/context/viewmodel_context_notifier.dart (line 222)
bool get hasContext => ViewModelContextNotifier.hasContextForViewModel(this);
```

### Internal Check Logic

```dart
// From ViewModelContextNotifier.hasContextForViewModel()
static bool hasContextForViewModel(Object? viewModel) {
  if (viewModel == null) {
    return _lastRegisteredContext != null || _globalContext != null;
  }
  // Check if specific ViewModel has context or if global context is available
  return _contexts.containsKey(viewModel.hashCode) || _globalContext != null;
}
```

## Usage Example

### Basic Pattern

```dart
class ResponsiveViewModel extends ViewModel<ResponsiveState> {
  ResponsiveViewModel() : super(ResponsiveState.initial());

  void updateLayout() {
    if (hasContext) {
      // Safe to access context
      final mediaQuery = MediaQuery.of(context!);
      _handleScreenSize(mediaQuery.size);
    } else {
      // Fallback behavior when context unavailable
      _useDefaultLayout();
    }
  }
}
```

### Conditional Initialization

```dart
class ThemeViewModel extends ViewModel<ThemeState> {
  ThemeViewModel() : super(ThemeState.system());

  @override
  void init() {
    if (hasContext) {
      _initializeWithContext();
    } else {
      _initializeWithDefaults();
    }
  }

  void _initializeWithContext() {
    final theme = Theme.of(context!);
    updateSilently(ThemeState(
      isDarkMode: theme.brightness == Brightness.dark,
      primaryColor: theme.primaryColor,
    ));
  }

  void _initializeWithDefaults() {
    updateSilently(ThemeState.system());
  }
}
```

### Safe MediaQuery Access

```dart
class LayoutViewModel extends ViewModel<LayoutState> {
  LayoutViewModel() : super(LayoutState.initial());

  @override
  void init() {
    updateSilently(LayoutState.initial());
    _updateFromContext();
  }

  void _updateFromContext() {
    if (hasContext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Double-check after frame callback
        if (!isDisposed && hasContext) {
          try {
            final mediaQuery = MediaQuery.of(context!);
            updateState(LayoutState(
              screenWidth: mediaQuery.size.width,
              screenHeight: mediaQuery.size.height,
              isTablet: mediaQuery.size.width > 600,
            ));
          } catch (e) {
            // Handle edge cases gracefully
          }
        }
      });
    }
  }
}
```

## When hasContext Returns true

| Condition | Returns |
|-----------|---------|
| After `ReactiveNotifier.initContext()` called | `true` |
| After any ReactiveBuilder mounts for this VM | `true` |
| Before any builder mounts (no global init) | `false` |
| After all builders dispose (no global init) | `false` |
| Global context initialized but no specific builder | `true` |

## Best Practices

### 1. Always Check Before Accessing Context

```dart
// CORRECT - Safe pattern
if (hasContext) {
  final theme = Theme.of(context!);
  // Use theme...
}

// INCORRECT - May throw
final theme = Theme.of(context!); // Unsafe!
```

### 2. Provide Fallback Logic

```dart
@override
void init() {
  if (hasContext) {
    _initializeWithTheme();
  } else {
    _initializeWithDefaults();
  }
}
```

### 3. Combine with isDisposed Check

```dart
void refreshLayout() {
  if (!isDisposed && hasContext) {
    final mediaQuery = MediaQuery.of(context!);
    updateState(LayoutState.fromMediaQuery(mediaQuery));
  }
}
```

### 4. Use in postFrameCallback

```dart
if (hasContext) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!isDisposed && hasContext) {
      // Safe MediaQuery/Theme access
    }
  });
}
```

## Common Patterns

### Graceful Degradation

```dart
class ConfigViewModel extends ViewModel<AppConfig> {
  @override
  void init() {
    if (hasContext) {
      try {
        final theme = Theme.of(context!);
        updateSilently(AppConfig.fromTheme(theme));
      } catch (e) {
        updateSilently(AppConfig.defaults());
      }
    } else {
      updateSilently(AppConfig.defaults());
    }
  }
}
```

### Navigation Guard

```dart
void navigateToDetails(String id) {
  if (hasContext) {
    Navigator.of(context!).push(
      MaterialPageRoute(builder: (_) => DetailsScreen(id: id)),
    );
  } else {
    // Store for later or handle differently
    _pendingNavigation = id;
  }
}
```

## Related

- [context](context.md) - The actual context getter
- [requireContext()](require-context.md) - Required context with errors
- [hasGlobalContext](has-global-context.md) - Check global context availability
- [init-context](init-context.md) - Global context initialization
