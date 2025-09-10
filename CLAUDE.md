# ReactiveNotifier - AI/Development Context Guide

## Quick Context
- **Version**: 2.13.0
- **Pattern**: Singleton state management with "create once, reuse always" philosophy
- **Architecture**: MVVM with reactive ViewModels and independent lifecycle management
- **Core Concept**: ViewModel lifecycle separated from UI lifecycle
- **Inspiration**: Android's LiveData and ViewModel architecture patterns
- **NEW v2.13.0**: State change hooks (onStateChanged, onAsyncStateChanged)
- **NEW v2.13.0**: Cross-service communication with explicit sandbox architecture  
- **Legacy v2.12.0**: Automatic BuildContext access in ViewModels for migration support

## Core Components

### ReactiveNotifier<T>
**Purpose**: Single instance state holder with automatic lifecycle
**When to use**: Simple state values, settings, flags, counters
**Key methods**: `updateState()`, `updateSilently()`, `transformState()`, `transformStateSilently()`, `listen()`, `from<T>()`

```dart
// Basic pattern
mixin ServiceName {
  static final ReactiveNotifier<Type> stateName = ReactiveNotifier<Type>(() => initialValue);
}
```

### ViewModel<T> (extends ChangeNotifier)
**Purpose**: Complex state with business logic and synchronous initialization
**When to use**: State that requires validation, complex operations, or synchronous initialization
**Key methods**: `init()`, `transformState()`, `transformStateSilently()`, `updateState()`, `updateSilently()`, `listenVM()`, `cleanState()`

```dart
class MyViewModel extends ViewModel<MyModel> {
  MyViewModel() : super(MyModel.initial());
  
  @override
  void init() {
    // Called once when created (MUST be synchronous)
  }
}
```

### AsyncViewModelImpl<T> (extends ChangeNotifier)
**Purpose**: Async operations with loading, success, error states
**When to use**: API calls, database operations, file I/O
**Key methods**: `init()`, `reload()`, `setupListeners()`, `removeListeners()`, `transformDataState()`, `transformDataStateSilently()`, `loadingState()`, `errorState()`
**States**: `AsyncState.initial()`, `loading()`, `success(data)`, `error(error)`
**Constructor Parameters**: `loadOnInit` (default: true), `waitForContext` (default: false)

#### Basic Usage
```dart
class DataViewModel extends AsyncViewModelImpl<List<Item>> {
  DataViewModel() : super(AsyncState.initial(), loadOnInit: true);
  
  @override
  Future<List<Item>> init() async {
    // Called once when created (MUST be asynchronous)
    return await repository.getData();
  }
}
```

#### NEW: waitForContext Parameter (v2.13.0+)
When `waitForContext: true`, the AsyncViewModel waits for BuildContext availability before initializing:

```dart
class ThemeAwareViewModel extends AsyncViewModelImpl<ThemeData> {
  ThemeAwareViewModel() : super(AsyncState.initial(), 
    loadOnInit: true, 
    waitForContext: true  // Wait for context before init()
  );
  
  @override
  Future<ThemeData> init() async {
    // This only runs after BuildContext becomes available
    final theme = Theme.of(requireContext('theme access'));
    return await loadThemeBasedData(theme);
  }
}
```

**waitForContext Benefits:**
- ViewModel stays in `AsyncState.initial()` until context is ready
- Automatic initialization once BuildContext becomes available
- Perfect for ViewModels needing MediaQuery, Theme, or Localizations
- No manual context management required

#### NEW: Global Context Initialization (v2.13.0+)
Initialize BuildContext globally for all ViewModels from app startup:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Initialize global context for all ViewModels
    ReactiveNotifier.initContext(context);
    
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}
```

**Global Context Benefits:**
- All ViewModels have immediate access to BuildContext
- No need for `waitForContext: true` on individual ViewModels  
- Theme, MediaQuery, Localizations available in all init() methods
- Automatic reinitialize of existing ViewModels with waitForContext: true
- Single setup for entire app

**Usage Pattern Comparison:**
```dart
// Option 1: Global initialization (recommended)
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  Widget build(context) {
    ReactiveNotifier.initContext(context); // ✅ All VMs get context
    return MaterialApp(...);
  }
}

// Option 2: Individual ViewModel waiting
class MyViewModel extends AsyncViewModelImpl<Data> {
  MyViewModel() : super(AsyncState.initial(), waitForContext: true); // ✅ This VM waits
}
```

## Builder Components (CURRENT API)

### ReactiveBuilder<T>
**Use case**: Simple state values
```dart
ReactiveBuilder<int>(
  notifier: CounterService.count,
  build: (value, notifier, keep) => Text('$value'),
)
```

### ReactiveViewModelBuilder<VM, T>
**Use case**: Custom ViewModels with complex state
```dart
ReactiveViewModelBuilder<UserViewModel, UserModel>(
  viewmodel: UserService.userState.notifier,
  build: (user, viewmodel, keep) => Text(user.name),
)
```

### ReactiveAsyncBuilder<VM, T>
**Use case**: AsyncViewModelImpl with loading/error states
```dart
ReactiveAsyncBuilder<MyViewModel, List<Item>>(
  notifier: DataService.items.notifier,
  onData: (items, viewModel, keep) => ListView(...),
  onLoading: () => CircularProgressIndicator(),
  onError: (error, stack) => Text('Error: $error'),
)
```

## ViewModel Lifecycle Management

### Core Lifecycle Pattern
ReactiveNotifier provides **independent ViewModel lifecycle** separated from UI:

1. **init()** - Initialization (synchronous for ViewModel, async for AsyncViewModelImpl)
2. **listen()/listenVM()** - Reactive communication between ViewModels
3. **setupListeners()/removeListeners()** - External listener management
4. **onResume()** - Post-initialization hook
5. **dispose()** - Cleanup

### Reactive Communication Between ViewModels
**Key Pattern**: Use instance variables + listenVM for cross-ViewModel communication

```dart
class NotificationViewModel extends ViewModel<NotificationModel> {
  NotificationViewModel() : super(NotificationModel.empty());
  
  // Instance variable to hold current state from other ViewModel
  UserModel? currentUser;
  
  @override
  void init() {
    // Listen to user changes reactively - gets current value and sets up listener
    UserService.userState.notifier.listenVM((userData) {
      // Update instance variable and react to changes
      currentUser = userData;
      updateNotificationsForUser(userData);
    });
    
    // Initialize with current user data
    if (currentUser != null) {
      updateNotificationsForUser(currentUser!);
    }
  }
  
  void updateNotificationsForUser(UserModel user) {
    transformState((state) => state.copyWith(
      userId: user.id,
      userName: user.name,
    ));
  }
}
```

## NEW: BuildContext Access in ViewModels (v2.12.0)

### ViewModelContextProvider Mixin

All ViewModels automatically inherit BuildContext access through the `ViewModelContextProvider` mixin:

```dart
// Automatically available in all ViewModels
abstract class ViewModel<T> extends ChangeNotifier 
    with HelperNotifier, ViewModelContextProvider {
  // BuildContext access methods are automatically available
}

abstract class AsyncViewModelImpl<T> extends ChangeNotifier
    with HelperNotifier, ViewModelContextProvider {
  // BuildContext access methods are automatically available  
}
```

### Context Access API

**Available methods in all ViewModels:**

- **`context`**: Nullable BuildContext getter (`BuildContext?`)
- **`hasContext`**: Boolean property to check availability (`bool`)
- **`requireContext([operation])`**: Required context with descriptive errors (`BuildContext`)

### Migration Use Cases

#### Riverpod Migration Pattern
```dart
class MigrationViewModel extends ViewModel<MigrationState> {
  MigrationViewModel() : super(MigrationState.initial());
  
  @override
  void init() {
    if (hasContext) {
      // Gradual migration from Riverpod
      final container = ProviderScope.containerOf(context!);
      final userData = container.read(userProvider);
      updateSilently(MigrationState.fromRiverpod(userData));
    } else {
      updateSilently(MigrationState.empty());
    }
  }
}
```

#### Theme/MediaQuery Access Pattern
```dart
class ResponsiveViewModel extends ViewModel<ResponsiveState> {
  ResponsiveViewModel() : super(ResponsiveState.initial());
  
  @override
  void init() {
    updateSilently(ResponsiveState.initial());
    _updateFromContext();
  }
  
  void _updateFromContext() {
    if (hasContext) {
      // Use postFrameCallback for safe MediaQuery access
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isDisposed && hasContext) {
          try {
            final mediaQuery = MediaQuery.of(requireContext('responsive design'));
            final screenWidth = mediaQuery.size.width;
            updateState(ResponsiveState(
              isTablet: screenWidth > 600,
              breakpoint: _getBreakpoint(screenWidth),
            ));
          } catch (e) {
            // Fallback if MediaQuery access fails
          }
        }
      });
    }
  }
}
```

### Context Lifecycle

1. **Registration**: Automatic when builders mount (`ReactiveBuilder`, `ReactiveViewModelBuilder`, `ReactiveAsyncBuilder`)
2. **Availability**: Context available after first builder mounts
3. **Multiple Builders**: Context remains available while any builder is active
4. **Cleanup**: Context cleared when last builder disposes
5. **Reinitialize**: ViewModels created without context are reinitialize when context becomes available

### Context Safety Patterns

```dart
class SafeContextViewModel extends ViewModel<SafeState> {
  @override
  void init() {
    // Always check availability first
    if (hasContext) {
      _handleWithContext();
    } else {
      _handleWithoutContext();
    }
  }
  
  void _handleWithContext() {
    try {
      final theme = Theme.of(requireContext('theme access'));
      // Use context-dependent logic
    } catch (e) {
      // Handle context access errors gracefully
      _handleWithoutContext();
    }
  }
  
  void _handleWithoutContext() {
    // Fallback logic when context unavailable
    updateSilently(SafeState.fallback());
  }
}
```

### Important Context Notes

- **Automatic**: Zero configuration required - works out of the box
- **Migration Focus**: Primary use case is gradual migration from Provider/Riverpod
- **Timing Sensitive**: Use `onResume()` or `postFrameCallback` for MediaQuery to avoid initState timing issues
- **Error Handling**: `requireContext()` provides descriptive errors for debugging
- **Backward Compatibility**: Fully backward compatible - existing code unchanged

## Decision Tree

### Choose ReactiveNotifier<T> when:
- Simple state values (int, bool, String)
- Settings or configuration
- State doesn't require initialization
- No complex business logic needed

### Choose ViewModel<T> when:
- Complex state objects
- State requires synchronous initialization
- Business logic is involved
- State validation needed
- Cross-ViewModel reactive communication needed

### Choose AsyncViewModelImpl<T> when:
- Loading data from external sources
- Need loading/error state handling
- API calls or database operations
- Background data synchronization
- Async initialization required
- Need to wait for BuildContext before initialization (`waitForContext: true`)

## Mandatory Patterns

### 1. Mixin Organization
```dart
// ✅ ALWAYS use mixins
mixin UserService {
  static final ReactiveNotifier<UserViewModel> userState = 
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

// ❌ NEVER use global variables
final userState = ReactiveNotifier<UserViewModel>(() => UserViewModel());
```

### 2. State Updates (All Available Methods)
```dart
// For ReactiveNotifier<T>
state.updateState(newValue);                    // Update with notification
state.updateSilently(newValue);                 // Update without notification
state.transformState((current) => newValue);    // Transform with notification
state.transformStateSilently((current) => newValue); // Transform without notification

// For ViewModel<T>
viewModel.updateState(newState);                // Update with notification
viewModel.updateSilently(newState);             // Update without notification
viewModel.transformState((current) => current.copyWith(...)); // Transform with notification
viewModel.transformStateSilently((current) => current.copyWith(...)); // Transform without notification

// For AsyncViewModelImpl<T>
asyncVM.updateState(data);                      // Update to success state
asyncVM.updateSilently(data);                   // Update to success state silently
asyncVM.transformState((state) => AsyncState.success(newData)); // Transform entire AsyncState
asyncVM.transformStateSilently((state) => AsyncState.loading()); // Transform AsyncState silently
asyncVM.transformDataState((data) => [...?data, newItem]); // Transform only data
asyncVM.transformDataStateSilently((data) => data?.sublist(0, 10)); // Transform data silently
asyncVM.loadingState();                         // Set loading state
asyncVM.errorState('Error message');            // Set error state
```

### 3. Reactive Communication Pattern
```dart
class SalesViewModel extends AsyncViewModelImpl<SaleModel> {
  SalesViewModel() : super(AsyncState.initial(), loadOnInit: false);
  
  CartModel? currentCart;
  
  @override
  void init() {
    // Listen to cart changes reactively
    CartService.cart.notifier.listenVM((cartData) {
      // Update instance variable and react automatically
      currentCart = cartData;
      if (cartData.products.isNotEmpty && cartData.readyForSale) {
        _processSaleAutomatically(cartData.products);
      }
    });
    
    // Process current cart if ready
    if (currentCart != null && currentCart!.readyForSale) {
      _processSaleAutomatically(currentCart!.products);
    }
  }
}
```

### 4. Listener Management (AsyncViewModelImpl only)
```dart
class MyViewModel extends AsyncViewModelImpl<DataType> {
  // Store listeners as class properties
  Future<void> _externalListener() async {
    if (hasInitializedListenerExecution) {
      // React to external state changes
    }
  }
  
  @override
  Future<void> setupListeners([List<String> currentListeners = const []]) async {
    ExternalService.state.notifier.addListener(_externalListener);
    await super.setupListeners(['_externalListener']);
  }
  
  @override
  Future<void> removeListeners([List<String> currentListeners = const []]) async {
    ExternalService.state.notifier.removeListener(_externalListener);
    await super.removeListeners(['_externalListener']);
  }
}
```

### 5. Related States System
```dart
mixin ShopService {
  static final ReactiveNotifier<UserState> userState = 
      ReactiveNotifier<UserState>(() => UserState.guest());
  static final ReactiveNotifier<CartState> cartState = 
      ReactiveNotifier<CartState>(() => CartState.empty());
  
  // Combined state that automatically updates when dependencies change
  static final ReactiveNotifier<ShopState> shopState = ReactiveNotifier<ShopState>(
    () => ShopState.initial(),
    related: [userState, cartState], // Automatically notified when these change
  );
  
  // Access related states
  static void showSummary() {
    final user = userState.notifier;
    final cart = shopState.from<CartState>();  // Get related state
  }
}
```

### 6. Testing Pattern
```dart
setUp(() {
  ReactiveNotifier.cleanup(); // Clear all states
  
  // Set test state directly
  MyService.state.notifier.updateSilently(TestData());
});
```

## Anti-Patterns (Never Do)

### 1. Creating instances in widgets
```dart
// ❌ NEVER
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = ReactiveNotifier<int>(() => 0); // Creates new instance every build
    return Text('${state.notifier}');
  }
}
```

### 2. Using old builder API
```dart
// ❌ OLD API - Don't use
ReactiveBuilder<int>(
  notifier: CounterService.count,
  builder: (value, keep) => Text('$value'), // Missing notifier parameter
)

// ✅ CURRENT API - Use this
ReactiveBuilder<int>(
  notifier: CounterService.count,
  build: (value, notifier, keep) => Text('$value'), // Correct parameters
)
```

### 3. Accessing .data outside builders
```dart
// ❌ NOT RECOMMENDED - Won't receive updates
final userData = UserService.userState.notifier.data;

// ✅ RECOMMENDED - Always receives updates
ReactiveViewModelBuilder<UserViewModel, UserModel>(
  viewmodel: UserService.userState.notifier,
  build: (userData, viewmodel, keep) {
    return Text(userData.name); // Always updated
  },
)

// ✅ ALTERNATIVE - Use listen/listenVM for reactive communication
UserModel? currentUser;
UserService.userState.notifier.listenVM((userData) {
  currentUser = userData;
  // React to changes
});
```

### 4. Complex logic in builders
```dart
// ❌ NEVER put business logic in builders
ReactiveBuilder<UserModel>(
  notifier: UserService.userState,
  build: (user, notifier, keep) {
    // Complex validation logic here - WRONG
    if (validateUser(user) && checkPermissions(user)) {
      return ComplexWidget();
    }
    return ErrorWidget();
  },
)

// ✅ Put logic in ViewModel methods
class UserViewModel extends ViewModel<UserModel> {
  bool get isValidUser => validateUser(data) && checkPermissions(data);
}
```

## Performance Optimization

### Use keep() for expensive widgets
```dart
ReactiveBuilder<UserModel>(
  notifier: UserService.userState,
  build: (user, notifier, keep) {
    return Column(
      children: [
        Text('Hello ${user.name}'), // Rebuilds when user changes
        keep(ExpensiveWidget()), // Never rebuilds
        keep(AnotherReactiveBuilder()), // Only rebuilds for its own state
      ],
    );
  },
)
```

### Silent updates for background operations
```dart
// Update data without triggering rebuilds
dataState.updateSilently(backgroundData);

// Later, notify when appropriate
dataState.updateState(dataState.notifier);
```

## Critical Recommendations

### Data Access Patterns
**⚠️ IMPORTANT**: Always access data inside ReactiveBuilder when possible. Using `.data` outside builders won't notify of changes.

### Reactive Communication Benefits
- **No Widget Coupling**: ViewModels communicate directly
- **Automatic Data Flow**: Changes propagate instantly between modules
- **Independent Lifecycle**: ViewModel lifecycle separate from UI
- **Real-time Synchronization**: State changes trigger automatic updates

### Testing Strategy
- Use `ReactiveNotifier.cleanup()` in setUp
- Update state directly with `updateSilently()` for test data
- Test actual service methods and ViewModels
- No complex mocking required

## Common Use Cases

### Global Context Setup
```dart
// main.dart - Single setup for entire app
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Enable context access for all ViewModels
    ReactiveNotifier.initContext(context);
    
    return MaterialApp(
      title: 'My App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}

// Any ViewModel can now access context in init()
class ThemeAwareViewModel extends AsyncViewModelImpl<AppTheme> {
  @override
  Future<AppTheme> init() async {
    final theme = Theme.of(requireContext('theme initialization'));
    final isDark = theme.brightness == Brightness.dark;
    return AppTheme(isDarkMode: isDark, primaryColor: theme.primaryColor);
  }
}

class ResponsiveViewModel extends ViewModel<ResponsiveState> {
  @override
  void init() {
    final mediaQuery = MediaQuery.of(requireContext('responsive setup'));
    final isTablet = mediaQuery.size.width > 600;
    updateSilently(ResponsiveState(isTablet: isTablet));
  }
}
```

### Cross-ViewModel Communication
```dart
// Shopping cart communicates with sales ViewModel automatically
class SalesViewModel extends AsyncViewModelImpl<SaleModel> {
  CartModel? currentCart;
  
  @override
  void init() {
    // Reactive communication - set up listener
    CartService.cart.notifier.listenVM((cartData) {
      currentCart = cartData;
      if (cartData.readyForSale) {
        processSale(cartData.products);
      }
    });
  }
}
```

### Multi-Source Reactive Dependencies
```dart
class ComplexViewModel extends AsyncViewModelImpl<ComplexData> {
  UserModel? currentUser;
  SettingsModel? currentSettings;
  
  @override
  void init() {
    // Listen to multiple sources reactively - set up listeners
    UserService.userViewModel.notifier.listenVM((userData) {
      currentUser = userData;
      _updateBasedOnDependencies();
    });
    
    SettingsService.settingsViewModel.notifier.listenVM((settingsData) {
      currentSettings = settingsData;
      _updateBasedOnDependencies();
    });
  }
}
```

## NEW: Widget-Aware Lifecycle Management (v2.13.0)

### Automatic Dispose & Reinitialize

ReactiveNotifier now tracks widget usage automatically and can dispose instances when no widgets are using them, then recreate them when needed again. This solves memory management concerns while maintaining the "create once, reuse always" philosophy.

#### Enable Auto-Dispose

```dart
mixin UserService {
  static final ReactiveNotifier<UserViewModel> userState = 
    ReactiveNotifier<UserViewModel>(
      () => UserViewModel(),
      autoDispose: true, // Enable automatic disposal
    );
    
  // Configure custom timeout (optional)
  static void configureAutoDispose() {
    userState.enableAutoDispose(timeout: Duration(minutes: 5));
  }
}
```

#### Reference Counting

The system automatically tracks active widgets:

```dart
// Widget 1 using the notifier
ReactiveBuilder<UserModel>(
  notifier: UserService.userState,
  build: (user, notifier, keep) => Text(user.name),
) // +1 reference

// Widget 2 using the same notifier  
ReactiveViewModelBuilder<UserViewModel, UserModel>(
  viewmodel: UserService.userState.notifier,
  build: (user, vm, keep) => Text(user.email),
) // +1 reference (total: 2)

// When both widgets dispose:
// References reach 0 -> Auto-dispose timer starts
// After timeout -> ReactiveNotifier cleans itself up
// When needed again -> Automatically recreates fresh instance
```

#### Manual Reinitialize

Force reinitialize after specific events:

```dart
mixin UserService {
  static final ReactiveNotifier<UserViewModel> userState = 
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
    
  static void logout() {
    // Reinitialize with fresh state after logout
    ReactiveNotifier.reinitializeInstance<UserViewModel>(
      userState.keyNotifier,
      () => UserViewModel(), // Fresh ViewModel
    );
  }
  
  static bool get isUserActive => 
    ReactiveNotifier.isInstanceActive<UserViewModel>(userState.keyNotifier);
}
```

#### Debug Information

Monitor lifecycle in development:

```dart
// Get reference count
final refCount = UserService.userState.referenceCount;

// Check if scheduled for dispose  
final isScheduled = UserService.userState.isScheduledForDispose;

// Get active references
final refs = UserService.userState.activeReferences;

print('User state references: $refCount');
print('Active refs: $refs');
```

### Benefits

1. **Memory Efficient**: Only keeps in memory what's actually being used
2. **Zero Breaking Changes**: Existing code works unchanged
3. **Automatic**: No manual memory management needed
4. **Configurable**: Custom timeouts and behavior per instance
5. **DevTools Ready**: Full visibility into lifecycle events

## NEW in v2.13.0: State Change Hooks

### ViewModel Hooks

ViewModels can now react to their own state changes internally using hooks:

```dart
class UserViewModel extends ViewModel<UserModel> {
  @override
  void onStateChanged(UserModel previous, UserModel next) {
    // React to any state change
    print('User changed from ${previous.name} to ${next.name}');
    
    // Log specific changes
    if (previous.email != next.email) {
      logEmailChange(previous.email, next.email);
    }
    
    // Trigger side effects
    if (previous.isActive != next.isActive) {
      notifyExternalServices(next.isActive);
    }
  }
}
```

### AsyncViewModel Hooks

AsyncViewModels have specialized hooks for async state changes:

```dart
class DataViewModel extends AsyncViewModelImpl<List<Item>> {
  @override
  void onAsyncStateChanged(AsyncState<List<Item>> previous, AsyncState<List<Item>> next) {
    // Handle loading states
    if (previous.isInitial && next.isLoading) {
      showLoadingIndicator();
    }
    
    // Handle success
    if (previous.isLoading && next.isSuccess) {
      hideLoadingIndicator();
      logSuccessfulLoad(next.data?.length ?? 0);
    }
    
    // Handle errors
    if (next.isError) {
      hideLoadingIndicator();
      showErrorMessage(next.error.toString());
    }
  }
}
```

### Hook Integration

Hooks are automatically called in all state update methods:
- `updateState()` - Triggers hooks with notifications
- `updateSilently()` - Triggers hooks without notifications  
- `transformState()` - Triggers hooks with notifications
- `transformStateSilently()` - Triggers hooks without notifications

## Cross-Service Communication (Explicit Architecture)

ReactiveNotifier v2.13.0 supports explicit communication between services using `listenVM`:

```dart
// User Service (Sandbox 1)
mixin UserService {
  static final ReactiveNotifier<UserViewModel> currentUser = 
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

// Notification Service (Sandbox 2)
mixin NotificationService {
  static final ReactiveNotifier<NotificationViewModel> notifications = 
    ReactiveNotifier<NotificationViewModel>(() => NotificationViewModel());
}

// Explicit cross-service communication
class NotificationViewModel extends ViewModel<NotificationModel> {
  @override
  void init() {
    // Listen to specific service instances (not magic type lookup)
    UserService.currentUser.notifier.listenVM((userData) {
      updateNotificationsForUser(userData);
    });
  }
}
```

### Multiple Instances per Type

```dart
// Multiple instances of same type in different services
mixin UserService {
  static final ReactiveNotifier<UserViewModel> mainUser = 
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
  static final ReactiveNotifier<UserViewModel> guestUser = 
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

mixin AdminService {
  static final ReactiveNotifier<UserViewModel> adminUser = 
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

// Explicit service access - no ambiguity
class DashboardViewModel extends ViewModel<DashboardModel> {
  @override
  void init() {
    UserService.mainUser.notifier.listenVM((mainUser) {
      updateDashboardForMainUser(mainUser);
    });
    
    AdminService.adminUser.notifier.listenVM((adminUser) {
      updateDashboardForAdmin(adminUser);
    });
  }
}
```

This guide covers the current API and reactive patterns of ReactiveNotifier v2.13.0. The new hooks system provides internal reactivity while maintaining the explicit, sandbox-based architecture for cross-service communication.
