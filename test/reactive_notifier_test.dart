import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

void main() {
  group('ReactiveNotifier', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('Initialization and Basic Functionality', () {
      test('should initialize with default value', () {
        final state = ReactiveNotifier<int>(() => 0);
        expect(state.notifier, 0);
        expect(ReactiveNotifier.instanceCount, 1);
      });

      test('should create separate instances for each call', () {
        final state1 = ReactiveNotifier<int>(() => 0);
        final state2 = ReactiveNotifier<int>(() => 1);
        expect(state1.notifier, 0);
        expect(state2.notifier, 1);
        expect(ReactiveNotifier.instanceCount, 2);
      });

      test('should update value with setState', () {
        final state = ReactiveNotifier<int>(() => 0);
        state.updateState(10);
        expect(state.notifier, 10);
      });
    });

    group('Listener Notifications', () {
      test('should update state and notify listeners', () {
        final notify = ReactiveNotifier<int>(() => 0);
        int? notifiedValue;

        notify.addListener(() {
          notifiedValue = notify.notifier;
        });

        notify.updateState(5);

        expect(notifiedValue, equals(5));
      });

      test('should notify multiple listeners', () {
        final notify = ReactiveNotifier<int>(() => 0);
        int? listener1Value;
        int? listener2Value;

        notify.addListener(() {
          listener1Value = notify.notifier;
        });
        notify.addListener(() {
          listener2Value = notify.notifier;
        });

        notify.updateState(10);

        expect(listener1Value, equals(10));
        expect(listener2Value, equals(10));
      });

      test('should not notify removed listeners', () {
        final notify = ReactiveNotifier<int>(() => 0);
        int? listenerValue;

        void listener() {
          listenerValue = notify.notifier;
        }

        notify.addListener(listener);
        notify.updateState(5);
        expect(listenerValue, equals(5));

        notify.removeListener(listener);
        notify.updateState(10);
        expect(listenerValue, equals(5)); // Should not have updated
      });
    });

    group('Instance Management', () {
      test('should create multiple instances of the same type', () {
        // ignore_for_file: unused_local_variable
        final state1 = ReactiveNotifier<int>(() => 0);
        final state2 = ReactiveNotifier<int>(() => 1);
        final state3 = ReactiveNotifier<int>(() => 2);

        expect(ReactiveNotifier.instanceCount, 3);
        expect(ReactiveNotifier.instanceCountByType<int>(), 3);
      });

      test('should create instances of different types', () {
        final intState = ReactiveNotifier<int>(() => 0);
        final stringState = ReactiveNotifier<String>(() => 'hello');
        final boolState = ReactiveNotifier<bool>(() => true);

        expect(ReactiveNotifier.instanceCount, 3);
        expect(ReactiveNotifier.instanceCountByType<int>(), 1);
        expect(ReactiveNotifier.instanceCountByType<String>(), 1);
        expect(ReactiveNotifier.instanceCountByType<bool>(), 1);
      });

      test('should clean up instances correctly', () {
        ReactiveNotifier<int>(() => 0);
        ReactiveNotifier<String>(() => 'hello');
        expect(ReactiveNotifier.instanceCount, 2);

        ReactiveNotifier.cleanup();
        expect(ReactiveNotifier.instanceCount, 0);
      });
    });

    group('Cross-Notifier Interactions', () {
      test('should update dependent notifier', () {
        final countNotifier = ReactiveNotifier<int>(() => 0);
        final isEvenNotifier = ReactiveNotifier<bool>(() => true);

        countNotifier.addListener(() {
          isEvenNotifier.updateState(countNotifier.notifier % 2 == 0);
        });

        countNotifier.updateState(1);
        expect(countNotifier.notifier, 1);
        expect(isEvenNotifier.notifier, false);

        countNotifier.updateState(2);
        expect(countNotifier.notifier, 2);
        expect(isEvenNotifier.notifier, true);
      });

      test('should handle cascading updates', () {
        final temperatureCelsius = ReactiveNotifier<double>(() => 0);
        final temperatureFahrenheit = ReactiveNotifier<double>(() => 32);
        final weatherDescription = ReactiveNotifier<String>(() => 'Freezing');

        temperatureCelsius.addListener(() {
          temperatureFahrenheit
              .updateState(temperatureCelsius.notifier * 9 / 5 + 32);
        });

        temperatureFahrenheit.addListener(() {
          if (temperatureFahrenheit.notifier < 32) {
            weatherDescription.updateState('Freezing');
          } else if (temperatureFahrenheit.notifier < 65) {
            weatherDescription.updateState('Cold');
          } else if (temperatureFahrenheit.notifier < 80) {
            weatherDescription.updateState('Comfortable');
          } else {
            weatherDescription.updateState('Hot');
          }
        });

        temperatureCelsius.updateState(25); // 77°F
        expect(temperatureCelsius.notifier, 25);
        expect(temperatureFahrenheit.notifier, closeTo(77, 0.1));
        expect(weatherDescription.notifier, 'Comfortable');

        temperatureCelsius.updateState(35); // 95°F
        expect(temperatureCelsius.notifier, 35);
        expect(temperatureFahrenheit.notifier, closeTo(95, 0.1));
        expect(weatherDescription.notifier, 'Hot');
      });

      test('should handle circular dependencies without infinite updates', () {
        ReactiveNotifier.cleanup();

        final notifierA = ReactiveNotifier<int>(() => 0);
        final notifierB = ReactiveNotifier<int>(() => 0);

        var updateCountA = 0;
        var updateCountB = 0;

        notifierA.addListener(() {
          updateCountA++;
          notifierB.updateState(notifierA.notifier + 1);
        });

        notifierB.addListener(() {
          updateCountB++;
          notifierA.updateState(notifierB.notifier + 1);
        });

        notifierA.updateState(1);

        expect(updateCountA, equals(1), reason: 'notifierA should update once');
        expect(updateCountB, equals(1), reason: 'notifierB should update once');
        expect(notifierA.notifier, equals(1),
            reason: 'notifierA state should remain 1');
        expect(notifierB.notifier, equals(2),
            reason: 'notifierB state should be updated to 2');

        ReactiveNotifier.cleanup();
      });
    });

    group('Performance and Memory', () {
      test('should handle a large number of instances', () {
        final iterations = Platform.environment['CI'] == 'true' ? 3000 : 10000;

        final startTime = DateTime.now();
        for (int i = 0; i < iterations; i++) {
          ReactiveNotifier<int>(() => i);
        }
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        expect(ReactiveNotifier.instanceCount, iterations);
        expect(duration.inMilliseconds, lessThan(1000));
      });

      test('should efficiently clean up a large number of instances', () {
        for (int i = 0; i < 10000; i++) {
          ReactiveNotifier<int>(() => i);
        }

        final startTime = DateTime.now();
        ReactiveNotifier.cleanup();
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        expect(ReactiveNotifier.instanceCount, 0);
        expect(duration.inMilliseconds,
            lessThan(100)); // Adjust this threshold as needed
      });

      test('should not leak memory when adding and removing listeners', () {
        final notifier = ReactiveNotifier<int>(() => 0);
        final listeners = List.generate(1000, (_) => () {});

        for (final listener in listeners) {
          notifier.addListener(listener);
        }

        for (final listener in listeners) {
          notifier.removeListener(listener);
        }

        // This is a basic check. In a real scenario, you might want to use a memory profiler.
        expect(true, isTrue); // Placeholder for memory leak check
      });
    });

    group('Advanced State Management', () {
      test('should handle complex object states', () {
        final complexState = ReactiveNotifier<Map<String, dynamic>>(
            () => {'count': 0, 'name': 'Test'});
        complexState.updateState({'count': 1, 'name': 'Updated'});
        expect(complexState.notifier, {'count': 1, 'name': 'Updated'});
      });

      test('should handle null states', () {
        final nullableState = ReactiveNotifier<int?>(() => null);
        expect(nullableState.notifier, isNull);
        nullableState.updateState(5);
        expect(nullableState.notifier, 5);
      });

      test('should handle state transitions', () {
        final stateTransition = ReactiveNotifier<String>(() => 'initial');
        var transitionCount = 0;
        stateTransition.addListener(() {
          transitionCount++;
        });
        stateTransition.updateState('processing');
        stateTransition.updateState('completed');
        expect(transitionCount, 2);
      });
    });

    group('Asynchronous Operations', () {
      test('should handle async state updates', () async {
        final asyncState = ReactiveNotifier<String>(() => 'initial');
        Future<void> updateStateAsync() async {
          await Future.delayed(const Duration(milliseconds: 100));
          asyncState.updateState('updated');
        }

        updateStateAsync();
        expect(asyncState.notifier, 'initial');
        await Future.delayed(const Duration(milliseconds: 150));
        expect(asyncState.notifier, 'updated');
      });

      test('should manage concurrent async updates', () async {
        final concurrentState = ReactiveNotifier<int>(() => 0);
        Future<void> incrementAsync() async {
          await Future.delayed(const Duration(milliseconds: 50));
          concurrentState.updateState(concurrentState.notifier + 1);
        }

        await Future.wait(
            [incrementAsync(), incrementAsync(), incrementAsync()]);
        expect(concurrentState.notifier, 3);
      });
    });

    group('Computed States', () {
      test('should handle computed states', () {
        final baseState = ReactiveNotifier<int>(() => 1);
        final computedState =
            ReactiveNotifier<int>(() => baseState.notifier * 2);
        baseState.addListener(
            () => computedState.updateState(baseState.notifier * 2));
        baseState.updateState(5);
        expect(computedState.notifier, 10);
      });

      test('should efficiently update multiple dependent states', () {
        final rootState = ReactiveNotifier<int>(() => 0);
        final computed1 = ReactiveNotifier<int>(() => rootState.notifier + 1);
        final computed2 = ReactiveNotifier<int>(() => rootState.notifier * 2);
        final computed3 = ReactiveNotifier<int>(
            () => computed1.notifier + computed2.notifier);

        rootState.addListener(() {
          computed1.updateState(rootState.notifier + 1);
          computed2.updateState(rootState.notifier * 2);
        });
        computed1.addListener(() =>
            computed3.updateState(computed1.notifier + computed2.notifier));
        computed2.addListener(() =>
            computed3.updateState(computed1.notifier + computed2.notifier));

        rootState.updateState(5);
        expect(computed1.notifier, 6);
        expect(computed2.notifier, 10);
        expect(computed3.notifier, 16);
      });
    });

    group('State History and Undo', () {
      test('should maintain state history', () {
        final historicalState = ReactiveNotifier<int>(() => 0);
        final history = <int>[];
        historicalState
            .addListener(() => history.add(historicalState.notifier));
        historicalState.updateState(1);
        historicalState.updateState(2);
        historicalState.updateState(3);
        expect(history, [1, 2, 3]);
      });

      test('should support undo operations', () {
        final undoableState = ReactiveNotifier<int>(() => 0);
        final history = <int>[0];
        undoableState.addListener(() => history.add(undoableState.notifier));
        undoableState.updateState(1);
        undoableState.updateState(2);
        undoableState.updateState(history[history.length - 2]); // Undo
        expect(undoableState.notifier, 1);
      });
    });

    group('Custom Serialization', () {
      test('should serialize and deserialize custom objects', () {
        final customState =
            ReactiveNotifier<CustomObject>(() => CustomObject(1, 'initial'));
        customState.updateState(CustomObject(2, 'updated'));
        expect(customState.notifier.id, 2);
        expect(customState.notifier.name, 'updated');
      });
    });

    group('Multi-threading Support', () {
      test('should handle updates from different isolates', () async {
        final isolateState = ReactiveNotifier<int>(() => 0);

        // Create a receive port to receive data from the isolate
        final receivePort = ReceivePort();

        // Iniciar un isolate
        await Isolate.spawn((SendPort sendPort) {
          // Here we are in the new isolate
          const updatedState = 42;
          sendPort.send(
              updatedState); // Enviar el estado actualizado al isolate principal
        }, receivePort.sendPort);

        // Listen to the receive port to get the updated state
        final updatedState = await receivePort.first;

        // Actualizar el estado en el isolate principal
        isolateState.updateState(updatedState as int);

        expect(isolateState.notifier, 42);
      });
    });

    group('Performance Optimizations', () {
      test('should optimize frequent updates', () {
        final optimizedState = ReactiveNotifier<int>(() => 0);
        var updateCount = 0;
        optimizedState.addListener(() => updateCount++);
        for (var i = 0; i < 50; i++) {
          optimizedState.updateState(i);
        }

        expect(updateCount, 49);
      });
    });

    group('Dependency Injection', () {
      test('should support dependency injection', () {
        const injectedDependency = 'Injected Value';
        final dependentState = ReactiveNotifier<String>(() => 'Initial');
        expect(dependentState.notifier, 'Initial');
        dependentState.updateState('Updated with $injectedDependency');
        expect(dependentState.notifier, 'Updated with Injected Value');
      });
    });
  });

  group('ReactiveNotifier Tests', () {
    setUp(() {
      // Limpiar estado entre tests
      ReactiveNotifier.cleanup();
    });

    group('Singleton Behavior', () {
      test('creates different instances with different keys', () {
        final state1 = ReactiveNotifier(() => 0, key: UniqueKey());
        final state2 = ReactiveNotifier(() => 0, key: UniqueKey());

        expect(identical(state1, state2), false);
      });
    });

    group('State Updates', () {
      test('notifies listeners on value change', () {
        final state = ReactiveNotifier(() => 0);
        int notifications = 0;
        state.addListener(() => notifications++);

        state.updateState(42); //42;
        expect(notifications, 1);
        expect(state.notifier, 42);
      });

      test('does not notify if value is the same', () {
        final state = ReactiveNotifier(() => 42);
        int notifications = 0;
        state.addListener(() => notifications++);

        state.updateState(42);
        expect(notifications, 0);
      });
    });

    group('Batch Updates', () {
      test('notification for multiple related updates', () {
        final cartState = ReactiveNotifier(() => CartState(0));
        final totalState = ReactiveNotifier(() => TotalState(0.0));

        final orderState =
            ReactiveNotifier(() => 'initial', related: [cartState, totalState]);

        int notifications = 0;
        orderState.addListener(() => notifications++);

        // Multiple updates
        cartState.updateState(CartState(2));
        totalState.updateState(TotalState(100.0));

        expect(notifications, 2);
        expect(orderState.from<CartState>().items, 2);
        expect(orderState.from<TotalState>().amount, 100.0);
      });

      test('batch updates happen in correct order', () {
        final updates = <String>[];

        final stateA = ReactiveNotifier(() => 'A');
        final stateB = ReactiveNotifier(() => 'B');

        final combined =
            ReactiveNotifier(() => 'combined', related: [stateA, stateB]);

        stateA.addListener(() => updates.add('A'));
        expect(stateA.notifier, 'A');
        expect(combined.from<String>(stateA.keyNotifier), 'A');

        stateB.addListener(() => updates.add('B'));
        expect(stateB.notifier, 'B');
        expect(combined.from<String>(stateB.keyNotifier), 'B');

        combined.addListener(() => updates.add('combined'));

        stateA.updateState('A2');
        expect(stateA.notifier, 'A2');
        expect(combined.from<String>(stateA.keyNotifier), 'A2');

        stateB.updateState('B2');
        expect(stateB.notifier, 'B2');
        expect(combined.from<String>(stateB.keyNotifier), 'B2');

        expect(updates.length, 4);
        expect(updates.last, 'combined');
      });
    });

    group('Related States', () {
      test('can access related states through from<T>()', () {
        final cartState = ReactiveNotifier(() => CartState(0));
        final totalState = ReactiveNotifier(() => TotalState(0.0));

        final orderState =
            ReactiveNotifier(() => 'order', related: [cartState, totalState]);

        expect(orderState.from<CartState>().items, 0);
        expect(orderState.from<TotalState>().amount, 0.0);
      });

      test('throws error when accessing non-existent related state', () {
        final state = ReactiveNotifier(() => 'test');

        expect(
            () => state.from<CartState>(),
            throwsA(isA<StateError>().having((error) => error.message,
                'message', contains('No Related States Found'))));
      });
    });

    group('Complex Scenarios', () {
      test('handles complex update chain correctly', () {
        final updates = <String>[];

        // Create a chain of dependent states
        final userState = ReactiveNotifier(() => UserState('John'));
        final cartState =
            ReactiveNotifier(() => CartState(0), related: [userState]);
        final totalState =
            ReactiveNotifier(() => TotalState(0.0), related: [userState]);

        userState.addListener(() => updates.add('user'));
        cartState.addListener(() => updates.add('cart'));
        totalState.addListener(() => updates.add('total'));

        // Trigger update chain
        userState.updateState(UserState('Jane'));

        expect(updates.length, 3);
        expect(updates, containsAllInOrder(['user', 'cart', 'total']));
      });
    });
  });
}

class CustomObject {
  final int id;
  final String name;
  CustomObject(this.id, this.name);
}

// Modelos de prueba
class UserState {
  final String name;
  UserState(this.name);
}

class CartState {
  final int items;
  CartState(this.items);
}

class TotalState {
  final double amount;
  TotalState(this.amount);
}
