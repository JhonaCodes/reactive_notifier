# ReactiveNotifier - Dispose and Recreation Guide

## 📋 Memory Management Philosophy

ReactiveNotifier follows the **"Developer Responsibility"** philosophy:
- **NO automatic auto-dispose** like in Riverpod
- **Developer controls when** to dispose and cleanup
- **Complete cleanup** when explicitly requested
- **On-demand recreation** after dispose

## 🗑️ How to Dispose

### 1. Dispose a Specific ViewModel

```dart
// Cleans a specific ViewModel and its ReactiveNotifier from the registry
myViewModel.dispose();
```

**What happens internally:**
1. ✅ Removes external listeners (`removeListeners()`)
2. ✅ Stops communication with other ViewModels (`stopListeningVM()`)
3. ✅ Cleans the ReactiveNotifier from the global registry automatically
4. ✅ Releases parent-child references
5. ✅ Marks as disposed and frees ChangeNotifier resources

### 2. Global Cleanup of All Instances

```dart
// Cleans ALL instances from the global registry
ReactiveNotifier.cleanup();
```

**Typical use cases:**
- User logout
- Application context change
- Application termination
- Testing (tearDown)

### 3. Forced ReactiveNotifier Cleanup

```dart
// Forces cleanup of specific ReactiveNotifier
myNotifier.cleanCurrentNotifier(forceCleanup: true);
```

## 🔄 Recreation After Dispose

### Problem: What happens after dispose?

```dart
mixin UserService {
  static final instance = ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

// After disposing:
UserService.instance.notifier.dispose();

// ❌ PROBLEM: The instance is still in memory but the ViewModel is disposed
// ❌ If you try to use UserService.instance.notifier again, you'll have problems
```

### Solution: recreate() Method or Manual Recreation

#### Option 1: Manual Recreation (Currently Recommended)
```dart
// ✅ SOLUTION: Clean and recreate manually
mixin UserService {
  static ReactiveNotifier<UserViewModel>? _instance;
  
  static ReactiveNotifier<UserViewModel> get instance {
    _instance ??= ReactiveNotifier<UserViewModel>(() => UserViewModel());
    return _instance!;
  }
  
  static void reset() {
    if (_instance != null) {
      _instance!.notifier.dispose(); // Cleans the current ViewModel
      _instance = null; // Resets the reference
    }
    // Next time .instance is accessed, a new one will be created
  }
}
```

#### Option 2: recreate() Method (In Development)
```dart
// 🚧 IN DEVELOPMENT: Automatic recreate method
UserService.instance.recreate();

// Note: This functionality is in active development
```

## 🔧 recreate() Implementation

### Automatic Recreation Pattern

```dart
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel.empty());
  
  @override
  void init() {
    updateSilently(UserModel.fromPreferences());
    // Rest of initialization...
  }
}

mixin UserService {
  static final instance = ReactiveNotifier<UserViewModel>(
    () => UserViewModel(), // Factory function saved for recreation
  );
  
  // Helper method for dispose + recreate in one step
  static void reset() {
    instance.recreate();
  }
}
```

### Typical Recreation Usage

```dart
// Scenario 1: User logout
void logout() {
  UserService.instance.notifier.dispose(); // Cleans user data
  UserService.instance.recreate();         // Creates new clean instance
}

// Scenario 2: Context change
void switchToGuestMode() {
  UserService.reset(); // Dispose + recreate in one step
}

// Scenario 3: Testing
setUp(() {
  ReactiveNotifier.cleanup();      // Cleans everything
  UserService.instance.recreate(); // Recreates only what I need
});
```

## 📚 Recommended Patterns

### 1. Services with Helper Methods

```dart
mixin AuthService {
  static final _userNotifier = ReactiveNotifier<UserViewModel>(() => UserViewModel());
  static final _sessionNotifier = ReactiveNotifier<SessionViewModel>(() => SessionViewModel());
  
  // Public getters
  static ReactiveNotifier<UserViewModel> get user => _userNotifier;
  static ReactiveNotifier<SessionViewModel> get session => _sessionNotifier;
  
  // Helper methods for lifecycle management
  static void logout() {
    _userNotifier.recreate();
    _sessionNotifier.recreate();
  }
  
  static void dispose() {
    _userNotifier.notifier.dispose();
    _sessionNotifier.notifier.dispose();
  }
  
  static void reset() {
    dispose();
    _userNotifier.recreate();
    _sessionNotifier.recreate();
  }
}
```

### 2. Related States with Recreation

```dart
mixin ShopService {
  static final _userNotifier = ReactiveNotifier<UserViewModel>(() => UserViewModel());
  static final _cartNotifier = ReactiveNotifier<CartViewModel>(() => CartViewModel());
  
  // Composite state with related states
  static final _shopNotifier = ReactiveNotifier<ShopViewModel>(
    () => ShopViewModel(),
    related: [_userNotifier, _cartNotifier],
  );
  
  static ReactiveNotifier<ShopViewModel> get shop => _shopNotifier;
  
  // Coordinated recreation of related states
  static void resetShop() {
    _userNotifier.recreate();
    _cartNotifier.recreate();
    _shopNotifier.recreate(); // Recreates with new relationships
  }
}
```

### 3. AsyncViewModels with Recreation

```dart
class DataViewModel extends AsyncViewModelImpl<List<Item>> {
  DataViewModel() : super(AsyncState.initial(), loadOnInit: true);
  
  @override
  Future<List<Item>> init() async {
    return await ApiService.getData();
  }
}

mixin DataService {
  static final instance = ReactiveNotifier<DataViewModel>(() => DataViewModel());
  
  // Reload data by creating new instance
  static void refresh() {
    instance.recreate(); // New instance that will execute init() and load fresh data
  }
}
```

## 🔍 Monitoring and Debugging

### Check Instance State

```dart
// Check if an instance is disposed
if (UserService.instance.notifier.isDisposed) {
  log('ViewModel is disposed, consider recreating');
  UserService.instance.recreate();
}

// Monitor memory
log('Total instances: ${ReactiveNotifier.instanceCount}');
log('User instances: ${ReactiveNotifier.instanceCountByType<UserViewModel>()}');
```

### Recreation Logs

```dart
// Logs will tell you when an instance is recreated:
// 🔄 ReactiveNotifier<UserViewModel> recreated
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Key: [Previous Key]
// Old instance: Disposed
// New instance: Initialized
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## ⚠️ Important Considerations

### 1. Listeners During Recreation

```dart
// ❌ PROBLEM: If you have widgets listening during recreate
ReactiveBuilder<UserModel>(
  notifier: UserService.instance,
  build: (user, notifier, keep) {
    // If UserService.instance.recreate() is called while this widget exists,
    // the listener will remain on the previous instance (disposed)
    return Text(user.name);
  },
)

// ✅ SOLUTION: Coordinate recreate with widget lifecycle
void logout() {
  // 1. Navigate away from screens using UserService
  Navigator.pushAndRemoveUntil(context, LoginRoute(), (route) => false);
  
  // 2. Then recreate
  UserService.instance.recreate();
}
```

### 2. Related States and Recreation

```dart
// ❌ CAREFUL: Recreating only one notifier from related states can cause inconsistencies
ShopService.user.recreate();     // User is recreated
// ShopService.shop still has reference to the previous user

// ✅ BETTER: Recreate all related states in coordination
ShopService.resetAll(); // Method that recreates user, cart and shop in correct order
```

### 3. Communication Between ViewModels

```dart
class NotificationViewModel extends ViewModel<NotificationModel> {
  UserModel? currentUser;
  
  @override
  void init() {
    // ⚠️ If UserService is recreated while this ViewModel exists,
    // communication can break
    UserService.user.notifier.listenVM((userData) {
      currentUser = userData;
    });
  }
}

// ✅ SOLUTION: Recreate dependent ViewModels too
void resetUserContext() {
  UserService.user.recreate();
  NotificationService.notifications.recreate(); // Recreate dependents too
}
```

## 🎯 Best Practices Summary

1. **Use dispose()** when you want to clean a specific ViewModel
2. **Use cleanup()** to clean everything (logout, testing)
3. **Use recreate()** when you need a fresh instance after dispose
4. **Coordinate recreate()** with navigation to avoid problems with active widgets
5. **Recreate related states** together to maintain consistency
6. **Monitor instanceCount** in development to detect memory leaks
7. **Use helper methods** in services to encapsulate lifecycle management

Recreation allows you to maintain the "create once, reuse always" philosophy while having complete control over when to clean and recreate instances according to your application's needs.