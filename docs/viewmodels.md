# ViewModels Guide

## ViewModel<T> - Synchronous State Management

### Purpose
Complex state management with business logic and synchronous initialization.

### Basic Structure
```dart
class CartViewModel extends ViewModel<CartState> {
  CartViewModel() : super(CartState.empty());
  
  @override
  void init() {
    // Synchronous initialization only
    loadLocalCart();
    setupCartValidation();
  }
  
  void addItem(Product product) {
    transformState((state) => state.copyWith(
      items: [...state.items, CartItem(product: product)],
      total: calculateTotal([...state.items, CartItem(product: product)])
    ));
  }
  
  void removeItem(String productId) {
    transformState((state) {
      final newItems = state.items.where((item) => item.id != productId).toList();
      return state.copyWith(
        items: newItems,
        total: calculateTotal(newItems)
      );
    });
  }
}
```

### Lifecycle Methods
- `init()` - Called once when created (must be synchronous)
- `onResume()` - Called after initialization
- `cleanState()` - Reset state to initial values
- `dispose()` - Cleanup when no longer needed

### State Update Methods
- `updateState(newState)` - Replace entire state with notification
- `updateSilently(newState)` - Replace state without notification
- `transformState((current) => newState)` - Transform with notification
- `transformStateSilently((current) => newState)` - Transform without notification

## AsyncViewModelImpl<T> - Asynchronous State Management

### Purpose
Handle async operations with automatic loading, success, and error states.

### Basic Structure
```dart
class ProductsViewModel extends AsyncViewModelImpl<List<Product>> {
  ProductsViewModel() : super(AsyncState.initial(), loadOnInit: true);
  
  @override
  Future<List<Product>> init() async {
    // Asynchronous initialization
    final products = await productRepository.getProducts();
    return products;
  }
  
  Future<void> refresh() async {
    loadingState();
    try {
      final products = await productRepository.getProducts();
      updateState(products);
    } catch (e) {
      errorState('Failed to load products: $e');
    }
  }
  
  Future<void> searchProducts(String query) async {
    loadingState();
    try {
      final results = await productRepository.searchProducts(query);
      updateState(results);
    } catch (e) {
      errorState('Search failed: $e');
    }
  }
}
```

### AsyncState Types
- `AsyncState.initial()` - Before any operation
- `AsyncState.loading()` - Operation in progress
- `AsyncState.success(data)` - Operation completed successfully
- `AsyncState.error(error)` - Operation failed

### Additional Methods
- `loadingState()` - Set loading state
- `errorState(message)` - Set error state
- `transformDataState((data) => newData)` - Transform only data part
- `transformDataStateSilently((data) => newData)` - Transform data without notification
- `reload()` - Re-run the init() method

### Listener Management
```dart
class DataViewModel extends AsyncViewModelImpl<DataModel> {
  StreamSubscription? _subscription;
  
  @override
  Future<void> setupListeners([List<String> currentListeners = const []]) async {
    _subscription = externalStream.listen(_handleExternalData);
    await super.setupListeners(['_subscription']);
  }
  
  @override
  Future<void> removeListeners([List<String> currentListeners = const []]) async {
    await _subscription?.cancel();
    await super.removeListeners(['_subscription']);
  }
  
  void _handleExternalData(ExternalData data) {
    if (hasInitializedListenerExecution) {
      // Process external data
      transformDataState((current) => current.copyWith(
        externalValue: data.value
      ));
    }
  }
}
```

## Cross-ViewModel Communication

### Reactive Listening Pattern
```dart
class NotificationViewModel extends ViewModel<NotificationState> {
  UserModel? currentUser;
  SettingsModel? currentSettings;
  
  @override
  void init() {
    // Listen to user changes
    UserService.userState.notifier.listenVM((userData) {
      currentUser = userData;
      updateNotificationsForUser(userData);
    });
    
    // Listen to settings changes
    SettingsService.settingsState.notifier.listenVM((settingsData) {
      currentSettings = settingsData;
      updateNotificationSettings(settingsData);
    });
  }
  
  void updateNotificationsForUser(UserModel user) {
    transformState((state) => state.copyWith(
      userId: user.id,
      userName: user.name,
      notifications: filterNotificationsForUser(state.notifications, user)
    ));
  }
}
```

### Benefits of Cross-ViewModel Communication
- **No Widget Coupling**: ViewModels communicate directly
- **Automatic Data Flow**: Changes propagate instantly
- **Independent Lifecycle**: ViewModel lifecycle separate from UI
- **Real-time Synchronization**: State changes trigger automatic updates

## Advanced Patterns

### Conditional State Updates
```dart
class SmartCartViewModel extends ViewModel<CartState> {
  @override
  void init() {
    // Listen to user authentication
    UserService.userState.notifier.listenVM((user) {
      if (user.isLoggedIn) {
        syncCartWithServer(user.id);
      } else {
        transformState((state) => state.copyWith(isGuest: true));
      }
    });
    
    // Listen to product changes
    ProductService.productsState.notifier.listenVM((products) {
      // Update cart items if products changed
      validateCartItems(products);
    });
  }
  
  void validateCartItems(List<Product> availableProducts) {
    transformState((state) {
      final validItems = state.items.where((item) => 
        availableProducts.any((product) => product.id == item.productId)
      ).toList();
      
      return state.copyWith(
        items: validItems,
        total: calculateTotal(validItems)
      );
    });
  }
}
```

### Background Data Synchronization
```dart
class SyncViewModel extends AsyncViewModelImpl<SyncStatus> {
  Timer? _syncTimer;
  
  @override
  Future<SyncStatus> init() async {
    _startPeriodicSync();
    return SyncStatus.idle();
  }
  
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _performBackgroundSync();
    });
  }
  
  Future<void> _performBackgroundSync() async {
    if (data.status != SyncStatusType.syncing) {
      transformDataStateSilently((status) => status.copyWith(
        status: SyncStatusType.syncing
      ));
      
      try {
        await syncRepository.performSync();
        transformDataState((status) => status.copyWith(
          status: SyncStatusType.completed,
          lastSync: DateTime.now()
        ));
      } catch (e) {
        transformDataState((status) => status.copyWith(
          status: SyncStatusType.failed,
          error: e.toString()
        ));
      }
    }
  }
  
  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
```

## Service Organization Pattern

```dart
mixin UserService {
  static final ReactiveNotifier<UserViewModel> userState = 
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
  
  // Convenience methods
  static UserModel get currentUser => userState.notifier.data;
  static bool get isLoggedIn => currentUser.isLoggedIn;
  
  static void login(String email, String password) {
    userState.notifier.login(email, password);
  }
  
  static void logout() {
    userState.notifier.logout();
  }
}

mixin CartService {
  static final ReactiveNotifier<CartViewModel> cartState = 
    ReactiveNotifier<CartViewModel>(() => CartViewModel());
  
  static void addProduct(Product product) {
    cartState.notifier.addItem(product);
  }
  
  static void removeProduct(String productId) {
    cartState.notifier.removeItem(productId);
  }
}
```

## Testing ViewModels

```dart
group('CartViewModel Tests', () {
  setUp(() {
    ReactiveNotifier.cleanup();
  });
  
  test('should add item to cart', () {
    final cart = CartService.cartState.notifier;
    final product = Product(id: '1', name: 'Test Product', price: 10.0);
    
    cart.addItem(product);
    
    expect(cart.data.items.length, equals(1));
    expect(cart.data.items.first.product, equals(product));
    expect(cart.data.total, equals(10.0));
  });
  
  test('should react to user login', () async {
    final cart = CartService.cartState.notifier;
    final user = UserService.userState.notifier;
    
    // Simulate user login
    user.updateState(UserModel(id: '1', name: 'Test', isLoggedIn: true));
    
    // Wait for reactive update
    await Future.delayed(Duration.zero);
    
    expect(cart.data.isGuest, equals(false));
  });
});
```

## Performance Considerations

### Silent Updates for Background Operations
```dart
// Update data without triggering UI rebuilds
viewModel.updateSilently(backgroundData);

// Later, notify UI when appropriate
viewModel.updateState(viewModel.data);
```

### Efficient State Transformations
```dart
// ❌ Inefficient - Creates unnecessary intermediate objects
void updateUserData(String name, String email) {
  final current = data;
  updateState(current.copyWith(name: name));
  updateState(data.copyWith(email: email));
}

// ✅ Efficient - Single state update
void updateUserData(String name, String email) {
  transformState((current) => current.copyWith(
    name: name,
    email: email
  ));
}
```