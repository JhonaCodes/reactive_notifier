import 'dart:developer';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'config/alchemist_config.dart';

ReactiveNotifier<int> state = ReactiveNotifier<int>(() => 0);

void main() {
  group('ReactiveBuilder Golden Tests', () {
    goldenTest(
      'ReactiveBuilder should default value',
      fileName: 'golden_reactive_builder_default_test',
      constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
      builder: () => GoldenTestGroup(
        scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        children: [
          GoldenTestScenario(
            name: 'Change value 0',
            child: ReactiveBuilder(
                notifier: state,
                build: (value, vm, child) {
                  return Column(
                    children: [
                      Text("Widget that rebuilds $value"),
                      child(const Text("My widget that doesn't rebuild")),
                      Text("Widget that rebuilds $value"),
                    ],
                  );
                  // return ListTile(
                  //   title: Text('ReactiveNotifier.value = $value'),
                  // );
                }),
          ),
        ],
      ),
    );

    goldenTest(
      'ReactiveBuilder should rebuild to new value',
      fileName: 'golden_reactive_builder_test',
      constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
      builder: () => GoldenTestGroup(
        scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        children: [
          GoldenTestScenario(
            name: 'Change value 200',
            child: ReactiveBuilder<int>(
                notifier: state,
                build: (value, vm, child) {
                  if (value == 0) {
                    state.updateState(200);
                  }
                  return ListTile(
                    title: Text('ReactiveNotifier.value = $value'),
                  );
                }),
          ),
        ],
      ),
    );
  });

  testWidgets('ReactiveBuilder does not rebuild non-rebuildable widgets',
      (WidgetTester tester) async {
    int rebuildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReactiveBuilder<int>(
            notifier: valueNotifier,
            build: (value, vm, noRebuildable) {
              rebuildCount++; // Counter to verify rebuilds
              log("Widget that rebuilds: $value");
              log("Widget that rebuilds: $value");
              return Column(
                children: [
                  Text("Widget that rebuilds: $value"),
                  noRebuildable(
                    const NonRebuildWidget(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Verify initial text
    expect(find.text("Widget that rebuilds: 0"), findsOneWidget);
    expect(find.text("Widget that doesn't rebuild"), findsOneWidget);
    expect(rebuildCount, 1); // Has been built once

    // Change the ValueNotifier value
    valueNotifier.updateState(1);
    await tester.pump(); // Update the UI

    // Verify that the rebuilding widget has changed
    expect(find.text("Widget that rebuilds: 1"), findsOneWidget);

    // Verificar que el widget no se ha reconstruido
    expect(rebuildCount, 2); // Should have incremented only once
  });
}

final ReactiveNotifier<int> valueNotifier = ReactiveNotifier(() => 0);

class NonRebuildWidget extends StatelessWidget {
  const NonRebuildWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const Text("Widget that doesn't rebuild");
  }
}
