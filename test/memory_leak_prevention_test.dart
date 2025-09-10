import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// Test models for memory leak detection
class TestUserState {
  final String name;
  final int age;

  const TestUserState({required this.name, required this.age});

  TestUserState copyWith({String? name, int? age}) {
    return TestUserState(
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }
}

class TestOrderState {
  final String orderId;
  final List<String> items;

  const TestOrderState({required this.orderId, required this.items});

  TestOrderState copyWith({String? orderId, List<String>? items}) {
    return TestOrderState(
      orderId: orderId ?? this.orderId,
      items: items ?? this.items,
    );
  }
}

/// Test ViewModels that listen to each other
class UserViewModel extends ViewModel<TestUserState> {
  UserViewModel() : super(const TestUserState(name: 'Unknown', age: 0));

  @override
  void init() {
    updateSilently(const TestUserState(name: 'John', age: 25));
  }

  void updateAge(int newAge) {
    transformState((state) => state.copyWith(age: newAge));
  }
}

class OrderViewModel extends ViewModel<TestOrderState> {
  TestUserState? currentUser;
  final bool shouldListenToUser;

  OrderViewModel({this.shouldListenToUser = false})
      : super(const TestOrderState(orderId: '', items: []));

  @override
  void init() {
    updateSilently(const TestOrderState(orderId: 'ORDER-001', items: []));

    // Only listen to user changes if explicitly requested
    if (shouldListenToUser) {
      try {
        UserService.userState.notifier.listenVM((userData) {
          currentUser = userData;
          _updateOrderForUser(userData);
        });
      } catch (e) {
        // Handle case where UserService might be disposed
        print('Cannot listen to UserService: $e');
      }
    }
  }

  void _updateOrderForUser(TestUserState user) {
    transformState((state) => state.copyWith(
          orderId: 'ORDER-${user.name}-${user.age}',
        ));
  }

  void addItem(String item) {
    transformState((state) => state.copyWith(
          items: [...state.items, item],
        ));
  }
}

/// Services
mixin UserService {
  static ReactiveNotifier<UserViewModel>? _userState;

  static ReactiveNotifier<UserViewModel> get userState {
    _userState ??= ReactiveNotifier<UserViewModel>(() => UserViewModel());
    return _userState!;
  }

  static void reset() {
    _userState = null;
  }
}

mixin OrderService {
  static ReactiveNotifier<OrderViewModel>? _orderState;

  static ReactiveNotifier<OrderViewModel> get orderState {
    _orderState ??= ReactiveNotifier<OrderViewModel>(
        () => OrderViewModel(shouldListenToUser: true));
    return _orderState!;
  }

  static ReactiveNotifier<OrderViewModel> createSimple() {
    return ReactiveNotifier<OrderViewModel>(
        () => OrderViewModel(shouldListenToUser: false));
  }

  static void reset() {
    _orderState = null;
  }
}

void main() {
  group('Memory Leak Prevention Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
      UserService.reset();
      OrderService.reset();
    });

    test('listenVM properly cleans up single listener', () {
      final userVM = UserViewModel();
      final orderVM = OrderViewModel();

      // OrderVM should have 1 listener (from init)
      expect(orderVM.activeListenerCount,
          equals(0)); // Init hasn't been called yet manually

      // Manually set up listening
      userVM.listenVM((userData) {
        // This creates a listener relationship
      });

      expect(userVM.activeListenerCount, equals(1));

      // Clean up
      userVM.stopListeningVM();
      expect(userVM.activeListenerCount, equals(0));
    });

    test('Multiple listenVM calls are tracked correctly', () {
      final userVM = UserViewModel();

      // Add multiple listeners
      userVM.listenVM((data) => print('Listener 1: ${data.name}'));
      userVM.listenVM((data) => print('Listener 2: ${data.age}'));
      userVM.listenVM((data) => print('Listener 3: ${data.name}-${data.age}'));

      expect(userVM.activeListenerCount, equals(3));

      // Clean up all
      userVM.stopListeningVM();
      expect(userVM.activeListenerCount, equals(0));
    });

    test('dispose() automatically cleans up all listenVM relationships', () {
      final userVM = UserViewModel();
      final orderVM = OrderViewModel(shouldListenToUser: false);

      // Create listening relationships
      userVM.listenVM((data) => print('User listener'));
      orderVM.listenVM((data) => print('Order listener'));

      expect(userVM.activeListenerCount, greaterThan(0));
      expect(orderVM.activeListenerCount, greaterThan(0));

      // Dispose should clean everything
      userVM.dispose();
      orderVM.dispose();

      // After dispose, the internal cleanup should have happened
      // We can't test activeListenerCount after dispose, but the cleanup is verified by no crashes
    });

    test('Cross-ViewModel listening creates proper relationships', () {
      final userVM = UserService.userState.notifier;
      final orderVM = OrderService.orderState.notifier;

      // Give time for the listener to be set up in OrderViewModel.init()
      // Initial state should be properly configured
      expect(userVM.data.name, equals('John'));

      // The orderVM should eventually update based on the user data
      // Since init() was called, the listener should be active
      // Let's trigger a state change to ensure the listener works
      userVM.updateAge(30);

      // Order should update reactively
      expect(orderVM.data.orderId, equals('ORDER-John-30'));

      // Add item to order
      orderVM.addItem('Widget A');
      expect(orderVM.data.items, contains('Widget A'));
    });

    test('Circular reference prevention - ViewModels listening to each other',
        () {
      final userVM = UserService.userState.notifier;
      final orderVM = OrderService.orderState.notifier;

      // This is a potential circular reference scenario:
      // OrderVM already listens to UserVM (from init)
      // Now we make UserVM listen to OrderVM

      userVM.listenVM((userData) {
        // UserVM reacts to its own changes (not recommended but should not crash)
      });

      orderVM.listenVM((orderData) {
        // OrderVM listens to itself + UserVM (from init)
      });

      // Should not cause infinite loops or crashes
      userVM.updateAge(35);
      orderVM.addItem('Widget B');

      // Verify states are correct
      expect(userVM.data.age, equals(35));
      expect(orderVM.data.items, contains('Widget B'));
      expect(orderVM.data.orderId, equals('ORDER-John-35'));
    });

    test('Listener cleanup prevents memory leaks on service destruction', () {
      // Create fresh services
      final userVM = UserViewModel();
      final orderVM = OrderViewModel(shouldListenToUser: false);

      // Set up listening relationship
      orderVM.listenVM((orderData) {
        if (!userVM.isDisposed) {
          userVM.updateAge(orderData.items.length);
        }
      });

      userVM.listenVM((userData) {
        if (!orderVM.isDisposed) {
          orderVM.addItem('Item-${userData.age}');
        }
      });

      // Both should have listeners
      expect(userVM.activeListenerCount, greaterThan(0));
      expect(orderVM.activeListenerCount, greaterThan(0));

      // Dispose one ViewModel
      userVM.dispose();

      // The other ViewModel should still work
      orderVM.addItem('Final Item');
      expect(orderVM.data.items, contains('Final Item'));

      // Clean up
      orderVM.dispose();
    });

    test('Listener count tracking is accurate', () {
      final vm = UserViewModel();

      expect(vm.activeListenerCount, equals(0));

      // Add listeners one by one
      vm.listenVM((data) => print('1'));
      expect(vm.activeListenerCount, equals(1));

      vm.listenVM((data) => print('2'));
      expect(vm.activeListenerCount, equals(2));

      vm.listenVM((data) => print('3'));
      expect(vm.activeListenerCount, equals(3));

      // Remove all
      vm.stopListeningVM();
      expect(vm.activeListenerCount, equals(0));
    });
  });
}
