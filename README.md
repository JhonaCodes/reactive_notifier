# ReactiveNotifier v2.13.0

**Professional State Management for Flutter** - A powerful, elegant, and secure solution for managing reactive state in Flutter applications. Built with enterprise-grade architecture in mind, ReactiveNotifier provides fine-grained control, automatic BuildContext access, memory leak prevention, and reactive state change hooks.

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

## What's New in v2.13.0

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
- **Automatic BuildContext access** - Zero-configuration context availability
- **State change hooks** - React to internal state changes
- **Cross-service communication** - Explicit sandbox-to-sandbox messaging
- **DevTools integration** - Enhanced debugging and monitoring capabilities
- **Comprehensive testing support** - Easy mocking and test utilities
- **Migration support** - Seamless transition from Provider, Riverpod, BLoC, GetX

---

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  reactive_notifier:
    git:
      url: https://github.com/jhonacode/reactive_notifier.git
      ref: v2.13.0
```

### DevTools Extension (Automatic)

The ReactiveNotifier DevTools extension is automatically initialized in debug mode. No additional setup required.

**Features:**
- Real-time state monitoring
- ViewModel lifecycle tracking  
- Memory usage analysis
- State change history
- Performance metrics

---

## Core Philosophy: "Create Once, Reuse Always"

ReactiveNotifier follows a singleton pattern where each state is created once and reused throughout the application lifecycle.

### Traditional State Management
```dart
// ❌ Multiple instances, complex lifecycle management
final provider1 = StateProvider<int>((ref) => 0);
final provider2 = StateProvider<int>((ref) => 0);
```

### ReactiveNotifier Approach
```dart
// ✅ Single instance per service, automatic lifecycle
mixin CounterService {
  static final ReactiveNotifier<int> count = ReactiveNotifier<int>(() => 0);
}
```

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

## State Change Hooks

ReactiveNotifier v2.13.0 introduces state change hooks that allow ViewModels to react to their own state changes internally.

### ViewModel Hooks

```dart
class UserViewModel extends ViewModel<UserModel> {
  @override
  void onStateChanged(UserModel previous, UserModel next) {
    // Called on every state change
    print('User state changed from ${previous.name} to ${next.name}');
    
    // Log specific changes
    if (previous.email != next.email) {
      logEmailChange(previous.email, next.email);
    }
    
    // Trigger side effects
    if (previous.isActive != next.isActive) {
      notifyUserStatusChange(next.isActive);
    }
  }

  void logEmailChange(String oldEmail, String newEmail) {
    // Analytics or logging
    print('Email changed from $oldEmail to $newEmail');
  }

  void notifyUserStatusChange(bool isActive) {
    // Notify external services
    if (isActive) {
      activateUserServices();
    } else {
      deactivateUserServices();
    }
  }
}
```

### AsyncViewModel Hooks

```dart
class DataViewModel extends AsyncViewModelImpl<List<Item>> {
  @override
  void onAsyncStateChanged(AsyncState<List<Item>> previous, AsyncState<List<Item>> next) {
    // Called on every async state change
    
    // Handle loading started
    if (previous.isInitial && next.isLoading) {
      showLoadingIndicator();
    }
    
    // Handle successful load
    if (previous.isLoading && next.isSuccess) {
      hideLoadingIndicator();
      logSuccessfulLoad(next.data?.length ?? 0);
    }
    
    // Handle errors
    if (next.isError) {
      hideLoadingIndicator();
      logError(next.error.toString());
      showErrorMessage(next.error.toString());
    }
  }

  void showLoadingIndicator() {
    // UI feedback logic
  }

  void hideLoadingIndicator() {
    // UI cleanup logic
  }

  void logSuccessfulLoad(int itemCount) {
    print('Successfully loaded $itemCount items');
  }

  void logError(String error) {
    print('Error loading data: $error');
  }

  void showErrorMessage(String error) {
    // Show user-friendly error message
  }
}
```

### Hook Integration

Hooks are automatically called in all state update methods:

- `updateState()` - Triggers hooks with notifications
- `updateSilently()` - Triggers hooks without notifications
- `transformState()` - Triggers hooks with notifications
- `transformStateSilently()` - Triggers hooks without notifications

---

## Builder Components

### ReactiveBuilder<T> - Simple Values

```dart
ReactiveBuilder<int>(
  notifier: CounterService.count,
  build: (value, notifier, keep) {
    return Text('Count: $value');
  },
)
```

### ReactiveViewModelBuilder<VM, T> - Complex State

```dart
ReactiveViewModelBuilder<UserViewModel, UserModel>(
  viewmodel: UserService.userState.notifier,
  build: (user, viewModel, keep) {
    return Column(
      children: [
        Text('Name: ${user.name}'),
        ElevatedButton(
          onPressed: () => viewModel.updateUserName('New Name'),
          child: Text('Update Name'),
        ),
      ],
    );
  },
)
```

### ReactiveAsyncBuilder<VM, T> - Async Operations

```dart
ReactiveAsyncBuilder<TodoListViewModel, List<Todo>>(
  notifier: TodoService.todoList.notifier,
  onData: (todos, viewModel, keep) {
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) => TodoTile(todo: todos[index]),
    );
  },
  onLoading: () => CircularProgressIndicator(),
  onError: (error, stackTrace) => ErrorWidget(error: error),
)
```

---

## Testing with ReactiveNotifier

### Essential Testing Setup

```dart
void main() {
  setUp(() {
    ReactiveNotifier.cleanup();
  });
  
  tearDown(() {
    ReactiveNotifier.cleanup();
  });
}
```

### Testing ViewModels

```dart
test('should update user name', () {
  final viewModel = UserService.userState.notifier;
  
  viewModel.updateUserName('John Doe');
  
  expect(viewModel.data.name, equals('John Doe'));
});

test('should trigger state change hook', () {
  final viewModel = TestUserViewModel();
  final stateChanges = <String>[];
  
  // Override hook for testing
  viewModel.onStateChanged = (previous, next) {
    stateChanges.add('${previous.name} -> ${next.name}');
  };
  
  viewModel.updateUserName('Jane');
  
  expect(stateChanges, contains(' -> Jane'));
});
```

### Testing Cross-Service Communication

```dart
test('should update notifications when user changes', () async {
  final userVM = UserService.currentUser.notifier;
  final notificationVM = NotificationService.notifications.notifier;
  
  userVM.updateUserName('John');
  
  await Future.delayed(Duration(milliseconds: 1));
  
  expect(notificationVM.data.userName, equals('John'));
});
```

---

## Migration Guides

### From Provider

```dart
// Before (Provider)
class Counter with ChangeNotifier {
  int _count = 0;
  int get count => _count;
  
  void increment() {
    _count++;
    notifyListeners();
  }
}

// After (ReactiveNotifier)
mixin CounterService {
  static final ReactiveNotifier<int> count = ReactiveNotifier<int>(() => 0);
}

// Update usage
CounterService.count.updateState(CounterService.count.notifier + 1);
```

### From Riverpod

```dart
// Before (Riverpod)
final counterProvider = StateProvider<int>((ref) => 0);

// After (ReactiveNotifier)
mixin CounterService {
  static final ReactiveNotifier<int> count = ReactiveNotifier<int>(() => 0);
}
```

### From BLoC

```dart
// Before (BLoC)
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}

// After (ReactiveNotifier)
class CounterViewModel extends ViewModel<int> {
  CounterViewModel() : super(0);
  
  @override
  void init() {}
  
  void increment() {
    updateState(data + 1);
  }
}
```

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

### AsyncViewModelImpl<T>
- Loading data from external sources
- Need loading/error state handling
- API calls or database operations
- Background data synchronization
- Async initialization required

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

### Build Optimization

```dart
ReactiveBuilder<UserModel>(
  notifier: UserService.userState,
  build: (user, notifier, keep) {
    return Column(
      children: [
        Text(user.name), // Rebuilds when user changes
        keep(ExpensiveWidget()), // Never rebuilds
      ],
    );
  },
)
```

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