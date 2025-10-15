# ReactiveContext - Complete Guide

## Overview

ReactiveContext is an advanced feature of ReactiveNotifier that provides clean, intuitive access to **global reactive state** directly from BuildContext. It's designed for specific use cases like language, theme, user preferences, and other global app state that needs to be accessed from multiple widgets without writing repetitive ReactiveBuilder code.

**ReactiveContext is NOT a replacement for ReactiveBuilder**. ReactiveBuilder remains the recommended approach for granular state management, component-specific state, and complex business logic.

## When to Use ReactiveContext

### ✅ **Perfect for:**
- **Global app state**: Language, theme, user preferences
- **Cross-widget state**: State accessed from many different widgets
- **Avoiding duplication**: Eliminating repetitive ReactiveBuilder code
- **Simple access patterns**: Direct property access without complex logic

### ❌ **NOT recommended for:**
- **Granular state management**: Component-specific state with precise rebuild control
- **Complex business logic**: State that requires validation, transformation, or business rules
- **Temporary state**: State that exists only within a specific widget or screen
- **Performance-critical state**: State that changes frequently and needs optimized rebuilds

## Key Features

- **Clean API**: Access global state with `context.lang.name` instead of verbose builders
- **Type-Safe**: Full type safety with compile-time checks
- **Performance Optimized**: Type-specific rebuilds prevent unnecessary updates
- **Widget Preservation**: Advanced `.keep()` system for preventing rebuilds
- **Generic Access**: Multiple ways to access state (`context<T>()`, `getByKey<T>()`)
- **Auto-Registration**: Transparent notifier registration and lifecycle management
- **Debug Support**: Comprehensive debugging and monitoring capabilities

## Quick Start

### Basic Setup

```dart
// 1. Define your state models
class MyLang {
  final String name;
  final String code;
  
  MyLang(this.name, this.code);
}

class MyTheme {
  final bool isDark;
  final Color primaryColor;
  
  MyTheme(this.isDark, this.primaryColor);
}

// 2. Create services with ReactiveNotifier
mixin LanguageService {
  static final ReactiveNotifier<MyLang> instance = ReactiveNotifier<MyLang>(
    () => MyLang('English', 'en'),
  );
  
  static void switchLanguage(String name, String code) {
    instance.updateState(MyLang(name, code));
  }
}

mixin ThemeService {
  static final ReactiveNotifier<MyTheme> instance = ReactiveNotifier<MyTheme>(
    () => MyTheme(false, Colors.blue),
  );
  
  static void toggleTheme() {
    final current = instance.notifier;
    instance.updateState(MyTheme(!current.isDark, current.primaryColor));
  }
}

// 3. Create extension methods for clean access
extension LanguageContext on BuildContext {
  MyLang get lang => getReactiveState(LanguageService.instance);
}

extension ThemeContext on BuildContext {
  MyTheme get theme => getReactiveState(ThemeService.instance);
}

// 4. Use in your widgets
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Language: ${context.lang.name}'),
        Text('Theme: ${context.theme.isDark ? 'Dark' : 'Light'}'),
        Container(color: context.theme.primaryColor),
      ],
    );
  }
}
```

## API Reference

### Extension Method API (Recommended)

The extension method approach provides the cleanest, most intuitive API:

```dart
// Define extensions for your specific use cases
extension UserContext on BuildContext {
  UserModel get user => getReactiveState(UserService.instance);
}

extension SettingsContext on BuildContext {
  SettingsModel get settings => getReactiveState(SettingsService.instance);
}

extension CartContext on BuildContext {
  CartModel get cart => getReactiveState(CartService.instance);
}

// Usage in widgets
class ProfileWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Welcome ${context.user.name}'),
        Text('Notifications: ${context.settings.notificationsEnabled}'),
        Text('Cart items: ${context.cart.items.length}'),
      ],
    );
  }
}
```

### Generic API

For dynamic scenarios or when you don't want to create specific extensions:

```dart
class GenericWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Access by type
        Text('User: ${context<UserModel>().name}'),
        Text('Settings: ${context<SettingsModel>().theme}'),
        
        // Access by key (intelligent matching)
        Text('User: ${context.getByKey<UserModel>('user').name}'),
        Text('Settings: ${context.getByKey<SettingsModel>('settings').theme}'),
        
        // Get all instances of a type
        ...context.getAllByType<NotificationModel>()
            .map((notification) => NotificationTile(notification)),
      ],
    );
  }
}
```

### Key-Based Access

The `getByKey<T>()` method provides intelligent matching:

```dart
// These will all match UserService.instance
context.getByKey<UserModel>('user');
context.getByKey<UserModel>('User');
context.getByKey<UserModel>('usermodel');
context.getByKey<UserModel>('UserService');

// Error handling with helpful messages
try {
  final user = context.getByKey<UserModel>('nonexistent');
} catch (e) {
  log(e); // Shows available keys and suggestions
}
```

## Widget Preservation System

ReactiveContext provides an advanced widget preservation system that goes beyond traditional approaches:

### Basic Widget Preservation

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // This rebuilds when language changes
        Text('Language: ${context.lang.name}'),
        
        // This never rebuilds
        ExpensiveWidget().keep('expensive_key'),
        
        // Context-aware preservation
        context.keep(AnotherWidget(), 'another_key'),
      ],
    );
  }
}
```

### Advanced Preservation Techniques

```dart
class AdvancedWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Batch preservation
        ...context.keepAll([
          Widget1(),
          Widget2(),
          Widget3(),
        ], 'batch_key'),
        
        // Preserve with reactive state dependency
        context.preserveReactive(
          ComplexWidget(theme: context.theme),
          ThemeService.instance,
          'reactive_preserved'
        ),
        
        // Preserve with builder pattern
        context.preserveReactiveBuilder<MyTheme>(
          ThemeService.instance,
          (theme) => StyledWidget(theme: theme),
          'themed_widget'
        ),
        
        // Automatic key generation
        ExpensiveWidget().keep(), // Auto-generated key
      ],
    );
  }
}
```

### Preservation API Reference

| Method | Description | Usage |
|--------|-------------|--------|
| `widget.keep(key)` | Extension method for direct preservation | `MyWidget().keep('key')` |
| `context.keep(widget, key)` | Context-aware preservation | `context.keep(MyWidget(), 'key')` |
| `context.keepAll(widgets, key)` | Batch preservation | `context.keepAll([w1, w2], 'key')` |
| `context.preserveReactive(widget, notifier, key)` | Preserve with reactive dependency | `context.preserveReactive(w, n, 'key')` |
| `context.preserveReactiveBuilder(notifier, builder, key)` | Preserve with builder pattern | `context.preserveReactiveBuilder(n, (s) => w, 'key')` |

## Performance Optimization

### Type-Specific Rebuilds

Unlike traditional state management, ReactiveContext implements type-specific rebuilds:

```dart
class PerformanceDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Only rebuilds when MyLang changes
        Text('Language: ${context.lang.name}'),
        
        // Only rebuilds when MyTheme changes
        Container(color: context.theme.primaryColor),
        
        // Only rebuilds when CounterModel changes
        Text('Count: ${context.counter.value}'),
      ],
    );
  }
}
```

This prevents the common "cross-rebuilds" problem where changing one piece of state causes unrelated widgets to rebuild.

### ReactiveOptimizer Widget

For maximum performance, use `ReactiveOptimizer` to force the InheritedWidget strategy:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ReactiveOptimizer(
        // Force InheritedWidget strategy for optimal performance
        forceInheritedFor: [
          LanguageService.instance,
          ThemeService.instance,
          UserService.instance,
        ],
        child: MyHomePage(),
      ),
    );
  }
}
```

### Performance Best Practices

1. **Use Extension Methods**: They provide the cleanest API and best performance
2. **Leverage ReactiveOptimizer**: For frequently accessed state
3. **Preserve Expensive Widgets**: Use `.keep()` for widgets that don't need updates
4. **Monitor Performance**: Use debug methods to track rebuild counts
5. **Group Related States**: Use related states system for dependent data

## Debugging and Monitoring

### Debug Methods

```dart
class DebugWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => context.debugReactiveContext(),
          child: Text('log Debug Info'),
        ),
        
        ElevatedButton(
          onPressed: () {
            final info = context.getReactiveDebugInfo();
            log('Active notifiers: ${info['activeNotifiers']}');
            log('Enhanced stats: ${info['enhancedContext']}');
            log('Preservation stats: ${info['preservation']}');
          },
          child: Text('Get Debug Statistics'),
        ),
        
        ElevatedButton(
          onPressed: () => context.cleanupReactiveContext(),
          child: Text('Cleanup Resources'),
        ),
      ],
    );
  }
}
```

### Debug Output Example

```
=== ReactiveContext Debug Info ===
Context Widget: MyWidget
Active Notifiers: 5
Notifier Types: [MyLang, MyTheme, UserModel, SettingsModel, CartModel]
Enhanced Stats: {
  typeSpecificElements: {MyLang: 3, MyTheme: 2, UserModel: 1},
  globalListenersSetup: 3,
  registeredNotifierTypes: 5,
  totalActiveElements: 6
}
Preservation Stats: {
  totalPreservedWidgets: 12,
  averageBuildCount: 1.2,
  cacheUtilization: 45.0%
}
=== End Debug Info ===
```

## Migration Guide

### From ReactiveBuilder

```dart
// Before: ReactiveBuilder
ReactiveBuilder<MyLang>(
  notifier: LanguageService.instance,
  build: (lang, notifier, keep) {
    return Text('Language: ${lang.name}');
  },
)

// After: ReactiveContext
extension LanguageContext on BuildContext {
  MyLang get lang => getReactiveState(LanguageService.instance);
}

// Usage
Text('Language: ${context.lang.name}')
```

### From ReactiveViewModelBuilder

```dart
// Before: ReactiveViewModelBuilder
ReactiveViewModelBuilder<UserViewModel, UserModel>(
  viewmodel: UserService.instance.notifier,
  build: (user, viewmodel, keep) {
    return Text('User: ${user.name}');
  },
)

// After: ReactiveContext
extension UserContext on BuildContext {
  UserModel get user => getReactiveState(UserService.instance);
}

// Usage
Text('User: ${context.user.name}')
```

### From NoRebuildWrapper

```dart
// Before: NoRebuildWrapper
NoRebuildWrapper(
  key: ValueKey('expensive_widget'),
  child: ExpensiveWidget(),
)

// After: ReactiveContext
ExpensiveWidget().keep('expensive_widget')
```

## Best Practices

### 1. Organization

```dart
// Group related extensions in separate files
// lib/extensions/user_context.dart
extension UserContext on BuildContext {
  UserModel get user => getReactiveState(UserService.instance);
  ProfileModel get profile => getReactiveState(ProfileService.instance);
}

// lib/extensions/app_context.dart
extension AppContext on BuildContext {
  ThemeModel get theme => getReactiveState(ThemeService.instance);
  LanguageModel get lang => getReactiveState(LanguageService.instance);
}
```

### 2. Naming Conventions

```dart
// Use clear, descriptive names
extension UserContext on BuildContext {
  UserModel get currentUser => getReactiveState(UserService.instance);
  UserPreferences get userPrefs => getReactiveState(UserPrefsService.instance);
}

// Avoid generic names
extension BadContext on BuildContext {
  // Don't do this
  dynamic get data => getReactiveState(SomeService.instance);
  Object get state => getReactiveState(AnotherService.instance);
}
```

### 3. Error Handling

```dart
extension SafeContext on BuildContext {
  UserModel? get userSafe {
    try {
      return getReactiveState(UserService.instance);
    } catch (e) {
      debuglog('Error accessing user: $e');
      return null;
    }
  }
}
```

### 4. Performance Optimization

```dart
// Use ReactiveOptimizer for frequently accessed state
ReactiveOptimizer(
  forceInheritedFor: [
    // Include frequently accessed notifiers
    UserService.instance,
    ThemeService.instance,
    // Don't include rarely accessed notifiers
    // OneTimeService.instance,
  ],
  child: MyApp(),
)
```

## Common Patterns

### 1. Conditional Rendering

```dart
class ConditionalWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return context.user.isLoggedIn
        ? LoggedInView()
        : LoginView();
  }
}
```

### 2. Computed Properties

```dart
extension ComputedContext on BuildContext {
  bool get isDarkMode => theme.isDark;
  String get displayName => user.displayName ?? user.username;
  int get cartTotal => cart.items.fold(0, (sum, item) => sum + item.price);
}
```

### 3. Localization

```dart
extension LocalizationContext on BuildContext {
  String get languageCode => lang.code;
  
  String translate(String key) {
    return LocalizationService.translate(key, languageCode);
  }
}

// Usage
Text(context.translate('welcome_message'))
```

## Testing

### Unit Testing

```dart
void main() {
  group('ReactiveContext Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
      
      // Setup test data
      LanguageService.instance.updateSilently(MyLang('Test', 'test'));
      ThemeService.instance.updateSilently(MyTheme(true, Colors.red));
    });
    
    testWidgets('should display reactive state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Column(
              children: [
                Text('Language: ${context.lang.name}'),
                Text('Theme: ${context.theme.isDark}'),
              ],
            ),
          ),
        ),
      );
      
      expect(find.text('Language: Test'), findsOneWidget);
      expect(find.text('Theme: true'), findsOneWidget);
    });
  });
}
```

### Integration Testing

```dart
void main() {
  group('ReactiveContext Integration', () {
    testWidgets('should update when state changes', (tester) async {
      await tester.pumpWidget(MyApp());
      
      // Initial state
      expect(find.text('Language: English'), findsOneWidget);
      
      // Change state
      LanguageService.switchLanguage('Spanish', 'es');
      await tester.pump();
      
      // Verify update
      expect(find.text('Language: Spanish'), findsOneWidget);
    });
  });
}
```

## Troubleshooting

### Common Issues

1. **State Not Updating**
   - Ensure you're using the correct extension method
   - Check that the notifier is properly registered
   - Verify the state is being updated with `updateState()` not `updateSilently()`

2. **Performance Issues**
   - Use `ReactiveOptimizer` for frequently accessed state
   - Implement widget preservation with `.keep()`
   - Check for unnecessary rebuilds with debug methods

3. **Type Errors**
   - Ensure extension methods return the correct type
   - Check that services are properly initialized
   - Use generic API for dynamic scenarios

### Debug Checklist

- [ ] Extensions are properly defined
- [ ] Services are using mixins
- [ ] NotifierTypes are registered
- [ ] ReactiveOptimizer is used where needed
- [ ] Debug methods show expected statistics

## Conclusion

ReactiveContext represents the next evolution of ReactiveNotifier, providing a clean, intuitive API for accessing reactive state while maintaining excellent performance and developer experience. By following the patterns and best practices outlined in this guide, you can create highly performant, maintainable Flutter applications with minimal boilerplate code.

The combination of type-specific rebuilds, advanced widget preservation, and clean API design makes ReactiveContext ideal for modern Flutter development where performance and developer experience are equally important.

---

For more examples and advanced usage patterns, check out the [complete example app](../example/reactive_context_example.dart) and the [ReactiveNotifier documentation](../README.md).