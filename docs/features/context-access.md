# Context Access in ViewModels

## Overview

ReactiveNotifier provides automatic BuildContext access within ViewModels through the `ViewModelContextService` mixin. This feature enables ViewModels to access context-dependent Flutter services like `Theme`, `MediaQuery`, `Localizations`, and facilitates gradual migration from other state management solutions like Riverpod or Provider.

### Why ViewModels Need BuildContext Access

In traditional Flutter architecture, ViewModels are business logic containers that should ideally be independent of the UI layer. However, there are legitimate scenarios where ViewModels need access to BuildContext:

1. **Theme-Aware Logic**: ViewModels that need to make decisions based on current theme (dark/light mode)
2. **Responsive Design**: Logic that depends on screen dimensions via MediaQuery
3. **Localization**: Accessing translated strings within business logic
4. **Migration Scenarios**: Gradual migration from Riverpod/Provider where existing code accesses context
5. **Platform Services**: Accessing InheritedWidgets or services registered in the widget tree

### Architecture Overview

```
+------------------+     +---------------------------+     +------------------+
|                  |     |                           |     |                  |
|  ReactiveBuilder |---->| ViewModelContextNotifier  |<----| ViewModel<T>     |
|  Widgets         |     | (Context Registry)        |     | AsyncViewModelImpl|
|                  |     |                           |     |                  |
+------------------+     +---------------------------+     +------------------+
        |                          ^                              |
        |                          |                              |
        v                          |                              v
   Registers context         Stores contexts            Accesses context via
   when mounting             per ViewModel              ViewModelContextService
```

---

## Global Context Initialization

### ReactiveNotifier.initContext(context)

The recommended approach for enabling context access across all ViewModels is to initialize a global context early in your application lifecycle.

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

### When to Call initContext

| Scenario | Location | Recommendation |
|----------|----------|----------------|
| Standard apps | `MyApp.build()` | Before MaterialApp |
| Apps with splash screens | After splash completes | When main UI is ready |
| Multi-window apps | Each window's root widget | Per window context |
| Testing | `setUp()` block | With mock context |

### What Happens When initContext is Called

1. **Context Registration**: The provided BuildContext is stored in `ViewModelContextNotifier._globalContext`
2. **ViewModel Reinitialization**: Any existing ViewModels with `waitForContext: true` that were waiting for context are automatically reinitialized
3. **Immediate Availability**: All ViewModels created after this call have immediate access to context via `hasContext`, `context`, and `requireContext()`

```dart
// Source: lib/src/notifier/reactive_notifier.dart (lines 1399-1452)
static void initContext(BuildContext context) {
  // Register context globally using the ContextNotifier system
  ViewModelContextNotifier.registerGlobalContext(context);

  // Check for ViewModels that were waiting for context and reinitialize them
  for (var instance in _instances.values) {
    if (instance is ReactiveNotifier) {
      final notifier = instance.notifier;
      if (notifier != null && notifier is ViewModelContextService) {
        try {
          final dynamic asyncVM = notifier;
          asyncVM.reinitializeWithContext();
        } catch (e) {
          // Silently ignore for ViewModel<T> which don't have this method
        }
      }
    }
  }
}
```

---

## Context Access in ViewModels

All ViewModels automatically inherit context access through the `ViewModelContextService` mixin:

```dart
// Source: lib/src/viewmodel/viewmodel_impl.dart (line 17-18)
abstract class ViewModel<T> extends ChangeNotifier
    with HelperNotifier, ViewModelContextService {

// Source: lib/src/viewmodel/async_viewmodel_impl.dart (line 36-37)
abstract class AsyncViewModelImpl<T> extends ChangeNotifier
    with HelperNotifier, ViewModelContextService {
```

### context Getter (Nullable)

Returns the current BuildContext if available, otherwise returns `null`.

```dart
// Source: lib/src/context/viewmodel_context_notifier.dart (lines 217-218)
BuildContext? get context =>
    ViewModelContextNotifier.getContextForViewModel(this);
```

**Usage:**

```dart
class ThemeAwareViewModel extends ViewModel<ThemeState> {
  ThemeAwareViewModel() : super(ThemeState.initial());

  @override
  void init() {
    // Safely access context
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

### hasContext Getter

Returns `true` if a BuildContext is available for this ViewModel, `false` otherwise.

```dart
// Source: lib/src/context/viewmodel_context_notifier.dart (line 222)
bool get hasContext => ViewModelContextNotifier.hasContextForViewModel(this);
```

**Usage:**

```dart
class ResponsiveViewModel extends ViewModel<ResponsiveState> {
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

### requireContext([operation])

Returns the BuildContext or throws a descriptive `StateError` if unavailable. The optional `operation` parameter provides context in error messages for debugging.

```dart
// Source: lib/src/context/viewmodel_context_notifier.dart (lines 235-262)
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
''');
  }
  return currentContext;
}
```

**Usage:**

```dart
class UserViewModel extends ViewModel<UserState> {
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

---

## Global Context Access

For scenarios where you need guaranteed access to a persistent context (especially during migration from Riverpod/Provider), use the global context accessors.

### globalContext Getter

Returns the global context initialized via `ReactiveNotifier.initContext()`, bypassing any specific ViewModel context.

```dart
// Source: lib/src/context/viewmodel_context_notifier.dart (lines 281-282)
BuildContext? get globalContext =>
    ViewModelContextNotifier.getGlobalContext();
```

### hasGlobalContext Getter

Returns `true` if a global context has been initialized.

```dart
// Source: lib/src/context/viewmodel_context_notifier.dart (lines 287)
bool get hasGlobalContext => ViewModelContextNotifier.hasGlobalContext();
```

### requireGlobalContext([operation])

Returns the global BuildContext or throws a descriptive `StateError` with instructions on how to initialize it.

```dart
// Source: lib/src/context/viewmodel_context_notifier.dart (lines 302-334)
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
''');
  }
  return ctx;
}
```

---

## Difference Between context vs globalContext

| Feature | `context` | `globalContext` |
|---------|-----------|-----------------|
| **Source** | Specific ViewModel context (falls back to global) | Always global context only |
| **Persistence** | May change when builders mount/unmount | Remains constant throughout app lifecycle |
| **Availability** | After any builder mounts OR global init | Only after `ReactiveNotifier.initContext()` |
| **Primary Use Case** | General widget operations | Riverpod/Provider migration |
| **Fallback Behavior** | Falls back to global context automatically | No fallback (null if not initialized) |

### Context Resolution Order

```
context getter:
  1. Check for specific ViewModel context (registered by builder)
  2. Fall back to global context (if available)
  3. Return null if neither available

globalContext getter:
  1. Return global context directly
  2. Return null if not initialized
```

### When to Use Each

**Use `context`** for:
- Theme access in general ViewModels
- MediaQuery access for responsive logic
- Localizations access
- Most everyday context needs

**Use `globalContext`** for:
- Riverpod migration where you need `ProviderScope.containerOf()`
- Provider migration where you need `Provider.of()` without `listen`
- Scenarios requiring context that persists across navigation
- When you specifically need the app-level context

```dart
// Riverpod migration example using globalContext
class MigrationViewModel extends ViewModel<MigrationState> {
  @override
  void init() {
    if (hasGlobalContext) {
      // Global context persists throughout app lifecycle
      final container = ProviderScope.containerOf(globalContext!);
      final userData = container.read(userProvider);
      updateSilently(MigrationState.fromRiverpod(userData));
    }
  }

  void refreshFromRiverpod() {
    // Always available after initContext, never loses reference
    final container = ProviderScope.containerOf(
      requireGlobalContext('Riverpod refresh')
    );
    final userData = container.read(userProvider);
    updateState(MigrationState.fromRiverpod(userData));
  }
}
```

---

## waitForContext Parameter in AsyncViewModelImpl

The `waitForContext` parameter allows AsyncViewModels to delay initialization until a BuildContext becomes available.

### Constructor Signature

```dart
// Source: lib/src/viewmodel/async_viewmodel_impl.dart (lines 49-68)
AsyncViewModelImpl(this._state,
    {this.loadOnInit = true, this.waitForContext = false})
    : super() {
  if (loadOnInit) {
    if (waitForContext && !hasContext) {
      // Wait for context - stay in initial state
      hasInitializedListenerExecution = false;
    } else {
      // Initialize immediately
      _initializeAsync();
      hasInitializedListenerExecution = true;
    }
  }
}
```

### Behavior

| `waitForContext` | `hasContext` on creation | Behavior |
|------------------|--------------------------|----------|
| `false` (default) | Any | Initializes immediately |
| `true` | `true` | Initializes immediately |
| `true` | `false` | Stays in `AsyncState.initial()` until context available |

### Usage Example

```dart
class ThemeAwareDataViewModel extends AsyncViewModelImpl<ThemeBasedData> {
  ThemeAwareDataViewModel() : super(
    AsyncState.initial(),
    loadOnInit: true,
    waitForContext: true,  // Wait for context before init()
  );

  @override
  Future<ThemeBasedData> init() async {
    // This only runs after BuildContext becomes available
    final theme = Theme.of(requireContext('theme-based data loading'));
    final isDark = theme.brightness == Brightness.dark;

    return await repository.loadData(darkMode: isDark);
  }
}
```

### When waitForContext Triggers Initialization

Context becomes available in these scenarios:

1. **Global Context Initialization**: When `ReactiveNotifier.initContext()` is called
2. **Builder Mount**: When a `ReactiveAsyncBuilder` or similar builder mounts with this ViewModel
3. **Manual Reinitialize**: When `reinitializeWithContext()` is called explicitly

---

## reinitializeWithContext() Method

This method allows ViewModels to reinitialize when context becomes available after initial creation.

### ViewModel Implementation

```dart
// Source: lib/src/viewmodel/viewmodel_impl.dart (lines 136-157)
void reinitializeWithContext() {
  if (_initializedWithoutContext && hasContext && !_disposed) {
    // Reset flags and perform full initialization
    _initializedWithoutContext = false;
    _initialized = false;

    // Now perform safe initialization with context
    _safeInitialization();
    hasInitializedListenerExecution = true;
  }
}
```

### AsyncViewModelImpl Implementation

```dart
// Source: lib/src/viewmodel/async_viewmodel_impl.dart (lines 767-793)
void reinitializeWithContext() {
  bool shouldReinitialize =
      (_initializedWithoutContext && hasContext && !_disposed) ||
          (waitForContext && !_initialized && hasContext && !_disposed);

  if (shouldReinitialize) {
    _initializedWithoutContext = false;
    _initialized = false;

    // Now perform async initialization with context
    _initializeAsync();
  }
}
```

### When Reinitialize is Called

1. **Automatic**: When `ReactiveNotifier.initContext()` is called, all existing ViewModels are checked
2. **By Builders**: When a ReactiveBuilder mounts and registers context for its ViewModel
3. **Manual**: Can be called explicitly if needed

### Example: Delayed Theme Initialization

```dart
class DelayedThemeViewModel extends ViewModel<ThemeConfig> {
  DelayedThemeViewModel() : super(ThemeConfig.defaults());

  @override
  void init() {
    if (hasContext) {
      // Full initialization with context
      final theme = Theme.of(context!);
      updateSilently(ThemeConfig.fromTheme(theme));
    } else {
      // Partial initialization - will be reinitialized later
      updateSilently(ThemeConfig.defaults());
    }
  }

  // This is called automatically when context becomes available
  // if the ViewModel was initially created without context
}
```

---

## Migration Patterns

### Riverpod to ReactiveNotifier Migration

```dart
// Before (Riverpod)
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    return Text(user.name);
  }
}

// After (ReactiveNotifier with gradual migration)
mixin UserService {
  static final ReactiveNotifier<UserViewModel> userState =
      ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel.empty());

  @override
  void init() {
    if (hasGlobalContext) {
      // Read from existing Riverpod provider during migration
      final container = ProviderScope.containerOf(globalContext!);
      final riverpodUser = container.read(userProvider);
      updateSilently(UserModel.fromRiverpod(riverpodUser));
    }
  }

  // Sync from Riverpod when needed
  void syncFromRiverpod() {
    if (hasGlobalContext) {
      final container = ProviderScope.containerOf(globalContext!);
      final riverpodUser = container.read(userProvider);
      updateState(UserModel.fromRiverpod(riverpodUser));
    }
  }
}

// Widget using ReactiveNotifier
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveViewModelBuilder<UserViewModel, UserModel>(
      viewmodel: UserService.userState.notifier,
      build: (user, viewmodel, keep) => Text(user.name),
    );
  }
}
```

### Provider to ReactiveNotifier Migration

```dart
// Before (Provider)
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    return Text(user.name);
  }
}

// After (ReactiveNotifier with gradual migration)
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel.empty());

  @override
  void init() {
    if (hasGlobalContext) {
      // Read from existing Provider during migration
      final providerUser = Provider.of<UserModel>(
        globalContext!,
        listen: false,
      );
      updateSilently(providerUser);
    }
  }
}
```

### Migration Strategy Recommendations

1. **Initialize Global Context First**
   ```dart
   class MyApp extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       ReactiveNotifier.initContext(context);
       return ProviderScope(  // Keep existing Riverpod/Provider
         child: MaterialApp(...),
       );
     }
   }
   ```

2. **Migrate ViewModels Gradually**
   - Start with leaf ViewModels (no dependencies)
   - Use context access to read from existing providers
   - Migrate dependent ViewModels last

3. **Remove Provider/Riverpod Dependencies**
   - Once a ViewModel is fully migrated, remove context-based reads
   - Replace with native ReactiveNotifier patterns (listenVM, related states)

---

## Theme and MediaQuery Access Patterns

### Theme Access Pattern

```dart
class ThemeAwareViewModel extends ViewModel<ThemeState> {
  ThemeAwareViewModel() : super(ThemeState.initial());

  @override
  void init() {
    _updateTheme();
  }

  void _updateTheme() {
    if (hasContext) {
      // Use postFrameCallback for safe access during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isDisposed && hasContext) {
          try {
            final theme = Theme.of(requireContext('theme access'));
            updateState(ThemeState(
              isDarkMode: theme.brightness == Brightness.dark,
              primaryColor: theme.primaryColor,
              textTheme: theme.textTheme,
            ));
          } catch (e) {
            // Fallback if Theme access fails
            updateState(ThemeState.fallback());
          }
        }
      });
    }
  }

  // Call when theme changes (e.g., from settings)
  void refreshTheme() {
    _updateTheme();
  }
}
```

### MediaQuery Access Pattern (Responsive Design)

```dart
class ResponsiveViewModel extends ViewModel<ResponsiveState> {
  ResponsiveViewModel() : super(ResponsiveState.initial());

  @override
  void init() {
    _updateResponsiveState();
  }

  void _updateResponsiveState() {
    if (hasContext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isDisposed && hasContext) {
          try {
            final mediaQuery = MediaQuery.of(requireContext('responsive design'));
            final size = mediaQuery.size;

            updateState(ResponsiveState(
              screenWidth: size.width,
              screenHeight: size.height,
              isTablet: size.width > 600,
              isDesktop: size.width > 1200,
              orientation: mediaQuery.orientation,
              devicePixelRatio: mediaQuery.devicePixelRatio,
            ));
          } catch (e) {
            // Fallback for default dimensions
            updateState(ResponsiveState.mobile());
          }
        }
      });
    }
  }
}
```

### Localizations Access Pattern

```dart
class LocalizedViewModel extends ViewModel<LocalizedState> {
  LocalizedViewModel() : super(LocalizedState.initial());

  @override
  void init() {
    if (hasContext) {
      _loadLocalizations();
    }
  }

  void _loadLocalizations() {
    if (hasContext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isDisposed && hasContext) {
          final locale = Localizations.localeOf(context!);
          final strings = AppLocalizations.of(context!);

          updateState(LocalizedState(
            currentLocale: locale,
            greeting: strings?.greeting ?? 'Hello',
            // ... other localized strings
          ));
        }
      });
    }
  }
}
```

---

## Complete Usage Examples

### Example 1: Full App Setup with Global Context

```dart
// main.dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize global context for all ViewModels
    ReactiveNotifier.initContext(context);

    return MaterialApp(
      title: 'ReactiveNotifier Demo',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

// services/user_service.dart
mixin UserService {
  static final ReactiveNotifier<UserViewModel> userState =
      ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

// viewmodels/user_viewmodel.dart
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel.guest());

  @override
  void init() {
    // Context is available immediately after initContext
    if (hasContext) {
      final theme = Theme.of(context!);
      // Use theme information if needed
    }

    // Initialize user state
    updateSilently(UserModel.guest());
  }
}

// pages/home_page.dart
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ReactiveViewModelBuilder<UserViewModel, UserModel>(
        viewmodel: UserService.userState.notifier,
        build: (user, viewmodel, keep) {
          return Center(
            child: Text('Welcome, ${user.name}!'),
          );
        },
      ),
    );
  }
}
```

### Example 2: AsyncViewModel with waitForContext

```dart
// viewmodels/theme_data_viewmodel.dart
class ThemeDataViewModel extends AsyncViewModelImpl<ThemeBasedConfig> {
  ThemeDataViewModel() : super(
    AsyncState.initial(),
    loadOnInit: true,
    waitForContext: true,  // Wait for context
  );

  @override
  Future<ThemeBasedConfig> init() async {
    // This only executes after context is available
    final theme = Theme.of(requireContext('loading theme config'));
    final isDark = theme.brightness == Brightness.dark;

    // Load configuration based on theme
    final config = await ConfigRepository.loadConfig(darkMode: isDark);
    return ThemeBasedConfig.fromConfig(config);
  }
}

// Usage in widget
class ConfigWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveAsyncBuilder<ThemeDataViewModel, ThemeBasedConfig>(
      notifier: ConfigService.configState.notifier,
      onData: (config, viewmodel, keep) {
        return ConfigDisplay(config: config);
      },
      onLoading: () => const CircularProgressIndicator(),
      onError: (error, stack) => ErrorWidget(error: error),
    );
  }
}
```

### Example 3: Safe Context Access with Error Handling

```dart
class SafeContextViewModel extends ViewModel<SafeState> {
  SafeContextViewModel() : super(SafeState.initial());

  @override
  void init() {
    _initializeWithContextSafety();
  }

  void _initializeWithContextSafety() {
    // Check availability first
    if (hasContext) {
      _handleWithContext();
    } else {
      _handleWithoutContext();
    }
  }

  void _handleWithContext() {
    try {
      final theme = Theme.of(requireContext('theme access'));
      final mediaQuery = MediaQuery.of(requireContext('media query'));

      updateSilently(SafeState(
        themeMode: theme.brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        screenSize: mediaQuery.size,
        isContextAvailable: true,
      ));
    } catch (e) {
      // Handle context access errors gracefully
      _handleWithoutContext();
    }
  }

  void _handleWithoutContext() {
    // Fallback logic when context unavailable
    updateSilently(SafeState.fallback());
  }

  // Public method to refresh with current context
  void refreshWithContext() {
    _initializeWithContextSafety();
  }
}
```

---

## Best Practices and Safety Patterns

### 1. Always Check Context Availability

```dart
// Good - Check before access
if (hasContext) {
  final theme = Theme.of(context!);
  // Use theme...
}

// Bad - Direct access without check
final theme = Theme.of(context!);  // May throw if context is null
```

### 2. Use postFrameCallback for MediaQuery Access

```dart
// Good - Safe MediaQuery access
void _updateScreenSize() {
  if (hasContext) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isDisposed && hasContext) {
        final mediaQuery = MediaQuery.of(context!);
        // Use mediaQuery...
      }
    });
  }
}

// Bad - Direct access in init (may fail during build)
@override
void init() {
  final mediaQuery = MediaQuery.of(context!);  // May fail
}
```

### 3. Provide Fallback Values

```dart
class ConfigViewModel extends ViewModel<AppConfig> {
  @override
  void init() {
    if (hasContext) {
      try {
        final theme = Theme.of(context!);
        updateSilently(AppConfig.fromTheme(theme));
      } catch (e) {
        updateSilently(AppConfig.defaults());  // Fallback
      }
    } else {
      updateSilently(AppConfig.defaults());  // Fallback
    }
  }
}
```

### 4. Use Descriptive Operation Names in requireContext

```dart
// Good - Descriptive error messages
final ctx = requireContext('loading user preferences');
final ctx = requireContext('showing confirmation dialog');
final ctx = requireContext('navigating to settings');

// Bad - No operation context
final ctx = requireContext();  // Generic error message
```

### 5. Use globalContext for Migration, context for General Access

```dart
class MigrationViewModel extends ViewModel<MigrationState> {
  @override
  void init() {
    // For Riverpod/Provider migration - use globalContext
    if (hasGlobalContext) {
      final container = ProviderScope.containerOf(globalContext!);
      // Read from existing providers...
    }
  }

  void showDialog() {
    // For general widget operations - use context
    if (hasContext) {
      showDialog(context: context!, builder: ...);
    }
  }
}
```

### 6. Clean Up Context Dependencies During Disposal

Context is automatically cleaned up by the `ViewModelContextNotifier` when builders unmount. However, ensure your ViewModels don't hold references to context-derived objects after disposal:

```dart
class CleanContextViewModel extends ViewModel<CleanState> {
  ThemeData? _cachedTheme;  // Don't cache BuildContext itself

  @override
  void init() {
    if (hasContext) {
      // Cache derived data, not the context
      _cachedTheme = Theme.of(context!);
    }
  }

  @override
  void dispose() {
    _cachedTheme = null;  // Clean up cached theme data
    super.dispose();
  }
}
```

### 7. Handle Context Unavailability Gracefully

```dart
class GracefulViewModel extends ViewModel<GracefulState> {
  @override
  void init() {
    updateSilently(GracefulState.loading());

    if (hasContext) {
      _initializeWithContext();
    } else {
      // Schedule initialization for when context becomes available
      updateSilently(GracefulState.waitingForContext());
    }
  }

  @override
  void reinitializeWithContext() {
    super.reinitializeWithContext();
    // Additional initialization logic when context arrives
    if (data.isWaitingForContext) {
      _initializeWithContext();
    }
  }

  void _initializeWithContext() {
    final theme = Theme.of(context!);
    updateState(GracefulState.ready(isDarkMode: theme.brightness == Brightness.dark));
  }
}
```

---

## Context Lifecycle Summary

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
        |                          |                          |
        v                          v                          v
+-------------------+     +---------------------+     +------------------+
| hasContext = true |     | context returns     |     | Falls back to    |
| hasGlobalContext  |     | specific or global  |     | global context   |
| = true            |     |                     |     | if available     |
+-------------------+     +---------------------+     +------------------+
```

---

## Troubleshooting

### Context Not Available

**Symptom**: `hasContext` returns `false` when expected to be `true`

**Solutions**:
1. Ensure `ReactiveNotifier.initContext(context)` is called in your app root
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
2. Ensure the context has access to MaterialApp (for Theme) or MediaQuery ancestors

### reinitializeWithContext Not Called

**Symptom**: ViewModel doesn't reinitialize when context becomes available

**Solutions**:
1. Verify `ReactiveNotifier.initContext()` is called
2. Check that the ViewModel implements `ViewModelContextService` (automatic for ViewModel and AsyncViewModelImpl)
3. Ensure the ViewModel was created without context initially (`_initializedWithoutContext = true`)
