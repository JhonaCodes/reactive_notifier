import 'dart:developer';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

ReactiveNotifier<int> state = ReactiveNotifier<int>(() => 0);

void main() {
  group('ReactiveBuilder Golden Tests', () {
    goldenTest(
      'ReactiveBuilder should default value',
      fileName: 'golden_reactive_builder_default_test',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 600),
        children: [
          GoldenTestScenario(
            name: 'Change value 0',
            child: ReactiveBuilder(
                notifier: state,
                builder: (value, child) {
                  return Column(
                    children: [
                      Text("Widget que se recontruye $value"),
                      child(const Text("Mi widget que no se recontruye")),
                      Text("Widget que se recontruye $value"),
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
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 600),
        children: [
          GoldenTestScenario(
            name: 'Change value 200',
            child: ReactiveBuilder<int>(
                notifier: state,
                builder: (value, child) {
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
            builder: (value, noRebuildable) {
              rebuildCount++; // Contador para verificar reconstrucciones
              log("Widget que se reconstruye: $value");
              log("Widget que se reconstruye: $value");
              return Column(
                children: [
                  Text("Widget que se reconstruye: $value"),
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

    // Verificar el texto inicial
    expect(find.text("Widget que se reconstruye: 0"), findsOneWidget);
    expect(find.text("Widget que no se reconstruye"), findsOneWidget);
    expect(rebuildCount, 1); // Se ha construido una vez

    // Cambiar el valor del ValueNotifier
    valueNotifier.updateState(1);
    await tester.pump(); // Actualizar la UI

    // Verificar que el widget que se reconstruye ha cambiado
    expect(find.text("Widget que se reconstruye: 1"), findsOneWidget);

    // Verificar que el widget no se ha reconstruido
    expect(rebuildCount, 2); // Se debería haber incrementado solo una vez
  });
}

final ReactiveNotifier<int> valueNotifier = ReactiveNotifier(() => 0);

class NonRebuildWidget extends StatelessWidget {
  const NonRebuildWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const Text("Widget que no se reconstruye");
  }
}
