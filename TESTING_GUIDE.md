# ReactiveNotifier Testing Guide

## 🧪 Comprehensive Testing Patterns for ViewModels with BuildContext Access

This guide covers **production-ready testing patterns** for ReactiveNotifier v2.12.0, focusing on ViewModels that require BuildContext access for migration scenarios.

---

## 🚨 Critical Testing Principles

### ❌ **AVOID**: Tests with Fallbacks (Hide Production Issues)**

```dart
// ❌ BAD - This test hides real production problems
class BadTestViewModel extends ViewModel<String> {
  @override
  void init() {
    if (hasContext) {
      // Use context
      final theme = Theme.of(context!);
      updateState('themed');
    } else {
      // FALLBACK - This hides context requirement issues!
      updateState('fallback');  
    }
  }
}
```

**Why this is bad:**
- ✗ Hides context timing issues
- ✗ Won't catch production errors
- ✗ Tests pass when production fails

### ✅ **CORRECT**: Strict Production-Like Tests

```dart
// ✅ GOOD - This exposes real production issues
class GoodTestViewModel extends ViewModel<String> {
  @override
  void init() {
    // REQUIRE context - no fallbacks
    if (!hasContext) {
      throw StateError('This ViewModel REQUIRES context for Riverpod migration');
    }
    
    // Initialize with basic state first
    updateSilently('initializing');
    
    // Use postFrameCallback for safe InheritedWidget access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isDisposed && hasContext) {
        try {
          final theme = Theme.of(context!);
          updateState(theme.brightness == Brightness.dark ? 'dark' : 'light');
        } catch (e) {
          updateState('error');
        }
      }
    });
  }
}
```

**Why this is correct:**
- ✓ Exposes real context timing issues
- ✓ Forces proper postFrameCallback usage
- ✓ Tests fail when production would fail

---

## 🎯 Core Testing Patterns

### 1. **Context-Required ViewModels**

```dart
class ProductionViewModel extends ViewModel<UserState> {
  ProductionViewModel() : super(UserState.initial());

  @override
  void init() {
    // Strict context requirement (migration scenarios)
    if (!hasContext) {
      throw StateError('ProductionViewModel REQUIRES context for Provider migration');
    }
    
    // Always initialize with safe state first
    updateSilently(UserState.initializing());
    
    // Use postFrameCallback for safe InheritedWidget access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isDisposed && hasContext) {
        try {
          // Safe to access Theme, MediaQuery, etc.
          final theme = Theme.of(requireContext('migration'));
          final mediaQuery = MediaQuery.of(context!);
          
          updateState(UserState.fromContext(
            isDark: theme.brightness == Brightness.dark,
            screenWidth: mediaQuery.size.width,
          ));
        } catch (e) {
          // Handle context access errors properly
          updateState(UserState.error('Context access failed: $e'));
        }
      }
    });
  }
}
```

### 2. **Context-Required AsyncViewModels**

```dart
class ProductionAsyncViewModel extends AsyncViewModelImpl<ApiData> {
  ProductionAsyncViewModel() : super(AsyncState.initial());

  @override
  Future<ApiData> init() async {
    // Strict context requirement
    if (!hasContext) {
      throw StateError('ProductionAsyncViewModel REQUIRES context');
    }

    // Use Completer for postFrameCallback pattern
    final completer = Completer<ApiData>();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!isDisposed && hasContext) {
        try {
          // Safe InheritedWidget access
          final mediaQuery = MediaQuery.of(requireContext('API call'));
          
          // Simulate API call based on context data
          final data = await _callApi(mediaQuery.size.width);
          
          if (!completer.isCompleted) {
            completer.complete(data);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      }
    });
    
    return completer.future;
  }
  
  Future<ApiData> _callApi(double screenWidth) async {
    // Simulate API call (no timers in tests)
    return ApiData(screenWidth: screenWidth);
  }
}
```

---

## 🧪 Test Implementation Patterns

### 1. **Basic Context Access Test**

```dart
testWidgets('ViewModel receives context correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: ReactiveViewModelBuilder<ProductionViewModel, UserState>(
        viewmodel: MyService.instance.notifier,
        build: (state, viewModel, keep) {
          return Column(
            children: [
              Text('Theme: ${state.theme}'),
              Text('HasContext: ${viewModel.hasContext}'),
            ],
          );
        },
      ),
    ),
  );

  await tester.pumpAndSettle();
  
  // Wait for postFrameCallback
  await tester.pump();
  
  // Strict assertions
  expect(find.text('Theme: dark'), findsOneWidget);
  expect(find.text('HasContext: true'), findsOneWidget);
  
  // Verify ViewModel state
  final vm = MyService.instance.notifier;
  expect(vm.hasContext, isTrue);
  expect(vm.context, isNotNull);
});
```

### 2. **Error Handling Test**

```dart
test('ViewModel without context fails appropriately', () {
  // Create ViewModel outside widget tree
  final vm = ProductionViewModel();
  
  // Should not have context
  expect(vm.hasContext, isFalse);
  expect(vm.context, isNull);
  
  // Should provide descriptive errors
  expect(
    () => vm.requireContext('migration'),
    throwsA(isA<StateError>().having(
      (e) => e.message,
      'message',
      allOf(
        contains('BuildContext Required But Not Available'),
        contains('migration'),
      ),
    )),
  );
});
```

### 3. **Context Lifecycle Test**

```dart
testWidgets('Context cleanup works correctly', (tester) async {
  // Build widget with context
  await tester.pumpWidget(
    MaterialApp(
      home: ReactiveViewModelBuilder<ProductionViewModel, UserState>(
        viewmodel: MyService.instance.notifier,
        build: (state, viewModel, keep) => Text('Test'),
      ),
    ),
  );

  await tester.pumpAndSettle();
  
  final vm = MyService.instance.notifier;
  expect(vm.hasContext, isTrue);

  // Remove widget - context should be cleaned up
  await tester.pumpWidget(const MaterialApp(
    home: Scaffold(body: Text('No Builder')),
  ));

  await tester.pumpAndSettle();
  
  // Context should be null
  expect(vm.hasContext, isFalse);
  expect(vm.context, isNull);
});
```

### 4. **Multiple Builders Test**

```dart
testWidgets('Multiple builders share context correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Column(
        children: [
          Expanded(
            child: ReactiveViewModelBuilder<AuthViewModel, AuthState>(
              viewmodel: AuthService.instance.notifier,
              build: (state, viewModel, keep) => Text('Auth: ${state.status}'),
            ),
          ),
          Expanded(
            child: ReactiveAsyncBuilder<DataViewModel, UserData>(
              notifier: DataService.instance.notifier,
              onData: (data, viewModel, keep) => Text('Data: ${data.name}'),
              onLoading: () => const Text('Loading'),
            ),
          ),
        ],
      ),
    ),
  );

  await tester.pumpAndSettle();

  final authVM = AuthService.instance.notifier;
  final dataVM = DataService.instance.notifier;
  
  // Both should have context
  expect(authVM.hasContext, isTrue);
  expect(dataVM.hasContext, isTrue);
  
  // Context should be the same instance
  expect(authVM.context, equals(dataVM.context));
});
```

---

## 🔧 Service Setup for Testing

### Proper Service Pattern with Test Support

```dart
mixin MyService {
  static ReactiveNotifier<MyViewModel>? _instance;
  
  static ReactiveNotifier<MyViewModel> get instance {
    _instance ??= ReactiveNotifier<MyViewModel>(MyViewModel.new);
    return _instance!;
  }
  
  // Essential for testing - creates fresh instance
  static ReactiveNotifier<MyViewModel> createNew() {
    _instance = ReactiveNotifier<MyViewModel>(MyViewModel.new);
    return _instance!;
  }
}
```

### Test Setup Pattern

```dart
setUp(() {
  // Essential: Clean up before each test
  ReactiveNotifier.cleanup();
  
  // Create fresh instances to avoid cross-test contamination
  AuthService.createNew();
  DataService.createNew();
  UserService.createNew();
});
```

---

## 🚦 Migration Testing Scenarios

### Riverpod Migration Test

```dart
// Simulates gradual migration from Riverpod
class RiverpodMigrationViewModel extends ViewModel<MigrationState> {
  RiverpodMigrationViewModel() : super(MigrationState.initial());

  @override
  void init() {
    if (!hasContext) {
      throw StateError('Migration ViewModel REQUIRES context for ProviderScope access');
    }
    
    updateSilently(MigrationState.migrating());
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isDisposed && hasContext) {
        try {
          // Access Riverpod container during migration
          final container = ProviderScope.containerOf(context!);
          final userData = container.read(userProvider);
          
          updateState(MigrationState.completed(userData));
        } catch (e) {
          updateState(MigrationState.failed('Riverpod access failed'));
        }
      }
    });
  }
}
```

### Provider Migration Test

```dart
// Simulates gradual migration from Provider
class ProviderMigrationViewModel extends AsyncViewModelImpl<UserProfile> {
  ProviderMigrationViewModel() : super(AsyncState.initial());

  @override
  Future<UserProfile> init() async {
    if (!hasContext) {
      throw StateError('Migration requires context for Provider.of access');
    }

    final completer = Completer<UserProfile>();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!isDisposed && hasContext) {
        try {
          // Access Provider during migration
          final userProvider = Provider.of<UserData>(context!, listen: false);
          final profile = await _buildProfile(userProvider);
          
          if (!completer.isCompleted) {
            completer.complete(profile);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      }
    });
    
    return completer.future;
  }
}
```

---

## ⚠️ Common Testing Anti-Patterns

### 1. **Using try-catch to hide errors**

```dart
// ❌ DON'T DO THIS
@override
void init() {
  try {
    final theme = Theme.of(context!);  // Can fail during initState
    updateState(theme.brightness.toString());
  } catch (e) {
    updateState('default');  // Hides the real problem
  }
}
```

### 2. **Direct Theme/MediaQuery access in init()**

```dart
// ❌ DON'T DO THIS - Causes Flutter exceptions
@override
void init() {
  final theme = Theme.of(context!);  // FORBIDDEN during initState
  final mediaQuery = MediaQuery.of(context!);  // FORBIDDEN during initState
}
```

### 3. **Tests with fallbacks**

```dart
// ❌ DON'T DO THIS - Hides production issues
if (hasContext) {
  // Do context-dependent work
} else {
  // Fallback that makes tests pass but hides real issues
}
```

---

## ✅ Testing Checklist

### Before Writing Tests

- [ ] Does the ViewModel require context for real production use?
- [ ] Are you testing the actual migration scenario?
- [ ] Do tests fail when production would fail?

### ViewModel Implementation

- [ ] Use `postFrameCallback` for InheritedWidget access
- [ ] Initialize with safe state first, then update with context data
- [ ] Proper disposal checks (`!isDisposed && hasContext`)
- [ ] No direct Theme/MediaQuery access in `init()`

### Test Implementation

- [ ] `ReactiveNotifier.cleanup()` in `setUp()`
- [ ] Create fresh service instances with `createNew()`
- [ ] Use `await tester.pump()` after `pumpAndSettle()` for postFrameCallback
- [ ] Test both success and error scenarios
- [ ] Verify context lifecycle (available → null when disposed)

### Test Coverage

- [ ] Context access during initialization
- [ ] Context cleanup when builders are disposed  
- [ ] Multiple builders sharing context
- [ ] Error handling without context
- [ ] Descriptive error messages with `requireContext()`

---

## 🎯 Key Takeaways

1. **No Fallbacks**: Tests should expose real production issues
2. **postFrameCallback**: Always use for InheritedWidget access
3. **Strict Requirements**: ViewModels should fail clearly without context
4. **Proper Cleanup**: Always clean up between tests
5. **Real Scenarios**: Test actual migration patterns, not simplified versions

This testing approach ensures your ViewModels will work correctly in production, especially during gradual migrations from Provider/Riverpod to ReactiveNotifier.