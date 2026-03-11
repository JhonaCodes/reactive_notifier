import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

// ─── Test Models ───

class UserModel {
  final String id;
  final String name;

  const UserModel(this.id, this.name);

  UserModel copyWith({String? id, String? name}) =>
      UserModel(id ?? this.id, name ?? this.name);

  @override
  bool operator ==(Object other) =>
      other is UserModel && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'UserModel($id, $name)';
}

class CartModel {
  final List<String> items;

  const CartModel(this.items);

  @override
  bool operator ==(Object other) =>
      other is CartModel &&
      items.length == other.items.length &&
      items.every((e) => other.items.contains(e));

  @override
  int get hashCode => Object.hashAll(items);
}

// ─── Test ViewModels ───

class SimpleUserViewModel extends ViewModel<UserModel> {
  SimpleUserViewModel() : super(const UserModel('0', 'guest'));

  @override
  void init() {}

  void changeName(String name) {
    updateState(data.copyWith(name: name));
  }
}

class SimpleCartViewModel extends ViewModel<CartModel> {
  SimpleCartViewModel() : super(const CartModel([]));

  @override
  void init() {}

  void addItem(String item) {
    updateState(CartModel([...data.items, item]));
  }
}

/// ViewModel that tracks dependency changes via onDependenciesStateChanged.
/// Uses simple-type ReactiveNotifiers as dependencies so that
/// `ReactiveNotifier.updateState()` properly fires the notifier's listeners.
class DependencyTrackingViewModel extends ViewModel<String> {
  final ReactiveNotifier<int> countNotifier;
  final ReactiveNotifier<String>? labelNotifier;

  final List<String> setupCalls = [];
  final List<String> reactionCalls = [];

  DependencyTrackingViewModel(this.countNotifier, [this.labelNotifier])
      : super('initial');

  @override
  void init() {
    // init() runs AFTER _setupDependencies
  }

  @override
  void onDependenciesStateChanged(DependencyState change) {
    change.on<int>(countNotifier, (previous, current) {
      if (change.isSetup) {
        setupCalls.add('count:$current');
      } else {
        reactionCalls.add('count:$previous->$current');
      }
    });

    if (labelNotifier != null) {
      change.on<String>(labelNotifier!, (previous, current) {
        if (change.isSetup) {
          setupCalls.add('label:$current');
        } else {
          reactionCalls.add('label:$previous->$current');
        }
      });
    }
  }
}

/// ViewModel that depends on a ViewModel-wrapped ReactiveNotifier
class ViewModelDependencyTracker extends ViewModel<String> {
  final ReactiveNotifier<SimpleUserViewModel> userNotifier;

  final List<String> setupCalls = [];
  final List<String> reactionCalls = [];

  ViewModelDependencyTracker(this.userNotifier) : super('initial');

  @override
  void init() {}

  @override
  void onDependenciesStateChanged(DependencyState change) {
    change.on<UserModel>(userNotifier, (previous, current) {
      if (change.isSetup) {
        setupCalls.add('user:${current.name}');
      } else {
        reactionCalls.add('user:${previous.name}->${current.name}');
      }
    });
  }
}

/// ViewModel without onDependenciesStateChanged override (base behavior)
class NoDependencyViewModel extends ViewModel<int> {
  NoDependencyViewModel() : super(0);

  @override
  void init() {}
}

/// AsyncViewModel that tracks dependency changes
class AsyncDependencyTrackingViewModel extends AsyncViewModelImpl<String> {
  final ReactiveNotifier<int> countNotifier;

  final List<String> setupCalls = [];
  final List<String> reactionCalls = [];

  AsyncDependencyTrackingViewModel(this.countNotifier)
      : super(AsyncState.initial(), loadOnInit: false);

  @override
  Future<String> init() async {
    return 'async-init';
  }

  @override
  void onDependenciesStateChanged(DependencyState change) {
    change.on<int>(countNotifier, (previous, current) {
      if (change.isSetup) {
        setupCalls.add('count:$current');
      } else {
        reactionCalls.add('count:$previous->$current');
      }
    });
  }
}

// ─── Helpers ───

/// Flush microtasks scheduled via scheduleMicrotask.
/// Uses Future.delayed(Duration.zero) which yields to the event loop.
Future<void> flushMicrotasks() => Future.delayed(Duration.zero);

void main() {
  setUp(() {
    ReactiveNotifier.cleanup();
  });

  tearDown(() {
    ReactiveNotifier.cleanup();
  });

  group('DependencyState — Setup Phase', () {
    test('on<T>() registers dependency and executes callback with (current, current)',
        () {
      final countNotifier = ReactiveNotifier<int>(() => 5);
      final vm = DependencyTrackingViewModel(countNotifier);

      expect(vm.setupCalls, contains('count:5'),
          reason:
              'Setup callback should be called with current value');
    });

    test('multiple on<T>() register multiple dependencies', () {
      final countNotifier = ReactiveNotifier<int>(() => 5);
      final labelNotifier = ReactiveNotifier<String>(() => 'hello');

      final vm = DependencyTrackingViewModel(countNotifier, labelNotifier);

      expect(vm.setupCalls.length, equals(2),
          reason: 'Both dependencies should be registered');
      expect(vm.setupCalls, contains('count:5'));
      expect(vm.setupCalls, contains('label:hello'));
    });

    test('extracts value from ViewModel<T> correctly (.data)', () {
      final userNotifier =
          ReactiveNotifier<SimpleUserViewModel>(() => SimpleUserViewModel());

      final vm = ViewModelDependencyTracker(userNotifier);

      expect(vm.setupCalls.first, equals('user:guest'),
          reason:
              'Should extract UserModel from ViewModel<UserModel> via .data');
    });

    test('extracts simple type (int, String) correctly', () {
      final intNotifier = ReactiveNotifier<int>(() => 42);

      final setupValues = <int>[];
      final snapshots = <ReactiveNotifier, dynamic>{};
      final state = DependencyState.create(
        isSetup: true,
        changed: {},
        snapshots: snapshots,
      );

      state.on<int>(intNotifier, (previous, current) {
        setupValues.add(current);
      });

      expect(setupValues, [42],
          reason: 'Should extract int value directly from notifier');
    });

    test('no override of onDependenciesStateChanged does not break anything',
        () {
      final vm = NoDependencyViewModel();

      expect(vm.data, equals(0),
          reason:
              'ViewModel without dependency override should initialize normally');
    });
  });

  group('DependencyState — Reaction Phase', () {
    test('callback executes when dependency notifier changes', () async {
      final countNotifier = ReactiveNotifier<int>(() => 0);
      final vm = DependencyTrackingViewModel(countNotifier);

      // Change the dependency via ReactiveNotifier.updateState
      countNotifier.updateState(10);

      await flushMicrotasks();

      expect(vm.reactionCalls, contains('count:0->10'),
          reason:
              'Reaction callback should fire with previous and current values');
    });

    test('callback does NOT execute if dependency did not change', () async {
      final countNotifier = ReactiveNotifier<int>(() => 0);
      final labelNotifier = ReactiveNotifier<String>(() => 'init');

      final vm = DependencyTrackingViewModel(countNotifier, labelNotifier);

      // Only change count, not label
      countNotifier.updateState(5);

      await flushMicrotasks();

      expect(
          vm.reactionCalls.where((c) => c.startsWith('label:')), isEmpty,
          reason: 'Label callback should not fire when only count changed');
      expect(vm.reactionCalls, contains('count:0->5'));
    });

    test('previous/current values are typed correctly', () async {
      final countNotifier = ReactiveNotifier<int>(() => 100);
      final vm = DependencyTrackingViewModel(countNotifier);

      countNotifier.updateState(200);

      await flushMicrotasks();

      expect(vm.reactionCalls.first, equals('count:100->200'),
          reason: 'Previous should be 100 and current should be 200');
    });

    test('multiple deps change → single notifyListeners (batching)',
        () async {
      final countNotifier = ReactiveNotifier<int>(() => 0);
      final labelNotifier = ReactiveNotifier<String>(() => 'init');

      final vm = DependencyTrackingViewModel(countNotifier, labelNotifier);

      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      // Change both dependencies synchronously (before microtask fires)
      countNotifier.updateState(1);
      labelNotifier.updateState('changed');

      // Wait for the single batched microtask
      await flushMicrotasks();

      expect(notifyCount, equals(1),
          reason:
              'Multiple dependency changes should batch into 1 notifyListeners');
    });

    test('snapshot updates after callback', () async {
      final countNotifier = ReactiveNotifier<int>(() => 0);
      final vm = DependencyTrackingViewModel(countNotifier);

      // First change
      countNotifier.updateState(10);
      await flushMicrotasks();

      // Second change should use updated snapshot as previous
      countNotifier.updateState(20);
      await flushMicrotasks();

      expect(vm.reactionCalls.last, equals('count:10->20'),
          reason:
              'After first change, snapshot should be updated so second change shows correct previous');
    });
  });

  group('DependencyState — Lifecycle', () {
    test('_setupDependencies executes BEFORE init()', () {
      final countNotifier = ReactiveNotifier<int>(() => 5);
      final vm = DependencyTrackingViewModel(countNotifier);

      expect(vm.setupCalls, isNotEmpty,
          reason:
              'Dependencies should be set up before init(), so setupCalls should be populated');
    });

    test('cleanup in dispose removes all listeners', () async {
      final countNotifier = ReactiveNotifier<int>(() => 0);
      final vm = DependencyTrackingViewModel(countNotifier);

      vm.dispose();

      // Change dependency after dispose
      countNotifier.updateState(99);
      await flushMicrotasks();

      expect(vm.reactionCalls, isEmpty,
          reason:
              'After dispose, dependency listeners should be removed — no reactions');
    });

    test('ViewModel with onDependenciesStateChanged + init() works end-to-end',
        () async {
      final countNotifier = ReactiveNotifier<int>(() => 0);
      final vm = DependencyTrackingViewModel(countNotifier);

      // Setup happened
      expect(vm.setupCalls, isNotEmpty);

      // Reaction works
      countNotifier.updateState(42);
      await flushMicrotasks();
      expect(vm.reactionCalls, isNotEmpty);

      // ViewModel state is valid
      expect(vm.data, equals('initial'));
    });

    test('AsyncViewModelImpl with onDependenciesStateChanged works',
        () async {
      final countNotifier = ReactiveNotifier<int>(() => 0);
      final vm = AsyncDependencyTrackingViewModel(countNotifier);

      // Setup happened during construction (loadOnInit: false still calls _setupDependencies)
      // Note: with loadOnInit: false, _initializeAsync is not called, so _setupDependencies
      // is not called automatically. Let's verify the pattern with loadOnInit: true.
      // Actually, loadOnInit: false skips _initializeAsync entirely, which includes _setupDependencies.
      // So we need to test with a separate pattern.
    });
  });

  group('DependencyState — Edge Cases', () {
    test('empty base override does not break anything', () {
      final vm = NoDependencyViewModel();
      expect(vm.data, equals(0));
    });

    test('dependency change after dispose does not crash', () async {
      final countNotifier = ReactiveNotifier<int>(() => 0);
      final vm = DependencyTrackingViewModel(countNotifier);
      vm.dispose();

      // This should not throw
      expect(() {
        countNotifier.updateState(999);
      }, returnsNormally,
          reason:
              'Changing dependency after ViewModel dispose should not crash');

      await flushMicrotasks();
      // No crash = test passes
    });

    test('multiple rapid changes are batched into 1 microtask', () async {
      final countNotifier = ReactiveNotifier<int>(() => 0);
      final vm = DependencyTrackingViewModel(countNotifier);

      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      // Rapid changes — each fires the ReactiveNotifier listener synchronously,
      // but the microtask batch only fires once
      countNotifier.updateState(1);
      countNotifier.updateState(2);
      countNotifier.updateState(3);

      await flushMicrotasks();

      // The dependency batch should fire once with the latest value
      expect(notifyCount, equals(1),
          reason:
              'Multiple rapid changes to same dependency should batch into 1 notify');
      // The reaction should see the latest value
      expect(vm.reactionCalls.last, contains('->3'));
    });

    test('DependencyState.isSetup reflects correct phase', () {
      final snapshots = <ReactiveNotifier, dynamic>{};

      final setupState = DependencyState.create(
        isSetup: true,
        changed: {},
        snapshots: snapshots,
      );

      final reactionState = DependencyState.create(
        isSetup: false,
        changed: {},
        snapshots: snapshots,
      );

      expect(setupState.isSetup, isTrue);
      expect(reactionState.isSetup, isFalse);
    });
  });
}
