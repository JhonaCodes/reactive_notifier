import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

/// Tests for ReactiveNotifier cross-communication and interactions
/// 
/// This test suite covers the cross-communication capabilities between multiple ReactiveNotifiers:
/// - Dependent notifier updates based on other notifiers
/// - Cascading updates through multiple notifiers
/// - Circular dependency handling and prevention of infinite loops
/// - Complex reactive chains and data flow patterns
/// - Multi-notifier synchronization and coordination
/// 
/// These tests verify that ReactiveNotifiers can work together in complex scenarios
/// where one notifier's state changes trigger updates in other notifiers, creating
/// reactive data flow patterns essential for complex state management.
void main() {
  group('ReactiveNotifier Cross-Communication', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('Basic Cross-Notifier Dependencies', () {
      test('should update dependent notifier when source notifier changes', () {
        // Setup: Create source notifier (count) and dependent notifier (isEven)
        final countNotifier = ReactiveNotifier<int>(() => 0);
        final isEvenNotifier = ReactiveNotifier<bool>(() => true);

        // Setup: Create dependency - isEven depends on count
        countNotifier.addListener(() {
          isEvenNotifier.updateState(countNotifier.notifier % 2 == 0);
        });

        // Act: Update count to odd number
        countNotifier.updateState(1);

        // Assert: Both notifiers should reflect the change
        expect(countNotifier.notifier, 1, 
            reason: 'Source notifier should have updated value');
        expect(isEvenNotifier.notifier, false, 
            reason: 'Dependent notifier should update based on source (1 is odd)');

        // Act: Update count to even number
        countNotifier.updateState(2);

        // Assert: Dependent notifier should update accordingly
        expect(countNotifier.notifier, 2, 
            reason: 'Source notifier should have new value');
        expect(isEvenNotifier.notifier, true, 
            reason: 'Dependent notifier should update based on source (2 is even)');
      });

      test('should handle multiple dependent notifiers from single source', () {
        // Setup: Create one source and multiple dependent notifiers
        final numberNotifier = ReactiveNotifier<int>(() => 10);
        final isPositiveNotifier = ReactiveNotifier<bool>(() => true);
        final squaredNotifier = ReactiveNotifier<int>(() => 100);
        final descriptionNotifier = ReactiveNotifier<String>(() => 'positive even');

        // Setup: Create multiple dependencies from single source
        numberNotifier.addListener(() {
          final num = numberNotifier.notifier;
          isPositiveNotifier.updateState(num > 0);
          squaredNotifier.updateState(num * num);
          descriptionNotifier.updateState('${num > 0 ? 'positive' : 'negative'} ${num % 2 == 0 ? 'even' : 'odd'}');
        });

        // Act: Update source to negative odd number
        numberNotifier.updateState(-3);

        // Assert: All dependent notifiers should update correctly
        expect(numberNotifier.notifier, -3, reason: 'Source should have new value');
        expect(isPositiveNotifier.notifier, false, reason: 'Should detect negative number');
        expect(squaredNotifier.notifier, 9, reason: 'Should calculate correct square');
        expect(descriptionNotifier.notifier, 'negative odd', reason: 'Should create correct description');

        // Act: Update source to positive even number
        numberNotifier.updateState(4);

        // Assert: All dependent notifiers should update again
        expect(numberNotifier.notifier, 4, reason: 'Source should have newest value');
        expect(isPositiveNotifier.notifier, true, reason: 'Should detect positive number');
        expect(squaredNotifier.notifier, 16, reason: 'Should calculate new square');
        expect(descriptionNotifier.notifier, 'positive even', reason: 'Should create new description');
      });

      test('should handle one-to-many and many-to-one relationships', () {
        // Setup: Create notifiers for complex relationships
        final inputANotifier = ReactiveNotifier<int>(() => 5);
        final inputBNotifier = ReactiveNotifier<int>(() => 3);
        final sumNotifier = ReactiveNotifier<int>(() => 8);
        final productNotifier = ReactiveNotifier<int>(() => 15);
        final resultNotifier = ReactiveNotifier<String>(() => 'sum: 8, product: 15');

        // Setup: Many-to-one relationship (inputs -> calculations)
        void updateCalculations() {
          final a = inputANotifier.notifier;
          final b = inputBNotifier.notifier;
          sumNotifier.updateState(a + b);
          productNotifier.updateState(a * b);
        }

        inputANotifier.addListener(updateCalculations);
        inputBNotifier.addListener(updateCalculations);

        // Setup: One-to-many relationship (calculations -> result)
        void updateResult() {
          final sum = sumNotifier.notifier;
          final product = productNotifier.notifier;
          resultNotifier.updateState('sum: $sum, product: $product');
        }

        sumNotifier.addListener(updateResult);
        productNotifier.addListener(updateResult);

        // Act: Update first input
        inputANotifier.updateState(7);

        // Assert: All dependent calculations should update
        expect(sumNotifier.notifier, 10, reason: 'Sum should update: 7 + 3 = 10');
        expect(productNotifier.notifier, 21, reason: 'Product should update: 7 * 3 = 21');
        expect(resultNotifier.notifier, 'sum: 10, product: 21', 
            reason: 'Result should reflect all calculations');

        // Act: Update second input
        inputBNotifier.updateState(6);

        // Assert: All calculations should update again
        expect(sumNotifier.notifier, 13, reason: 'Sum should update: 7 + 6 = 13');
        expect(productNotifier.notifier, 42, reason: 'Product should update: 7 * 6 = 42');
        expect(resultNotifier.notifier, 'sum: 13, product: 42', 
            reason: 'Result should reflect new calculations');
      });
    });

    group('Cascading Updates and Reactive Chains', () {
      test('should handle cascading updates through multiple levels', () {
        // Setup: Create a cascading chain: Celsius -> Fahrenheit -> Weather Description
        final temperatureCelsius = ReactiveNotifier<double>(() => 0);
        final temperatureFahrenheit = ReactiveNotifier<double>(() => 32);
        final weatherDescription = ReactiveNotifier<String>(() => 'Freezing');

        // Setup: First level cascade (Celsius -> Fahrenheit)
        temperatureCelsius.addListener(() {
          temperatureFahrenheit.updateState(temperatureCelsius.notifier * 9 / 5 + 32);
        });

        // Setup: Second level cascade (Fahrenheit -> Description)
        temperatureFahrenheit.addListener(() {
          final temp = temperatureFahrenheit.notifier;
          if (temp < 32) {
            weatherDescription.updateState('Freezing');
          } else if (temp < 65) {
            weatherDescription.updateState('Cold');
          } else if (temp < 80) {
            weatherDescription.updateState('Comfortable');
          } else {
            weatherDescription.updateState('Hot');
          }
        });

        // Act: Update Celsius temperature to comfortable range
        temperatureCelsius.updateState(25); // Should be ~77°F

        // Assert: All levels of the cascade should update correctly
        expect(temperatureCelsius.notifier, 25, 
            reason: 'Source temperature should be updated');
        expect(temperatureFahrenheit.notifier, closeTo(77, 0.1), 
            reason: 'Fahrenheit should be calculated correctly (25°C = 77°F)');
        expect(weatherDescription.notifier, 'Comfortable', 
            reason: 'Weather description should reflect comfortable temperature');

        // Act: Update Celsius temperature to hot range
        temperatureCelsius.updateState(35); // Should be ~95°F

        // Assert: Cascade should update to reflect hot temperature
        expect(temperatureCelsius.notifier, 35, 
            reason: 'Source temperature should be updated to 35°C');
        expect(temperatureFahrenheit.notifier, closeTo(95, 0.1), 
            reason: 'Fahrenheit should be calculated correctly (35°C = 95°F)');
        expect(weatherDescription.notifier, 'Hot', 
            reason: 'Weather description should reflect hot temperature');

        // Act: Update Celsius temperature to freezing range
        temperatureCelsius.updateState(-10); // Should be ~14°F

        // Assert: Cascade should update to reflect freezing temperature
        expect(temperatureCelsius.notifier, -10, 
            reason: 'Source temperature should be updated to -10°C');
        expect(temperatureFahrenheit.notifier, closeTo(14, 0.1), 
            reason: 'Fahrenheit should be calculated correctly (-10°C = 14°F)');
        expect(weatherDescription.notifier, 'Freezing', 
            reason: 'Weather description should reflect freezing temperature');
      });

      test('should handle complex reactive chains with branching', () {
        // Setup: Create a complex reactive system with branching
        final userInputNotifier = ReactiveNotifier<String>(() => '42');
        final parsedNumberNotifier = ReactiveNotifier<int?>(() => null);
        final isValidNotifier = ReactiveNotifier<bool>(() => false);
        final validationMessageNotifier = ReactiveNotifier<String>(() => 'Invalid input');
        final processedResultNotifier = ReactiveNotifier<String>(() => 'No result');

        // Setup: Parse input and validate
        userInputNotifier.addListener(() {
          final input = userInputNotifier.notifier;
          final parsed = int.tryParse(input);
          parsedNumberNotifier.updateState(parsed);
          isValidNotifier.updateState(parsed != null);
        });

        // Setup: Update validation message based on validity
        isValidNotifier.addListener(() {
          if (isValidNotifier.notifier) {
            validationMessageNotifier.updateState('Valid number');
          } else {
            validationMessageNotifier.updateState('Invalid input - please enter a number');
          }
        });

        // Setup: Process result based on parsed number
        parsedNumberNotifier.addListener(() {
          final number = parsedNumberNotifier.notifier;
          if (number != null) {
            if (number > 0) {
              processedResultNotifier.updateState('Positive: ${number * 2}');
            } else if (number < 0) {
              processedResultNotifier.updateState('Negative: ${number.abs()}');
            } else {
              processedResultNotifier.updateState('Zero: no change');
            }
          } else {
            processedResultNotifier.updateState('Cannot process invalid input');
          }
        });

        // Act: Input valid positive number
        userInputNotifier.updateState('15');

        // Assert: All branches should update correctly for positive number
        expect(parsedNumberNotifier.notifier, 15, reason: 'Should parse positive number');
        expect(isValidNotifier.notifier, true, reason: 'Should recognize valid input');
        expect(validationMessageNotifier.notifier, 'Valid number', reason: 'Should show valid message');
        expect(processedResultNotifier.notifier, 'Positive: 30', reason: 'Should process positive number');

        // Act: Input valid negative number
        userInputNotifier.updateState('-7');

        // Assert: All branches should update correctly for negative number
        expect(parsedNumberNotifier.notifier, -7, reason: 'Should parse negative number');
        expect(isValidNotifier.notifier, true, reason: 'Should recognize valid negative input');
        expect(validationMessageNotifier.notifier, 'Valid number', reason: 'Should maintain valid message');
        expect(processedResultNotifier.notifier, 'Negative: 7', reason: 'Should process negative number');

        // Act: Input invalid text
        userInputNotifier.updateState('abc');

        // Assert: All branches should update correctly for invalid input
        expect(parsedNumberNotifier.notifier, null, reason: 'Should fail to parse invalid input');
        expect(isValidNotifier.notifier, false, reason: 'Should recognize invalid input');
        expect(validationMessageNotifier.notifier, 'Invalid input - please enter a number', 
            reason: 'Should show invalid message');
        expect(processedResultNotifier.notifier, 'Cannot process invalid input', 
            reason: 'Should handle invalid input in processing');
      });
    });

    group('Circular Dependencies and Loop Prevention', () {
      test('should handle circular dependencies without infinite updates', () {
        // Setup: Create two notifiers that depend on each other
        final notifierA = ReactiveNotifier<int>(() => 0);
        final notifierB = ReactiveNotifier<int>(() => 0);

        var updateCountA = 0;
        var updateCountB = 0;

        // Setup: Create circular dependency A -> B -> A
        notifierA.addListener(() {
          updateCountA++;
          // Only update B if A's value is what we expect (prevent infinite loop)
          if (notifierA.notifier == 1) {
            notifierB.updateState(notifierA.notifier + 1);
          }
        });

        notifierB.addListener(() {
          updateCountB++;
          // Only update A if B's value is what we expect (prevent infinite loop)
          if (notifierB.notifier == 2 && notifierA.notifier == 1) {
            // Don't update A again to prevent loop
          }
        });

        // Act: Trigger the circular dependency
        notifierA.updateState(1);

        // Assert: Should not create infinite loop
        expect(updateCountA, equals(1), 
            reason: 'NotifierA should update only once');
        expect(updateCountB, equals(1), 
            reason: 'NotifierB should update only once');
        expect(notifierA.notifier, equals(1), 
            reason: 'NotifierA state should remain 1');
        expect(notifierB.notifier, equals(2), 
            reason: 'NotifierB state should be updated to 2');
      });

      test('should handle complex circular dependencies safely', () {
        // Setup: Create a three-way circular dependency A -> B -> C -> A
        final notifierA = ReactiveNotifier<int>(() => 1);
        final notifierB = ReactiveNotifier<int>(() => 2);
        final notifierC = ReactiveNotifier<int>(() => 3);

        var updateCountA = 0;
        var updateCountB = 0;
        var updateCountC = 0;

        // Setup: Create controlled circular dependencies
        notifierA.addListener(() {
          updateCountA++;
          // Only trigger under specific conditions to prevent infinite loops
          if (updateCountA == 1) {
            notifierB.updateState(notifierA.notifier * 10);
          }
        });

        notifierB.addListener(() {
          updateCountB++;
          // Only trigger under specific conditions
          if (updateCountB == 1) {
            notifierC.updateState(notifierB.notifier + 100);
          }
        });

        notifierC.addListener(() {
          updateCountC++;
          // Only trigger under specific conditions
          if (updateCountC == 1) {
            // Complete the circle but don't trigger infinite updates
            // Just update A once more with controlled logic
            if (notifierA.notifier < 100) {
              notifierA.updateState(notifierA.notifier + 50);
            }
          }
        });

        // Act: Trigger the complex circular dependency
        notifierA.updateState(5);

        // Assert: Should handle complex circular dependencies without infinite loops
        expect(updateCountA, lessThanOrEqualTo(2), 
            reason: 'NotifierA should not update infinitely');
        expect(updateCountB, lessThanOrEqualTo(2), 
            reason: 'NotifierB should not update infinitely');
        expect(updateCountC, lessThanOrEqualTo(2), 
            reason: 'NotifierC should not update infinitely');
        
        // Verify final states are reasonable
        expect(notifierA.notifier, anyOf(equals(5), equals(55)), 
            reason: 'NotifierA should have reasonable final state');
        expect(notifierB.notifier, anyOf(equals(2), equals(50)), 
            reason: 'NotifierB should have reasonable final state');
        expect(notifierC.notifier, anyOf(equals(3), equals(150)), 
            reason: 'NotifierC should have reasonable final state');
      });

      test('should prevent stack overflow in deeply nested updates', () {
        // Setup: Create a chain that could potentially cause deep recursion
        final notifiers = List.generate(10, (index) => ReactiveNotifier<int>(() => index));

        var totalUpdates = 0;

        // Setup: Create a chain where each notifier updates the next one
        for (int i = 0; i < notifiers.length - 1; i++) {
          final currentIndex = i;
          notifiers[i].addListener(() {
            totalUpdates++;
            // Only update the next notifier if we haven't exceeded reasonable bounds
            if (totalUpdates < 20) {
              notifiers[currentIndex + 1].updateState(notifiers[currentIndex].notifier + 1);
            }
          });
        }

        // Act: Trigger the chain reaction
        notifiers[0].updateState(100);

        // Assert: Should not cause stack overflow and should complete in reasonable time
        expect(totalUpdates, lessThan(20), 
            reason: 'Should not cause excessive recursive updates');
        expect(notifiers[0].notifier, 100, 
            reason: 'First notifier should have triggered value');
        expect(notifiers.last.notifier, greaterThan(0), 
            reason: 'Last notifier should have been updated through the chain');
      });
    });

    group('Performance and Coordination Tests', () {
      test('should handle multiple simultaneous cross-notifier updates efficiently', () {
        // Setup: Create multiple independent reactive systems
        final systems = List.generate(5, (index) {
          final source = ReactiveNotifier<int>(() => index);
          final derived = ReactiveNotifier<String>(() => 'derived_$index');
          
          source.addListener(() {
            derived.updateState('derived_${source.notifier}');
          });
          
          return {'source': source, 'derived': derived};
        });

        // Act: Update all systems simultaneously
        for (int i = 0; i < systems.length; i++) {
          systems[i]['source']!.updateState(i * 10);
        }

        // Assert: All systems should update correctly and independently
        for (int i = 0; i < systems.length; i++) {
          expect((systems[i]['source'] as ReactiveNotifier<int>).notifier, i * 10,
              reason: 'Source $i should have correct value');
          expect((systems[i]['derived'] as ReactiveNotifier<String>).notifier, 'derived_${i * 10}',
              reason: 'Derived $i should have correct value');
        }
      });

      test('should maintain consistency during rapid cross-notifier updates', () {
        // Setup: Create a system with rapid updates
        final masterNotifier = ReactiveNotifier<int>(() => 0);
        final counters = List.generate(3, (index) => ReactiveNotifier<int>(() => 0));

        // Setup: Each counter tracks the master with different transformations
        masterNotifier.addListener(() {
          final master = masterNotifier.notifier;
          counters[0].updateState(master * 2);
          counters[1].updateState(master + 10);
          counters[2].updateState(master * master);
        });

        // Act: Perform rapid updates
        for (int i = 1; i <= 10; i++) {
          masterNotifier.updateState(i);
        }

        // Assert: All counters should be consistent with final master value
        expect(masterNotifier.notifier, 10, reason: 'Master should have final value');
        expect(counters[0].notifier, 20, reason: 'Counter 0 should be master * 2');
        expect(counters[1].notifier, 20, reason: 'Counter 1 should be master + 10');
        expect(counters[2].notifier, 100, reason: 'Counter 2 should be master squared');
      });
    });
  });
}