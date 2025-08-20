# ReactiveNotifier v2.12.0

**Professional State Management for Flutter** - A powerful, elegant, and secure solution for managing reactive state in Flutter applications. Built with enterprise-grade architecture in mind, ReactiveNotifier provides fine-grained control, automatic BuildContext access, memory leak prevention, and seamless migration support.

![reactive_notifier](https://github.com/user-attachments/assets/ca97c7e6-a254-4b19-b58d-fd07206ff6ee)

[![Dart SDK Version](https://img.shields.io/badge/Dart-SDK%20%3E%3D%203.5.4-0175C2?logo=dart)](https://dart.dev)
[![Flutter Platform](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![pub package](https://img.shields.io/pub/v/reactive_notifier.svg)](https://pub.dev/packages/reactive_notifier)
[![likes](https://img.shields.io/pub/likes/reactive_notifier?logo=dart)](https://pub.dev/packages/reactive_notifier/score)
[![downloads](https://img.shields.io/badge/dynamic/json?url=https://pub.dev/api/packages/reactive_notifier/score&label=downloads&query=$.downloadCount30Days&color=blue)](https://pub.dev/packages/reactive_notifier)
[![popularity](https://img.shields.io/pub/popularity/reactive_notifier?logo=dart)](https://pub.dev/packages/reactive_notifier/score)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/jhonacodes/reactive_notifier/workflows/ci/badge.svg)](https://github.com/jhonacodes/reactive_notifier/actions)

---

## 🚀 **What's New in v2.12.0**

### **🎯 Automatic BuildContext Access**
- **Zero-configuration** BuildContext access in ViewModels
- **Seamless migration** from Provider/Riverpod with `context` property
- **Safe context access** with `hasContext` and `requireContext()`
- **Automatic lifecycle** management across multiple builders

### **🛡️ Memory Management & Performance**
- **Context isolation** per ViewModel instance (no global contamination)
- **Memory leak prevention** with comprehensive listener tracking
- **Multiple listener support** with automatic cleanup
- **Enhanced disposal** logging and monitoring

### **🔧 Improved Architecture**
- **Unified behavior** between ViewModel and AsyncViewModelImpl
- **Consistent initialization** patterns with `reinitializeWithContext`
- **Error propagation** (no silent failures)
- **Production-ready** reliability with 469 passing tests

---

## ✨ **Key Features**

- 🚀 **Simple and intuitive API** - Clean, developer-friendly interface
- 🏗️ **Enterprise MVVM architecture** - Built for scalable applications
- 🔄 **Independent lifecycle management** - ViewModels exist beyond UI lifecycle
- 🎯 **Type-safe state management** - Full generics support with compile-time safety
- 📡 **Built-in Async and Stream support** - Handle loading, success, error states effortlessly
- 🔗 **Smart related states system** - Automatic dependency management
- 🛠️ **Repository/Service layer integration** - Clean separation of concerns
- ⚡ **High performance** with minimal rebuilds and widget preservation
- 🛠️ **Built-in DevTools extension** - Integrated debugging with real-time state monitoring
- 🐛 **Powerful debugging tools** - Comprehensive logging and monitoring
- 📊 **Detailed error reporting** - Descriptive error messages and stack traces
- 🧹 **Full lifecycle control** - Memory management and state cleaning
- 🔍 **Comprehensive state tracking** - Monitor all state changes and listeners
- 📊 **Granular state update control** - Silent updates, transformations, and notifications
- 🎯 **NEW: Automatic BuildContext access** for seamless migrations
- 🔄 **NEW: Memory leak prevention** with advanced listener tracking
- 🛡️ **NEW: Context isolation** prevents cross-ViewModel contamination

![performance_test](https://github.com/user-attachments/assets/0dc568d2-7e0a-46e5-8ad6-1fec92b772be)

---

## 📦 **Installation**

Add ReactiveNotifier to your `pubspec.yaml`:

```yaml
dependencies:
  reactive_notifier: ^2.12.0
```

Then run:
```bash
flutter pub get
```

### 🛠️ **DevTools Extension (Automatic)**

ReactiveNotifier includes a **built-in DevTools extension** that activates automatically when you import the package. No additional setup required!

**Features:**
- 📊 **Real-time state monitoring** - See all ReactiveNotifier instances live
- 🔍 **Interactive state inspector** - View and edit state directly from DevTools  
- 📈 **Performance analytics** - Monitor memory usage and rebuild performance
- 🐛 **Memory leak detection** - Automatic detection of potential issues
- 📝 **State change history** - Complete timeline of all state changes

**How to access:**
1. Run your app: `flutter run --debug`
2. Open Flutter DevTools (from VS Code, Android Studio, or browser)
3. Look for the **"ReactiveNotifier"** tab
4. Start debugging! 🎉

---

## 🎯 **Core Philosophy: "Create Once, Reuse Always"**

ReactiveNotifier follows a unique **singleton-based approach** that differs from traditional state management:

### **Traditional State Management**
```dart
// ❌ Creates new instances, memory overhead, complex cleanup
Provider.of<MyState>(context)  // New instance per access
BlocProvider.of<MyBloc>(context)  // Provider wrapper complexity
```

### **ReactiveNotifier Approach**
```dart
// ✅ Single instance, automatic lifecycle, zero boilerplate
MyService.state.notifier  // Always the same instance
```

### **Key Principles**

1. **🏗️ Create Once**: States are created only when first accessed
2. **♻️ Reuse Always**: Same instance used throughout app lifecycle  
3. **🧹 Clean, Don't Destroy**: Reset state to clean values, keep instances
4. **📁 Organize with Mixins**: Group related state in service mixins
5. **🔒 Memory Safe**: Automatic cleanup prevents leaks

**Benefits:**
- **🚀 Zero Boilerplate**: No providers, no complex setup
- **⚡ High Performance**: No instance recreation overhead
- **🧠 Predictable Memory**: Controlled instance lifecycle
- **🔧 Easy Testing**: Direct state access in tests
- **📈 Scalable**: Same patterns work for small apps and enterprise systems

---

## 🎯 **Quick Start Guide**

### **1. Simple State with ReactiveNotifier**

Perfect for primitive values, settings, and simple state:

```dart
// 📁 Create a service mixin to organize state
mixin ThemeService {
  static final ReactiveNotifier<bool> isDarkMode = 
      ReactiveNotifier<bool>(() => false);
  
  // 🔧 Business logic methods
  static void toggleTheme() {
    isDarkMode.updateState(!isDarkMode.notifier);
  }
  
  static void setTheme(bool isDark) {
    isDarkMode.updateState(isDark);
  }
}

// 🖼️ Use in widgets with ReactiveBuilder
class ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<bool>(
      notifier: ThemeService.isDarkMode,
      build: (isDark, notifier, keep) {
        return Column(
          children: [
            Text('Theme: ${isDark ? 'Dark' : 'Light'}'),
            Switch(
              value: isDark,
              onChanged: (_) => ThemeService.toggleTheme(),
            ),
            
            // 🔒 Widget preservation - prevents rebuilds
            keep(
              ExpensiveWidget(), // Won't rebuild when theme changes
            ),
          ],
        );
      },
    );
  }
}
```

### **2. Complex State with ViewModel**

For business logic, complex state objects, and synchronous operations:

> **🎯 IMPORTANT RULE**: 
> - **ViewModel classes** → Use `ReactiveViewModelNotifier<ViewModelClass>` + `ReactiveViewModelBuilder`
> - **AsyncViewModelImpl classes** → Use `ReactiveNotifier<AsyncViewModelClass>` + `ReactiveAsyncBuilder`

```dart
// 📊 Define your state model
class CounterState {
  final int count;
  final String message;
  final DateTime lastUpdated;
  
  const CounterState({
    required this.count,
    required this.message,
    required this.lastUpdated,
  });
  
  // 🔄 Immutable updates with copyWith
  CounterState copyWith({
    int? count,
    String? message,
    DateTime? lastUpdated,
  }) {
    return CounterState(
      count: count ?? this.count,
      message: message ?? this.message,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// 🧠 Create your ViewModel with business logic
class CounterViewModel extends ViewModel<CounterState> {
  CounterViewModel() : super(CounterState(
    count: 0,
    message: 'Initial state',
    lastUpdated: DateTime.now(),
  ));
  
  @override
  void init() {
    // 🚀 Initialization logic (called once when created)
    print('Counter ViewModel initialized at ${DateTime.now()}');
  }
  
  // 📈 Business logic methods
  void increment() {
    transformState((state) => state.copyWith(
      count: state.count + 1,
      message: 'Incremented to ${state.count + 1}',
      lastUpdated: DateTime.now(),
    ));
  }
  
  void decrement() {
    transformState((state) => state.copyWith(
      count: state.count - 1,
      message: 'Decremented to ${state.count - 1}',
      lastUpdated: DateTime.now(),
    ));
  }
  
  void reset() {
    updateState(CounterState(
      count: 0,
      message: 'Reset to zero',
      lastUpdated: DateTime.now(),
    ));
  }
}

// 📁 Organize in service mixin
mixin CounterService {
  static final ReactiveViewModelNotifier<CounterViewModel> viewModel =
      ReactiveViewModelNotifier<CounterViewModel>(() => CounterViewModel());
  
  // 🔧 Convenience methods (optional)
  static void increment() => viewModel.notifier.increment();
  static void decrement() => viewModel.notifier.decrement();
  static void reset() => viewModel.notifier.reset();
}

// 🖼️ Use with ReactiveViewModelBuilder
class CounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveViewModelBuilder<CounterViewModel, CounterState>(
      viewmodel: CounterService.viewModel.notifier,
      build: (state, viewmodel, keep) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Count: ${state.count}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(state.message),
                Text(
                  'Last updated: ${state.lastUpdated.toLocal()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                
                // 🔒 Preserve buttons (prevent rebuilds)
                keep(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: viewmodel.decrement,
                        child: const Icon(Icons.remove),
                      ),
                      ElevatedButton(
                        onPressed: viewmodel.reset,
                        child: const Icon(Icons.refresh),
                      ),
                      ElevatedButton(
                        onPressed: viewmodel.increment,
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

### **3. Async Operations with AsyncViewModelImpl**

For API calls, database operations, and async workflows:

> **🎯 REMEMBER**: AsyncViewModelImpl uses `ReactiveNotifier<AsyncViewModelClass>` + `ReactiveAsyncBuilder`

```dart
// 📊 Data model
class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  
  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });
  
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      category: json['category'],
    );
  }
}

// 🔗 Repository for data access
class ProductRepository {
  Future<List<Product>> getProducts() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    return [
      Product(id: '1', name: 'Laptop', price: 999.99, category: 'Electronics'),
      Product(id: '2', name: 'Book', price: 19.99, category: 'Education'),
      Product(id: '3', name: 'Coffee', price: 4.99, category: 'Food'),
    ];
  }
  
  Future<List<Product>> searchProducts(String query) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final products = await getProducts();
    return products.where((p) => 
      p.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}

// 🧠 Async ViewModel for managing async operations
class ProductsViewModel extends AsyncViewModelImpl<List<Product>> {
  final ProductRepository repository;
  
  ProductsViewModel(this.repository) 
      : super(AsyncState.initial(), loadOnInit: true);
  
  @override
  Future<List<Product>> init() async {
    // 🚀 Called automatically when loadOnInit: true
    return await repository.getProducts();
  }
  
  // 🔍 Business logic methods
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      await reload(); // Reload all products
      return;
    }
    
    loadingState(); // Set loading state
    
    try {
      final results = await repository.searchProducts(query);
      updateState(results); // Set success state
    } catch (error) {
      errorState('Search failed: $error'); // Set error state
    }
  }
  
  Future<void> refreshProducts() async {
    await reload(); // Reloads and calls init() again
  }
}

// 📁 Service organization
mixin ProductService {
  static final _repository = ProductRepository();
  
  static final ReactiveNotifier<ProductsViewModel> products = 
      ReactiveNotifier<ProductsViewModel>(() => ProductsViewModel(_repository));
  
  // 🔧 Convenience methods
  static Future<void> searchProducts(String query) =>
      products.notifier.searchProducts(query);
      
  static Future<void> refreshProducts() =>
      products.notifier.refreshProducts();
}

// 🖼️ UI with automatic loading, error, and success states
class ProductListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔍 Search field
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: ProductService.searchProducts,
          ),
        ),
        
        // 📊 Reactive async UI
        Expanded(
          child: ReactiveAsyncBuilder<ProductsViewModel, List<Product>>(
            notifier: ProductService.products.notifier,
            onData: (products, viewModel, keep) {
              return RefreshIndicator(
                onRefresh: viewModel.refreshProducts,
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text('${product.category} • \$${product.price}'),
                      leading: const Icon(Icons.shopping_cart),
                    );
                  },
                ),
              );
            },
            onLoading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading products...'),
                ],
              ),
            ),
            onError: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: ProductService.refreshProducts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            onInitial: () => const Center(
              child: Text('Ready to load products'),
            ),
          ),
        ),
      ],
    );
  }
}
```

---

## 🔗 **Reactive Communication Between ViewModels**

One of ReactiveNotifier's most powerful features is **direct communication between ViewModels** without widget coupling. This enables complex workflows with automatic state synchronization.

### **Cross-ViewModel Reactive Communication**

```dart
// 🛒 Cart ViewModel
class CartViewModel extends ViewModel<CartModel> {
  CartViewModel() : super(CartModel.empty());
  
  void addProduct(Product product) {
    transformState((cart) => cart.copyWith(
      products: [...cart.products, product],
      total: cart.total + product.price,
    ));
  }
  
  void markReadyForSale() {
    transformState((cart) => cart.copyWith(readyForSale: true));
  }
  
  void clearCart() {
    updateState(CartModel.empty());
  }
}

// 💰 Sales ViewModel - automatically reacts to cart changes
class SalesViewModel extends AsyncViewModelImpl<SaleModel> {
  SalesViewModel() : super(AsyncState.initial(), loadOnInit: false);
  
  // 📝 Instance variable to hold current cart state
  CartModel? currentCart;
  
  @override
  void init() {
    // 🔗 Listen to cart changes reactively
    CartService.cart.notifier.listenVM((cartData) {
      // Update instance variable and react to changes
      currentCart = cartData;
      
      // Automatic reaction: process sale when cart is ready
      if (cartData.products.isNotEmpty && cartData.readyForSale) {
        _processSaleAutomatically(cartData.products);
      }
    });
    
    // Get current cart state for initial processing
    final cartData = CartService.cart.notifier.data;
    if (cartData.products.isNotEmpty && cartData.readyForSale) {
      currentCart = cartData;
      _processSaleAutomatically(cartData.products);
    }
  }
  
  // 🚀 Called by user action - triggers the entire flow
  void initiateSale() {
    CartService.cart.notifier.markReadyForSale();
    // This triggers listenVM callback automatically
  }
  
  Future<void> _processSaleAutomatically(List<Product> products) async {
    loadingState();
    
    try {
      final sale = await salesRepository.createSale(products);
      updateState(sale);
      
      // 🔄 Communicate back to other ViewModels
      CartService.cart.notifier.clearCart();
      InventoryService.inventory.notifier.updateAfterSale(products);
      NotificationService.showSuccess('Sale completed!');
      
    } catch (error) {
      errorState('Sale failed: $error');
      
      // Reset cart state on error
      CartService.cart.notifier.transformState((cart) => 
        cart.copyWith(readyForSale: false));
    }
  }
}

// 📦 Inventory ViewModel - reacts to sales
class InventoryViewModel extends ViewModel<InventoryModel> {
  InventoryViewModel() : super(InventoryModel.initial());
  
  UserModel? currentUser;
  SaleModel? lastSale;
  
  @override
  void init() {
    // 🔗 React to multiple ViewModels
    UserService.user.notifier.listenVM((userData) {
      currentUser = userData;
      _updateInventoryAccess();
    });
    
    SalesService.sales.notifier.listenVM((saleData) {
      lastSale = saleData;
      if (saleData.isCompleted) {
        _updateStockAfterSale(saleData);
      }
    });
    
    // Get current state for initial setup
    currentUser = UserService.user.notifier.data;
    lastSale = SalesService.sales.notifier.hasData ? SalesService.sales.notifier.data : null;
    _updateInventoryAccess();
  }
  
  void updateAfterSale(List<Product> products) {
    // Reduce inventory quantities
    transformState((inventory) => inventory.reduceStock(products));
  }
  
  void _updateInventoryAccess() {
    if (currentUser?.hasInventoryAccess == true) {
      transformState((inventory) => inventory.enableManagement());
    }
  }
  
  void _updateStockAfterSale(SaleModel sale) {
    transformState((inventory) => 
      inventory.updateLastSale(sale.id, sale.completedAt));
  }
}

---

## ⚠️ **CRITICAL: Reactive Communication Pattern Rules**

### **❌ WRONG Patterns - Never Do This:**

```dart
// ❌ NEVER assign listenVM to variable
currentUser = UserService.user.notifier.listenVM((userData) => {});

// ❌ NEVER assign inside listenVM callback  
UserService.user.notifier.listenVM((userData) {
  currentUser = userData; // ❌ WRONG
});
```

### **✅ CORRECT Pattern - Always Do This:**

```dart
class MyViewModel extends ViewModel<MyState> {
  UserModel? currentUser; // Instance variable
  
  @override
  void init() {
    // ✅ Set up reactive listener (no assignment)
    UserService.user.notifier.listenVM((userData) {
      // React to changes - update your own state
      _handleUserChange(userData);
    });
    
    // ✅ Get current state separately  
    currentUser = UserService.user.notifier.data;
  }
  
  void _handleUserChange(UserModel userData) {
    // Update your ViewModel's state based on the change
    transformState((state) => state.copyWith(
      userName: userData.name,
      isAdmin: userData.hasAdminAccess,
    ));
  }
}
```

### **🎯 Key Rules:**
1. **Never assign `listenVM()` to variables** - it sets up listeners, doesn't return values
2. **Never assign inside callbacks** - use the data to trigger reactions
3. **Get current data separately** - use `.data` property for immediate access
4. **Use reactive callbacks to update your own state** - not to store external state

---

// 📁 Service organization
mixin CartService {
  static final ReactiveViewModelNotifier<CartViewModel> cart = 
    ReactiveViewModelNotifier<CartViewModel>(() => CartViewModel());
}

mixin SalesService {
  static final ReactiveNotifier<SalesViewModel> sales = 
    ReactiveNotifier<SalesViewModel>(() => SalesViewModel());
}

mixin InventoryService {
  static final ReactiveViewModelNotifier<InventoryViewModel> inventory = 
    ReactiveViewModelNotifier<InventoryViewModel>(() => InventoryViewModel());
}

// 🖼️ Simple UI - ViewModels handle all the complexity
class SalesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🛒 Cart status
        ReactiveViewModelBuilder<CartViewModel, CartModel>(
          viewmodel: CartService.cart.notifier,
          build: (cart, viewmodel, keep) {
            return Card(
              child: ListTile(
                title: Text('Cart: ${cart.products.length} items'),
                subtitle: Text('Total: \$${cart.total.toStringAsFixed(2)}'),
                trailing: cart.products.isNotEmpty
                  ? ElevatedButton(
                      onPressed: SalesService.sales.notifier.initiateSale,
                      child: const Text('Process Sale'),
                    )
                  : null,
              ),
            );
          },
        ),
        
        // 💰 Sales status
        ReactiveAsyncBuilder<SalesViewModel, SaleModel>(
          notifier: SalesService.sales.notifier,
          onData: (sale, viewModel, keep) => Card(
            child: ListTile(
              title: Text('Sale #${sale.id}'),
              subtitle: Text('Completed: ${sale.completedAt}'),
              leading: const Icon(Icons.check_circle, color: Colors.green),
            ),
          ),
          onLoading: () => const Card(
            child: ListTile(
              title: Text('Processing sale...'),
              leading: CircularProgressIndicator(),
            ),
          ),
          onError: (error, _) => Card(
            child: ListTile(
              title: Text('Sale failed'),
              subtitle: Text(error.toString()),
              leading: const Icon(Icons.error, color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
```

### **Key Benefits of Reactive Communication:**

- **🔄 Automatic Data Flow**: Changes in one ViewModel trigger updates in dependent ViewModels
- **🚫 No Widget Coupling**: Direct ViewModel-to-ViewModel communication
- **⚡ Real-time Synchronization**: State changes propagate instantly
- **🧹 Clean Architecture**: Each ViewModel maintains its own responsibility
- **📈 Scalable**: Add new ViewModels without modifying existing ones

---

## 🆕 **Automatic BuildContext Access in ViewModels**

**NEW in v2.12.0**: ViewModels now provide automatic BuildContext access for seamless migration from Provider/Riverpod and context-dependent operations.

### **🔧 Zero Configuration Required**

Context access is **automatic** - no setup needed:

```dart
class MyViewModel extends ViewModel<MyState> {
  @override
  void init() {
    // ✅ Context automatically available
    if (hasContext) {
      final theme = Theme.of(context!);
      final mediaQuery = MediaQuery.of(context!);
      // Use context for migrations, theme access, etc.
    }
  }
}
```

### **🔄 Seamless Migration Examples**

Perfect for gradual migration from other state management solutions:

#### **From Riverpod**

```dart
// 🔄 Gradual migration from Riverpod to ReactiveNotifier
class RiverpodMigrationViewModel extends ViewModel<UserState> {
  RiverpodMigrationViewModel() : super(UserState.initial());
  
  @override
  void init() {
    if (hasContext) {
      // 📦 Access existing Riverpod providers during migration
      final container = ProviderScope.containerOf(requireContext('migration'));
      final userData = container.read(userProvider);
      final settingsData = container.read(settingsProvider);
      final themeData = container.read(themeProvider);
      
      // 🔄 Transfer data to ReactiveNotifier
      updateSilently(UserState.fromRiverpod(
        user: userData,
        settings: settingsData,
        theme: themeData,
      ));
    } else {
      updateSilently(UserState.guest());
    }
  }
}

// Gradual replacement strategy
mixin MigrationService {
  // Step 1: Keep Riverpod providers running
  static final riverpodMigration = ReactiveViewModelNotifier<RiverpodMigrationViewModel>(
    () => RiverpodMigrationViewModel()
  );
  
  // Step 2: New features use ReactiveNotifier
  static final newFeature = ReactiveViewModelNotifier<NewFeatureViewModel>(
    () => NewFeatureViewModel()
  );
}
```

#### **From Provider**

```dart
// 🔄 Migration from Provider pattern
class ProviderMigrationViewModel extends ViewModel<AppState> {
  ProviderMigrationViewModel() : super(AppState.initial());
  
  @override
  void init() {
    if (hasContext) {
      // 📦 Access existing Provider instances
      final userProvider = Provider.of<UserProvider>(context!, listen: false);
      final cartProvider = Provider.of<CartProvider>(context!, listen: false);
      final themeProvider = Provider.of<ThemeProvider>(context!, listen: false);
      
      // 🔄 Migrate data to ReactiveNotifier
      updateSilently(AppState.fromProvider(
        user: userProvider.currentUser,
        cart: cartProvider.items,
        theme: themeProvider.currentTheme,
      ));
      
      // 🔗 Set up reactive listeners for new architecture
      _setupReactiveListeners(userProvider, cartProvider);
    }
  }
  
  void _setupReactiveListeners(UserProvider userProvider, CartProvider cartProvider) {
    // Bridge old Provider changes to new reactive system
    userProvider.addListener(() {
      if (!isDisposed) {
        transformState((state) => state.copyWith(
          user: userProvider.currentUser,
        ));
      }
    });
  }
}
```

#### **From BLoC**

```dart
// 🔄 Migration from BLoC pattern
class BlocMigrationViewModel extends ViewModel<CounterState> {
  CounterMigrationViewModel() : super(CounterState.initial());
  
  // Keep reference to existing BLoC during migration
  CounterBloc? _legacyBloc;
  
  @override
  void init() {
    if (hasContext) {
      // 📦 Access existing BLoC
      _legacyBloc = BlocProvider.of<CounterBloc>(context!);
      
      // 🔄 Sync current BLoC state
      updateSilently(CounterState(count: _legacyBloc!.state));
      
      // 🔗 Listen to BLoC changes and mirror in ReactiveNotifier
      _legacyBloc!.stream.listen((blocState) {
        if (!isDisposed) {
          updateState(CounterState(count: blocState));
        }
      });
    }
  }
  
  // New methods use ReactiveNotifier
  void increment() {
    transformState((state) => state.copyWith(count: state.count + 1));
    
    // During migration, also update legacy BLoC
    _legacyBloc?.add(CounterIncrement());
  }
  
  @override
  void dispose() {
    _legacyBloc = null;
    super.dispose();
  }
}
```

#### **From GetX**

```dart
// 🔄 Migration from GetX
class GetXMigrationViewModel extends ViewModel<UserProfile> {
  GetXMigrationViewModel() : super(UserProfile.empty());
  
  @override
  void init() {
    // 📦 Access existing GetX controllers
    final userController = Get.find<UserController>();
    final settingsController = Get.find<SettingsController>();
    
    // 🔄 Transfer GetX state to ReactiveNotifier
    updateSilently(UserProfile(
      name: userController.name.value,
      email: userController.email.value,
      preferences: settingsController.preferences.value,
    ));
    
    // 🔗 React to GetX changes during migration period
    ever(userController.name, (String name) {
      if (!isDisposed) {
        transformState((state) => state.copyWith(name: name));
      }
    });
    
    ever(settingsController.preferences, (prefs) {
      if (!isDisposed) {
        transformState((state) => state.copyWith(preferences: prefs));
      }
    });
  }
}

// Service with GetX compatibility
mixin UserMigrationService {
  static final profile = ReactiveViewModelNotifier<GetXMigrationViewModel>(
    () => GetXMigrationViewModel()
  );
  
  // Convenience methods that work with both systems
  static void updateName(String name) {
    // Update ReactiveNotifier
    profile.notifier.transformState((state) => state.copyWith(name: name));
    
    // Also update GetX during migration
    if (Get.isRegistered<UserController>()) {
      Get.find<UserController>().name.value = name;
    }
  }
}
```

#### **From MobX**

```dart
// 🔄 Migration from MobX
class MobXMigrationViewModel extends ViewModel<StoreState> {
  MobXMigrationViewModel() : super(StoreState.initial());
  
  // Keep reference to MobX store during migration
  late TodoStore _mobxStore;
  
  @override
  void init() {
    if (hasContext) {
      // 📦 Access existing MobX store
      _mobxStore = Provider.of<TodoStore>(context!, listen: false);
      
      // 🔄 Sync current MobX state
      updateSilently(StoreState(
        todos: _mobxStore.todos,
        filter: _mobxStore.filter,
        isLoading: _mobxStore.isLoading,
      ));
      
      // 🔗 React to MobX changes
      autorun((_) {
        if (!isDisposed) {
          updateState(StoreState(
            todos: _mobxStore.todos,
            filter: _mobxStore.filter,
            isLoading: _mobxStore.isLoading,
          ));
        }
      });
    }
  }
  
  // New methods use ReactiveNotifier pattern
  void addTodo(String title) {
    transformState((state) => state.copyWith(
      todos: [...state.todos, Todo(title: title)],
    ));
    
    // During migration, also update MobX store
    _mobxStore.addTodo(title);
  }
}
```

#### **From Redux**

```dart
// 🔄 Migration from Redux
class ReduxMigrationViewModel extends ViewModel<AppState> {
  ReduxMigrationViewModel() : super(AppState.initial());
  
  Store<AppState>? _reduxStore;
  
  @override
  void init() {
    if (hasContext) {
      // 📦 Access existing Redux store
      _reduxStore = StoreProvider.of<AppState>(context!);
      
      // 🔄 Sync current Redux state
      updateSilently(_reduxStore!.state);
      
      // 🔗 Listen to Redux store changes
      _reduxStore!.onChange.listen((state) {
        if (!isDisposed) {
          updateState(state);
        }
      });
    }
  }
  
  // Dispatch actions to both systems during migration
  void incrementCounter() {
    // Update ReactiveNotifier
    transformState((state) => state.copyWith(
      counter: state.counter + 1,
    ));
    
    // Also dispatch to Redux during migration
    _reduxStore?.dispatch(IncrementAction());
  }
}
```

#### **From setState (StatefulWidget)**

```dart
// 🔄 Migration from StatefulWidget setState pattern
class SetStateMigrationViewModel extends ViewModel<CounterState> {
  SetStateMigrationViewModel() : super(CounterState(count: 0));
  
  @override
  void init() {
    // Initialize with any persisted state
    _loadPersistedState();
  }
  
  void _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCount = prefs.getInt('counter') ?? 0;
      updateSilently(CounterState(count: savedCount));
    } catch (e) {
      // Handle error
    }
  }
  
  // Replace setState calls with reactive updates
  void increment() {
    transformState((state) => state.copyWith(
      count: state.count + 1,
      lastUpdated: DateTime.now(),
    ));
    
    // Persist state
    _saveState();
  }
  
  void _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counter', data.count);
  }
}

// Before: StatefulWidget with setState
class OldCounterWidget extends StatefulWidget {
  @override
  _OldCounterWidgetState createState() => _OldCounterWidgetState();
}

class _OldCounterWidgetState extends State<OldCounterWidget> {
  int counter = 0;
  
  void _increment() {
    setState(() {  // ❌ Old way
      counter++;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Text('$counter');
  }
}

// After: ReactiveNotifier
class NewCounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveViewModelBuilder<SetStateMigrationViewModel, CounterState>(
      viewmodel: CounterMigrationService.counter.notifier,
      build: (state, viewmodel, keep) {
        return Text('${state.count}');  // ✅ New way
      },
    );
  }
}
```

### **📱 Responsive Design with MediaQuery**

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
      // 🔒 Safe MediaQuery access with postFrameCallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isDisposed && hasContext) {
          try {
            final mediaQuery = MediaQuery.of(requireContext('responsive design'));
            final screenWidth = mediaQuery.size.width;
            
            updateState(ResponsiveState(
              isTablet: screenWidth > 600,
              isLandscape: mediaQuery.orientation == Orientation.landscape,
              screenSize: mediaQuery.size,
            ));
          } catch (e) {
            // Graceful fallback if MediaQuery access fails
          }
        }
      });
    }
  }
}
```

### **🎨 Theme-Aware ViewModels**

```dart
class ThemedViewModel extends AsyncViewModelImpl<ThemedData> {
  ThemedViewModel() : super(AsyncState.initial(), loadOnInit: true);
  
  @override
  Future<ThemedData> init() async {
    if (hasContext) {
      final theme = Theme.of(requireContext('theme access'));
      final brightness = theme.brightness;
      final primaryColor = theme.primaryColor;
      
      // 🎨 Fetch theme-appropriate data
      return await repository.getThemedData(
        isDark: brightness == Brightness.dark,
        accentColor: primaryColor,
      );
    }
    
    return ThemedData.defaultLight();
  }
}
```

### **🔒 Context API Reference**

All ViewModels automatically inherit these context access methods:

| Method | Type | Description |
|--------|------|-------------|
| `context` | `BuildContext?` | Nullable context getter for safe access |
| `hasContext` | `bool` | Check if context is currently available |
| `requireContext([operation])` | `BuildContext` | Required context with descriptive errors |

```dart
class ExampleViewModel extends ViewModel<ExampleState> {
  @override
  void init() {
    // 🔒 Safe nullable access
    final ctx = context; // BuildContext?
    
    // ✅ Check availability
    if (hasContext) {
      final navigator = Navigator.of(context!);
      final scaffold = Scaffold.of(context!);
    }
    
    // 🎯 Required access with helpful error messages
    try {
      final messenger = ScaffoldMessenger.of(
        requireContext('showing snackbar')
      );
    } catch (e) {
      // Descriptive error: "BuildContext Required But Not Available for showing snackbar"
      print(e);
    }
  }
}
```

### **📋 Context Lifecycle**

1. **Registration**: Automatic when builders mount
2. **Availability**: Context available after first builder mounts  
3. **Multiple Builders**: Context remains available while any builder is active
4. **Cleanup**: Context cleared when last builder disposes
5. **Reinitialize**: ViewModels created without context are reinitialized when context becomes available

### **⚠️ Important Usage Notes**

- **🎯 Primary Use**: Migration from Provider/Riverpod
- **⏰ Timing**: Use `onResume()` or `postFrameCallback` for MediaQuery
- **🔧 Automatic**: Works with all builders (ReactiveBuilder, ReactiveViewModelBuilder, ReactiveAsyncBuilder)
- **🛡️ Isolation**: Each ViewModel gets its own context instance
- **📝 Error Handling**: `requireContext()` provides descriptive errors

---

## 🚀 **ReactiveContext - Clean Global State Access**

**NEW in v2.12.0**: ReactiveContext provides a **clean, intuitive API** to access global reactive state directly from BuildContext without verbose ReactiveBuilder calls.

### **🎯 Two Complementary Features:**

1. **ReactiveContext Extensions** - Clean context access for global state (theme, language, etc.)
2. **registerNotifier** - Register notifiers for context access without builders

### **⚡ When to Use Each Approach:**

**ReactiveContext (recommended for):**
- 🌍 Global app state (language, theme, user preferences)
- 📱 State accessed from many different widgets
- 🚫 Avoiding duplicate ReactiveBuilder code across the app
- 🎨 Quick access to theme/language without boilerplate

**ReactiveBuilder (recommended for):**
- 🎯 Granular state management
- 🧩 Component-specific state
- 🔧 State requiring precise rebuild control
- 💼 Complex state logic with business rules

### **🔧 Setup and Usage:**

```dart
// 📊 Define your global state models
class AppLanguage {
  final String name;
  final String code;
  final bool isRTL;
  
  AppLanguage(this.name, this.code, this.isRTL);
}

class AppTheme {
  final bool isDark;
  final Color primaryColor;
  final String fontFamily;
  
  AppTheme(this.isDark, this.primaryColor, this.fontFamily);
}

// 🏗️ Create services with ReactiveNotifier
mixin LanguageService {
  static final ReactiveNotifier<AppLanguage> language = ReactiveNotifier<AppLanguage>(
    () => AppLanguage('English', 'en', false),
  );
  
  static void switchToSpanish() => language.updateState(
    AppLanguage('Español', 'es', false)
  );
  
  static void switchToArabic() => language.updateState(
    AppLanguage('العربية', 'ar', true)
  );
}

mixin ThemeService {
  static final ReactiveNotifier<AppTheme> theme = ReactiveNotifier<AppTheme>(
    () => AppTheme(false, Colors.blue, 'Roboto'),
  );
  
  static void toggleDarkMode() {
    final current = theme.notifier;
    theme.updateState(AppTheme(!current.isDark, current.primaryColor, current.fontFamily));
  }
  
  static void changePrimaryColor(Color color) {
    final current = theme.notifier;
    theme.updateState(AppTheme(current.isDark, color, current.fontFamily));
  }
}

// 🎯 Method 1: Create clean extension methods for context access
extension AppLanguageContext on BuildContext {
  AppLanguage get language => getReactiveState(LanguageService.language);
  void switchLanguage(String name, String code, bool isRTL) {
    LanguageService.language.updateState(AppLanguage(name, code, isRTL));
  }
}

extension AppThemeContext on BuildContext {
  AppTheme get theme => getReactiveState(ThemeService.theme);
  void toggleTheme() => ThemeService.toggleDarkMode();
}

// 🎯 Method 2: Register notifiers for context access (alternative approach)
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          // Register notifiers once at app level
          context.registerNotifier(LanguageService.language, key: 'language');
          context.registerNotifier(ThemeService.theme, key: 'theme');
          
          return MyHomePage();
        },
      ),
    );
  }
}
```

### **💡 Clean Usage in Widgets:**

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          context.language.name,
          style: TextStyle(
            fontFamily: context.theme.fontFamily,
            color: context.theme.primaryColor,
          ),
        ),
      ),
      body: Column(
        children: [
          // 🌍 Clean access to global reactive state
          Card(
            child: ListTile(
              title: Text('Current Language: ${context.language.name}'),
              subtitle: Text('Code: ${context.language.code}'),
              trailing: Switch(
                value: context.language.isRTL,
                onChanged: null, // Read-only display
              ),
            ),
          ),
          
          Card(
            child: ListTile(
              title: Text('Theme Mode'),
              subtitle: Text(context.theme.isDark ? 'Dark Mode' : 'Light Mode'),
              trailing: Switch(
                value: context.theme.isDark,
                onChanged: (_) => context.toggleTheme(),
              ),
            ),
          ),
          
          // 🔒 Widget preservation with clean API
          ExpensiveWidget().keep('expensive_component'),
          
          // 📱 Context-aware preservation
          context.keep(
            AnotherExpensiveWidget(),
            'context_preserved_widget',
          ),
          
          // 🎛️ Action buttons
          Wrap(
            children: [
              ElevatedButton(
                onPressed: () => context.switchLanguage('Español', 'es', false),
                child: const Text('Español'),
              ),
              ElevatedButton(
                onPressed: () => context.switchLanguage('العربية', 'ar', true),
                child: const Text('العربية'),
              ),
              ElevatedButton(
                onPressed: () => ThemeService.changePrimaryColor(Colors.green),
                child: const Text('Green Theme'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### **🔍 Alternative: Generic Access Patterns**

```dart
class GenericAccessWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🏷️ Access by type
        Text('Language: ${context<AppLanguage>().name}'),
        Text('Theme: ${context<AppTheme>().isDark ? 'Dark' : 'Light'}'),
        
        // 🔑 Access by registered key
        Text('Language: ${context.getByKey<AppLanguage>('language').name}'),
        Text('Theme: ${context.getByKey<AppTheme>('theme').primaryColor}'),
        
        // 🎯 Direct notifier access
        Text('Direct: ${context.getNotifier<AppLanguage>().notifier.code}'),
      ],
    );
  }
}
```

### **⚡ Performance Benefits:**

- **🚀 Zero Boilerplate**: No ReactiveBuilder needed for simple access
- **📦 Automatic Rebuilds**: Widgets rebuild only when accessed state changes
- **🧠 Intelligent Caching**: State accessed once is cached until next change
- **🔧 Granular Control**: Combine with ReactiveBuilder for complex cases

### **🎛️ Advanced Usage: Mixed Patterns**

```dart
class MixedPatternWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🌍 Global state with clean context access
        Text('Theme: ${context.theme.isDark ? 'Dark' : 'Light'}'),
        Text('Language: ${context.language.name}'),
        
        // 🎯 Complex state with ReactiveBuilder for business logic
        ReactiveViewModelBuilder<UserViewModel, UserState>(
          viewmodel: UserService.profile.notifier,
          build: (userState, viewModel, keep) {
            return Card(
              child: Column(
                children: [
                  Text('User: ${userState.name}'),
                  Text('Language: ${context.language.name}'), // Mixed!
                  
                  // Complex business logic in builder
                  if (userState.hasNotifications)
                    keep(NotificationBadge(
                      count: userState.notificationCount,
                      theme: context.theme, // Global state in component
                    )),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
```

### **🔑 Key Advantages:**

1. **🎯 Clean API**: `context.theme.isDark` vs verbose ReactiveBuilder
2. **📱 Global State Focus**: Perfect for app-wide settings
3. **🔄 Automatic Reactivity**: Still gets reactive updates
4. **🧩 Flexible**: Combine with ReactiveBuilder when needed
5. **⚡ Performance**: No unnecessary builder overhead
6. **🛠️ Developer Experience**: Intuitive, readable code

### **🎛️ Precision Rebuilds with ReactiveContextBuilder**

For **maximum performance** when you need ultra-precise rebuilds, use `ReactiveContextBuilder`. This specialized builder optimizes reactive context access by using InheritedWidget strategy for specified notifiers:

```dart
class UltraOptimizedWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveContextBuilder(
      // 🎯 Force InheritedWidget strategy for specific notifiers
      forceInheritedFor: [
        LanguageService.language,
        ThemeService.theme,
      ],
      child: Column(
        children: [
          // 🚀 These will use optimized InheritedWidget rebuilds
          Text('Language: ${context.language.name}'),
          Text('Theme: ${context.theme.isDark ? 'Dark' : 'Light'}'),
          
          // 🔧 Mix with ReactiveBuilder for complex logic
          ReactiveViewModelBuilder<UserViewModel, UserState>(
            viewmodel: UserService.profile.notifier,
            build: (userState, viewModel, keep) {
              return Card(
                child: Column(
                  children: [
                    Text('User: ${userState.name}'),
                    // 🌍 Global state access inside reactive builder
                    Text('UI Language: ${context.language.name}'),
                    // 🎨 Theme-aware styling
                    Container(
                      color: context.theme.primaryColor,
                      child: Text('Themed Container'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

### **⚡ Performance Strategies:**

1. **Default Strategy**: Automatic smart rebuilds for simple usage
2. **Optimized Strategy**: `ReactiveContextBuilder` for high-performance apps
3. **Mixed Strategy**: Combine both for different parts of your app

> **🎯 Builder Pattern**: `ReactiveContextBuilder` follows the same naming convention as `ReactiveBuilder`, `ReactiveViewModelBuilder`, and `ReactiveAsyncBuilder` - making it intuitive for developers familiar with ReactiveNotifier's ecosystem.

```dart
class PerformanceAwareApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ReactiveContextBuilder(
        // 🏎️ Optimize only frequently accessed global state
        forceInheritedFor: [
          LanguageService.language,
          ThemeService.theme,
        ],
        child: MyHomePage(),
      ),
    );
  }
}
```

### **⚠️ Important Notes:**

- **Context Registration**: Use `registerNotifier()` or extension methods
- **Global State Only**: Best for app-wide state, not component-specific
- **Combine Wisely**: Use with ReactiveBuilder for complex state logic
- **Performance**: Perfect for simple access, ReactiveBuilder for complex cases
- **Ultra Performance**: Use `ReactiveContextBuilder` for maximum efficiency

---

## 📊 **State Update Methods**

ReactiveNotifier provides comprehensive methods for updating state with precise control:

### **Direct Updates**

```dart
// 📝 For simple ReactiveNotifier<T>
counter.updateState(5);                    // Updates and notifies widgets
counter.updateSilently(5);                 // Updates without rebuilding widgets

// 🧠 For ViewModel<T>
userViewModel.updateState(newUser);         // Updates and notifies
userViewModel.updateSilently(newUser);      // Updates without notifying

// ⚡ For AsyncViewModelImpl<T>
productsViewModel.updateState(newProducts); // Updates to success state and notifies
productsViewModel.updateSilently(newProducts); // Updates to success state silently
```

### **Transform Updates**

Transform updates allow you to modify state based on the current value:

```dart
// 📝 Simple ReactiveNotifier<T>
counter.transformState((current) => current + 1);
counter.transformStateSilently((current) => current + 1);

// 🧠 ViewModel<T>
user.transformState((current) => current.copyWith(name: 'New Name'));
user.transformStateSilently((current) => current.copyWith(email: 'new@email.com'));

// ⚡ AsyncViewModelImpl<T> - Transform entire AsyncState
products.transformState((currentState) => AsyncState.success(newProducts));
products.transformStateSilently((currentState) => AsyncState.loading());

// 🎯 AsyncViewModelImpl<T> - Transform only the data within success state
products.transformDataState((currentData) => [...?currentData, newProduct]);
products.transformDataStateSilently((currentData) => currentData?.sublist(0, 10));
```

### **AsyncViewModelImpl Specific Methods**

```dart
// 🔄 State control methods
productsViewModel.loadingState();                    // Set to loading state
productsViewModel.errorState('Network error');       // Set to error state
productsViewModel.cleanState();                      // Reset to initial and reload

// 📊 Data access
final data = productsViewModel.data;                 // Get current data (throws if error)
final hasData = productsViewModel.hasData;           // Check if has valid data
final isLoading = productsViewModel.isLoading;       // Check if loading
final error = productsViewModel.error;               // Get current error (if any)

// 🔄 Async operations
await productsViewModel.reload();                    // Reload data (calls init() again)
```

### **Silent vs Notifying Updates**

```dart
// 🔊 Notifying updates (default) - Rebuilds UI
userService.updateState(newUser);           // UI rebuilds
cartService.transformState((cart) => cart.addItem(product)); // UI updates

// 🔇 Silent updates - No UI rebuilds (background operations)
userService.updateSilently(backgroundUpdate);  // No UI change
cartService.transformStateSilently((cart) => cart.prepareData()); // Background prep
```

**When to use silent updates:**
- 📝 Background data preparation
- 🔧 Internal state modifications
- 📊 Logging and analytics updates
- 🕐 Timestamp and metadata updates

---

## 🏗️ **Builder Components**

ReactiveNotifier provides specialized builders for different state types:

### **ReactiveBuilder<T>** - Simple Values

For primitive types and simple state values:

```dart
ReactiveBuilder<bool>(
  notifier: SettingsService.isNotificationsEnabled,
  build: (enabled, notifier, keep) {
    return Card(
      child: SwitchListTile(
        title: const Text('Notifications'),
        subtitle: Text(enabled ? 'Enabled' : 'Disabled'),
        value: enabled,
        onChanged: (value) => SettingsService.toggleNotifications(),
      ),
    );
  },
)
```

### **ReactiveViewModelBuilder<VM, T>** - Complex State

For ViewModel-based state with business logic:

```dart
ReactiveViewModelBuilder<ProfileViewModel, UserProfile>(
  viewmodel: ProfileService.viewModel.notifier,
  build: (profile, viewmodel, keep) {
    return Column(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(profile.avatarUrl),
          radius: 50,
        ),
        Text(
          profile.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(profile.email),
        
        // 🔒 Prevent button rebuilds
        keep(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: viewmodel.editProfile,
                child: const Text('Edit'),
              ),
              ElevatedButton(
                onPressed: viewmodel.logout,
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ],
    );
  },
)
```

### **ReactiveAsyncBuilder<VM, T>** - Async Operations

For async operations with loading, error, and success states:

```dart
ReactiveAsyncBuilder<ProductsViewModel, List<Product>>(
  notifier: ProductService.products.notifier,
  onData: (products, viewModel, keep) {
    return Column(
      children: [
        // 📊 Header with statistics
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${products.length} Products'),
                IconButton(
                  onPressed: viewModel.refreshProducts,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ),
        
        // 📋 Products list
        Expanded(
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text('\$${product.price}'),
                onTap: () => ProductService.selectProduct(product.id),
              );
            },
          ),
        ),
      ],
    );
  },
  onLoading: () => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Loading products...'),
      ],
    ),
  ),
  onError: (error, stackTrace) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text('Error: $error'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: ProductService.products.notifier.reload,
          child: const Text('Retry'),
        ),
      ],
    ),
  ),
  onInitial: () => const Center(
    child: Text('Ready to load products'),
  ),
)
```

### **Widget Preservation with keep()**

All builders provide a `keep()` function to prevent unnecessary rebuilds:

```dart
ReactiveBuilder<int>(
  notifier: CounterService.counter,
  build: (count, notifier, keep) {
    return Column(
      children: [
        // 🔄 Rebuilds when count changes
        Text('Count: $count'),
        
        // 🔒 These widgets NEVER rebuild when count changes
        keep(
          ExpensiveAnimationWidget(),
        ),
        
        keep(
          Image.asset('assets/counter_background.png'),
        ),
        
        // 🔒 Even other ReactiveBuilders inside keep won't rebuild
        keep(
          ReactiveBuilder<bool>(
            notifier: ThemeService.isDarkMode,
            build: (isDark, themeNotifier, innerKeep) {
              return Container(
                color: isDark ? Colors.grey[800] : Colors.white,
                child: Text('Theme: ${isDark ? 'Dark' : 'Light'}'),
              );
            },
          ),
        ),
      ],
    );
  },
)
```

---

## 🎯 **Advanced Listener Management**

ReactiveNotifier provides sophisticated listener management for complex ViewModels that need to react to external state changes.

### **setupListeners() and removeListeners()**

For ViewModels that need to listen to other state changes:

```dart
class OrdersViewModel extends AsyncViewModelImpl<List<Order>> {
  final OrderRepository repository;
  
  // 📝 Store listener methods as class properties
  Future<void> _userListener() async {
    if (hasInitializedListenerExecution) {
      // React to user changes (login/logout)
      await reload(); // Reload orders for new user
    }
  }
  
  Future<void> _paymentListener() async {
    if (hasInitializedListenerExecution) {
      final lastPayment = PaymentService.lastPayment.notifier;
      if (lastPayment.isCompleted) {
        // Update order status after payment
        await _updateOrderStatus(lastPayment.orderId, 'PAID');
      }
    }
  }
  
  // 🏷️ Define listener names for debugging
  final List<String> _listenersName = ["_userListener", "_paymentListener"];
  
  OrdersViewModel(this.repository) 
      : super(AsyncState.initial(), loadOnInit: true);

  @override
  Future<List<Order>> init() async {
    return await repository.getOrders();
  }
  
  @override
  Future<void> setupListeners([List<String> currentListeners = const []]) async {
    // 🔗 Register listeners with their respective services
    UserService.instance.notifier.addListener(_userListener);
    PaymentService.lastPayment.notifier.addListener(_paymentListener);
    
    // 📊 Call super with listeners list for logging and lifecycle management
    await super.setupListeners(_listenersName);
  }
  
  @override
  Future<void> removeListeners([List<String> currentListeners = const []]) async {
    // 🔌 Unregister all listeners
    UserService.instance.notifier.removeListener(_userListener);
    PaymentService.lastPayment.notifier.removeListener(_paymentListener);
    
    // 🧹 Call super for cleanup
    await super.removeListeners(_listenersName);
  }
  
  Future<void> _updateOrderStatus(String orderId, String status) async {
    // Update specific order status
    transformDataState((orders) {
      return orders?.map((order) {
        if (order.id == orderId) {
          return order.copyWith(status: status);
        }
        return order;
      }).toList();
    });
  }
}
```

### **Automatic Lifecycle Management**

Listeners are automatically managed at key points:

| Event | setupListeners() | removeListeners() |
|-------|------------------|-------------------|
| Initial load completion | ✅ | |
| Before reload() | | ✅ |
| During cleanState() | ✅ | ✅ |
| During dispose() | | ✅ |

### **Memory Leak Prevention**

The listener pattern prevents memory leaks by ensuring:

- 🔌 Listeners are properly removed when data is reloaded
- 🧹 Listeners are cleaned up when the ViewModel is disposed
- 🚫 No duplicate listeners are created when a ViewModel is reused
- 📊 Comprehensive logging for debugging listener issues

---

## 🔗 **Direct State Listening APIs**

ReactiveNotifier provides powerful APIs for listening to state changes from anywhere in your application:

### **listen(callback)** - Simple State Listening

For listening to **simple ReactiveNotifier<T>** values:

```dart
// 🔊 Listen to theme changes in a service or widget
class ThemeListenerWidget extends StatefulWidget {
  @override
  _ThemeListenerWidgetState createState() => _ThemeListenerWidgetState();
}

class _ThemeListenerWidgetState extends State<ThemeListenerWidget> {
  bool? currentTheme;
  
  @override
  void initState() {
    super.initState();
    
    // Listen to theme changes
    ThemeService.isDarkMode.listen((isDark) {
      if (mounted) {
        setState(() {
          currentTheme = isDark;
        });
        print('Theme changed to: ${isDark ? 'Dark' : 'Light'}');
        // Update other systems based on theme change
      }
    });
    
    // Get initial value
    currentTheme = ThemeService.isDarkMode.notifier;
  }
  
  @override
  Widget build(BuildContext context) {
    return Text('Current theme is dark: ${currentTheme ?? false}');
  }
}

// Example: Listen to network status across the app
mixin NetworkStatusListener {
  static void setupGlobalNetworkListener() {
    NetworkService.isConnected.listen((isConnected) {
      if (isConnected) {
        // Resume pending operations
        SyncService.resumeSync();
        AnalyticsService.sendPendingEvents();
      } else {
        // Handle offline mode
        CacheService.enableOfflineMode();
        NotificationService.showOfflineMessage();
      }
    });
  }
}
```

### **listenVM(callback)** - ViewModel State Listening

For listening to **ViewModel internal state changes**:

```dart
// 🔊 Listen to user state changes across the app
class NotificationViewModel extends ViewModel<NotificationState> {
  NotificationViewModel() : super(NotificationState.empty());
  
  UserModel? currentUser;
  
  @override
  void init() {
    // 🔗 Listen to user changes reactively
    UserService.userState.notifier.listenVM((userData) {
      // Update instance variable and react to changes
      currentUser = userData;
      updateNotificationsForUser(userData);
    });
    
    // Get current user data for initial setup
    currentUser = UserService.userState.notifier.data;
    if (currentUser != null) {
      updateNotificationsForUser(currentUser!);
    }
  }
  
  void updateNotificationsForUser(UserModel user) {
    transformState((state) => state.copyWith(
      userId: user.id,
      userName: user.name,
      welcomeMessage: 'Welcome ${user.name}!',
      unreadCount: user.unreadNotifications,
    ));
  }
}
```

### **Cross-ViewModel Communication Example**

Complete example of ViewModels communicating reactively:

```dart
// 🛒 Shopping Cart ViewModel
class CartViewModel extends ViewModel<CartModel> {
  CartViewModel() : super(CartModel.empty());
  
  void addProduct(Product product) {
    transformState((cart) => cart.copyWith(
      products: [...cart.products, product],
      total: cart.total + product.price,
      lastUpdated: DateTime.now(),
    ));
  }
  
  void checkout() {
    transformState((cart) => cart.copyWith(
      status: CartStatus.readyForCheckout,
    ));
  }
}

// 💳 Payment ViewModel - reacts to cart changes
class PaymentViewModel extends AsyncViewModelImpl<PaymentModel> {
  PaymentViewModel() : super(AsyncState.initial(), loadOnInit: false);
  
  CartModel? currentCart;
  
  @override
  void init() {
    // 🔗 Listen to cart changes reactively
    CartService.cart.notifier.listenVM((cartData) {
      // React to changes - update payment state
      if (cartData.status == CartStatus.readyForCheckout) {
        _preparePayment(cartData);
      }
    });
    
    // Get current cart state separately
    currentCart = CartService.cart.notifier.data;
  }
  
  Future<void> _preparePayment(CartModel cart) async {
    loadingState();
    
    try {
      final paymentData = await paymentRepository.preparePayment(
        amount: cart.total,
        items: cart.products,
      );
      
      updateState(paymentData);
      
      // Notify other systems
      AnalyticsService.trackCheckoutStarted(cart.total);
      
    } catch (error) {
      errorState('Payment preparation failed: $error');
    }
  }
}

// 📊 Analytics ViewModel - reacts to multiple sources
class AnalyticsViewModel extends ViewModel<AnalyticsModel> {
  AnalyticsViewModel() : super(AnalyticsModel.initial());
  
  CartModel? currentCart;
  PaymentModel? currentPayment;
  UserModel? currentUser;
  
  @override
  void init() {
    // 🔗 Listen to multiple ViewModels
    CartService.cart.notifier.listenVM((cartData) {
      currentCart = cartData;
      _updateAnalytics();
    });
    
    PaymentService.payment.notifier.listenVM((paymentData) {
      currentPayment = paymentData;
      _updateAnalytics();
    });
    
    UserService.user.notifier.listenVM((userData) {
      currentUser = userData;
      _updateAnalytics();
    });
  }
  
  void _updateAnalytics() {
    transformState((state) => state.copyWith(
      cartValue: currentCart?.total ?? 0.0,
      paymentStatus: currentPayment?.status ?? 'none',
      userId: currentUser?.id ?? 'anonymous',
      lastUpdate: DateTime.now(),
    ));
  }
  
  void trackCheckoutStarted(double amount) {
    transformState((state) => state.copyWith(
      events: [...state.events, 
        AnalyticsEvent.checkoutStarted(amount, DateTime.now())
      ],
    ));
  }
}

// 📁 Service organization
mixin CartService {
  static final ReactiveViewModelNotifier<CartViewModel> cart = 
    ReactiveViewModelNotifier<CartViewModel>(() => CartViewModel());
}

mixin PaymentService {
  static final ReactiveNotifier<PaymentViewModel> payment = 
    ReactiveNotifier<PaymentViewModel>(() => PaymentViewModel());
}

mixin AnalyticsService {
  static final ReactiveViewModelNotifier<AnalyticsViewModel> analytics = 
    ReactiveViewModelNotifier<AnalyticsViewModel>(() => AnalyticsViewModel());
    
  static void trackCheckoutStarted(double amount) =>
    analytics.notifier.trackCheckoutStarted(amount);
}
```

**Key Benefits:**
- 🔄 **Automatic Synchronization**: Changes propagate instantly between ViewModels
- 🚫 **No Widget Coupling**: Direct ViewModel-to-ViewModel communication
- 📊 **Real-time Updates**: State changes trigger immediate reactions
- 🧹 **Clean Architecture**: Each ViewModel maintains its own responsibility
- 📈 **Scalable**: Add new reactive relationships without modifying existing code

---

## 🔗 **Related States System**

For managing interdependent states efficiently:

```dart
mixin ShopService {
  // 📊 Individual state notifiers
  static final ReactiveNotifier<UserState> userState = 
      ReactiveNotifier<UserState>(() => UserState.guest());
  
  static final ReactiveNotifier<CartState> cartState = 
      ReactiveNotifier<CartState>(() => CartState.empty());
  
  static final ReactiveNotifier<ProductsState> productsState = 
      ReactiveNotifier<ProductsState>(() => ProductsState.initial());
  
  // 🔗 Combined state that automatically updates when dependencies change
  static final ReactiveNotifier<ShopState> shopState = ReactiveNotifier<ShopState>(
    () => ShopState.initial(),
    related: [userState, cartState, productsState], // Auto-notified when these change
  );
  
  // 🎯 Access related states in multiple ways
  static void showShopSummary() {
    // 1. Direct access
    final user = userState.notifier;
    
    // 2. Using from<T>()
    final cart = shopState.from<CartState>();
    
    // 3. Using keyNotifier
    final products = shopState.from<ProductsState>(productsState.keyNotifier);
    
    print("${user.name}'s cart has ${cart.items.length} items");
    print("Products from ${products.categories.length} categories");
  }
}
```

**Benefits:**
- 🔄 **Automatic Updates**: Shop state rebuilds when any dependency changes
- 🎯 **Flexible Access**: Multiple ways to access related states
- 🧹 **Clean Organization**: Keep related states grouped together

---

## 🧪 **Testing with ReactiveNotifier**

ReactiveNotifier makes testing straightforward with its singleton pattern and direct state access:

### **Essential Testing Setup**

```dart
// 📋 Basic test setup
void main() {
  group('CounterViewModel Tests', () {
    setUp(() {
      // 🧹 CRITICAL: Always cleanup before each test
      ReactiveNotifier.cleanup();
      
      // 🔄 Create fresh instances to avoid cross-test contamination
      CounterService.createNew();
    });
    
    // ... tests
  });
}
```

### **Testing Simple State**

```dart
test('should increment counter correctly', () {
  // 🔧 Setup initial state
  CounterService.counter.updateSilently(0);
  
  // 🎯 Execute action
  CounterService.increment();
  
  // ✅ Verify result
  expect(CounterService.counter.notifier, equals(1));
});
```

### **Testing ViewModels**

```dart
testWidgets('should display counter value', (WidgetTester tester) async {
  // 🔧 Setup mock state
  CounterService.viewModel.notifier.updateSilently(CounterState(
    count: 5,
    message: 'Test Initial State',
    lastUpdated: DateTime.now(),
  ));
  
  // 🖼️ Build widget
  await tester.pumpWidget(
    MaterialApp(
      home: CounterWidget(), // Use actual widget that uses CounterService
    ),
  );
  
  // ✅ Verify UI displays mocked state
  expect(find.text('Count: 5'), findsOneWidget);
  expect(find.text('Test Initial State'), findsOneWidget);
  
  // 🎯 Test interaction
  CounterService.viewModel.notifier.increment();
  await tester.pump();
  
  // ✅ Verify UI updated
  expect(find.text('Count: 6'), findsOneWidget);
});
```

### **Testing Async ViewModels**

```dart
testWidgets('should handle async operations', (WidgetTester tester) async {
  // 🔧 Setup mock repository
  final mockRepository = MockProductRepository();
  when(mockRepository.getProducts()).thenAnswer((_) async => [
    Product(id: '1', name: 'Test Product', price: 99.99),
  ]);
  
  // 🔧 Setup ViewModel with mock
  ProductService.products.notifier.updateSilently(
    ProductsViewModel(mockRepository)
  );
  
  // 🖼️ Build widget
  await tester.pumpWidget(
    MaterialApp(
      home: ProductListWidget(),
    ),
  );
  
  // ✅ Verify loading state
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  
  // ⏰ Wait for async operation
  await tester.pumpAndSettle();
  
  // ✅ Verify success state
  expect(find.text('Test Product'), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsNothing);
});
```

### **Testing Context-Dependent ViewModels**

```dart
testWidgets('ViewModel should access context correctly', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: ReactiveViewModelBuilder<ResponsiveViewModel, ResponsiveState>(
        viewmodel: ResponsiveService.instance.notifier,
        build: (state, viewModel, keep) => Text('Theme: ${state.theme}'),
      ),
    ),
  );

  await tester.pumpAndSettle();
  
  // ✅ Verify context access worked
  expect(find.text('Theme: dark'), findsOneWidget);
  
  final vm = ResponsiveService.instance.notifier;
  expect(vm.hasContext, isTrue);
});
```

### **Service Pattern for Testing**

Create services with a `createNew()` method for fresh instances:

```dart
mixin MyService {
  static ReactiveViewModelNotifier<MyViewModel>? _instance;
  
  static ReactiveViewModelNotifier<MyViewModel> get instance {
    _instance ??= ReactiveViewModelNotifier<MyViewModel>(MyViewModel.new);
    return _instance!;
  }
  
  // 🔄 Essential for testing - creates fresh instance
  static ReactiveViewModelNotifier<MyViewModel> createNew() {
    _instance = ReactiveViewModelNotifier<MyViewModel>(MyViewModel.new);
    return _instance!;
  }
}
```

### **Testing Benefits**

ReactiveNotifier's testing approach offers several advantages:

1. **🎯 No Complex Mocking**: Use actual services with controlled data
2. **🔄 Same Instances**: Test real components with predictable state
3. **🧹 Simple Setup**: Just cleanup and set mock data
4. **📊 Direct Access**: Verify state changes directly
5. **🔧 No Providers**: No complex dependency injection setup

---

## 🏗️ **Recommended Architecture**

ReactiveNotifier works optimally with feature-based MVVM architecture:

### **📁 Project Structure**

```
src/
├── features/
│   ├── auth/                   # Authentication feature
│   │   ├── ui/
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   └── widgets/
│   │   │       ├── login_form.dart
│   │   │       └── auth_button.dart
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   └── auth_state.dart
│   │   ├── viewmodels/
│   │   │   └── auth_viewmodel.dart
│   │   ├── repositories/
│   │   │   └── auth_repository.dart
│   │   └── services/
│   │       └── auth_service.dart    # ReactiveNotifier mixin
│   │
│   ├── products/               # Product catalog feature
│   │   ├── ui/
│   │   ├── models/
│   │   ├── viewmodels/
│   │   ├── repositories/
│   │   └── services/
│   │
│   └── cart/                   # Shopping cart feature
│       ├── ui/
│       ├── models/
│       ├── viewmodels/
│       ├── repositories/
│       └── services/
│
├── shared/                     # Shared components
│   ├── ui/
│   │   ├── widgets/
│   │   └── theme/
│   ├── services/
│   │   ├── api_service.dart
│   │   └── storage_service.dart
│   └── utils/
│
└── core/                       # Core app infrastructure
    ├── routing/
    ├── config/
    └── constants/
```

### **🔧 Feature Implementation Example**

```dart
// 📁 features/auth/models/auth_state.dart
class AuthState {
  final UserModel? user;
  final bool isAuthenticated;
  final String? token;
  final DateTime? loginTime;
  
  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.token,
    this.loginTime,
  });
  
  factory AuthState.initial() => const AuthState();
  
  factory AuthState.authenticated(UserModel user, String token) {
    return AuthState(
      user: user,
      isAuthenticated: true,
      token: token,
      loginTime: DateTime.now(),
    );
  }
  
  AuthState copyWith({
    UserModel? user,
    bool? isAuthenticated,
    String? token,
    DateTime? loginTime,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      loginTime: loginTime ?? this.loginTime,
    );
  }
}

// 📁 features/auth/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<AuthResult> login(String email, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiService apiService;
  
  AuthRepositoryImpl(this.apiService);
  
  @override
  Future<AuthResult> login(String email, String password) async {
    final response = await apiService.post('/auth/login', {
      'email': email,
      'password': password,
    });
    
    return AuthResult.fromJson(response.data);
  }
  
  @override
  Future<void> logout() async {
    await apiService.post('/auth/logout');
  }
  
  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await apiService.get('/auth/user');
      return UserModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
}

// 📁 features/auth/viewmodels/auth_viewmodel.dart
class AuthViewModel extends AsyncViewModelImpl<AuthState> {
  final AuthRepository repository;
  
  AuthViewModel(this.repository) 
      : super(AsyncState.initial(), loadOnInit: true);
  
  @override
  Future<AuthState> init() async {
    // 🔍 Check for existing authentication
    final user = await repository.getCurrentUser();
    
    if (user != null) {
      return AuthState.authenticated(user, 'existing_token');
    }
    
    return AuthState.initial();
  }
  
  Future<void> login(String email, String password) async {
    loadingState();
    
    try {
      final result = await repository.login(email, password);
      
      if (result.success) {
        final authState = AuthState.authenticated(result.user, result.token);
        updateState(authState);
        
        // 🔄 Communicate to other features
        UserService.updateCurrentUser(result.user);
        CartService.initializeForUser(result.user.id);
        
      } else {
        errorState(result.error ?? 'Login failed');
      }
    } catch (error) {
      errorState('Login error: $error');
    }
  }
  
  Future<void> logout() async {
    loadingState();
    
    try {
      await repository.logout();
      updateState(AuthState.initial());
      
      // 🔄 Clean up other features
      UserService.clearCurrentUser();
      CartService.clearCart();
      
    } catch (error) {
      errorState('Logout error: $error');
    }
  }
}

// 📁 features/auth/services/auth_service.dart
mixin AuthService {
  static final ReactiveNotifier<AuthViewModel> _auth = 
      ReactiveNotifier<AuthViewModel>(() => AuthViewModel(
        AuthRepositoryImpl(ApiService.instance)
      ));
  
  static ReactiveNotifier<AuthViewModel> get auth => _auth;
  
  // 🔧 Convenience methods
  static Future<void> login(String email, String password) =>
      _auth.notifier.login(email, password);
      
  static Future<void> logout() => _auth.notifier.logout();
  
  static bool get isAuthenticated => 
      _auth.notifier.hasData && _auth.notifier.data!.isAuthenticated;
      
  static UserModel? get currentUser => 
      _auth.notifier.hasData ? _auth.notifier.data!.user : null;
}

// 📁 features/auth/ui/screens/login_screen.dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: ReactiveAsyncBuilder<AuthViewModel, AuthState>(
        notifier: AuthService.auth.notifier,
        onData: (authState, viewModel, keep) {
          if (authState.isAuthenticated) {
            // Navigate to home screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/home');
            });
            return const Center(child: Text('Login successful!'));
          }
          
          return const LoginForm();
        },
        onLoading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Logging in...'),
            ],
          ),
        ),
        onError: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Login failed: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => AuthService.auth.notifier.reload(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### **🔄 Cross-Feature Communication**

```dart
// Features communicate through their services without direct dependencies

// 📁 features/cart/viewmodels/cart_viewmodel.dart
class CartViewModel extends ViewModel<CartState> {
  CartViewModel() : super(CartState.empty());
  
  UserModel? currentUser;
  
  @override
  void init() {
    // 🔗 Listen to auth changes reactively
    AuthService.auth.notifier.listenVM((authState) {
      // React to authentication changes
      if (authState.isAuthenticated) {
        _loadCartForUser(authState.user!.id);
      } else {
        clearCart();
      }
    });
    
    // Get current user state separately
    final authState = AuthService.auth.notifier.data;
    currentUser = authState?.user;
  }
  
  void _loadCartForUser(String userId) {
    // Load user's cart from storage
    transformState((cart) => cart.loadForUser(userId));
  }
  
  void clearCart() {
    updateState(CartState.empty());
  }
}

// 📁 features/products/viewmodels/products_viewmodel.dart
class ProductsViewModel extends AsyncViewModelImpl<List<Product>> {
  ProductsViewModel(this.repository) 
      : super(AsyncState.initial(), loadOnInit: true);
      
  UserModel? currentUser;
  
  @override
  Future<List<Product>> init() async {
    // 🔗 React to user changes for personalized products
    AuthService.auth.notifier.listenVM((authState) {
      // React to authentication changes
      if (authState.isAuthenticated) {
        _loadPersonalizedProducts();
      }
    });
    
    // Get current user state for initial load
    final authState = AuthService.auth.notifier.data;
    currentUser = authState?.user;
    
    // Load initial products
    return await repository.getProducts();
  }
  
  void _loadPersonalizedProducts() {
    if (currentUser != null) {
      // Reload with personalized recommendations
      reload();
    }
  }
}
```

**Architecture Benefits:**
- 🏗️ **Feature Isolation**: Each feature is self-contained
- 🔄 **Reactive Communication**: Features communicate through reactive state
- 🧹 **Clean Dependencies**: No circular dependencies between features
- 📈 **Scalable**: Add new features without modifying existing ones
- 🧪 **Testable**: Each feature can be tested independently

---

## 🚫 **Anti-Patterns and Best Practices**

### **❌ What NOT to Do**

```dart
// ❌ DON'T create instances in widgets
class BadWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This creates a new instance on every build - DON'T DO THIS!
    final counter = ReactiveNotifier<int>(() => 0);
    return Text('${counter.notifier}');
  }
}

// ❌ DON'T use global variables
final globalCounter = ReactiveNotifier<int>(() => 0); // Bad organization

// ❌ DON'T access .data outside builders (won't receive updates)
class BadDataAccess extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = CounterService.counter.notifier; // Static, no updates
    return Text('Count: $count'); // Won't update when counter changes
  }
}

// ❌ DON'T put business logic in builders
ReactiveBuilder<UserModel>(
  notifier: UserService.user,
  build: (user, notifier, keep) {
    // Don't do complex validation here - put it in ViewModel
    if (validateUser(user) && checkPermissions(user) && authenticateUser(user)) {
      return ComplexWidget();
    }
    return ErrorWidget();
  },
)
```

### **✅ What TO Do**

```dart
// ✅ DO organize with mixins
mixin CounterService {
  static final ReactiveNotifier<int> counter = 
      ReactiveNotifier<int>(() => 0);
      
  static void increment() => counter.updateState(counter.notifier + 1);
}

// ✅ DO access data inside builders
class GoodDataAccess extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<int>(
      notifier: CounterService.counter,
      build: (count, notifier, keep) {
        return Text('Count: $count'); // Always updated
      },
    );
  }
}

// ✅ DO put business logic in ViewModels
class UserViewModel extends ViewModel<UserModel> {
  bool get isValidUser => _validateUser(data) && _checkPermissions(data);
  
  bool _validateUser(UserModel user) {
    // Business logic here
    return user.isActive && user.email.isNotEmpty;
  }
  
  bool _checkPermissions(UserModel user) {
    // Permission logic here
    return user.permissions.isNotEmpty;
  }
}

// ✅ DO use widget preservation
ReactiveBuilder<int>(
  notifier: CounterService.counter,
  build: (count, notifier, keep) {
    return Column(
      children: [
        Text('Count: $count'), // Rebuilds when count changes
        keep(ExpensiveWidget()), // Never rebuilds
        keep(AnotherReactiveBuilder()), // Only rebuilds for its own state
      ],
    );
  },
)

// ✅ DO clean state, not dispose instances
@override
void dispose() {
  // Reset state but keep the instance
  UserService.logout(); // Cleans state to guest
  super.dispose();
}
```

### **🔧 Performance Best Practices**

```dart
// ✅ Use silent updates for background operations
mixin AnalyticsService {
  static final analytics = ReactiveNotifier<AnalyticsModel>(() => AnalyticsModel.initial());
  
  static void trackEvent(String event) {
    // Background tracking - don't rebuild UI
    analytics.updateSilently(analytics.notifier.addEvent(event));
  }
  
  static void updateUI() {
    // Trigger UI update when needed
    analytics.updateState(analytics.notifier);
  }
}

// ✅ Use transformState for complex updates
mixin CartService {
  static final cart = ReactiveNotifier<CartModel>(() => CartModel.empty());
  
  static void addItem(Product product) {
    cart.transformState((currentCart) => currentCart.copyWith(
      items: [...currentCart.items, CartItem.fromProduct(product)],
      total: currentCart.total + product.price,
      lastUpdated: DateTime.now(),
    ));
  }
}

// ✅ Use keep() for expensive widgets
ReactiveBuilder<ThemeData>(
  notifier: ThemeService.theme,
  build: (theme, notifier, keep) {
    return Column(
      children: [
        Text('Theme: ${theme.brightness}'), // Rebuilds on theme change
        keep(
          ExpensiveAnimationWidget(), // Never rebuilds
        ),
        keep(
          ComplexChartWidget(data: expensiveData), // Preserved with data
        ),
      ],
    );
  },
)
```

---

## 🐛 **Debugging and Monitoring**

ReactiveNotifier provides comprehensive debugging tools for development:

### **📊 Lifecycle Tracking**

```
🔧 ViewModel<UserState> created
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: vm_user_789
Location: package:my_app/auth/user_viewmodel.dart:25
Initial state: UserState.guest()
Memory address: 0x7fa8c4028a60
```

### **📝 State Updates**

```
📝 ViewModel<UserState> updated
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: vm_user_789
Update #: 3
Previous: UserState.guest()
New: UserState.authenticated(User(id: 123))
Triggered by: login()
```

### **🔗 Listener Management**

```
🔗 Listener added to UserViewModel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Listener: CartViewModel._userListener
Total listeners: 2
Memory tracking: Enabled
Leak detection: Active
```

### **⚠️ Memory Leak Detection**

```
⚠️ Potential Memory Leak Detected!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ViewModel: CartViewModel
Issue: 15 listeners attached, 0 removed
Recommendation: Call removeListeners() in dispose()
Location: package:my_app/cart/cart_viewmodel.dart:45
```

### **🔄 Context Access Logging**

```
🎯 Context access in ViewModel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ViewModel: ResponsiveViewModel
Operation: MediaQuery access
Status: Success
Context available: true
Builder count: 2
```

### **🛠️ Debug Methods**

```dart
// Enable debug logging
ReactiveNotifier.enableDebugMode();

// Check memory usage
final memoryInfo = ReactiveNotifier.getMemoryInfo();
print('Active ViewModels: ${memoryInfo.activeViewModels}');
print('Total listeners: ${memoryInfo.totalListeners}');

// Cleanup all instances (for testing)
ReactiveNotifier.cleanup();

// Get detailed state information
final debugInfo = MyService.viewModel.getDebugInfo();
print('State hash: ${debugInfo.stateHash}');
print('Listener count: ${debugInfo.listenerCount}');
print('Last update: ${debugInfo.lastUpdate}');
```

---

## 📚 **Migration Guides**

### **🔄 From Provider**

```dart
// ❌ OLD: Provider approach
class ProviderCounter extends ChangeNotifier {
  int _count = 0;
  int get count => _count;
  
  void increment() {
    _count++;
    notifyListeners();
  }
}

// Provider setup
ChangeNotifierProvider(
  create: (_) => ProviderCounter(),
  child: Consumer<ProviderCounter>(
    builder: (context, counter, child) {
      return Text('${counter.count}');
    },
  ),
)

// ✅ NEW: ReactiveNotifier approach
mixin CounterService {
  static final ReactiveNotifier<int> counter = 
      ReactiveNotifier<int>(() => 0);
      
  static void increment() => counter.updateState(counter.notifier + 1);
}

// Usage
ReactiveBuilder<int>(
  notifier: CounterService.counter,
  build: (count, notifier, keep) => Text('$count'),
)
```

### **🔄 From Riverpod**

```dart
// ❌ OLD: Riverpod approach
final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  
  void increment() => state++;
}

// Usage
Consumer(
  builder: (context, ref, child) {
    final count = ref.watch(counterProvider);
    return Text('$count');
  },
)

// ✅ NEW: ReactiveNotifier approach
class CounterViewModel extends ViewModel<CounterState> {
  CounterViewModel() : super(CounterState(count: 0));
  
  void increment() {
    transformState((state) => state.copyWith(count: state.count + 1));
  }
}

mixin CounterService {
  static final ReactiveViewModelNotifier<CounterViewModel> counter = 
      ReactiveViewModelNotifier<CounterViewModel>(() => CounterViewModel());
}

// Usage - cleaner, no providers needed
ReactiveViewModelBuilder<CounterViewModel, CounterState>(
  viewmodel: CounterService.counter.notifier,
  build: (state, viewmodel, keep) => Text('${state.count}'),
)
```

### **🔄 From BLoC**

```dart
// ❌ OLD: BLoC approach
abstract class CounterEvent {}
class Increment extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}

// Usage
BlocProvider(
  create: (_) => CounterBloc(),
  child: BlocBuilder<CounterBloc, int>(
    builder: (context, count) => Text('$count'),
  ),
)

// ✅ NEW: ReactiveNotifier approach
class CounterViewModel extends ViewModel<int> {
  CounterViewModel() : super(0);
  
  void increment() => updateState(data + 1);
}

mixin CounterService {
  static final ReactiveViewModelNotifier<CounterViewModel> counter = 
      ReactiveViewModelNotifier<CounterViewModel>(() => CounterViewModel());
}

// Usage - much simpler
ReactiveViewModelBuilder<CounterViewModel, int>(
  viewmodel: CounterService.counter.notifier,
  build: (count, viewmodel, keep) => Text('$count'),
)
```

**Migration Benefits:**
- 🚀 **Less Boilerplate**: No providers, events, or complex setup
- ⚡ **Better Performance**: Singleton instances, optimized rebuilds
- 🧹 **Cleaner Code**: Direct state access, no wrapping widgets
- 🔧 **Easier Testing**: Direct state manipulation in tests

---

## 🎯 **When to Use Each Component**

### **📝 ReactiveNotifier<T>** ✅

**Use for:**
- ✅ Simple values (int, bool, String, List)
- ✅ Settings and configuration
- ✅ Flags and toggles
- ✅ State that doesn't require initialization

```dart
// Perfect examples
ReactiveNotifier<bool>(() => false)     // Theme toggle
ReactiveNotifier<String>(() => 'en')    // Language code
ReactiveNotifier<List<String>>(() => []) // Simple lists
```

### **🧠 ViewModel<T>** ✅

**Use for:**
- ✅ Complex state objects
- ✅ Business logic and validation
- ✅ Synchronous initialization
- ✅ Cross-ViewModel communication
- ✅ State that requires copyWith pattern

```dart
// Perfect examples
ViewModel<UserModel>        // User profile data
ViewModel<CartState>        // Shopping cart with business logic
ViewModel<FormState>        // Forms with validation
```

### **⚡ AsyncViewModelImpl<T>** ✅

**Use for:**
- ✅ API calls and network requests
- ✅ Database operations
- ✅ File I/O operations
- ✅ Any async operations with loading/error states

```dart
// Perfect examples
AsyncViewModelImpl<List<Product>>   // Product catalog from API
AsyncViewModelImpl<UserProfile>     // User profile from database
AsyncViewModelImpl<FileData>        // File uploads/downloads
```

### **🎯 Decision Tree**

```
Need async operations? 
├─ YES → AsyncViewModelImpl<T>
└─ NO → Has business logic?
         ├─ YES → ViewModel<T>
         └─ NO → ReactiveNotifier<T>
```

---

## 🌍 **Real-World Examples**

### **📱 Social Media App Architecture**

Complete example of a social media app using ReactiveNotifier:

```dart
// 👤 User Profile Management
class UserProfileViewModel extends AsyncViewModelImpl<UserProfile> {
  UserProfileViewModel() : super(AsyncState.initial(), loadOnInit: true);
  
  @override
  Future<UserProfile> init() async {
    return await userRepository.getCurrentUserProfile();
  }
  
  Future<void> updateProfilePicture(File imageFile) async {
    loadingState();
    try {
      final uploadedUrl = await storageService.uploadImage(imageFile);
      final updatedProfile = await userRepository.updateProfilePicture(uploadedUrl);
      updateState(updatedProfile);
      
      // Notify other parts of the app
      NotificationService.showSuccess('Profile picture updated!');
    } catch (e) {
      errorState('Failed to update profile picture: $e');
    }
  }
}

// 📝 Posts Feed Management
class PostsFeedViewModel extends AsyncViewModelImpl<List<Post>> {
  PostsFeedViewModel() : super(AsyncState.initial(), loadOnInit: true);
  
  UserProfile? currentUser;
  String? selectedFilter = 'all';
  
  @override
  Future<List<Post>> init() async {
    return await postsRepository.getFeedPosts();
  }
  
  @override
  void init() {
    super.init();
    
    // React to user profile changes
    UserService.profile.notifier.listenVM((userProfile) {
      currentUser = userProfile;
      // Refresh feed with user preferences
      if (userProfile.feedPreferences != selectedFilter) {
        selectedFilter = userProfile.feedPreferences;
        reload();
      }
    });
    
    // Get current user
    currentUser = UserService.profile.notifier.hasData 
        ? UserService.profile.notifier.data 
        : null;
  }
  
  Future<void> likePost(String postId) async {
    try {
      await postsRepository.likePost(postId);
      
      // Update local state optimistically
      transformDataState((posts) {
        return posts?.map((post) {
          if (post.id == postId) {
            return post.copyWith(
              likedByUser: true,
              likesCount: post.likesCount + 1,
            );
          }
          return post;
        }).toList();
      });
      
      // Update user's liked posts
      UserService.likedPosts.notifier.addLikedPost(postId);
      
    } catch (e) {
      // Revert optimistic update
      transformDataState((posts) {
        return posts?.map((post) {
          if (post.id == postId) {
            return post.copyWith(
              likedByUser: false,
              likesCount: post.likesCount - 1,
            );
          }
          return post;
        }).toList();
      });
      
      NotificationService.showError('Failed to like post');
    }
  }
  
  Future<void> createPost(String content, List<File>? images) async {
    loadingState();
    try {
      final newPost = await postsRepository.createPost(content, images);
      
      // Add to feed optimistically
      transformDataState((posts) => [newPost, ...?posts]);
      
      // Update user's posts count
      UserService.profile.notifier.incrementPostsCount();
      
      NotificationService.showSuccess('Post created successfully!');
    } catch (e) {
      errorState('Failed to create post: $e');
    }
  }
}

// 💬 Chat System
class ChatViewModel extends AsyncViewModelImpl<List<Message>> {
  final String chatId;
  ChatViewModel(this.chatId) : super(AsyncState.initial(), loadOnInit: true);
  
  UserProfile? currentUser;
  bool isTyping = false;
  
  @override
  Future<List<Message>> init() async {
    return await chatRepository.getMessages(chatId);
  }
  
  @override
  void init() {
    super.init();
    
    // Listen to real-time messages
    chatRepository.getMessageStream(chatId).listen((newMessage) {
      if (!isDisposed) {
        transformDataState((messages) => [...?messages, newMessage]);
        
        // Mark as read if app is active
        if (AppStateService.isAppActive.notifier) {
          markMessageAsRead(newMessage.id);
        }
      }
    });
    
    // React to user changes
    UserService.profile.notifier.listenVM((userProfile) {
      currentUser = userProfile;
    });
    
    currentUser = UserService.profile.notifier.hasData 
        ? UserService.profile.notifier.data 
        : null;
  }
  
  Future<void> sendMessage(String content, {String? replyToId}) async {
    if (currentUser == null) return;
    
    // Create optimistic message
    final optimisticMessage = Message.optimistic(
      content: content,
      senderId: currentUser!.id,
      chatId: chatId,
      replyToId: replyToId,
    );
    
    // Add optimistically
    transformDataState((messages) => [...?messages, optimisticMessage]);
    
    try {
      final sentMessage = await chatRepository.sendMessage(
        chatId: chatId,
        content: content,
        replyToId: replyToId,
      );
      
      // Replace optimistic message with real one
      transformDataState((messages) {
        return messages?.map((msg) {
          if (msg.id == optimisticMessage.id) {
            return sentMessage;
          }
          return msg;
        }).toList();
      });
      
      // Update last message in chats list
      ChatsListService.updateLastMessage(chatId, sentMessage);
      
    } catch (e) {
      // Remove failed message
      transformDataState((messages) {
        return messages?.where((msg) => msg.id != optimisticMessage.id).toList();
      });
      
      NotificationService.showError('Failed to send message');
    }
  }
  
  void setTyping(bool typing) {
    if (isTyping != typing) {
      isTyping = typing;
      chatRepository.sendTypingStatus(chatId, typing);
    }
  }
}

// 🔔 Notifications Management
class NotificationsViewModel extends AsyncViewModelImpl<List<AppNotification>> {
  NotificationsViewModel() : super(AsyncState.initial(), loadOnInit: true);
  
  int unreadCount = 0;
  
  @override
  Future<List<AppNotification>> init() async {
    final notifications = await notificationsRepository.getNotifications();
    unreadCount = notifications.where((n) => !n.isRead).length;
    return notifications;
  }
  
  @override
  void init() {
    super.init();
    
    // Listen to real-time notifications
    notificationsRepository.getNotificationStream().listen((notification) {
      if (!isDisposed) {
        transformDataState((notifications) => [notification, ...?notifications]);
        
        if (!notification.isRead) {
          unreadCount++;
          
          // Show in-app notification
          if (AppStateService.isAppActive.notifier) {
            NotificationService.showInApp(notification);
          }
          
          // Update app badge
          BadgeService.updateBadgeCount(unreadCount);
        }
      }
    });
  }
  
  Future<void> markAsRead(String notificationId) async {
    try {
      await notificationsRepository.markAsRead(notificationId);
      
      transformDataState((notifications) {
        return notifications?.map((notification) {
          if (notification.id == notificationId && !notification.isRead) {
            unreadCount--;
            return notification.copyWith(isRead: true);
          }
          return notification;
        }).toList();
      });
      
      BadgeService.updateBadgeCount(unreadCount);
    } catch (e) {
      NotificationService.showError('Failed to mark notification as read');
    }
  }
  
  Future<void> markAllAsRead() async {
    try {
      await notificationsRepository.markAllAsRead();
      
      transformDataState((notifications) {
        return notifications?.map((notification) => 
          notification.copyWith(isRead: true)
        ).toList();
      });
      
      unreadCount = 0;
      BadgeService.updateBadgeCount(0);
    } catch (e) {
      NotificationService.showError('Failed to mark all notifications as read');
    }
  }
}

// 📊 Services Organization
mixin UserService {
  static final profile = ReactiveNotifier<UserProfileViewModel>(
    () => UserProfileViewModel()
  );
  
  static final likedPosts = ReactiveNotifier<LikedPostsViewModel>(
    () => LikedPostsViewModel()
  );
}

mixin PostsService {
  static final feed = ReactiveNotifier<PostsFeedViewModel>(
    () => PostsFeedViewModel()
  );
  
  static final trending = ReactiveNotifier<TrendingPostsViewModel>(
    () => TrendingPostsViewModel()
  );
}

mixin ChatService {
  static final _chatInstances = <String, ReactiveNotifier<ChatViewModel>>{};
  
  static ReactiveNotifier<ChatViewModel> getChat(String chatId) {
    return _chatInstances.putIfAbsent(
      chatId,
      () => ReactiveNotifier<ChatViewModel>(() => ChatViewModel(chatId))
    );
  }
  
  static final chatsList = ReactiveNotifier<ChatsListViewModel>(
    () => ChatsListViewModel()
  );
}

mixin NotificationService {
  static final notifications = ReactiveNotifier<NotificationsViewModel>(
    () => NotificationsViewModel()
  );
  
  static void showSuccess(String message) {
    // Show success notification
  }
  
  static void showError(String message) {
    // Show error notification
  }
  
  static void showInApp(AppNotification notification) {
    // Show in-app notification overlay
  }
}
```

### **🛒 E-Commerce App Architecture**

```dart
// 🛍️ Shopping Cart with Complex Business Logic
class ShoppingCartViewModel extends ViewModel<CartState> {
  ShoppingCartViewModel() : super(CartState.empty());
  
  UserModel? currentUser;
  List<Coupon> availableCoupons = [];
  ShippingInfo? shippingInfo;
  
  @override
  void init() {
    // React to user changes
    UserService.user.notifier.listenVM((user) {
      currentUser = user;
      _updateCartForUser(user);
    });
    
    // React to shipping info changes
    CheckoutService.shippingInfo.notifier.listenVM((shipping) {
      shippingInfo = shipping;
      _recalculateTotal();
    });
    
    // React to available coupons
    CouponService.available.notifier.listenVM((coupons) {
      availableCoupons = coupons;
      _validateAppliedCoupons();
    });
    
    // Initialize current state
    currentUser = UserService.user.notifier.data;
    shippingInfo = CheckoutService.shippingInfo.notifier.data;
    availableCoupons = CouponService.available.notifier.data ?? [];
  }
  
  void addProduct(Product product, {int quantity = 1, String? variant}) {
    transformState((cart) {
      final existingItem = cart.items.firstWhere(
        (item) => item.productId == product.id && item.variant == variant,
        orElse: () => CartItem.empty(),
      );
      
      List<CartItem> updatedItems;
      if (existingItem.productId.isNotEmpty) {
        // Update existing item
        updatedItems = cart.items.map((item) {
          if (item.productId == product.id && item.variant == variant) {
            return item.copyWith(quantity: item.quantity + quantity);
          }
          return item;
        }).toList();
      } else {
        // Add new item
        final newItem = CartItem(
          productId: product.id,
          name: product.name,
          price: product.price,
          quantity: quantity,
          variant: variant,
        );
        updatedItems = [...cart.items, newItem];
      }
      
      return cart.copyWith(
        items: updatedItems,
        lastUpdated: DateTime.now(),
      );
    });
    
    _recalculateTotal();
    _saveCartToStorage();
    
    // Analytics
    AnalyticsService.trackAddToCart(product.id, quantity);
    
    // Show feedback
    NotificationService.showSuccess('${product.name} added to cart');
  }
  
  void removeProduct(String productId, {String? variant}) {
    transformState((cart) {
      final updatedItems = cart.items.where((item) => 
        !(item.productId == productId && item.variant == variant)
      ).toList();
      
      return cart.copyWith(
        items: updatedItems,
        lastUpdated: DateTime.now(),
      );
    });
    
    _recalculateTotal();
    _saveCartToStorage();
  }
  
  void applyCoupon(String couponCode) {
    final coupon = availableCoupons.firstWhere(
      (c) => c.code == couponCode,
      orElse: () => Coupon.empty(),
    );
    
    if (coupon.code.isEmpty) {
      NotificationService.showError('Invalid coupon code');
      return;
    }
    
    if (!_isCouponValid(coupon)) {
      NotificationService.showError('Coupon is not valid for your cart');
      return;
    }
    
    transformState((cart) => cart.copyWith(
      appliedCoupon: coupon,
      lastUpdated: DateTime.now(),
    ));
    
    _recalculateTotal();
    NotificationService.showSuccess('Coupon applied: ${coupon.name}');
  }
  
  void _recalculateTotal() {
    transformState((cart) {
      double subtotal = cart.items.fold(0, (sum, item) => sum + (item.price * item.quantity));
      double shipping = shippingInfo?.cost ?? 0;
      double discount = _calculateDiscount(cart.appliedCoupon, subtotal);
      double tax = _calculateTax(subtotal - discount, shippingInfo?.address.state);
      
      return cart.copyWith(
        subtotal: subtotal,
        shipping: shipping,
        discount: discount,
        tax: tax,
        total: subtotal + shipping - discount + tax,
      );
    });
  }
  
  bool _isCouponValid(Coupon coupon) {
    final cart = data;
    
    // Check minimum order amount
    if (coupon.minimumAmount > 0 && cart.subtotal < coupon.minimumAmount) {
      return false;
    }
    
    // Check user eligibility
    if (coupon.firstTimeOnly && currentUser?.isFirstTimeCustomer != true) {
      return false;
    }
    
    // Check product eligibility
    if (coupon.eligibleProductIds.isNotEmpty) {
      final hasEligibleProduct = cart.items.any((item) => 
        coupon.eligibleProductIds.contains(item.productId)
      );
      if (!hasEligibleProduct) return false;
    }
    
    return true;
  }
  
  double _calculateDiscount(Coupon? coupon, double subtotal) {
    if (coupon == null) return 0;
    
    if (coupon.type == CouponType.percentage) {
      return subtotal * (coupon.value / 100);
    } else {
      return coupon.value;
    }
  }
  
  double _calculateTax(double taxableAmount, String? state) {
    // Tax calculation logic based on shipping address
    final taxRate = TaxService.getTaxRate(state ?? '');
    return taxableAmount * taxRate;
  }
  
  void _updateCartForUser(UserModel user) {
    // Load user's saved cart
    // Apply user-specific pricing
    // Update loyalty discounts
  }
  
  void _validateAppliedCoupons() {
    final cart = data;
    if (cart.appliedCoupon != null && !_isCouponValid(cart.appliedCoupon!)) {
      transformState((cart) => cart.copyWith(appliedCoupon: null));
      _recalculateTotal();
      NotificationService.showError('Applied coupon is no longer valid');
    }
  }
  
  Future<void> _saveCartToStorage() async {
    try {
      await StorageService.saveCart(data);
    } catch (e) {
      // Handle storage error
    }
  }
}

// 🔍 Product Search with Filters
class ProductSearchViewModel extends AsyncViewModelImpl<SearchResult> {
  ProductSearchViewModel() : super(AsyncState.initial());
  
  String currentQuery = '';
  SearchFilters filters = SearchFilters.empty();
  List<String> recentSearches = [];
  
  @override
  Future<SearchResult> init() async {
    // Load recent searches
    recentSearches = await StorageService.getRecentSearches();
    return SearchResult.empty();
  }
  
  Future<void> search(String query, {SearchFilters? searchFilters}) async {
    if (query.trim().isEmpty) {
      updateState(SearchResult.empty());
      return;
    }
    
    currentQuery = query;
    filters = searchFilters ?? filters;
    
    loadingState();
    
    try {
      final results = await productRepository.searchProducts(
        query: query,
        filters: filters,
      );
      
      updateState(results);
      
      // Save to recent searches
      _addToRecentSearches(query);
      
      // Analytics
      AnalyticsService.trackSearch(query, results.products.length);
      
    } catch (e) {
      errorState('Search failed: $e');
    }
  }
  
  Future<void> applyFilters(SearchFilters newFilters) async {
    filters = newFilters;
    
    if (currentQuery.isNotEmpty) {
      await search(currentQuery, searchFilters: newFilters);
    }
  }
  
  void _addToRecentSearches(String query) {
    recentSearches = [
      query,
      ...recentSearches.where((s) => s != query).take(9)
    ];
    StorageService.saveRecentSearches(recentSearches);
  }
  
  Future<void> clearRecentSearches() async {
    recentSearches = [];
    await StorageService.clearRecentSearches();
    updateState(data.copyWith(recentSearches: []));
  }
}

// Services for E-commerce
mixin CartService {
  static final cart = ReactiveViewModelNotifier<ShoppingCartViewModel>(
    () => ShoppingCartViewModel()
  );
}

mixin ProductService {
  static final search = ReactiveNotifier<ProductSearchViewModel>(
    () => ProductSearchViewModel()
  );
  
  static final categories = ReactiveViewModelNotifier<CategoriesViewModel>(
    () => CategoriesViewModel()
  );
  
  static final recommendations = ReactiveViewModelNotifier<RecommendationsViewModel>(
    () => RecommendationsViewModel()
  );
}

mixin CheckoutService {
  static final shippingInfo = ReactiveViewModelNotifier<ShippingInfoViewModel>(
    () => ShippingInfoViewModel()
  );
  
  static final payment = ReactiveNotifier<PaymentViewModel>(
    () => PaymentViewModel()
  );
  
  static final orderSummary = ReactiveViewModelNotifier<OrderSummaryViewModel>(
    () => OrderSummaryViewModel()
  );
}
```

### **💰 Financial/Banking App Architecture**

```dart
// 💳 Account Balance Management
class AccountBalanceViewModel extends AsyncViewModelImpl<AccountBalance> {
  AccountBalanceViewModel() : super(AsyncState.initial(), loadOnInit: true);
  
  @override
  Future<AccountBalance> init() async {
    return await bankingRepository.getAccountBalance();
  }
  
  @override
  void init() {
    super.init();
    
    // Listen for real-time balance updates
    bankingRepository.getBalanceUpdatesStream().listen((update) {
      if (!isDisposed) {
        transformDataState((balance) => balance?.applyUpdate(update));
        
        // Show notification for significant changes
        if (update.amount.abs() > 100) {
          NotificationService.showBalanceUpdate(update);
        }
      }
    });
  }
  
  Future<void> refreshBalance() async {
    await reload();
    NotificationService.showSuccess('Balance updated');
  }
}

// 💸 Transaction History with Real-time Updates
class TransactionsViewModel extends AsyncViewModelImpl<List<Transaction>> {
  TransactionsViewModel() : super(AsyncState.initial(), loadOnInit: true);
  
  TransactionFilters filters = TransactionFilters.all();
  
  @override
  Future<List<Transaction>> init() async {
    return await bankingRepository.getTransactions(filters);
  }
  
  @override
  void init() {
    super.init();
    
    // Listen for new transactions
    bankingRepository.getTransactionUpdatesStream().listen((newTransaction) {
      if (!isDisposed) {
        transformDataState((transactions) => [newTransaction, ...?transactions]);
        
        // Update account balance
        AccountService.balance.notifier.reload();
        
        // Show notification
        NotificationService.showNewTransaction(newTransaction);
      }
    });
  }
  
  Future<void> applyFilters(TransactionFilters newFilters) async {
    filters = newFilters;
    loadingState();
    
    try {
      final filteredTransactions = await bankingRepository.getTransactions(filters);
      updateState(filteredTransactions);
    } catch (e) {
      errorState('Failed to load transactions: $e');
    }
  }
  
  Future<void> exportTransactions(DateRange dateRange) async {
    try {
      final csvData = await bankingRepository.exportTransactions(dateRange);
      await FileService.saveAndShare(csvData, 'transactions.csv');
      NotificationService.showSuccess('Transactions exported successfully');
    } catch (e) {
      NotificationService.showError('Failed to export transactions: $e');
    }
  }
}

// 💰 Money Transfer
class MoneyTransferViewModel extends AsyncViewModelImpl<TransferResult> {
  MoneyTransferViewModel() : super(AsyncState.initial());
  
  List<Contact> recentContacts = [];
  List<BankAccount> linkedAccounts = [];
  
  @override
  void init() {
    super.init();
    _loadRecentContacts();
    _loadLinkedAccounts();
  }
  
  Future<void> transferMoney({
    required String recipientId,
    required double amount,
    required String description,
    bool isScheduled = false,
    DateTime? scheduledDate,
  }) async {
    // Validate transfer
    final validationResult = await _validateTransfer(amount);
    if (!validationResult.isValid) {
      errorState(validationResult.error);
      return;
    }
    
    loadingState();
    
    try {
      final transferResult = await bankingRepository.transferMoney(
        recipientId: recipientId,
        amount: amount,
        description: description,
        isScheduled: isScheduled,
        scheduledDate: scheduledDate,
      );
      
      updateState(transferResult);
      
      // Update balance immediately for pending transfers
      if (!isScheduled) {
        AccountService.balance.notifier.reload();
      }
      
      // Add to recent contacts
      _addToRecentContacts(recipientId);
      
      // Show success message
      NotificationService.showSuccess(
        isScheduled 
          ? 'Transfer scheduled successfully'
          : 'Transfer completed successfully'
      );
      
      // Analytics
      AnalyticsService.trackTransfer(amount, recipientId, isScheduled);
      
    } catch (e) {
      errorState('Transfer failed: $e');
    }
  }
  
  Future<TransferValidation> _validateTransfer(double amount) async {
    final balance = AccountService.balance.notifier.data;
    
    if (balance == null) {
      return TransferValidation.invalid('Unable to verify account balance');
    }
    
    if (amount > balance.available) {
      return TransferValidation.invalid('Insufficient funds');
    }
    
    if (amount > balance.dailyTransferLimit) {
      return TransferValidation.invalid('Amount exceeds daily transfer limit');
    }
    
    return TransferValidation.valid();
  }
  
  void _addToRecentContacts(String recipientId) {
    // Add logic to update recent contacts
  }
  
  Future<void> _loadRecentContacts() async {
    recentContacts = await bankingRepository.getRecentContacts();
  }
  
  Future<void> _loadLinkedAccounts() async {
    linkedAccounts = await bankingRepository.getLinkedAccounts();
  }
}

// Financial Services
mixin AccountService {
  static final balance = ReactiveNotifier<AccountBalanceViewModel>(
    () => AccountBalanceViewModel()
  );
  
  static final transactions = ReactiveNotifier<TransactionsViewModel>(
    () => TransactionsViewModel()
  );
}

mixin TransferService {
  static final moneyTransfer = ReactiveNotifier<MoneyTransferViewModel>(
    () => MoneyTransferViewModel()
  );
  
  static final scheduledTransfers = ReactiveNotifier<ScheduledTransfersViewModel>(
    () => ScheduledTransfersViewModel()
  );
}
```

These real-world examples demonstrate:

- **🔄 Complex reactive communication** between multiple ViewModels
- **📊 Real-time data synchronization** with streams and websockets
- **🎯 Optimistic updates** for better user experience
- **⚡ Error handling** and rollback strategies
- **📱 Cross-feature integration** without tight coupling
- **🧪 Testable architecture** with clear separation of concerns
- **📈 Analytics integration** throughout the app flow
- **💾 Persistent state management** with storage integration

---

## 💡 **Advanced Patterns**

### **🔄 State Transformation Chains**

```dart
mixin ShoppingService {
  static final cart = ReactiveNotifier<CartModel>(() => CartModel.empty());
  static final checkout = ReactiveViewModelNotifier<CheckoutViewModel>(
    () => CheckoutViewModel()
  );
  
  // Chain transformations across multiple states
  static void processOrder() {
    // 1. Validate cart
    cart.transformState((cart) => cart.validate());
    
    // 2. Start checkout
    checkout.notifier.startCheckout(cart.notifier);
    
    // 3. Clear cart after successful checkout
    checkout.notifier.listenVM((checkoutState) {
      if (checkoutState.isCompleted) {
        cart.updateState(CartModel.empty());
      }
    });
  }
}
```

### **📊 Computed States**

```dart
class ShopSummaryViewModel extends ViewModel<ShopSummary> {
  ShopSummaryViewModel() : super(ShopSummary.empty());
  
  CartModel? currentCart;
  UserModel? currentUser;
  List<Product>? currentProducts;
  
  @override
  void init() {
    // Listen to multiple sources and compute derived state
    CartService.cart.notifier.listenVM((cart) {
      _computeSummary();
    });
    
    UserService.user.notifier.listenVM((user) {
      _computeSummary();
    });
    
    ProductService.products.notifier.listenVM((products) {
      _computeSummary();
    });
    
    // Get current states separately
    currentCart = CartService.cart.notifier.data;
    currentUser = UserService.user.notifier.data;
    currentProducts = ProductService.products.notifier.data;
    
    // Compute initial summary
    _computeSummary();
  }
  
  void _computeSummary() {
    // Always get current states dynamically
    final cart = CartService.cart.notifier.data;
    final user = UserService.user.notifier.data;
    final products = ProductService.products.notifier.data;
    
    if (cart != null && user != null && products != null) {
      final summary = ShopSummary.compute(
        cart: cart,
        user: user,
        products: products,
      );
      updateState(summary);
    }
  }
}
```

### **🎛️ State Middleware**

```dart
mixin AnalyticsMiddleware {
  static void trackStateChange<T>(ReactiveNotifier<T> notifier, String event) {
    notifier.listen((newState) {
      AnalyticsService.track(event, {
        'state_type': T.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'value': newState.toString(),
      });
    });
  }
}

// Usage
void main() {
  // Add analytics tracking to any state
  AnalyticsMiddleware.trackStateChange(UserService.user, 'user_state_changed');
  AnalyticsMiddleware.trackStateChange(CartService.cart, 'cart_state_changed');
  
  runApp(MyApp());
}
```

---

## 🚀 **Performance Optimization**

### **📊 Memory Management**

```dart
// Monitor memory usage
class MemoryMonitor {
  static void checkMemoryUsage() {
    final info = ReactiveNotifier.getMemoryInfo();
    
    if (info.totalListeners > 100) {
      print('⚠️ High listener count: ${info.totalListeners}');
      _optimizeListeners();
    }
    
    if (info.activeViewModels > 50) {
      print('⚠️ High ViewModel count: ${info.activeViewModels}');
      _cleanupUnusedViewModels();
    }
  }
  
  static void _optimizeListeners() {
    // Remove unused listeners
    ReactiveNotifier.cleanup();
  }
  
  static void _cleanupUnusedViewModels() {
    // Clean state of ViewModels not currently in use
    UserService.user.notifier.cleanState();
    CartService.cart.notifier.cleanState();
  }
}
```

### **⚡ Build Optimization**

```dart
// Use widget preservation aggressively
ReactiveBuilder<ShopState>(
  notifier: ShopService.shop,
  build: (shop, notifier, keep) {
    return Column(
      children: [
        // Dynamic content - rebuilds on state change
        Text('Shop: ${shop.name}'),
        Text('Items: ${shop.itemCount}'),
        
        // Static content - preserved
        keep(NavigationBar()),
        keep(Footer()),
        keep(SideMenu()),
        
        // Expensive content - preserved
        keep(ComplexChart(data: shop.analytics)),
        keep(HeavyAnimationWidget()),
      ],
    );
  },
)
```

### **🔧 Lazy Loading**

```dart
mixin LazyService {
  static ReactiveNotifier<ExpensiveViewModel>? _instance;
  
  static ReactiveNotifier<ExpensiveViewModel> get instance {
    // Only create when actually needed
    _instance ??= ReactiveNotifier<ExpensiveViewModel>(
      () => ExpensiveViewModel()
    );
    return _instance!;
  }
  
  static void preload() {
    // Preload in background if needed
    instance.loadNotifier();
  }
}
```

---

## 📖 **Examples and Resources**

### **📱 Complete App Example**

Check out our comprehensive example app that demonstrates:

- 🏗️ Feature-based architecture
- 🔄 Cross-ViewModel communication
- 📊 Complex async operations
- 🧪 Testing patterns
- 🎯 Context access for migrations

[**View Example App →**](https://github.com/jhonacodes/reactive_notifier/tree/main/example)

### **📚 Additional Resources**

- **[API Documentation](https://pub.dev/documentation/reactive_notifier/latest/)**
- **[GitHub Repository](https://github.com/jhonacodes/reactive_notifier)**
- **[Issue Tracker](https://github.com/jhonacodes/reactive_notifier/issues)**
- **[Discussions](https://github.com/jhonacodes/reactive_notifier/discussions)**

---

## 🤝 **Contributing**

We welcome contributions! Here's how you can help:

### **🐛 Bug Reports**
1. Check existing [issues](https://github.com/jhonacodes/reactive_notifier/issues)
2. Create detailed bug report with reproduction steps
3. Include Flutter/Dart versions and error logs

### **✨ Feature Requests**
1. Open an [issue](https://github.com/jhonacodes/reactive_notifier/issues) with your idea
2. Discuss the feature with maintainers
3. Submit a pull request with implementation

### **📝 Documentation**
1. Improve existing documentation
2. Add more examples and use cases
3. Fix typos and clarifications

### **🔧 Development Setup**

```bash
# Clone the repository
git clone https://github.com/jhonacodes/reactive_notifier.git

# Install dependencies
cd reactive_notifier
flutter pub get

# Run tests
flutter test

# Run example app
cd example
flutter run
```

### **📋 Pull Request Process**

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -am 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 JhonaCode

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 💖 **Support the Project**

If ReactiveNotifier has helped you build amazing Flutter apps, consider supporting the project:

- ⭐ **Star the repository** on GitHub
- 👍 **Like the package** on pub.dev
- 🐛 **Report bugs** and help improve the library
- 📝 **Contribute** to documentation and examples
- 💬 **Share your experience** in discussions
- 📱 **Showcase your apps** built with ReactiveNotifier

---

## 🙏 **Acknowledgments**

ReactiveNotifier is built with inspiration from:

- **Flutter's ChangeNotifier** - For the foundation of reactive state
- **Provider Package** - For dependency injection patterns
- **Riverpod** - For advanced state management concepts
- **BLoC Pattern** - For event-driven architecture ideas
- **MobX** - For reactive programming principles

Special thanks to the Flutter community for feedback and contributions!

---

<div align="center">

**Made with ❤️ by [JhonaCode](https://github.com/jhonacodes)**

[⬆️ Back to Top](#reactivenotifier-v2120)

</div>