# 🎯 ReactiveNotifier Context Pattern Guide

## Overview

ReactiveNotifier v2.12.0+ includes automatic BuildContext access for ViewModels, enabling seamless migration from other state management solutions like Riverpod and Provider while maintaining the core philosophy of independent ViewModel lifecycle.

## 🏗️ Architecture

### Context Per ViewModel Instance
- Each ViewModel gets its own isolated BuildContext
- No shared global context between ViewModels
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

## 🎨 Usage Patterns

### 1. **Migration from Riverpod**
```dart
class MigrationViewModel extends ViewModel<UserState> {
  MigrationViewModel() : super(UserState.initial());
  
  @override
  void init() {
    // Check if context is available for gradual migration
    if (hasContext) {
      try {
        // Access Riverpod container for gradual migration
        final container = ProviderScope.containerOf(context!);
        final userData = container.read(userProvider);
        updateState(UserState.fromRiverpod(userData));
      } catch (e) {
        // Fallback if Riverpod access fails
        updateState(UserState.fallback());
      }
    } else {
      // Pure ReactiveNotifier initialization
      updateState(UserState.empty());
    }
  }
}
```

### 2. **Theme and MediaQuery Access**
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
          print('Context access failed: $e');
        }
      }
    });
  }
}
```

### 3. **Navigation from ViewModels**
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

### 4. **Safe Async Context Access**
```dart
class AsyncContextViewModel extends AsyncViewModelImpl<UserData> {
  AsyncContextViewModel() : super(AsyncState.initial());
  
  @override
  Future<UserData> init() async {
    if (!hasContext) {
      // Return fallback data when context not available
      return UserData.fallback();
    }
    
    // Use postFrameCallback for safe context access in async operations
    final completer = Completer<UserData>();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!isDisposed && hasContext) {
          final theme = Theme.of(requireContext('user data'));
          final mediaQuery = MediaQuery.of(requireContext('screen info'));
          
          // Simulate API call with context-derived data
          final userData = await _fetchUserData(
            isDarkMode: theme.brightness == Brightness.dark,
            screenSize: mediaQuery.size,
          );
          
          if (!completer.isCompleted) {
            completer.complete(userData);
          }
        }
      } catch (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }
    });
    
    return completer.future;
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

## 🔧 API Reference

### Context Access Methods
```dart
// Available in all ViewModels through ViewModelContextService mixin
BuildContext? get context;           // Nullable context getter
bool get hasContext;                 // Check if context is available
BuildContext requireContext(String operation); // Required context with errors
```

### Context Safety Patterns
```dart
// ✅ SAFE: Always check availability first
if (hasContext) {
  final theme = Theme.of(context!);
  // Use context-dependent logic
}

// ✅ SAFE: Use requireContext with operation description
try {
  final mediaQuery = MediaQuery.of(requireContext('responsive layout'));
  // Use mediaQuery
} catch (e) {
  // Handle context unavailable error
}

// ❌ UNSAFE: Direct context access without checking
final theme = Theme.of(context!); // May throw if context is null
```

### Timing Considerations
```dart
// ✅ RECOMMENDED: Use postFrameCallback for MediaQuery/Theme in init()
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

// ❌ AVOID: Direct Theme/MediaQuery access in init()
@override  
void init() {
  final theme = Theme.of(context!); // May not be ready yet
}
```

## 🎯 Best Practices

### 1. **Graceful Degradation**
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
  updateState(MyState.fromTheme(theme));
}

void _initializeWithoutContext() {
  updateState(MyState.default());
}
```

### 2. **Context Isolation**
Each ViewModel has its own context. Don't share context between ViewModels:
```dart
// ✅ CORRECT: Each ViewModel uses its own context
class UserViewModel extends ViewModel<UserState> {
  void updateTheme() {
    if (hasContext) {
      final theme = Theme.of(context!); // This ViewModel's context
      // Update based on theme
    }
  }
}

class SettingsViewModel extends ViewModel<SettingsState> {
  void updateTheme() {
    if (hasContext) {
      final theme = Theme.of(context!); // Different context instance
      // Update based on theme
    }
  }
}
```

### 3. **Error Handling**
Use descriptive operation names with requireContext:
```dart
// ✅ GOOD: Descriptive error messages
final mediaQuery = MediaQuery.of(requireContext('responsive calculations'));
final theme = Theme.of(requireContext('color scheme detection'));
final navigator = Navigator.of(requireContext('details navigation'));

// ❌ POOR: Generic error messages  
final mediaQuery = MediaQuery.of(requireContext('operation'));
```

### 4. **Migration Strategy**
For gradual migration from other state managers:
```dart
class HybridViewModel extends ViewModel<HybridState> {
  @override
  void init() {
    // Phase 1: Basic ReactiveNotifier state
    updateSilently(HybridState.basic());
    
    // Phase 2: Enhance with context if available
    if (hasContext) {
      try {
        // Access legacy Riverpod/Provider data
        final legacyData = _getLegacyData(context!);
        updateState(HybridState.enhanced(legacyData));
      } catch (e) {
        // Continue with basic state if legacy access fails
        print('Legacy data access failed: $e');
      }
    }
  }
  
  LegacyData _getLegacyData(BuildContext context) {
    // Gradually migrate data from Riverpod/Provider
    final container = ProviderScope.containerOf(context);
    return container.read(legacyProvider);
  }
}
```

## 🔍 Debugging

### Context Availability Debugging
```dart
class DebugViewModel extends ViewModel<DebugState> {
  @override
  void init() {
    assert(() {
      print('''
🐛 DebugViewModel Context Info:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Has context: $hasContext
Context: ${context?.toString() ?? 'null'}
Widget: ${context?.widget.runtimeType ?? 'N/A'}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');
      return true;
    }());
    
    updateSilently(DebugState(contextAvailable: hasContext));
  }
}
```

### Common Issues and Solutions

#### Issue: "BuildContext Required But Not Available"
```dart
// Problem: Accessing context before any builder is mounted
final vm = MyService.instance.notifier;
vm.doSomethingWithContext(); // ❌ No builder mounted yet

// Solution: Use context only within or after builder mounting
ReactiveViewModelBuilder<MyViewModel, MyState>(
  viewmodel: MyService.instance.notifier,
  build: (state, viewModel, keep) {
    // ✅ Context is now available
    viewModel.doSomethingWithContext();
    return MyWidget();
  },
)
```

#### Issue: MediaQuery not ready in init()
```dart
// Problem: MediaQuery accessed too early
@override
void init() {
  final size = MediaQuery.of(context!).size; // ❌ May not be ready
}

// Solution: Use postFrameCallback
@override
void init() {
  updateSilently(MyState.initial());
  
  if (hasContext) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isDisposed && hasContext) {
        final size = MediaQuery.of(context!).size; // ✅ Ready now
        updateState(MyState.withSize(size));
      }
    });
  }
}
```

## 🚀 Advanced Use Cases

### 1. **Dynamic Theme Switching**
```dart
class ThemeViewModel extends ViewModel<ThemeState> {
  ThemeViewModel() : super(ThemeState.system());
  
  void toggleTheme() {
    if (hasContext) {
      final currentTheme = Theme.of(context!);
      final newBrightness = currentTheme.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark;
      
      updateState(ThemeState.custom(newBrightness));
    }
  }
  
  void resetToSystemTheme() {
    if (hasContext) {
      final platformBrightness = MediaQuery.of(context!).platformBrightness;
      updateState(ThemeState.system(platformBrightness));
    }
  }
}
```

### 2. **Localization with Context**
```dart
class LocalizationViewModel extends ViewModel<LocalizationState> {
  LocalizationViewModel() : super(LocalizationState.initial());
  
  @override
  void init() {
    if (hasContext) {
      final locale = Localizations.of(context!);
      updateState(LocalizationState(
        locale: locale.locale,
        isRTL: locale.locale.languageCode == 'ar' || 
               locale.locale.languageCode == 'he',
      ));
    }
  }
  
  void changeLanguage(String languageCode) {
    updateState(LocalizationState(
      locale: Locale(languageCode),
      isRTL: languageCode == 'ar' || languageCode == 'he',
    ));
  }
}
```

## 📚 Summary

The ReactiveNotifier Context Pattern provides:

- ✅ **Automatic Context Management**: No manual setup required
- ✅ **Isolated Context Per ViewModel**: No shared state between ViewModels  
- ✅ **Migration Support**: Seamless transition from Riverpod/Provider
- ✅ **Safe Access Patterns**: Built-in error handling and validation
- ✅ **Backward Compatibility**: Existing code works unchanged
- ✅ **Memory Leak Prevention**: Automatic cleanup on disposal

This pattern enables powerful context-dependent features while maintaining ReactiveNotifier's core philosophy of independent ViewModel lifecycle and reactive communication.