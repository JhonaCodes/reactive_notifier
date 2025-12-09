# ReactiveNotifier.initContext() Static Method

## Signature

```dart
static void initContext(BuildContext context)
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `context` | `BuildContext` | Yes | The BuildContext to register globally for all ViewModels |

## Return Type

`void`

## Description

The `initContext()` static method initializes a global BuildContext that becomes available to all ViewModels throughout the application lifecycle. This is the recommended approach for enabling context access across all ViewModels and is essential for migration scenarios from Riverpod or Provider.

### Source Implementation

```dart
// From lib/src/notifier/reactive_notifier.dart (lines 1564-1614)
static void initContext(BuildContext context) {
  // Register context globally using the ContextNotifier system
  ViewModelContextNotifier.registerGlobalContext(context);

  // Check for ViewModels that were waiting for context and reinitialize them
  int reinitializedCount = 0;
  for (var instance in _instances.values) {
    if (instance is ReactiveNotifier) {
      final notifier = instance.notifier;

      // Check if the ViewModel has a reinitializeWithContext method
      if (notifier != null && notifier is ViewModelContextService) {
        try {
          final dynamic asyncVM = notifier;
          asyncVM.reinitializeWithContext();
          reinitializedCount++;
        } catch (e) {
          // Silently ignore for ViewModels without this method
        }
      }
    }
  }
}
```

## What Happens When Called

1. **Context Registration**: The provided BuildContext is stored in `ViewModelContextNotifier._globalContext`
2. **ViewModel Reinitialization**: All existing ViewModels with `waitForContext: true` that were waiting for context are automatically reinitialized
3. **Immediate Availability**: All ViewModels created after this call have immediate access to context via `hasContext`, `context`, `hasGlobalContext`, `globalContext`

## Usage Example

### Basic App Setup

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

### With Riverpod (Migration)

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Builder(
        builder: (innerContext) {
          // Initialize with context that has access to ProviderScope
          ReactiveNotifier.initContext(innerContext);
          return MaterialApp(
            home: HomePage(),
          );
        },
      ),
    );
  }
}
```

### With Provider (Migration)

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<UserService>(create: (_) => UserService()),
        // ... other providers
      ],
      child: Builder(
        builder: (innerContext) {
          // Initialize with context that has access to providers
          ReactiveNotifier.initContext(innerContext);
          return MaterialApp(
            home: HomePage(),
          );
        },
      ),
    );
  }
}
```

### After Splash Screen

```dart
class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Perform splash screen operations...
    await Future.delayed(Duration(seconds: 2));

    // Then navigate to main app
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (mainContext) {
          // Initialize context when main UI is ready
          ReactiveNotifier.initContext(mainContext);
          return HomePage();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SplashWidget();
}
```

## When to Call initContext

| Scenario | Location | Recommendation |
|----------|----------|----------------|
| Standard apps | `MyApp.build()` | Before MaterialApp |
| Apps with splash screens | After splash completes | When main UI is ready |
| Multi-window apps | Each window's root widget | Per window context |
| Testing | `setUp()` block | With mock context |
| Riverpod migration | Inside ProviderScope Builder | After ProviderScope |
| Provider migration | Inside MultiProvider Builder | After providers setup |

## Best Practices

### 1. Call Early in App Lifecycle

```dart
// RECOMMENDED - In app root
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ReactiveNotifier.initContext(context); // First thing
    return MaterialApp(...);
  }
}
```

### 2. Use Builder for Migration Scenarios

```dart
// RECOMMENDED - Ensures providers are accessible
return ProviderScope(
  child: Builder(
    builder: (innerContext) {
      ReactiveNotifier.initContext(innerContext);
      return MaterialApp(...);
    },
  ),
);
```

### 3. Call Only Once

```dart
// The context is registered globally - calling multiple times
// will just update the reference to the new context
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ReactiveNotifier.initContext(context); // OK
    return MaterialApp(...);
  }
}

// If widget rebuilds, it's safe to call again
// The new context will replace the old one
```

### 4. Avoid Calling Too Late

```dart
// BAD - ViewModels may already be initialized without context
class SomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Too late - ViewModels created earlier won't have context
    ReactiveNotifier.initContext(context);
    return Scaffold(...);
  }
}
```

## Effects on ViewModels

### ViewModels Created Before initContext

- If `waitForContext: true`: Will be reinitialized automatically
- If `waitForContext: false`: Will work but had no context during init
- Can still use `context` and `globalContext` after initContext is called

### ViewModels Created After initContext

- Have immediate access to context in `init()`
- `hasContext` and `hasGlobalContext` return `true`
- No need for `waitForContext: true`

## Example: Full App with Context Access

```dart
// main.dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize global context
    ReactiveNotifier.initContext(context);

    return MaterialApp(
      title: 'ReactiveNotifier Demo',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

// services/theme_service.dart
mixin ThemeService {
  static final ReactiveNotifier<ThemeViewModel> themeState =
      ReactiveNotifier<ThemeViewModel>(() => ThemeViewModel());
}

// viewmodels/theme_viewmodel.dart
class ThemeViewModel extends ViewModel<ThemeState> {
  ThemeViewModel() : super(ThemeState.system());

  @override
  void init() {
    // Context is available immediately because initContext was called
    if (hasContext) {
      final theme = Theme.of(context!);
      updateSilently(ThemeState(
        isDarkMode: theme.brightness == Brightness.dark,
        primaryColor: theme.primaryColor,
      ));
    }
  }
}
```

## Testing

```dart
void main() {
  setUp(() {
    // Clean up state between tests
    ReactiveNotifier.cleanup();
  });

  testWidgets('ViewModel has context after initContext', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            // Initialize context in test
            ReactiveNotifier.initContext(context);
            return Container();
          },
        ),
      ),
    );

    // Now ViewModels will have access to context
    final vm = MyService.state.notifier;
    expect(vm.hasContext, true);
    expect(vm.hasGlobalContext, true);
  });
}
```

## Related

- [context](context.md) - Context getter with fallback
- [globalContext](global-context.md) - Direct global context access
- [hasContext](has-context.md) - Check context availability
- [hasGlobalContext](has-global-context.md) - Check global context availability
- [waitForContext](wait-for-context.md) - AsyncViewModel parameter to wait for context
