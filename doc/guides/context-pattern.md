# Context Pattern Guide

Comprehensive guide for using BuildContext in ReactiveNotifier ViewModels, including migration patterns from Riverpod and Provider.

## Overview

ReactiveNotifier v2.12.0+ includes automatic BuildContext access for ViewModels, enabling seamless migration from other state management solutions while maintaining the core philosophy of independent ViewModel lifecycle.

## Architecture

### Context Per ViewModel Instance

- Each ViewModel gets its own isolated BuildContext (when using builders)
- Global context available for all ViewModels (via `initContext()`)
- Automatic registration/cleanup by reactive builders
- Context available when any builder is mounted

### Automatic Lifecycle Management

```dart
ReactiveViewModelBuilder<MyViewModel, MyState>(
  viewmodel: MyService.instance.notifier,
  build: (state, viewModel, keep) {
    // Context automatically registered for MyViewModel instance
    // viewModel.context is now available
    return MyWidget();
  },
)
// Context automatically cleaned up when builder disposes
```

## Usage Patterns

### 1. Global Context Setup (Recommended)

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Initialize global context for all ViewModels
    ReactiveNotifier.initContext(context);

    return MaterialApp(
      title: 'My App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}
```

### 2. Migration from Riverpod

```dart
class MigrationViewModel extends ViewModel<UserState> {
  MigrationViewModel() : super(UserState.initial());

  @override
  void init() {
    // Check if context is available for gradual migration
    if (hasGlobalContext) {
      try {
        // Access Riverpod container for gradual migration
        final container = ProviderScope.containerOf(globalContext!);
        final userData = container.read(userProvider);
        updateSilently(UserState.fromRiverpod(userData));
      } catch (e) {
        // Fallback if Riverpod access fails
        updateSilently(UserState.fallback());
      }
    } else {
      // Pure ReactiveNotifier initialization
      updateSilently(UserState.empty());
    }
  }
}
```

### 3. Theme and MediaQuery Access

```dart
class ResponsiveViewModel extends ViewModel<ResponsiveState> {
  ResponsiveViewModel() : super(ResponsiveState.initial());

  @override
  void init() {
    // Initialize with basic state first
    updateSilently(ResponsiveState.initial());

    // Use context if available
    if (hasContext) {
      _updateFromContext();
    }
  }

  void _updateFromContext() {
    // Use postFrameCallback for safe MediaQuery access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isDisposed && hasContext) {
        try {
          final mediaQuery = MediaQuery.of(requireContext('responsive design'));
          final theme = Theme.of(requireContext('theme access'));

          updateState(ResponsiveState(
            screenWidth: mediaQuery.size.width,
            screenHeight: mediaQuery.size.height,
            isDarkMode: theme.brightness == Brightness.dark,
            isTablet: mediaQuery.size.width > 600,
          ));
        } catch (e) {
          // Handle context access errors gracefully
        }
      }
    });
  }
}
```

### 4. Navigation from ViewModels

```dart
class NavigationViewModel extends ViewModel<NavigationState> {
  NavigationViewModel() : super(NavigationState.initial());

  void navigateToDetails(String itemId) {
    if (hasContext) {
      try {
        Navigator.of(requireContext('navigation')).push(
          MaterialPageRoute(
            builder: (_) => DetailsScreen(itemId: itemId),
          ),
        );
      } catch (e) {
        // Handle navigation errors
        updateState(NavigationState.error('Navigation failed: $e'));
      }
    } else {
      // Store navigation request for later
      updateState(NavigationState.pendingNavigation(itemId));
    }
  }
}
```

### 5. AsyncViewModel with waitForContext

```dart
class AsyncContextViewModel extends AsyncViewModelImpl<UserData> {
  AsyncContextViewModel() : super(
    AsyncState.initial(),
    waitForContext: true,  // Wait for context before init()
  );

  @override
  Future<UserData> init() async {
    // Context guaranteed to be available
    final theme = Theme.of(requireContext('user data'));
    final mediaQuery = MediaQuery.of(requireContext('screen info'));

    return await _fetchUserData(
      isDarkMode: theme.brightness == Brightness.dark,
      screenSize: mediaQuery.size,
    );
  }

  Future<UserData> _fetchUserData({
    required bool isDarkMode,
    required Size screenSize,
  }) async {
    // API call with context-derived parameters
    return UserData(
      name: 'User',
      prefersDarkMode: isDarkMode,
      screenInfo: '${screenSize.width}x${screenSize.height}',
    );
  }
}
```

## API Reference

### Context Access Methods

```dart
// Available in all ViewModels through ViewModelContextService mixin
BuildContext? get context;           // Nullable (falls back to global)
bool get hasContext;                 // Check any context available
BuildContext requireContext(String operation); // Required with errors

// Global context access
BuildContext? get globalContext;     // Direct global access
bool get hasGlobalContext;           // Check global context available
BuildContext requireGlobalContext(String operation); // Required global
```

### Context Safety Patterns

```dart
// SAFE: Always check availability first
if (hasContext) {
  final theme = Theme.of(context!);
  // Use context-dependent logic
}

// SAFE: Use requireContext with operation description
try {
  final mediaQuery = MediaQuery.of(requireContext('responsive layout'));
  // Use mediaQuery
} catch (e) {
  // Handle context unavailable error
}

// UNSAFE: Direct context access without checking
final theme = Theme.of(context!); // May throw if context is null
```

### Timing Considerations

```dart
// RECOMMENDED: Use postFrameCallback for MediaQuery/Theme in init()
@override
void init() {
  updateSilently(MyState.initial());

  if (hasContext) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isDisposed && hasContext) {
        // Safe to access Theme/MediaQuery here
      }
    });
  }
}

// AVOID: Direct Theme/MediaQuery access in init()
@override
void init() {
  final theme = Theme.of(context!); // May not be ready yet
}
```

## Best Practices

### 1. Graceful Degradation

Always provide fallback behavior when context is not available:

```dart
@override
void init() {
  if (hasContext) {
    _initializeWithContext();
  } else {
    _initializeWithoutContext();
  }
}

void _initializeWithContext() {
  final theme = Theme.of(context!);
  updateSilently(MyState.fromTheme(theme));
}

void _initializeWithoutContext() {
  updateSilently(MyState.defaults());
}
```

### 2. Use globalContext for Migration

```dart
// For Riverpod/Provider migration - use globalContext
if (hasGlobalContext) {
  final container = ProviderScope.containerOf(globalContext!);
  // Read from existing providers...
}

// For general widget operations - use context
if (hasContext) {
  final theme = Theme.of(context!);
  // Use theme...
}
```

### 3. Error Handling with Descriptive Messages

```dart
// GOOD: Descriptive error messages
final mediaQuery = MediaQuery.of(requireContext('responsive calculations'));
final theme = Theme.of(requireContext('color scheme detection'));
final navigator = Navigator.of(requireContext('details navigation'));

// POOR: Generic error messages
final mediaQuery = MediaQuery.of(requireContext('operation'));
```

### 4. Context Isolation

Each ViewModel has its own context. Don't share context between ViewModels:

```dart
// CORRECT: Each ViewModel uses its own context
class UserViewModel extends ViewModel<UserState> {
  void updateTheme() {
    if (hasContext) {
      final theme = Theme.of(context!); // This ViewModel's context
    }
  }
}

class SettingsViewModel extends ViewModel<SettingsState> {
  void updateTheme() {
    if (hasContext) {
      final theme = Theme.of(context!); // Different context instance
    }
  }
}
```

## Migration Strategy

### Complete Riverpod Migration Setup

```dart
// Step 1: App setup with both systems
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

// Step 2: Create hybrid ViewModels
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

### Migration Phases

1. **Phase 1: Setup**
   - Add `ReactiveNotifier.initContext()` in app root
   - Keep existing Riverpod/Provider setup

2. **Phase 2: Hybrid ViewModels**
   - Create ViewModels that read from existing providers
   - Use `globalContext` for provider access

3. **Phase 3: Gradual Migration**
   - Move logic from providers to ViewModels
   - Use `listenVM` for cross-ViewModel communication

4. **Phase 4: Cleanup**
   - Remove provider dependencies
   - Remove `globalContext` usage
   - Use pure ReactiveNotifier patterns

## Troubleshooting

### Context Not Available

**Symptom**: `hasContext` returns `false` when expected to be `true`

**Solutions**:
1. Ensure `ReactiveNotifier.initContext(context)` is called in app root
2. Verify the builder widget is mounted before accessing context
3. Use `waitForContext: true` for AsyncViewModels that need context in `init()`

### requireContext Throws StateError

**Symptom**: `requireContext()` throws with "BuildContext Required But Not Available"

**Solutions**:
1. Check `hasContext` before calling `requireContext()`
2. Move context-dependent logic to `onResume()` instead of `init()`
3. Use `postFrameCallback` for context access during widget build

### Theme/MediaQuery Access Fails

**Symptom**: `Theme.of(context!)` or `MediaQuery.of(context!)` throws

**Solutions**:
1. Wrap access in `postFrameCallback`:
   ```dart
   WidgetsBinding.instance.addPostFrameCallback((_) {
     if (hasContext) {
       final theme = Theme.of(context!);
     }
   });
   ```
2. Ensure the context has access to MaterialApp ancestors

## Summary

The ReactiveNotifier Context Pattern provides:

- **Automatic Context Management**: No manual setup required
- **Isolated Context Per ViewModel**: No shared state between ViewModels
- **Migration Support**: Seamless transition from Riverpod/Provider
- **Safe Access Patterns**: Built-in error handling and validation
- **Backward Compatibility**: Existing code works unchanged
- **Memory Leak Prevention**: Automatic cleanup on disposal

## Related Documentation

- [Context Access Reference](../features/context-access.md) - API reference
- [context](../features/context/context.md) - context getter
- [globalContext](../features/context/global-context.md) - Global context access
- [initContext](../features/context/init-context.md) - Global initialization
- [waitForContext](../features/context/wait-for-context.md) - AsyncViewModel parameter
- [ReactiveContextBuilder](../features/builders/reactive-context-builder.md) - Context builder widget
