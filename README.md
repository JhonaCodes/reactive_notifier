# reactive_notifier

**State Management for Flutter** - ReactiveNotifier is a state manager designed for MVVM architecture with clear separation of responsibilities. It manages ViewModel lifecycle independently from UI, supports applications of any size, follows "create once, reuse always" philosophy, and keeps business logic out of widgets.

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

## What's New in v2.13.xx

### State Change Hooks
- **onStateChanged(previous, next)** hooks for ViewModels
- **onAsyncStateChanged(previous, next)** hooks for AsyncViewModels
- **Internal state reaction** capabilities without external observers
- **Integrated lifecycle** hooks in all state update methods

### Improved Architecture
- **Eliminated observer complexity** - Focus on explicit service communication
- **Sandbox-based architecture** - Multiple instances per type supported
- **Cross-sandbox communication** using existing listenVM API
- **Simplified state management** without magic type lookup

### Enhanced Documentation
- **Professional documentation** with clear, direct examples
- **Simplified code samples** focusing on practical usage
- **Updated migration guides** for all major state management libraries
- **Comprehensive testing** with improved test coverage

---

## Key Features

- **Simple and intuitive API** - Clean, developer-friendly interface
- **Enterprise MVVM architecture** - Built for scalable applications
- **Independent lifecycle management** - ViewModels exist beyond UI lifecycle
- **Type-safe state management** - Full generics support with compile-time safety
- **Built-in Async and Stream support** - Handle loading, success, error states effortlessly
- **Smart related states system** - Automatic dependency management
- **Repository/Service layer integration** - Clean separation of concerns
- **High performance** with minimal rebuilds and widget preservation
- **Memory leak prevention** - Comprehensive listener tracking and cleanup
- **Automatic BuildContext access** - Zero-configuration context availability in ALL ViewModels
- **Hybrid state management** - Use ReactiveNotifier + Riverpod/Provider simultaneously
- **State change hooks** - React to internal state changes
- **Cross-service communication** - Explicit sandbox-to-sandbox messaging
- **DevTools integration** - Enhanced debugging and monitoring capabilities
- **Comprehensive testing support** - Easy mocking and test utilities
- **Migration support** - Gradual migration or hybrid usage with existing state managers

---

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  reactive_notifier: ^2.13.1
```

### DevTools Extension (Automatic)

ReactiveNotifier includes a **full DevTools extension** that appears as a dedicated tab in Flutter DevTools. The extension is automatically loaded when your app depends on this package.

**🔧 How to Access:**
1. **Flutter DevTools** - Open DevTools and look for the "ReactiveNotifier" tab
2. **In-App DevTool** - Use `showReactiveNotifierDevTool(context)` for quick debugging
3. **Floating FAB** - Add `ReactiveNotifierDevToolFAB()` to any screen for instant access

**📊 Features:**
- **Real-time state monitoring** - See all active ReactiveNotifier instances
- **ViewModel lifecycle tracking** - Monitor creation, updates, and disposal
- **Memory usage analysis** - Detect potential memory leaks
- **State change history** - View detailed state transition logs
- **Performance metrics** - Track update counts and timing
- **Interactive state inspection** - Drill down into individual state objects
- **Auto-dispose monitoring** - Track widget-aware lifecycle management

---

## Core Philosophy: "Create Once, Reuse Always"

ReactiveNotifier follows a singleton pattern where each state is created once and reused throughout the application lifecycle.

### Key Principles

- **One instance per service** - Each ReactiveNotifier creates a single, reusable instance
- **Automatic lifecycle** - No manual initialization or disposal needed
- **Service-based organization** - Group related state in service mixins
- **Explicit communication** - Services communicate through explicit API calls
- **Memory efficient** - Automatic cleanup and leak prevention
- **Type safety** - Full compile-time type checking
- **Independent of UI** - State exists beyond widget lifecycle

---

## Quick Start Guide

### 1. Simple State with ReactiveNotifier

```dart
// Define service with reactive state
mixin CounterService {
  static final ReactiveNotifier<int> count = ReactiveNotifier<int>(() => 0);
}

// Update state
CounterService.count.updateState(5);

// Listen to changes
CounterService.count.listen((value) {
  print('Counter: $value');
});

// Use in widgets
class CounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<int>(
      notifier: CounterService.count,
      build: (value, notifier, keep) {
        return Column(
          children: [
            Text('Count: $value'),
            ElevatedButton(
              onPressed: () => notifier.updateState(value + 1),
              child: Text('Increment'),
            ),
          ],
        );
      },
    );
  }
}
```

### 2. Complex State with ViewModel

```dart
// Define model
class UserModel {
  final String name;
  final String email;
  final bool isActive;

  UserModel({
    required this.name,
    required this.email,
    this.isActive = true,
  });

  UserModel copyWith({String? name, String? email, bool? isActive}) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
    );
  }
}

// Define ViewModel with hooks
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel(name: '', email: ''));

  @override
  void init() {
    // Synchronous initialization
    updateState(UserModel(name: 'John Doe', email: 'john@example.com'));
  }

  @override
  void onStateChanged(UserModel previous, UserModel next) {
    // React to state changes
    if (previous.isActive != next.isActive) {
      print('User activation changed: ${next.isActive}');
    }
  }

  void updateUserName(String name) {
    transformState((current) => current.copyWith(name: name));
  }

  void toggleActive() {
    transformState((current) => current.copyWith(isActive: !current.isActive));
  }
}

// Define service
mixin UserService {
  static final ReactiveNotifier<UserViewModel> userState = 
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

// Use in widget
class UserProfileWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveViewModelBuilder<UserViewModel, UserModel>(
      viewmodel: UserService.userState.notifier,
      build: (user, viewModel, keep) {
        return Column(
          children: [
            Text('Name: ${user.name}'),
            Text('Email: ${user.email}'),
            Text('Status: ${user.isActive ? 'Active' : 'Inactive'}'),
            ElevatedButton(
              onPressed: () => viewModel.toggleActive(),
              child: Text('Toggle Status'),
            ),
          ],
        );
      },
    );
  }
}
```

### 3. Async Operations with AsyncViewModelImpl

```dart
// Define async ViewModel with hooks
class TodoListViewModel extends AsyncViewModelImpl<List<Todo>> {
  final TodoRepository _repository;

  TodoListViewModel(this._repository) : super(AsyncState.initial());

  @override
  Future<List<Todo>> init() async {
    // Async initialization
    return await _repository.getAllTodos();
  }

  @override
  void onAsyncStateChanged(AsyncState<List<Todo>> previous, AsyncState<List<Todo>> next) {
    // React to async state changes
    if (previous.isLoading && next.isSuccess) {
      print('Successfully loaded ${next.data?.length ?? 0} todos');
    }
    if (next.isError) {
      print('Failed to load todos: ${next.error}');
    }
  }

  Future<void> addTodo(String title) async {
    loadingState();
    try {
      final newTodo = await _repository.createTodo(title);
      final currentList = state.data ?? [];
      updateState([...currentList, newTodo]);
    } catch (error) {
      errorState(error);
    }
  }

  Future<void> removeTodo(String todoId) async {
    final currentList = state.data ?? [];
    final updatedList = currentList.where((todo) => todo.id != todoId).toList();
    updateState(updatedList);
  }
}

// Use in widget
class TodoListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveAsyncBuilder<TodoListViewModel, List<Todo>>(
      notifier: TodoService.todoList.notifier,
      onData: (todos, viewModel, keep) {
        return ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context, index) {
            final todo = todos[index];
            return ListTile(
              title: Text(todo.title),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => viewModel.removeTodo(todo.id),
              ),
            );
          },
        );
      },
      onLoading: () => CircularProgressIndicator(),
      onError: (error, stackTrace) => Text('Error: $error'),
    );
  }
}
```

### 4. Stream Operations with ReactiveStreamBuilder

For reactive streams, you can use `ReactiveStreamBuilder` with ViewModels that manage streams internally:

```dart
// ViewModel that manages a stream internally
class ChatViewModel extends ViewModel<ChatState> {
  StreamSubscription? _messageSubscription;
  
  ChatViewModel() : super(ChatState.initial());
  
  @override
  void init() {
    // Listen to stream inside ViewModel
    _messageSubscription = _chatRepository.messageStream().listen(
      (message) => updateState(data.copyWith(messages: [...data.messages, message])),
      onError: (error) => updateState(data.copyWith(error: error)),
    );
  }
  
  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}

// Service with ViewModel
mixin ChatService {
  static final ReactiveNotifier<ChatViewModel> chat = 
    ReactiveNotifier<ChatViewModel>(() => ChatViewModel());
}

// Or: ReactiveNotifier holding a stream directly
mixin StreamService {
  static final ReactiveNotifier<Stream<String>> dataStream = 
    ReactiveNotifier<Stream<String>>(() => Stream.periodic(
      Duration(seconds: 1), 
      (i) => 'Data $i'
    ));
}

// Use ReactiveStreamBuilder for direct stream handling
class StreamWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveStreamBuilder<ReactiveNotifier<Stream<String>>, String>(
      notifier: StreamService.dataStream,
      onData: (data, notifier, keep) {
        return Column(
          children: [
            Text('Current: $data'),
            keep(ExpensiveWidget()), // Preserved widget
          ],
        );
      },
      onLoading: () => CircularProgressIndicator(),
      onError: (error) => Text('Error: $error'),
      onEmpty: () => Text('Waiting for data...'),
      onDone: () => Text('Stream finished'),
    );
  }
}

// Alternative: Use regular ReactiveBuilder with ViewModel
class ChatWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveViewModelBuilder<ChatViewModel, ChatState>(
      viewmodel: ChatService.chat.notifier,
      build: (chatState, viewModel, keep) {
        if (chatState.isLoading) {
          return CircularProgressIndicator();
        }
        
        return ListView.builder(
          itemCount: chatState.messages.length,
          itemBuilder: (context, index) {
            return MessageTile(message: chatState.messages[index]);
          },
        );
      },
    );
  }
}
```

**Stream Usage Patterns:**
- **ViewModel with internal stream** - Stream managed inside ViewModel lifecycle
- **ReactiveNotifier<Stream<T>>** - Direct stream exposure for ReactiveStreamBuilder
- **Hybrid approach** - Stream data transformed to ViewModel state

### Manual Listener Management

For complex scenarios where you need to register external listeners manually, both `ViewModel` and `AsyncViewModelImpl` provide `setupListeners` and `removeListeners` methods:

```dart
class NotificationViewModel extends ViewModel<List<String>> {
  NotificationViewModel() : super([]);
  
  // Store listeners as class properties for proper cleanup
  void _externalServiceListener() {
    addNotification('External service updated');
  }
  
  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    // Register external listeners
    ExternalService.updates.addListener(_externalServiceListener);
    WebSocketService.messages.listen(_handleWebSocketMessage);
    
    // Always call super to maintain internal state
    await super.setupListeners(currentListeners: currentListeners);
  }
  
  @override
  Future<void> removeListeners({List<String> currentListeners = const []}) async {
    // Clean up external listeners to prevent memory leaks
    ExternalService.updates.removeListener(_externalServiceListener);
    WebSocketService.messages.cancel();
    
    // Always call super to maintain internal state
    await super.removeListeners(currentListeners: currentListeners);
  }
  
  void addNotification(String message) {
    transformState((current) => [...current, message]);
  }
}
```

**Key Points:**
- `setupListeners` is called automatically after `init()`
- `removeListeners` is called automatically on `dispose()`
- Always call `super.setupListeners()` and `super.removeListeners()`
- Store listener references as class properties for proper cleanup
- Use named parameters: `{List<String> currentListeners = const []}`

### BuildContext Access in ViewModels

**ALL ViewModels** (both `ViewModel<T>` and `AsyncViewModelImpl<T>`) automatically provide `BuildContext` access for seamless migration from Provider/Riverpod and accessing Theme, MediaQuery, Navigator, etc.

```dart
// ✅ Works in ViewModel<T>
class UserViewModel extends ViewModel<UserState> {
  UserViewModel() : super(UserState.initial());
  
  @override
  void init() {
    if (hasContext) {
      // Access Riverpod container - can use both simultaneously!
      final container = ProviderScope.containerOf(context!);
      final riverpodData = container.read(someRiverpodProvider);
      
      // Access Flutter services
      final theme = Theme.of(context!);
      final navigator = Navigator.of(context!);
      
      updateSilently(UserState.fromMigration(
        riverpodData: riverpodData,
        isDarkTheme: theme.brightness == Brightness.dark,
      ));
    }
  }
  
  void navigateToProfile() {
    if (hasContext) {
      Navigator.of(context!).pushNamed('/profile');
    }
  }
}

// ✅ Works in AsyncViewModelImpl<T>  
class DataViewModel extends AsyncViewModelImpl<List<Item>> {
  DataViewModel() : super(AsyncState.initial());
  
  @override
  Future<List<Item>> init() async {
    // Context access works in async ViewModels too!
    if (hasContext) {
      // Can combine Riverpod with ReactiveNotifier
      final container = ProviderScope.containerOf(context!);
      final apiClient = container.read(apiClientProvider);
      
      // Use both state management systems together
      final localData = await _localDatabase.getItems();
      final serverData = await apiClient.fetchItems();
      
      return [...localData, ...serverData];
    }
    
    // Fallback without context
    return await _localDatabase.getItems();
  }
  
  void showSnackBar(String message) {
    if (hasContext) {
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

// ✅ Hybrid usage - ReactiveNotifier + Riverpod simultaneously
class HybridService {
  // ReactiveNotifier state
  static final ReactiveNotifier<HybridViewModel> state = 
    ReactiveNotifier<HybridViewModel>(() => HybridViewModel());
}

class HybridViewModel extends ViewModel<HybridState> {
  @override
  void init() {
    if (hasContext) {
      // Read from Riverpod providers
      final container = ProviderScope.containerOf(context!);
      final userNotifier = container.read(userNotifierProvider.notifier);
      final settingsNotifier = container.read(settingsNotifierProvider.notifier);
      
      // Listen to Riverpod changes and sync to ReactiveNotifier
      container.listen(userNotifierProvider, (previous, next) {
        updateState(data.copyWith(user: next));
      });
      
      // Both systems work together seamlessly!
    }
  }
}
```

**Context API:**
- **`context`** - Nullable BuildContext getter (`BuildContext?`)
- **`hasContext`** - Check if context is available (`bool`) 
- **`requireContext([operation])`** - Required context with descriptive errors

**Context Lifecycle:**
- Context automatically registered when any `ReactiveBuilder` mounts
- Context remains available while any builder is active
- Context cleared when last builder disposes

### Reactive Context Extensions

Access reactive state directly from `BuildContext` for hybrid usage patterns:

```dart
// Create context extensions for your services
extension AppContext on BuildContext {
  UserModel get user => getReactiveState(UserService.userState);
  SettingsModel get settings => getReactiveState(SettingsService.settings);
}

// Use in regular StatelessWidget/StatefulWidget
class HybridWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Direct access without ReactiveBuilder
    final user = context.user;
    final settings = context.settings;
    
    return Column(
      children: [
        Text('Hello ${user.name}'),
        Text('Theme: ${settings.isDarkMode ? 'Dark' : 'Light'}'),
      ],
    );
  }
}

// Generic access by type
final userState = context<UserModel>();

// Access by service key
final langState = context.getByKey('languageService');
```

---

## Cross-Service Communication

ReactiveNotifier supports explicit communication between different services using the existing `listenVM` API.

### Service Communication Example

```dart
// User Service
mixin UserService {
  static final ReactiveNotifier<UserViewModel> currentUser = 
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

// Notification Service  
mixin NotificationService {
  static final ReactiveNotifier<NotificationViewModel> notifications = 
    ReactiveNotifier<NotificationViewModel>(() => NotificationViewModel());
}

// Notification ViewModel listens to User changes
class NotificationViewModel extends ViewModel<NotificationModel> {
  NotificationViewModel() : super(NotificationModel.empty());

  @override
  void init() {
    // Explicit cross-service communication
    UserService.currentUser.notifier.listenVM((userData) {
      updateNotificationsForUser(userData);
    });
  }

  @override
  void onStateChanged(NotificationModel previous, NotificationModel next) {
    // React to notification changes
    if (next.unreadCount > previous.unreadCount) {
      print('New notifications: ${next.unreadCount}');
    }
  }

  void updateNotificationsForUser(UserModel user) {
    if (user.isActive) {
      fetchNotificationsForUser(user.email);
    } else {
      clearNotifications();
    }
  }

  Future<void> fetchNotificationsForUser(String email) async {
    // Fetch notifications logic
  }

  void clearNotifications() {
    transformState((current) => current.copyWith(notifications: []));
  }
}
```

### Multiple Service Instances

```dart
// Multiple instances of the same type in different services
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

// Explicit service access
class DashboardViewModel extends ViewModel<DashboardModel> {
  @override
  void init() {
    // Listen to specific user instances
    UserService.mainUser.notifier.listenVM((mainUser) {
      updateDashboardForMainUser(mainUser);
    });

    AdminService.adminUser.notifier.listenVM((adminUser) {
      updateDashboardForAdmin(adminUser);
    });
  }
}
```

---

## Testing with ReactiveNotifier

### Complete Testing Example

ReactiveNotifier is designed to be easy to test. Here's a comprehensive working example:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

// Simple model for testing
class CounterModel {
  final int count;
  final String message;

  CounterModel(this.count, this.message);

  CounterModel copyWith({int? count, String? message}) {
    return CounterModel(count ?? this.count, message ?? this.message);
  }
}

// ViewModel with state change hooks
class CounterViewModel extends ViewModel<CounterModel> {
  final List<String> stateChanges = [];
  
  CounterViewModel() : super(CounterModel(0, 'Initial'));
  
  @override
  void onStateChanged(CounterModel previous, CounterModel next) {
    stateChanges.add('${previous.count} → ${next.count}: ${next.message}');
  }
  
  void increment() {
    final newCount = data.count + 1;
    updateState(CounterModel(newCount, 'Incremented to $newCount'));
  }
}

// Services for cross-communication testing
mixin UserService {
  static final ReactiveNotifier<UserViewModel> user = 
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

mixin NotificationService {
  static final ReactiveNotifier<NotificationViewModel> notifications = 
    ReactiveNotifier<NotificationViewModel>(() => NotificationViewModel());
}

void main() {
  group('ReactiveNotifier Testing', () {
    setUp(() {
      // Clean up between test groups only
      ReactiveNotifier.cleanup();
    });
    
    group('Simple State Testing', () {
      test('should update and listen to state changes', () {
        final counter = ReactiveNotifier<int>(() => 0);
        final changes = <int>[];
        
        // Listen to changes
        counter.listen((value) => changes.add(value));
        
        // Update state
        counter.updateState(5);
        counter.transformState((current) => current + 10);
        
        expect(counter.notifier, equals(15));
        expect(changes, [5, 15]);
      });
    });
    
    group('ViewModel Testing', () {
      test('should update state and trigger hooks', () {
        final viewModel = CounterViewModel();
        
        expect(viewModel.data.count, equals(0));
        
        // Test increment
        viewModel.increment();
        viewModel.increment();
        
        expect(viewModel.data.count, equals(2));
        
        // Check state change hooks were called
        expect(viewModel.stateChanges, [
          '0 → 1: Incremented to 1',
          '1 → 2: Incremented to 2'
        ]);
      });
      
      test('should handle silent updates', () {
        final viewModel = CounterViewModel();
        
        // Silent updates still trigger hooks
        viewModel.updateSilently(CounterModel(5, 'Silent update'));
        
        expect(viewModel.data.count, equals(5));
        expect(viewModel.stateChanges.last, equals('0 → 5: Silent update'));
      });
    });
    
    group('Cross-Service Communication', () {
      test('should communicate between ViewModels', () async {
        final userVM = UserService.user.notifier;
        final notificationVM = NotificationService.notifications.notifier;
        
        // Update user and check notification was triggered
        userVM.updatePoints(100);
        
        // Allow async communication to complete
        await Future.delayed(Duration(milliseconds: 1));
        
        expect(notificationVM.data, isNotEmpty);
        expect(notificationVM.data.first, contains('100 points'));
      });
    });
  });
}
```

### Key Testing Principles

1. **Use `ReactiveNotifier.cleanup()`** only in `setUp()` between test groups, not individual tests
2. **Test state changes directly** by checking `.data` property
3. **Test state change hooks** by checking accumulated changes in custom lists
4. **Test cross-service communication** with small delays for async operations
5. **Use `updateSilently()`** for setting up test data without triggering notifications

---

## ReactiveContextBuilder - Maximum Performance

For high-performance applications with many reactive dependencies, use `ReactiveContextBuilder` to force InheritedWidget strategy, providing maximum efficiency:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveContextBuilder(
      // Force InheritedWidget strategy for these notifiers
      forceInheritedFor: [
        UserService.userState,
        SettingsService.settings,
        ThemeService.theme,
        LocalizationService.language,
      ],
      child: MaterialApp(
        home: HomePage(),
      ),
    );
  }
}

// Now these work with maximum performance through InheritedWidget
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Zero overhead - uses InheritedWidget.of() internally
    final user = context.user;
    final theme = context.theme;
    final language = context.language;
    
    return Column(
      children: [
        Text('Hello ${user.name}'),
        Text(language.greeting),
        // Regular reactive builders still work
        ReactiveBuilder<int>(
          notifier: CounterService.count,
          build: (value, notifier, keep) => Text('$value'),
        ),
      ],
    );
  }
}
```

**Performance Benefits:**
- **InheritedWidget efficiency** - Flutter's fastest rebuild mechanism
- **Zero listener overhead** - Uses Flutter's native dependency system
- **Automatic cleanup** - InheritedWidget handles lifecycle automatically
- **Cross-widget optimization** - Multiple widgets share same InheritedWidget

**When to Use ReactiveContextBuilder:**
- Apps with 10+ reactive dependencies
- Performance-critical applications
- Many widgets accessing same state
- When you need maximum Flutter efficiency

---

## When to Use Each Component

### ReactiveNotifier<T>
- Simple state values (int, bool, String)
- Settings and configuration
- State that doesn't require initialization
- No complex business logic needed

### ViewModel<T>
- Complex state objects  
- State requires synchronous initialization
- Business logic is involved
- State validation needed
- Cross-service reactive communication needed
- **✅ BuildContext access** for migration/hybrid usage

### AsyncViewModelImpl<T>
- Loading data from external sources
- Need loading/error state handling
- API calls or database operations
- Background data synchronization
- Async initialization required
- **✅ BuildContext access** for migration/hybrid usage

### ReactiveStreamBuilder<VM, T>
- **Real-time data streams** (WebSocket, Server-Sent Events)
- **Database change streams** (Firestore, PostgreSQL LISTEN/NOTIFY)
- **File system watchers** and live data feeds
- **Periodic data updates** with automatic stream management
- **Chat applications**, live notifications, stock prices
- **IoT sensor data** and real-time analytics

### Reactive Context Extensions
- **Hybrid apps** migrating from Provider/Riverpod
- **Mixed architecture** with existing StatelessWidget/StatefulWidget
- **Legacy code integration** without full ReactiveBuilder adoption
- **Performance optimization** with context.keep() for expensive widgets
- **Direct state access** without builder pattern

### ReactiveContextBuilder
- **High-performance apps** with many reactive dependencies
- **Enterprise applications** requiring maximum efficiency
- **Apps with complex state trees** (10+ reactive services)
- **When InheritedWidget strategy is preferred** over listener-based rebuilds

---

## Performance Optimization

### Memory Management

```dart
// Automatic cleanup
ReactiveNotifier.cleanup(); // Clears all instances

// Manual cleanup for specific instances
service.dispose();

// Memory leak prevention
@override
void dispose() {
  // ViewModels automatically clean up listeners
  super.dispose();
}
```

### Build Optimization & Widget Preservation

ReactiveNotifier provides multiple strategies for preventing expensive widget rebuilds:

#### 1. keep() Function in Builders
```dart
ReactiveBuilder<UserModel>(
  notifier: UserService.userState,
  build: (user, notifier, keep) {
    return Column(
      children: [
        Text('Hello ${user.name}'), // Rebuilds when user changes
        keep(ExpensiveAnimationWidget()), // Never rebuilds
        keep(ComplexChartWidget(), 'chart_key'), // Preserved with specific key
      ],
    );
  },
)
```

#### 2. Widget Extensions for Preservation
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Dynamic content'),
        // Extension method - preserves automatically
        ExpensiveWidget().keep('expensive_key'),
        HeavyAnimationWidget().keep(), // Auto-generated key
      ],
    );
  }
}
```

#### 3. Context-Based Preservation
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Dynamic content'),
        // Context-aware preservation
        context.keep(ExpensiveWidget(), 'context_key'),
        // Batch preservation
        ...context.keepAll([
          Widget1(),
          Widget2(),
          Widget3(),
        ], 'batch_widgets'),
      ],
    );
  }
}
```

#### 4. Advanced Preservation Strategies
```dart
// Automatic cleanup and intelligent caching
ReactiveContextPreservationWrapper(
  preservationKey: 'complex_widget',
  enableAutomaticCleanup: true,
  child: SuperExpensiveWidget(),
)

// Functional approach
final preservedWidgets = preserveWidgets([
  ExpensiveWidget1(),
  ExpensiveWidget2(),
], 'batch_key');
```

**Performance Benefits:**
- **Automatic key management** - No manual key tracking needed
- **LRU cache cleanup** - Prevents memory leaks with intelligent cleanup
- **Batch operations** - Optimize multiple widget preservation
- **Debug statistics** - Monitor preservation performance with `getPreservationStatistics()`

---

## Contributing

We welcome contributions to ReactiveNotifier! Here's how you can help:

### Bug Reports
Please use the GitHub issue tracker to report bugs. Include a minimal reproduction case.

### Feature Requests  
Suggest new features through GitHub issues. Provide use cases and examples.

### Documentation
Help improve documentation by submitting PRs with clarifications and examples.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/jhonacode/reactive_notifier.git

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run example app
cd example && flutter run
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Support the Project

If ReactiveNotifier has been helpful for your projects, consider:

- Giving it a star on GitHub
- Writing a review on pub.dev
- Sharing it with your team
- Contributing to the codebase
- Reporting bugs and suggesting improvements

---

## Acknowledgments

- Thanks to the Flutter team for the excellent framework
- Inspired by Android's LiveData and ViewModel architecture patterns
- Based on native resource management principles and lifecycle patterns
- Community feedback and contributions
- All developers who have tested and improved ReactiveNotifier

---

**Made with ❤️ by [@jhonacode](https://github.com/jhonacode)**

*ReactiveNotifier - State Management for Flutter*