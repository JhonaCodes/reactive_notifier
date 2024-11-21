# ReactiveNotifier

A powerful, elegant, and type-safe state management solution for Flutter that seamlessly integrates with MVVM pattern while maintaining complete independence from BuildContext. Perfect for applications of any size.

![reactive_notifier](https://github.com/user-attachments/assets/ca97c7e6-a254-4b19-b58d-fd07206ff6ee)

[![Dart SDK Version](https://img.shields.io/badge/Dart-SDK%20%3E%3D%202.17.0-0175C2?logo=dart)](https://dart.dev)
[![Flutter Platform](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![pub package](https://img.shields.io/pub/v/reactive_notifier.svg)](https://pub.dev/packages/reactive_notifier)
[![likes](https://img.shields.io/pub/likes/reactive_notifier?logo=dart)](https://pub.dev/packages/reactive_notifier/score)
[![popularity](https://img.shields.io/pub/popularity/reactive_notifier?logo=dart)](https://pub.dev/packages/reactive_notifier/score)
[![Downloads](https://img.shields.io/pub/downloads/reactive_notifier?logo=dart)](https://pub.dev/packages/reactive_notifier/score)

[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![codecov](https://codecov.io/gh/jhonacodes/reactive_notifier/branch/main/graph/badge.svg)](https://codecov.io/gh/jhonacodes/reactive_notifier)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/jhonacodes/reactive_notifier/workflows/ci/badge.svg)](https://github.com/jhonacodes/reactive_notifier/actions)

> **Note**: Are you migrating from `reactive_notify`? The API remains unchanged - just update your dependency to `reactive_notifier`.

## Features

- 🚀 Simple and intuitive API
- 🏗️ Perfect for MVVM architecture
- 🔄 Independent from BuildContext
- 🎯 Type-safe state management
- 📡 Built-in Async and Stream support
- 🔗 Smart related states system
- 🛠️ Repository/Service layer integration
- ⚡ High performance with minimal rebuilds
- 🐛 Powerful debugging tools
- 📊 Detailed error reporting

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  reactive_notifier: ^2.2.0
```

## Quick Start

### Basic Usage

```dart
// Define states globally or in a mixin
final counterState = ReactiveNotifier<int>(() => 0);

// Using a mixin (recommended for organization)
mixin AppStateMixin {
  static final counterState = ReactiveNotifier<int>(() => 0);
  static final userState = ReactiveNotifier<UserState>(() => UserState());
}

// Use in widgets - No BuildContext needed for state management!
class CounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<int>(
      valueListenable: AppStateMixin.counterState,
      builder: (context, value, keep) {
        return Column(
          children: [
            Text('Count: $value'),
            keep(const CounterButtons()), // Static content preserved
          ],
        );
      },
    );
  }
}
```

## Core Concepts

### 1. State Management Patterns

```dart
// ✅ Recommended: Global state declaration
final userState = ReactiveNotifier<UserState>(() => UserState());

// ✅ Recommended: Mixin with static states
mixin AuthStateMixin {
  static final authState = ReactiveNotifier<AuthState>(() => AuthState());
  static final sessionState = ReactiveNotifier<SessionState>(() => SessionState());
}

// ❌ Avoid: Never create inside widgets
class WrongWidget extends StatelessWidget {
  final state = ReactiveNotifier<int>(() => 0); // Don't do this!
}
```

### 2. MVVM Integration

```dart
// 1. Repository Layer
class UserRepository {
  Future<User> getUser() async => // Implementation
}

// 2. ViewModel
class UserViewModel extends ViewModelImpl<UserState> {
  UserViewModel(UserRepository repository) 
    : super(repository, UserState());
    
  Future<void> loadUser() async {
    try {
      final user = await repository.getUser();
      setState(UserState(name: user.name, isLoggedIn: true));
    } catch (e) {
      setError(e);
    }
  }
}

// 3. Create ViewModel Notifier
final userNotifier = ReactiveNotifier<UserViewModel>(
  () => UserViewModel(UserRepository())
);

// 4. Use in View
class UserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<UserViewModel>(
      valueListenable: userNotifier,
      builder: (_, viewModel, keep) {
        return Column(
          children: [
            Text('Welcome ${viewModel.state.name}'),
            keep(const UserActions()),
          ],
        );
      },
    );
  }
}
```

### 3. Related States System

```dart
// Define individual states
final userState = ReactiveNotifier<UserState>(() => UserState());
final cartState = ReactiveNotifier<CartState>(() => CartState());

// Create relationships
final appState = ReactiveNotifier<AppState>(
  () => AppState(),
  related: [userState, cartState]
);

// Access in widgets
class AppDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<AppState>(
      valueListenable: appState,
      builder: (context, state, keep) {
        final user = appState.from<UserState>();
        final cart = appState.from<CartState>();
        
        return Column(
          children: [
            Text('Welcome ${user.name}'),
            Text('Cart Items: ${cart.items.length}'),
          ],
        );
      },
    );
  }
}
```

### 4. Async & Stream Support

```dart
// Async Operations
class ProductsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveAsyncBuilder<List<Product>>(
      viewModel: productViewModel,
      buildSuccess: (products) => ProductGrid(products),
      buildLoading: () => const LoadingSpinner(),
      buildError: (error, stack) => ErrorWidget(error),
    );
  }
}

// Stream Handling
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveStreamBuilder<Message>(
      streamNotifier: messagesStream,
      buildData: (message) => MessageBubble(message),
      buildLoading: () => const LoadingIndicator(),
      buildError: (error) => ErrorMessage(error),
    );
  }
}
```

## Best Practices

### Performance Optimization
- Use `keep` for static content
- Maintain flat state hierarchy
- Avoid unnecessary rebuilds
- Use keyNotifier for specific state access

### Architecture Guidelines
- Follow MVVM pattern
- Use Repository/Service patterns
- Keep state updates context-independent
- Initialize ViewModels automatically

### State Management
- Declare states globally or in mixins
- Maintain flat relationships
- Avoid circular dependencies
- Use type-safe access methods

## Debugging

ReactiveNotifier includes comprehensive debugging tools:

```dart
// Enable debugging
ReactiveNotifier.debugMode = true;

// Custom debug logging
ReactiveNotifier.onDebug = (message) {
  print('🔍 Debug: $message');
};

// Performance monitoring
ReactiveNotifier.onPerformanceWarning = (details) {
  print('⚠️ Performance: ${details.message}');
};
```

## Examples

Check out our [example app](https://github.com/jhonacodes/reactive_notifier/tree/main/example) for more comprehensive examples and use cases.

## Contributing

We love contributions! Please read our [Contributing Guide](CONTRIBUTING.md) first.

1. Fork it
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Create a new Pull Request

## Support

- 🌟 Star the repo to show support
- 🐛 Create an [issue](https://github.com/jhonacodes/reactive_notifier/issues) for bugs
- 💡 Submit feature requests through [issues](https://github.com/jhonacodes/reactive_notifier/issues)
- 📝 Contribute to the [documentation](https://github.com/jhonacodes/reactive_notifier/wiki)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ by [JhonaCodes](https://github.com/jhonacodes)
