# Core Concepts

## Philosophy: "Create Once, Reuse Always"

ReactiveNotifier follows a unique approach where states are created on demand and maintained throughout the app lifecycle. This means:

- States are created only when needed
- States persist across the app
- Cleanup focuses on resetting state, not destroying instances
- Organization through mixins, not global variables

## The Three Core Components

### 1. ReactiveNotifier<T>
**Purpose**: Simple state values with automatic lifecycle
**When to use**: Primitives, settings, flags, simple objects

```dart
mixin SettingsService {
  static final ReactiveNotifier<bool> darkMode = ReactiveNotifier<bool>(() => false);
  static final ReactiveNotifier<String> language = ReactiveNotifier<String>(() => 'en');
}
```

### 2. ViewModel<T>
**Purpose**: Complex state with business logic and synchronous initialization
**When to use**: Complex state objects, validation, business logic

```dart
class CartViewModel extends ViewModel<CartState> {
  CartViewModel() : super(CartState.empty());
  
  @override
  void init() {
    // Synchronous initialization only
    loadLocalCart();
  }
  
  void addItem(Product product) {
    transformState((state) => state.copyWith(
      items: [...state.items, CartItem(product: product)]
    ));
  }
}
```

### 3. AsyncViewModelImpl<T>
**Purpose**: Async operations with loading/error states
**When to use**: API calls, database operations, file I/O

```dart
class ProductsViewModel extends AsyncViewModelImpl<List<Product>> {
  ProductsViewModel() : super(AsyncState.initial(), loadOnInit: true);
  
  @override
  Future<List<Product>> init() async {
    // Asynchronous initialization
    return await productRepository.getProducts();
  }
  
  Future<void> refresh() async {
    loadingState();
    try {
      final products = await productRepository.getProducts();
      updateState(products);
    } catch (e) {
      errorState(e.toString());
    }
  }
}
```

## ViewModel Lifecycle

ReactiveNotifier provides independent ViewModel lifecycle management:

1. **Creation**: On first access, instance is created
2. **init()**: Called once when created (sync for ViewModel, async for AsyncViewModelImpl)
3. **listen()/listenVM()**: Reactive communication setup
4. **setupListeners()/removeListeners()**: External listener management (AsyncViewModelImpl only)
5. **onResume()**: Post-initialization hook
6. **dispose()**: Cleanup when no longer needed

## State Update Methods

### All Components Support:
- `updateState(newValue)` - Update with notification
- `updateSilently(newValue)` - Update without notification
- `transformState((current) => newValue)` - Transform with notification
- `transformStateSilently((current) => newValue)` - Transform without notification

### AsyncViewModelImpl Additional Methods:
- `transformDataState((data) => newData)` - Transform only data part
- `transformDataStateSilently((data) => newData)` - Transform data silently
- `loadingState()` - Set loading state
- `errorState(message)` - Set error state

## Reactive Communication

ViewModels can communicate reactively using `listen()` and `listenVM()`:

```dart
class NotificationViewModel extends ViewModel<NotificationState> {
  UserModel? currentUser;
  
  @override
  void init() {
    // Listen to user changes
    UserService.userState.notifier.listenVM((userData) {
      currentUser = userData;
      updateNotificationsForUser(userData);
    });
  }
}
```

## Related States System

States can depend on other states automatically:

```dart
mixin ShopService {
  static final ReactiveNotifier<UserState> userState = 
    ReactiveNotifier<UserState>(() => UserState.guest());
  
  static final ReactiveNotifier<CartState> cartState = 
    ReactiveNotifier<CartState>(() => CartState.empty());
  
  // Automatically notified when userState or cartState change
  static final ReactiveNotifier<ShopState> shopState = ReactiveNotifier<ShopState>(
    () => ShopState.initial(),
    related: [userState, cartState],
  );
}
```

## Decision Tree

**Choose ReactiveNotifier<T> when:**
- Simple values (int, bool, String)
- Settings or configuration
- No initialization needed
- No business logic

**Choose ViewModel<T> when:**
- Complex state objects
- Synchronous initialization needed
- Business logic involved
- Cross-ViewModel communication needed

**Choose AsyncViewModelImpl<T> when:**
- Loading external data
- Need loading/error states
- API calls or database operations
- Async initialization required