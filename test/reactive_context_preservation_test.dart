import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// Test widget with build counter
class CountedWidget extends StatelessWidget {
  final String text;
  static int buildCount = 0;

  const CountedWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    buildCount++;
    return Text('$text - Build #$buildCount');
  }
}

/// Test service for preservation tests
mixin TestDataService {
  static ReactiveNotifier<String>? _instance;

  static ReactiveNotifier<String> get instance {
    return _instance ??= ReactiveNotifier<String>(
      () => 'initial',
    );
  }

  static void updateData(String value) {
    instance.updateState(value);
  }

  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}

/// Extension for clean API
extension TestDataContext on BuildContext {
  String get data => getReactiveState(TestDataService.instance);
}

void main() {
  group('ReactiveContext Preservation Registry Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
      TestDataService.reset();
      CountedWidget.buildCount = 0;
    });

    testWidgets('should preserve widgets with unique keys', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Builder(
                  builder: (context) => Text('Data: ${context.data}'),
                ),
                const CountedWidget(text: 'Preserved').keep('widget_1'),
                Builder(
                  builder: (context) {
                    // This builder depends on data and should rebuild
                    final data =
                        context.data; // Access data to create dependency
                    return CountedWidget(text: 'Normal-$data');
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Initial build
      expect(CountedWidget.buildCount, 2);
      expect(find.text('Preserved - Build #1'), findsOneWidget);
      expect(find.text('Normal-initial - Build #2'), findsOneWidget);

      // Update data - only normal widget should rebuild
      TestDataService.updateData('updated');
      await tester.pump();

      expect(CountedWidget.buildCount, 3);
      expect(find.text('Preserved - Build #1'), findsOneWidget); // No rebuild
      expect(find.text('Normal-updated - Build #3'), findsOneWidget); // Rebuilt
    });

    testWidgets('should handle multiple preserved widgets properly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    Text('Data: ${context.data}'),
                    const CountedWidget(text: 'Widget A').keep('key_a'),
                    const CountedWidget(text: 'Widget B').keep('key_b'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Both widgets should be preserved with unique keys
      expect(CountedWidget.buildCount, 2);
      expect(find.text('Widget A - Build #1'), findsOneWidget);
      expect(find.text('Widget B - Build #2'), findsOneWidget);

      // Update data - both should be preserved
      TestDataService.updateData('updated');
      await tester.pump();

      expect(CountedWidget.buildCount, 2); // No new builds
      expect(find.text('Widget A - Build #1'), findsOneWidget);
      expect(find.text('Widget B - Build #2'), findsOneWidget);
    });

    testWidgets('should handle automatic key generation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    Text('Data: ${context.data}'),
                    // Keep without explicit key - should auto-generate
                    const CountedWidget(text: 'Auto Key').keep(),
                    CountedWidget(text: 'Normal-${context.data}'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(CountedWidget.buildCount, 2);

      // Update data
      TestDataService.updateData('updated');
      await tester.pump();

      expect(CountedWidget.buildCount, 3);
      expect(find.text('Auto Key - Build #1'), findsOneWidget); // Preserved
      expect(find.text('Normal-updated - Build #3'), findsOneWidget); // Rebuilt
    });

    testWidgets('should handle context.keep() method', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    Text('Data: ${context.data}'),
                    context.keep(
                      const CountedWidget(text: 'Context Kept'),
                      'context_key',
                    ),
                    CountedWidget(text: 'Normal-${context.data}'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(CountedWidget.buildCount, 2);

      // Update data
      TestDataService.updateData('context_updated');
      await tester.pump();

      expect(CountedWidget.buildCount, 3);
      expect(find.text('Context Kept - Build #1'), findsOneWidget); // Preserved
      expect(find.text('Normal-context_updated - Build #3'),
          findsOneWidget); // Rebuilt
    });

    testWidgets('should handle context.keepAll() for batch preservation',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    Text('Data: ${context.data}'),
                    ...context.keepAll([
                      const CountedWidget(text: 'Batch 1'),
                      const CountedWidget(text: 'Batch 2'),
                      const CountedWidget(text: 'Batch 3'),
                    ], 'batch_key'),
                    CountedWidget(text: 'Normal-${context.data}'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(CountedWidget.buildCount, 4);

      // Update data
      TestDataService.updateData('batch_updated');
      await tester.pump();

      expect(CountedWidget.buildCount, 5);
      expect(find.text('Batch 1 - Build #1'), findsOneWidget); // Preserved
      expect(find.text('Batch 2 - Build #2'), findsOneWidget); // Preserved
      expect(find.text('Batch 3 - Build #3'), findsOneWidget); // Preserved
      expect(find.text('Normal-batch_updated - Build #5'),
          findsOneWidget); // Rebuilt
    });

    testWidgets('should handle widget tree changes with preservation',
        (tester) async {
      bool showPreserved = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          setState(() => showPreserved = !showPreserved),
                      child: const Text('Toggle'),
                    ),
                    Text('Data: ${TestDataService.instance.notifier}'),
                    if (showPreserved)
                      const CountedWidget(text: 'Preserved').keep('toggle_key'),
                    const CountedWidget(text: 'Always Visible'),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(CountedWidget.buildCount, 2);

      // Hide preserved widget
      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(find.text('Preserved'), findsNothing);
      expect(find.text('Always Visible - Build #2'), findsOneWidget);

      // Show preserved widget again
      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(find.text('Preserved - Build #3'),
          findsOneWidget); // Re-created after removal
      expect(find.text('Always Visible - Build #2'),
          findsOneWidget); // Should still be there
      expect(CountedWidget.buildCount, 3); // One new build when re-added
    });

    testWidgets('should handle memory cleanup correctly', (tester) async {
      // Create many preserved widgets
      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      Text('Data: ${context.data}'),
                      CountedWidget(text: 'Widget $i').keep('key_$i'),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      }

      expect(CountedWidget.buildCount, 5);

      // Update data multiple times
      for (int i = 0; i < 3; i++) {
        TestDataService.updateData('update_$i');
        await tester.pump();
      }

      // All widgets should remain preserved
      expect(CountedWidget.buildCount, 5);

      // Widget tree should still work correctly
      expect(find.text('Widget 4 - Build #5'), findsOneWidget);
    });

    testWidgets('should handle nested preservation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    Text('Data: ${context.data}'),
                    Column(
                      children: [
                        const CountedWidget(text: 'Nested Preserved')
                            .keep('nested_key'),
                        const CountedWidget(text: 'Nested Normal'),
                      ],
                    ).keep('container_key'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(CountedWidget.buildCount, 2);

      // Update data
      TestDataService.updateData('nested_updated');
      await tester.pump();

      // Both widgets should be preserved due to container preservation
      expect(CountedWidget.buildCount, 2);
      expect(find.text('Nested Preserved - Build #1'), findsOneWidget);
      expect(find.text('Nested Normal - Build #2'), findsOneWidget);
    });

    testWidgets('should handle rapid state changes efficiently',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final data = context.data;
                return Column(
                  children: [
                    Text('Data: $data'),
                    const CountedWidget(text: 'Preserved').keep('rapid_key'),
                    CountedWidget(text: 'Normal-$data'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(CountedWidget.buildCount, 2);

      // Rapid updates
      for (int i = 0; i < 10; i++) {
        TestDataService.updateData('rapid_$i');
        await tester.pump();
      }

      // Preserved widget should not rebuild, normal widget rebuilds 10 times
      expect(CountedWidget.buildCount, 12);
      expect(find.text('Preserved - Build #1'), findsOneWidget);
      expect(find.text('Normal-rapid_9 - Build #12'), findsOneWidget);
    });
  });
}
