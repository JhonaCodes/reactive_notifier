# Quick Start Guide

## Installation

```yaml
dependencies:
  reactive_notifier: ^2.10.5
```

## Basic Usage

### 1. Simple State with ReactiveNotifier

```dart
// Define service
mixin CounterService {
  static final ReactiveNotifier<int> count = ReactiveNotifier<int>(() => 0);
}

// Use in UI
ReactiveBuilder<int>(
  notifier: CounterService.count,
  build: (value, notifier, keep) => Text('Count: $value'),
)

// Update state
CounterService.count.updateState(5);
```

### 2. Complex State with ViewModel

```dart
// Define state model
class UserState {
  final String name;
  final bool isLoggedIn;
  
  const UserState({required this.name, required this.isLoggedIn});
  
  UserState copyWith({String? name, bool? isLoggedIn}) => UserState(
    name: name ?? this.name,
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
  );
}

// Define ViewModel
class UserViewModel extends ViewModel<UserState> {
  UserViewModel() : super(UserState(name: '', isLoggedIn: false));
  
  @override
  void init() {
    log('User ViewModel initialized');
  }
  
  void login(String name) {
    transformState((state) => state.copyWith(name: name, isLoggedIn: true));
  }
}

// Service
mixin UserService {
  static final ReactiveNotifier<UserViewModel> userState = 
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

// Use in UI
ReactiveViewModelBuilder<UserViewModel, UserState>(
  viewmodel: UserService.userState.notifier,
  build: (user, viewmodel, keep) => Text('Welcome ${user.name}'),
)
```

### 3. Async Data with AsyncViewModelImpl

```dart
class DataViewModel extends AsyncViewModelImpl<List<String>> {
  DataViewModel() : super(AsyncState.initial(), loadOnInit: true);
  
  @override
  Future<List<String>> init() async {
    await Future.delayed(Duration(seconds: 2));
    return ['Item 1', 'Item 2', 'Item 3'];
  }
}

// Service
mixin DataService {
  static final ReactiveNotifier<DataViewModel> dataState = 
    ReactiveNotifier<DataViewModel>(() => DataViewModel());
}

// Use in UI
ReactiveAsyncBuilder<DataViewModel, List<String>>(
  notifier: DataService.dataState.notifier,
  onData: (items, viewModel, keep) => ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => ListTile(title: Text(items[index])),
  ),
  onLoading: () => CircularProgressIndicator(),
  onError: (error, stack) => Text('Error: $error'),
)
```

## Key Concepts

1. **Singleton Pattern**: "Create once, reuse always"
2. **Mixin Organization**: Always use mixins for services
3. **Lifecycle Management**: Independent from UI lifecycle
4. **Reactive Communication**: ViewModels can listen to each other