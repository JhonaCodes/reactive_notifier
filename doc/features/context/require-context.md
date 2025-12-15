# requireContext() Method

## Signature

```dart
BuildContext requireContext([String? operation])
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `operation` | `String?` | No | Descriptive name for the operation requiring context |

## Return Type

`BuildContext` - The current BuildContext, guaranteed to be non-null.

## Throws

`StateError` - If no BuildContext is available, with a descriptive error message including:
- The operation name (if provided)
- The ViewModel type
- Common causes
- Suggested solutions

## Description

The `requireContext()` method provides a safe way to access BuildContext when it is absolutely required for an operation. Unlike the nullable `context` getter, this method throws a descriptive error if context is unavailable, making debugging easier.

### Source Implementation

```dart
// From lib/src/context/viewmodel_context_notifier.dart (lines 235-262)
BuildContext requireContext([String? operation]) {
  final currentContext = context;
  if (currentContext == null) {
    throw StateError('''
BuildContext Required But Not Available
Operation: ${operation ?? 'ViewModel operation'}
ViewModel: $runtimeType

Context is not available when:
  1. No ReactiveBuilder widgets are currently mounted
  2. ViewModel.init() runs before any builder is active
  3. All builders have been disposed

Solutions:
  1. Check hasContext first: if (hasContext) { ... }
  2. Move context logic to onResume() method
  3. Make context usage optional with null safety

Context is automatically provided by:
  - ReactiveBuilder<T>
  - ReactiveViewModelBuilder<VM,T>
  - ReactiveAsyncBuilder<VM,T>
''');
  }
  return currentContext;
}
```

## Usage Example

### Basic Usage

```dart
class UserViewModel extends ViewModel<UserState> {
  UserViewModel() : super(UserState.guest());

  void showUserDialog() {
    // Will throw descriptive error if context unavailable
    final ctx = requireContext('showing user dialog');

    showDialog(
      context: ctx,
      builder: (dialogContext) => UserDialog(user: data),
    );
  }
}
```

### With Error Handling

```dart
class NavigationViewModel extends ViewModel<NavigationState> {
  void navigateToDetails(String itemId) {
    try {
      final ctx = requireContext('navigation to details');
      Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (_) => DetailsScreen(itemId: itemId),
        ),
      );
    } on StateError catch (e) {
      // Handle context unavailable gracefully
      updateState(NavigationState.pendingNavigation(itemId));
    }
  }
}
```

### Descriptive Operation Names

```dart
class ResponsiveViewModel extends ViewModel<ResponsiveState> {
  void updateResponsiveLayout() {
    // Use descriptive operation names for better error messages
    final mediaQuery = MediaQuery.of(
      requireContext('responsive layout calculation')
    );

    updateState(ResponsiveState(
      screenWidth: mediaQuery.size.width,
      isTablet: mediaQuery.size.width > 600,
    ));
  }

  void applyTheme() {
    final theme = Theme.of(
      requireContext('theme application')
    );

    updateState(data.copyWith(
      isDarkMode: theme.brightness == Brightness.dark,
    ));
  }
}
```

### With postFrameCallback

```dart
class LayoutViewModel extends ViewModel<LayoutState> {
  @override
  void init() {
    updateSilently(LayoutState.initial());

    if (hasContext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isDisposed && hasContext) {
          try {
            final mediaQuery = MediaQuery.of(
              requireContext('layout initialization')
            );
            updateState(LayoutState.fromMediaQuery(mediaQuery));
          } catch (e) {
            // Fallback if context access fails
            updateState(LayoutState.defaults());
          }
        }
      });
    }
  }
}
```

## Best Practices

### 1. Use Descriptive Operation Names

```dart
// GOOD - Descriptive error messages
final ctx = requireContext('loading user preferences');
final ctx = requireContext('showing confirmation dialog');
final ctx = requireContext('navigating to settings');

// BAD - Generic error messages
final ctx = requireContext(); // Unclear what failed
final ctx = requireContext('operation'); // Not helpful
```

### 2. Wrap in Try-Catch When Appropriate

```dart
void performContextOperation() {
  try {
    final theme = Theme.of(requireContext('theme access'));
    // Use theme...
  } on StateError catch (e) {
    // Handle gracefully
    _useFallbackTheme();
  }
}
```

### 3. Check hasContext First for Optional Operations

```dart
// For required operations - use requireContext
void showMustShowDialog() {
  showDialog(
    context: requireContext('critical dialog'),
    builder: (_) => CriticalDialog(),
  );
}

// For optional operations - check hasContext first
void showOptionalToast() {
  if (hasContext) {
    ScaffoldMessenger.of(context!).showSnackBar(...);
  }
}
```

### 4. Combine with postFrameCallback for Theme/MediaQuery

```dart
@override
void init() {
  if (hasContext) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isDisposed && hasContext) {
        final mediaQuery = MediaQuery.of(
          requireContext('responsive design')
        );
        // Use mediaQuery...
      }
    });
  }
}
```

## Error Message Example

When `requireContext()` throws, the error message provides helpful context:

```
StateError: BuildContext Required But Not Available

Operation: responsive layout calculation
ViewModel: ResponsiveViewModel

Context is not available when:
  1. No ReactiveBuilder widgets are currently mounted
  2. ViewModel.init() runs before any builder is active
  3. All builders have been disposed

Solutions:
  1. Check hasContext first: if (hasContext) { ... }
  2. Move context logic to onResume() method
  3. Make context usage optional with null safety

Context is automatically provided by:
  - ReactiveBuilder<T>
  - ReactiveViewModelBuilder<VM,T>
  - ReactiveAsyncBuilder<VM,T>
```

## When to Use

| Scenario | Use `requireContext()` | Use `context` + null check |
|----------|------------------------|---------------------------|
| Context is absolutely required | Yes | No |
| Want descriptive error messages | Yes | No |
| Operation is optional | No | Yes |
| Debugging context issues | Yes | No |

## Related

- [context](context.md) - Nullable context getter
- [hasContext](has-context.md) - Check context availability
- [requireGlobalContext()](require-global-context.md) - Required global context
- [init-context](init-context.md) - Global context initialization
