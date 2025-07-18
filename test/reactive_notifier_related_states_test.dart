import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

/// Tests for ReactiveNotifier related states and batch updates
/// 
/// This test suite covers advanced ReactiveNotifier features:
/// - Singleton behavior with keys and instance management
/// - Related states system for state coordination
/// - Batch updates and notification batching
/// - Complex scenarios with state chains and dependencies
/// - State access patterns and error handling
/// 
/// These tests verify that ReactiveNotifier can handle sophisticated state
/// coordination patterns including related states, batch operations, and
/// complex update chains essential for enterprise-level state management.
void main() {
  group('ReactiveNotifier Related States and Batch Updates', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('Singleton Behavior and Key Management', () {
      test('should create different instances with different keys', () {
        // Setup: Create ReactiveNotifiers with different keys
        final state1 = ReactiveNotifier(() => 0, key: UniqueKey());
        final state2 = ReactiveNotifier(() => 0, key: UniqueKey());

        // Assert: Different keys should create different instances
        expect(identical(state1, state2), false,
            reason: 'Different keys should create different instances');
        expect(state1.notifier, 0,
            reason: 'First instance should have initial value');
        expect(state2.notifier, 0,
            reason: 'Second instance should have initial value');

        // Act: Update each instance independently
        state1.updateState(10);
        state2.updateState(20);

        // Assert: Instances should maintain independent state
        expect(state1.notifier, 10,
            reason: 'First instance should maintain its own state');
        expect(state2.notifier, 20,
            reason: 'Second instance should maintain its own state');
      });

      test('should handle key-based instance management correctly', () {
        // Setup: Create instances with specific keys
        final key1 = UniqueKey();
        final key2 = UniqueKey();

        final stateA1 = ReactiveNotifier(() => 'A1', key: key1);
        final stateB1 = ReactiveNotifier(() => 'B1', key: key2);

        // Assert: Different keys should create different instances
        expect(identical(stateA1, stateB1), false,
            reason: 'Different keys should create different instances');

        // Test that creating a notifier with duplicate key is prevented
        expect(() => ReactiveNotifier(() => 'A2', key: key1), throwsStateError,
            reason: 'Creating a notifier with duplicate key should throw StateError');

        // Verify original instances still work correctly
        expect(stateA1.notifier, 'A1',
            reason: 'Original instance should maintain its value');
        expect(stateB1.notifier, 'B1',
            reason: 'Original instance should maintain its value');
      });

      test('should handle instance lifecycle with keys correctly', () {
        // Setup: Create instances with keys and track them
        final keyA = UniqueKey();
        final keyB = UniqueKey();

        final instanceA = ReactiveNotifier(() => 100, key: keyA);
        final instanceB = ReactiveNotifier(() => 200, key: keyB);

        var listenerACallCount = 0;
        var listenerBCallCount = 0;

        instanceA.addListener(() => listenerACallCount++);
        instanceB.addListener(() => listenerBCallCount++);

        // Act: Update instances
        instanceA.updateState(150);
        instanceB.updateState(250);

        // Assert: Each instance should notify its own listeners
        expect(listenerACallCount, 1,
            reason: 'Instance A listener should be called once');
        expect(listenerBCallCount, 1,
            reason: 'Instance B listener should be called once');
        expect(instanceA.notifier, 150,
            reason: 'Instance A should have updated value');
        expect(instanceB.notifier, 250,
            reason: 'Instance B should have updated value');
      });
    });

    group('State Update Notifications and Behavior', () {
      test('should notify listeners on value change', () {
        // Setup: Create ReactiveNotifier with listener
        final state = ReactiveNotifier(() => 0);
        int notifications = 0;
        int? lastNotifiedValue;

        state.addListener(() {
          notifications++;
          lastNotifiedValue = state.notifier;
        });

        // Act: Update state with new value
        state.updateState(42);

        // Assert: Listener should be notified with new value
        expect(notifications, 1,
            reason: 'Listener should be called once for value change');
        expect(state.notifier, 42,
            reason: 'State should have updated value');
        expect(lastNotifiedValue, 42,
            reason: 'Listener should receive updated value');
      });

      test('should not notify if value is the same', () {
        // Setup: Create ReactiveNotifier with initial value
        final state = ReactiveNotifier(() => 42);
        int notifications = 0;

        state.addListener(() => notifications++);

        // Act: Update state with same value
        state.updateState(42);

        // Assert: Listener should not be notified for same value
        expect(notifications, 0,
            reason: 'Listener should not be called when value does not change');
        expect(state.notifier, 42,
            reason: 'State value should remain the same');
      });

      test('should handle multiple value changes correctly', () {
        // Setup: Create ReactiveNotifier with change tracking
        final state = ReactiveNotifier(() => 'initial');
        final valueChanges = <String>[];
        var totalNotifications = 0;

        state.addListener(() {
          totalNotifications++;
          valueChanges.add(state.notifier);
        });

        // Act: Perform multiple state changes
        state.updateState('first');
        state.updateState('first');     // Same value - should not notify
        state.updateState('second');
        state.updateState('third');
        state.updateState('third');     // Same value - should not notify

        // Assert: Only actual changes should trigger notifications
        expect(totalNotifications, 3,
            reason: 'Only 3 actual value changes should trigger notifications');
        expect(valueChanges, ['first', 'second', 'third'],
            reason: 'Only distinct values should be recorded');
        expect(state.notifier, 'third',
            reason: 'Final state should be the last distinct value');
      });
    });

    group('Related States System', () {
      test('should access related states through from<T>() correctly', () {
        // Setup: Create related states
        final cartState = ReactiveNotifier(() => CartState(0));
        final totalState = ReactiveNotifier(() => TotalState(0.0));

        final orderState = ReactiveNotifier(
            () => 'order',
            related: [cartState, totalState]
        );

        // Assert: Should be able to access related states
        expect(orderState.from<CartState>().items, 0,
            reason: 'Should access cart state through related states');
        expect(orderState.from<TotalState>().amount, 0.0,
            reason: 'Should access total state through related states');

        // Act: Update related states
        cartState.updateState(CartState(5));
        totalState.updateState(TotalState(99.99));

        // Assert: Related state access should reflect updates
        expect(orderState.from<CartState>().items, 5,
            reason: 'Related cart state should be updated');
        expect(orderState.from<TotalState>().amount, 99.99,
            reason: 'Related total state should be updated');
      });

      test('should throw error when accessing non-existent related state', () {
        // Setup: Create ReactiveNotifier without related states
        final state = ReactiveNotifier(() => 'test');

        // Act & Assert: Should throw error for non-existent related state
        expect(
            () => state.from<CartState>(),
            throwsA(isA<StateError>().having(
                (error) => error.message,
                'message',
                contains('No Related States Found'))),
            reason: 'Should throw StateError when accessing non-existent related state'
        );
      });

      test('should handle complex related state relationships', () {
        // Setup: Create complex related state network
        final userState = ReactiveNotifier(() => UserState('John'));
        final cartState = ReactiveNotifier(() => CartState(0));
        final totalState = ReactiveNotifier(() => TotalState(0.0));
        final discountState = ReactiveNotifier(() => DiscountState(0.0));

        final orderState = ReactiveNotifier(
            () => OrderState('pending'),
            related: [userState, cartState, totalState, discountState]
        );

        // Assert: Should access all related states
        expect(orderState.from<UserState>().name, 'John',
            reason: 'Should access user state');
        expect(orderState.from<CartState>().items, 0,
            reason: 'Should access cart state');
        expect(orderState.from<TotalState>().amount, 0.0,
            reason: 'Should access total state');
        expect(orderState.from<DiscountState>().percentage, 0.0,
            reason: 'Should access discount state');

        // Act: Update multiple related states
        userState.updateState(UserState('Jane'));
        cartState.updateState(CartState(3));
        totalState.updateState(TotalState(150.00));
        discountState.updateState(DiscountState(10.0));

        // Assert: All related state updates should be accessible
        expect(orderState.from<UserState>().name, 'Jane',
            reason: 'User state update should be accessible');
        expect(orderState.from<CartState>().items, 3,
            reason: 'Cart state update should be accessible');
        expect(orderState.from<TotalState>().amount, 150.00,
            reason: 'Total state update should be accessible');
        expect(orderState.from<DiscountState>().percentage, 10.0,
            reason: 'Discount state update should be accessible');
      });

      test('should handle related states with key-based access', () {
        // Setup: Create related states with key-based access
        final stateA = ReactiveNotifier(() => 'A');
        final stateB = ReactiveNotifier(() => 'B');

        final combined = ReactiveNotifier(
            () => 'combined',
            related: [stateA, stateB]
        );

        // Assert: Should access related states by key
        expect(combined.from<String>(stateA.keyNotifier), 'A',
            reason: 'Should access state A by key');
        expect(combined.from<String>(stateB.keyNotifier), 'B',
            reason: 'Should access state B by key');

        // Act: Update related states
        stateA.updateState('A2');
        stateB.updateState('B2');

        // Assert: Key-based access should reflect updates
        expect(combined.from<String>(stateA.keyNotifier), 'A2',
            reason: 'Key-based access should show updated state A');
        expect(combined.from<String>(stateB.keyNotifier), 'B2',
            reason: 'Key-based access should show updated state B');
      });
    });

    group('Batch Updates and Coordination', () {
      test('should handle batch updates with multiple related states', () {
        // Setup: Create batch update scenario
        final cartState = ReactiveNotifier(() => CartState(0));
        final totalState = ReactiveNotifier(() => TotalState(0.0));

        final orderState = ReactiveNotifier(
            () => 'initial',
            related: [cartState, totalState]
        );

        int notifications = 0;
        final notificationOrder = <String>[];

        orderState.addListener(() {
          notifications++;
          notificationOrder.add('order');
        });

        cartState.addListener(() {
          notificationOrder.add('cart');
        });

        totalState.addListener(() {
          notificationOrder.add('total');
        });

        // Act: Perform multiple updates (simulating batch)
        cartState.updateState(CartState(2));
        totalState.updateState(TotalState(100.0));

        // Assert: Related states should be updated and order should notify
        expect(notifications, 2,
            reason: 'Order state should be notified for each related state update');
        expect(orderState.from<CartState>().items, 2,
            reason: 'Cart state should be updated in order state');
        expect(orderState.from<TotalState>().amount, 100.0,
            reason: 'Total state should be updated in order state');
        expect(notificationOrder, ['cart', 'order', 'total', 'order'],
            reason: 'Notifications should happen in correct order');
      });

      test('should coordinate batch updates in correct order', () {
        // Setup: Create coordinated batch update system
        final updates = <String>[];

        final stateA = ReactiveNotifier(() => 'A');
        final stateB = ReactiveNotifier(() => 'B');

        final combined = ReactiveNotifier(
            () => 'combined',
            related: [stateA, stateB]
        );

        // Setup: Track update order
        stateA.addListener(() => updates.add('A'));
        stateB.addListener(() => updates.add('B'));
        combined.addListener(() => updates.add('combined'));

        // Assert: Initial state access should work
        expect(stateA.notifier, 'A',
            reason: 'State A should have initial value');
        expect(combined.from<String>(stateA.keyNotifier), 'A',
            reason: 'Combined should access state A');

        expect(stateB.notifier, 'B',
            reason: 'State B should have initial value');
        expect(combined.from<String>(stateB.keyNotifier), 'B',
            reason: 'Combined should access state B');

        // Act: Perform coordinated updates
        stateA.updateState('A2');
        expect(stateA.notifier, 'A2',
            reason: 'State A should be updated');
        expect(combined.from<String>(stateA.keyNotifier), 'A2',
            reason: 'Combined should access updated state A');

        stateB.updateState('B2');
        expect(stateB.notifier, 'B2',
            reason: 'State B should be updated');
        expect(combined.from<String>(stateB.keyNotifier), 'B2',
            reason: 'Combined should access updated state B');

        // Assert: Updates should happen in correct order
        expect(updates.length, 4,
            reason: 'Should have 4 updates total');
        expect(updates.last, 'combined',
            reason: 'Combined state should be notified last');
      });

      test('should handle large batch operations efficiently', () {
        // Setup: Create large batch operation scenario
        final batchStates = List.generate(
            10,
            (index) => ReactiveNotifier(() => 'state_$index')
        );

        final aggregatorState = ReactiveNotifier(
            () => 'aggregated',
            related: batchStates
        );

        var totalNotifications = 0;
        final notificationTimes = <DateTime>[];

        aggregatorState.addListener(() {
          totalNotifications++;
          notificationTimes.add(DateTime.now());
        });

        // Act: Perform batch updates
        final startTime = DateTime.now();
        for (int i = 0; i < batchStates.length; i++) {
          batchStates[i].updateState('updated_$i');
        }
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Assert: Batch operations should be efficient
        expect(totalNotifications, batchStates.length,
            reason: 'Aggregator should be notified for each batch update');
        expect(duration.inMilliseconds, lessThan(100),
            reason: 'Batch operations should complete quickly');

        // Verify all states are accessible through aggregator
        for (int i = 0; i < batchStates.length; i++) {
          expect(aggregatorState.from<String>(batchStates[i].keyNotifier), 'updated_$i',
              reason: 'Batch state $i should be accessible through aggregator');
        }
      });
    });

    group('Complex State Chain Scenarios', () {
      test('should handle complex update chain correctly', () {
        // Setup: Create complex state dependency chain
        final updates = <String>[];

        // Create a chain of dependent states
        final userState = ReactiveNotifier(() => UserState('John'));
        final cartState = ReactiveNotifier(
            () => CartState(0),
            related: [userState]
        );
        final totalState = ReactiveNotifier(
            () => TotalState(0.0),
            related: [userState]
        );

        // Setup: Track update chain
        userState.addListener(() => updates.add('user'));
        cartState.addListener(() => updates.add('cart'));
        totalState.addListener(() => updates.add('total'));

        // Act: Trigger update chain
        userState.updateState(UserState('Jane'));

        // Assert: Update chain should propagate correctly
        expect(updates.length, 3,
            reason: 'Should have 3 updates in the chain');
        expect(updates, containsAllInOrder(['user', 'cart', 'total']),
            reason: 'Updates should happen in dependency order');

        // Verify state access through related states
        expect(cartState.from<UserState>().name, 'Jane',
            reason: 'Cart should access updated user state');
        expect(totalState.from<UserState>().name, 'Jane',
            reason: 'Total should access updated user state');
      });

      test('should handle cascading updates with complex business logic', () {
        // Setup: Create business logic scenario with independent states
        final productState = ReactiveNotifier(() => ProductState('Widget', 10.0));
        final quantityState = ReactiveNotifier(() => QuantityState(1));
        final discountState = ReactiveNotifier(() => DiscountState(0.0));

        // Create calculation state that depends on product, quantity, and discount
        final calculationState = ReactiveNotifier(
            () => CalculationState(10.0, 0.0, 10.0),
            related: [productState, quantityState, discountState]
        );

        // Create order summary state independently (no related states to avoid circular reference)
        final orderSummaryState = ReactiveNotifier(
            () => OrderSummaryState('Order Summary')
        );

        var calculationUpdates = 0;
        var summaryUpdates = 0;

        // Setup: Business logic for calculations
        void updateCalculations() {
          calculationUpdates++;
          final product = calculationState.from<ProductState>();
          final quantity = calculationState.from<QuantityState>();
          final discount = calculationState.from<DiscountState>();

          final subtotal = product.price * quantity.amount;
          final discountAmount = subtotal * (discount.percentage / 100);
          final total = subtotal - discountAmount;

          calculationState.updateState(CalculationState(subtotal, discountAmount, total));
        }

        productState.addListener(updateCalculations);
        quantityState.addListener(updateCalculations);
        discountState.addListener(updateCalculations);

        // Setup: Summary updates based on calculations
        calculationState.addListener(() {
          summaryUpdates++;
          final calc = calculationState.notifier;
          orderSummaryState.updateState(OrderSummaryState(
              'Total: \$${calc.total.toStringAsFixed(2)} '
              '(Subtotal: \$${calc.subtotal.toStringAsFixed(2)}, '
              'Discount: \$${calc.discountAmount.toStringAsFixed(2)})'
          ));
        });

        // Act: Perform business logic updates
        quantityState.updateState(QuantityState(3));        // 3 widgets
        discountState.updateState(DiscountState(15.0));     // 15% discount

        // Assert: Business logic should cascade correctly
        final finalCalc = calculationState.notifier;
        expect(finalCalc.subtotal, 30.0,
            reason: 'Subtotal should be 3 * 10.0 = 30.0');
        expect(finalCalc.discountAmount, 4.5,
            reason: 'Discount should be 30.0 * 0.15 = 4.5');
        expect(finalCalc.total, 25.5,
            reason: 'Total should be 30.0 - 4.5 = 25.5');

        // Assert: Order summary should be updated with correct calculation
        final finalSummary = orderSummaryState.notifier;
        expect(finalSummary.summary, contains('Total: \$25.50'),
            reason: 'Order summary should reflect final calculation');

        expect(calculationUpdates, 2,
            reason: 'Calculations should update twice (quantity + discount)');
        expect(summaryUpdates, greaterThan(0),
            reason: 'Summary should update based on calculations');
      });
    });
  });
}

// Test model classes for related states testing
class CartState {
  final int items;
  CartState(this.items);
}

class TotalState {
  final double amount;
  TotalState(this.amount);
}

class UserState {
  final String name;
  UserState(this.name);
}

class DiscountState {
  final double percentage;
  DiscountState(this.percentage);
}

class OrderState {
  final String status;
  OrderState(this.status);
}

class ProductState {
  final String name;
  final double price;
  ProductState(this.name, this.price);
}

class QuantityState {
  final int amount;
  QuantityState(this.amount);
}

class CalculationState {
  final double subtotal;
  final double discountAmount;
  final double total;
  CalculationState(this.subtotal, this.discountAmount, this.total);
}

class OrderSummaryState {
  final String summary;
  OrderSummaryState(this.summary);
}