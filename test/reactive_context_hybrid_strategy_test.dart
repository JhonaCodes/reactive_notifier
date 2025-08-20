import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// Test model for hybrid strategy testing
class HybridTestData {
  final String value;
  final int counter;

  HybridTestData(this.value, this.counter);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HybridTestData &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          counter == other.counter;

  @override
  int get hashCode => value.hashCode ^ counter.hashCode;

  @override
  String toString() => 'HybridTestData(value: $value, counter: $counter)';
}

/// Test services for different types
mixin ServiceA {
  static final ReactiveNotifier<HybridTestData> instance =
      ReactiveNotifier<HybridTestData>(
    () => HybridTestData('A', 0),
  );

  static void updateData(String value, int counter) {
    instance.updateState(HybridTestData(value, counter));
  }
}

mixin ServiceB {
  static final ReactiveNotifier<HybridTestData> instance =
      ReactiveNotifier<HybridTestData>(
    () => HybridTestData('B', 0),
  );

  static void updateData(String value, int counter) {
    instance.updateState(HybridTestData(value, counter));
  }
}

mixin ServiceC {
  static final ReactiveNotifier<String> instance = ReactiveNotifier<String>(
    () => 'C_initial',
  );

  static void updateData(String value) {
    instance.updateState(value);
  }
}

/// Extensions for clean API
extension ServiceAContext on BuildContext {
  HybridTestData get dataA => getReactiveState(ServiceA.instance);
}

extension ServiceBContext on BuildContext {
  HybridTestData get dataB => getReactiveState(ServiceB.instance);
}

extension ServiceCContext on BuildContext {
  String get dataC => getReactiveState(ServiceC.instance);
}

/// Widget that tracks builds for each service
class HybridTrackingWidget extends StatelessWidget {
  static int buildsA = 0;
  static int buildsB = 0;
  static int buildsC = 0;

  final String trackingType;

  const HybridTrackingWidget({super.key, required this.trackingType});

  @override
  Widget build(BuildContext context) {
    switch (trackingType) {
      case 'A':
        buildsA++;
        return Text(
            'A: ${context.dataA.value}-${context.dataA.counter} (Build #$buildsA)');
      case 'B':
        buildsB++;
        return Text(
            'B: ${context.dataB.value}-${context.dataB.counter} (Build #$buildsB)');
      case 'C':
        buildsC++;
        return Text('C: ${context.dataC} (Build #$buildsC)');
      default:
        return const Text('Unknown');
    }
  }

  static void resetCounters() {
    buildsA = 0;
    buildsB = 0;
    buildsC = 0;
  }
}

/// Widget that uses multiple services
class MultiServiceWidget extends StatelessWidget {
  static int builds = 0;

  const MultiServiceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    builds++;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Multi A: ${context.dataA.value}'),
        Text('Multi B: ${context.dataB.value}'),
        Text('Multi C: ${context.dataC}'),
        Text('Multi Build #$builds'),
      ],
    );
  }

  static void resetCounter() {
    builds = 0;
  }
}

void main() {
  group('ReactiveContext Hybrid Strategy Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
      HybridTrackingWidget.resetCounters();
      MultiServiceWidget.resetCounter();
    });

    testWidgets('should prevent cross-rebuilds between different types',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HybridTrackingWidget(trackingType: 'A'),
                HybridTrackingWidget(trackingType: 'B'),
                HybridTrackingWidget(trackingType: 'C'),
              ],
            ),
          ),
        ),
      );

      // Initial builds
      expect(HybridTrackingWidget.buildsA, 1);
      expect(HybridTrackingWidget.buildsB, 1);
      expect(HybridTrackingWidget.buildsC, 1);

      // Update Service A - should only rebuild A widget
      ServiceA.updateData('A_updated', 1);
      await tester.pump();

      expect(HybridTrackingWidget.buildsA, 2);
      expect(HybridTrackingWidget.buildsB, 1); // Should not rebuild
      expect(HybridTrackingWidget.buildsC, 1); // Should not rebuild

      // Update Service B - should only rebuild B widget
      ServiceB.updateData('B_updated', 1);
      await tester.pump();

      expect(HybridTrackingWidget.buildsA, 2); // Should not rebuild
      expect(HybridTrackingWidget.buildsB, 2);
      expect(HybridTrackingWidget.buildsC, 1); // Should not rebuild

      // Update Service C - should only rebuild C widget
      ServiceC.updateData('C_updated');
      await tester.pump();

      expect(HybridTrackingWidget.buildsA, 2); // Should not rebuild
      expect(HybridTrackingWidget.buildsB, 2); // Should not rebuild
      expect(HybridTrackingWidget.buildsC, 2);
    });

    testWidgets('should handle widgets using multiple services',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HybridTrackingWidget(trackingType: 'A'),
                MultiServiceWidget(),
                HybridTrackingWidget(trackingType: 'B'),
              ],
            ),
          ),
        ),
      );

      // Initial builds
      expect(HybridTrackingWidget.buildsA, 1);
      expect(HybridTrackingWidget.buildsB, 1);
      expect(MultiServiceWidget.builds, 1);

      // Update Service A - should rebuild A widget and multi-service widget
      ServiceA.updateData('A_multi', 1);
      await tester.pump();

      expect(HybridTrackingWidget.buildsA, 2);
      expect(HybridTrackingWidget.buildsB, 1); // Should not rebuild
      expect(MultiServiceWidget.builds, 2); // Should rebuild (uses A)

      // Update Service B - should rebuild B widget and multi-service widget
      ServiceB.updateData('B_multi', 1);
      await tester.pump();

      expect(HybridTrackingWidget.buildsA, 2); // Should not rebuild
      expect(HybridTrackingWidget.buildsB, 2);
      expect(MultiServiceWidget.builds, 3); // Should rebuild (uses B)
    });

    testWidgets('should handle InheritedWidget strategy correctly',
        (tester) async {
      await tester.pumpWidget(
        ReactiveContextBuilder(
          forceInheritedFor: [ServiceA.instance, ServiceB.instance],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  HybridTrackingWidget(trackingType: 'A'),
                  HybridTrackingWidget(trackingType: 'B'),
                  HybridTrackingWidget(trackingType: 'C'),
                ],
              ),
            ),
          ),
        ),
      );

      // Initial builds
      expect(HybridTrackingWidget.buildsA, 1);
      expect(HybridTrackingWidget.buildsB, 1);
      expect(HybridTrackingWidget.buildsC, 1);

      // Update Service A - should use InheritedWidget strategy
      ServiceA.updateData('A_inherited', 1);
      await tester.pump();

      expect(HybridTrackingWidget.buildsA, 2);
      expect(HybridTrackingWidget.buildsB, 1); // Should not rebuild
      expect(HybridTrackingWidget.buildsC, 1); // Should not rebuild

      // Update Service C - should use markNeedsBuild strategy
      ServiceC.updateData('C_marked');
      await tester.pump();

      expect(HybridTrackingWidget.buildsA, 2); // Should not rebuild
      expect(HybridTrackingWidget.buildsB, 1); // Should not rebuild
      expect(HybridTrackingWidget.buildsC, 2);
    });

    testWidgets('should handle rapid state changes efficiently',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HybridTrackingWidget(trackingType: 'A'),
                HybridTrackingWidget(trackingType: 'B'),
              ],
            ),
          ),
        ),
      );

      // Initial builds
      expect(HybridTrackingWidget.buildsA, 1);
      expect(HybridTrackingWidget.buildsB, 1);

      // Rapid updates to Service A
      for (int i = 0; i < 10; i++) {
        ServiceA.updateData('A_rapid_$i', i);
        await tester.pump();
      }

      // Only A should rebuild multiple times
      expect(HybridTrackingWidget.buildsA, 11);
      expect(HybridTrackingWidget.buildsB, 1); // Should not rebuild

      // Rapid updates to Service B
      for (int i = 0; i < 5; i++) {
        ServiceB.updateData('B_rapid_$i', i);
        await tester.pump();
      }

      // Only B should rebuild, A should remain unchanged
      expect(HybridTrackingWidget.buildsA, 11); // Should not rebuild
      expect(HybridTrackingWidget.buildsB, 6);
    });

    testWidgets('should handle concurrent updates correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HybridTrackingWidget(trackingType: 'A'),
                HybridTrackingWidget(trackingType: 'B'),
                HybridTrackingWidget(trackingType: 'C'),
                MultiServiceWidget(),
              ],
            ),
          ),
        ),
      );

      // Initial builds
      expect(HybridTrackingWidget.buildsA, 1);
      expect(HybridTrackingWidget.buildsB, 1);
      expect(HybridTrackingWidget.buildsC, 1);
      expect(MultiServiceWidget.builds, 1);

      // Concurrent updates
      ServiceA.updateData('A_concurrent', 1);
      ServiceB.updateData('B_concurrent', 1);
      ServiceC.updateData('C_concurrent');
      await tester.pump();

      // All should rebuild once
      expect(HybridTrackingWidget.buildsA, 2);
      expect(HybridTrackingWidget.buildsB, 2);
      expect(HybridTrackingWidget.buildsC, 2);
      expect(
          MultiServiceWidget.builds, 2); // Rebuilds once due to A or B change
    });

    testWidgets('should handle widget tree modifications during updates',
        (tester) async {
      bool showWidgetA = true;
      bool showWidgetB = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () =>
                              setState(() => showWidgetA = !showWidgetA),
                          child: const Text('Toggle A'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              setState(() => showWidgetB = !showWidgetB),
                          child: const Text('Toggle B'),
                        ),
                      ],
                    ),
                    if (showWidgetA)
                      const HybridTrackingWidget(trackingType: 'A'),
                    if (showWidgetB)
                      const HybridTrackingWidget(trackingType: 'B'),
                    const HybridTrackingWidget(trackingType: 'C'),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Initial builds
      expect(HybridTrackingWidget.buildsA, 1);
      expect(HybridTrackingWidget.buildsB, 1);
      expect(HybridTrackingWidget.buildsC, 1);

      // Hide widget A
      await tester.tap(find.text('Toggle A'));
      await tester.pump();

      expect(find.byType(HybridTrackingWidget), findsNWidgets(2)); // B and C

      // Update Service A while A widget is hidden
      ServiceA.updateData('A_hidden', 1);
      await tester.pump();

      expect(HybridTrackingWidget.buildsA, 1); // Should not rebuild (hidden)
      expect(HybridTrackingWidget.buildsB,
          3); // Rebuilt due to StatefulBuilder toggle + service A update
      expect(HybridTrackingWidget.buildsC,
          2); // Rebuilt due to StatefulBuilder toggle

      // Show widget A again
      await tester.tap(find.text('Toggle A'));
      await tester.pump();

      expect(
          find.byType(HybridTrackingWidget), findsNWidgets(3)); // A, B, and C
      expect(
          HybridTrackingWidget.buildsA, 2); // Should rebuild with current state
      expect(HybridTrackingWidget.buildsB,
          4); // Rebuilt due to StatefulBuilder toggle again
      expect(HybridTrackingWidget.buildsC,
          3); // Rebuilt due to StatefulBuilder toggle
    });

    testWidgets('should handle memory cleanup during strategy switching',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HybridTrackingWidget(trackingType: 'A'),
                HybridTrackingWidget(trackingType: 'B'),
              ],
            ),
          ),
        ),
      );

      // Update states multiple times
      for (int i = 0; i < 5; i++) {
        ServiceA.updateData('A_cleanup_$i', i);
        ServiceB.updateData('B_cleanup_$i', i);
        await tester.pump();
      }

      expect(HybridTrackingWidget.buildsA, 6); // 1 initial + 5 updates
      expect(HybridTrackingWidget.buildsB, 6); // 1 initial + 5 updates

      // Switch to optimizer mode
      await tester.pumpWidget(
        ReactiveContextBuilder(
          forceInheritedFor: [ServiceA.instance],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  HybridTrackingWidget(trackingType: 'A'),
                  HybridTrackingWidget(trackingType: 'B'),
                ],
              ),
            ),
          ),
        ),
      );

      // Continue updates with optimizer
      for (int i = 5; i < 10; i++) {
        ServiceA.updateData('A_optimized_$i', i);
        ServiceB.updateData('B_optimized_$i', i);
        await tester.pump();
      }

      // Should continue working correctly
      expect(HybridTrackingWidget.buildsA,
          12); // 6 previous + 1 strategy switch + 5 new
      expect(HybridTrackingWidget.buildsB,
          12); // 6 previous + 1 strategy switch + 5 new
    });
  });
}
