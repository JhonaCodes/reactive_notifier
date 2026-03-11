import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

// ─── Test Models ───

class UserModel {
  final String name;
  final int age;

  const UserModel(this.name, this.age);

  @override
  String toString() => 'UserModel($name, $age)';
}

// ─── Test ViewModels ───

class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(const UserModel('guest', 0));

  @override
  void init() {}
}

class ItemsViewModel extends AsyncViewModelImpl<List<String>> {
  ItemsViewModel() : super(AsyncState.initial(), loadOnInit: false);

  @override
  Future<List<String>> init() async {
    return ['item1', 'item2'];
  }
}

void main() {
  setUp(() {
    ReactiveNotifier.cleanup();
  });

  tearDown(() {
    ReactiveNotifier.cleanup();
  });

  group('call() syntax — ReactiveNotifier<T> (simple types)', () {
    test('ReactiveNotifier<int> → call() returns int', () {
      final notifier = ReactiveNotifier<int>(() => 42);

      final result = notifier();

      expect(result, equals(42), reason: 'call() should return the int value');
      expect(result, isA<int>());
    });

    test('ReactiveNotifier<String> → call() returns String', () {
      final notifier = ReactiveNotifier<String>(() => 'hello');

      final result = notifier();

      expect(result, equals('hello'),
          reason: 'call() should return the String value');
      expect(result, isA<String>());
    });

    test('ReactiveNotifier<bool> → call() returns bool', () {
      final notifier = ReactiveNotifier<bool>(() => true);

      final result = notifier();

      expect(result, isTrue, reason: 'call() should return the bool value');
    });
  });

  group('call() syntax — ReactiveNotifier<ViewModel<T>>', () {
    test('ReactiveNotifier<ViewModel<T>> → call() returns T (data from VM)',
        () {
      final notifier =
          ReactiveNotifier<UserViewModel>(() => UserViewModel());

      final result = notifier();

      // call() on ReactiveNotifier<ViewModel<T>> should return T (the .data)
      expect(result, isA<UserModel>(),
          reason: 'call() should unwrap ViewModel to return its data');
      expect((result as UserModel).name, equals('guest'));
    });
  });

  group('call() syntax — ReactiveNotifierViewModel<VM, T>', () {
    test('ReactiveNotifierViewModel<VM, T> → call() returns T', () {
      final notifier = ReactiveNotifierViewModel<UserViewModel, UserModel>(
          () => UserViewModel());

      final result = notifier();

      expect(result, isA<UserModel>(),
          reason:
              'call() on ReactiveNotifierViewModel should return T directly');
      expect(result.name, equals('guest'));
      expect(result.age, equals(0));
    });

    test('call() returns current snapshot (not reactive)', () {
      final notifier = ReactiveNotifierViewModel<UserViewModel, UserModel>(
          () => UserViewModel());

      // Take snapshot
      final snapshot1 = notifier();

      // Modify state
      notifier.notifier
          .updateState(const UserModel('Alice', 30));

      // Take another snapshot
      final snapshot2 = notifier();

      expect(snapshot1.name, equals('guest'),
          reason: 'First snapshot should reflect initial state');
      expect(snapshot2.name, equals('Alice'),
          reason: 'Second snapshot should reflect updated state');
    });
  });

  group('call() syntax — ReactiveNotifier<AsyncViewModelImpl<T>>', () {
    test(
        'ReactiveNotifier<AsyncViewModelImpl<T>> → call() returns T? (data)',
        () async {
      final notifier =
          ReactiveNotifier<ItemsViewModel>(() => ItemsViewModel());

      // Before loading, data is null
      final resultBeforeLoad = notifier();
      expect(resultBeforeLoad, isNull,
          reason:
              'call() on unloaded AsyncViewModel should return null (no data yet)');

      // Load data
      await notifier.notifier.reload();

      final resultAfterLoad = notifier();
      expect(resultAfterLoad, isA<List<String>>(),
          reason: 'call() should return T? after data is loaded');
      expect((resultAfterLoad as List<String>).length, equals(2));
    });
  });

  group('call() syntax — snapshot behavior', () {
    test('call() returns current snapshot, not a reactive reference', () {
      final notifier = ReactiveNotifier<int>(() => 10);

      final snapshot = notifier();
      notifier.updateState(20);
      final snapshot2 = notifier();

      expect(snapshot, equals(10),
          reason: 'Snapshot taken before update should be 10');
      expect(snapshot2, equals(20),
          reason: 'Snapshot taken after update should be 20');
    });
  });
}
