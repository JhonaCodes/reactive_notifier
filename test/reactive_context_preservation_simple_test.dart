import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// Simple test for widget preservation
class SimpleCountedWidget extends StatelessWidget {
  final String text;
  static int buildCount = 0;

  const SimpleCountedWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    buildCount++;
    return Text('$text - Build #$buildCount');
  }
}

mixin SimpleDataService {
  static final ReactiveNotifier<String> instance =
      ReactiveNotifier<String>(() => 'initial');

  static void updateData(String value) {
    instance.updateState(value);
  }
}

extension SimpleDataContext on BuildContext {
  String get data => getReactiveState(SimpleDataService.instance);
}

void main() {
  group('Simple ReactiveContext Preservation Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
      SimpleCountedWidget.buildCount = 0;
    });

    testWidgets('should demonstrate basic preservation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // This widget depends on data and will rebuild
                Builder(
                  builder: (context) =>
                      SimpleCountedWidget(text: 'Reactive: ${context.data}'),
                ),
                // This widget is preserved and should not rebuild
                const SimpleCountedWidget(text: 'Preserved')
                    .keep('preserved_key'),
                // This widget doesn't depend on data but is in the same tree
                const SimpleCountedWidget(text: 'Static'),
              ],
            ),
          ),
        ),
      );

      // Initial build - all 3 widgets should build
      expect(SimpleCountedWidget.buildCount, 3);
      expect(find.text('Reactive: initial - Build #1'), findsOneWidget);
      expect(find.text('Preserved - Build #2'), findsOneWidget);
      expect(find.text('Static - Build #3'), findsOneWidget);

      // Update data - only the reactive widget should rebuild
      SimpleDataService.updateData('updated');
      await tester.pump();

      // Should be 4 builds total: original 3 + 1 reactive rebuild
      expect(SimpleCountedWidget.buildCount, 4);
      expect(find.text('Reactive: updated - Build #4'), findsOneWidget);
      expect(find.text('Preserved - Build #2'), findsOneWidget); // No rebuild
      expect(find.text('Static - Build #3'), findsOneWidget); // No rebuild
    });

    testWidgets('should show widget preservation works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    Text('Data: ${context.data}'),
                    const SimpleCountedWidget(text: 'Preserved')
                        .keep('test_key'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Initial build
      expect(SimpleCountedWidget.buildCount, 1);
      expect(find.text('Preserved - Build #1'), findsOneWidget);

      // Update data - the builder will rebuild but the preserved widget should not
      SimpleDataService.updateData('changed');
      await tester.pump();

      // Still only 1 build because widget is preserved
      expect(SimpleCountedWidget.buildCount, 1);
      expect(find.text('Preserved - Build #1'), findsOneWidget);
    });
  });
}
