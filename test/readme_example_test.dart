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
  
  @override
  String toString() => 'CounterModel($count, $message)';
}

// ViewModel with hooks for testing
class CounterViewModel extends ViewModel<CounterModel> {
  final List<String> stateChanges = [];
  
  CounterViewModel() : super(CounterModel(0, 'Initial'));
  
  @override
  void init() {
    // Initialize if needed
  }
  
  @override
  void onStateChanged(CounterModel previous, CounterModel next) {
    stateChanges.add('${previous.count} → ${next.count}: ${next.message}');
  }
  
  void increment() {
    final newCount = data.count + 1;
    updateState(CounterModel(newCount, 'Incremented to $newCount'));
  }
}

// Simple ReactiveNotifier test
class SimpleCounterService {
  static final ReactiveNotifier<int> count = ReactiveNotifier<int>(() => 0);
}

// User model for cross-service communication test
class UserModel {
  final String name;
  final int points;
  
  UserModel(this.name, this.points);
  
  UserModel copyWith({String? name, int? points}) {
    return UserModel(name ?? this.name, points ?? this.points);
  }
}

// User ViewModel
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel('Guest', 0));
  
  @override
  void init() {}
  
  void updatePoints(int points) {
    transformState((current) => current.copyWith(points: points));
  }
}

// Notification ViewModel that listens to User changes
class NotificationViewModel extends ViewModel<List<String>> {
  NotificationViewModel() : super([]);
  
  @override
  void init() {
    // Cross-service communication using listenVM
    UserService.user.notifier.listenVM((userData) {
      addNotification('User ${userData.name} now has ${userData.points} points');
    });
  }
  
  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    // Example of setupListeners - called automatically in init
    await super.setupListeners(currentListeners: currentListeners);
  }
  
  void addNotification(String notification) {
    transformState((current) => [...current, notification]);
  }
}

// Services
class UserService {
  static final ReactiveNotifier<UserViewModel> user = 
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

class NotificationService {
  static final ReactiveNotifier<NotificationViewModel> notifications = 
    ReactiveNotifier<NotificationViewModel>(() => NotificationViewModel());
}

void main() {
  group('ReactiveNotifier Testing Guide', () {
    setUp(() {
      // Clean up only between test groups, not individual tests
      ReactiveNotifier.cleanup();
    });
    
    group('Simple State Testing', () {
      test('should update simple state', () {
        final counter = SimpleCounterService.count;
        
        expect(counter.notifier, equals(0));
        
        counter.updateState(5);
        expect(counter.notifier, equals(5));
        
        counter.transformState((current) => current + 10);
        expect(counter.notifier, equals(15));
      });
      
      test('should listen to state changes', () {
        final counter = SimpleCounterService.count;
        final changes = <int>[];
        
        // Listen to changes
        counter.listen((value) {
          changes.add(value);
        });
        
        counter.updateState(1);
        counter.updateState(2);
        
        expect(changes, [1, 2]);
      });
    });
    
    group('ViewModel Testing', () {
      test('should update ViewModel state', () {
        final viewModel = CounterViewModel();
        
        expect(viewModel.data.count, equals(0));
        expect(viewModel.data.message, equals('Initial'));
        
        viewModel.increment();
        
        expect(viewModel.data.count, equals(1));
        expect(viewModel.data.message, equals('Incremented to 1'));
      });
      
      test('should trigger state change hooks', () {
        final viewModel = CounterViewModel();
        
        viewModel.increment();
        viewModel.increment();
        
        // Check hooks were called
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
      test('should communicate between services', () async {
        final userVM = UserService.user.notifier;
        final notificationVM = NotificationService.notifications.notifier;
        
        // Initially no notifications
        expect(notificationVM.data, isEmpty);
        
        // Update user points
        userVM.updatePoints(100);
        
        // Allow async communication to complete
        await Future.delayed(Duration(milliseconds: 1));
        
        // Check notification was created
        expect(notificationVM.data, isNotEmpty);
        expect(notificationVM.data.first, contains('Guest'));
        expect(notificationVM.data.first, contains('100 points'));
      });
      
      test('should handle setupListeners correctly', () {
        final notificationVM = NotificationService.notifications.notifier;
        
        // setupListeners is called automatically in init()
        expect(notificationVM.hasInitializedListenerExecution, isTrue);
      });
    });
    
    group('State Management Methods', () {
      test('should test transformState', () {
        final viewModel = CounterViewModel();
        
        viewModel.transformState((current) => 
          CounterModel(current.count + 10, 'Transformed'));
        
        expect(viewModel.data.count, equals(10));
        expect(viewModel.data.message, equals('Transformed'));
      });
      
      test('should test transformStateSilently', () {
        final viewModel = CounterViewModel();
        
        viewModel.transformStateSilently((current) => 
          CounterModel(current.count + 5, 'Silent transform'));
        
        expect(viewModel.data.count, equals(5));
        expect(viewModel.data.message, equals('Silent transform'));
      });
    });
  });
}