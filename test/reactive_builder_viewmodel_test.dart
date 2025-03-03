import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

// Mock de un StateNotifierImpl simple para testing
class MockStateNotifier extends ViewModel<String> {
  MockStateNotifier() : super('initial');

  void updateValue(String newValue) {
    updateState(newValue);
  }

  @override
  void init() {
    // TODO: implement init
  }
}

void main() {
  group('ReactiveViewModelBuilder Tests', () {
    late MockStateNotifier mockNotifier;

    setUp(() {
      mockNotifier = MockStateNotifier();
    });

    testWidgets('should build with initial state', (WidgetTester tester) async {
      // Arrange
      String? capturedState;

      await tester.pumpWidget(
        MaterialApp(
          home: ReactiveViewModelBuilder<String>(
            viewmodel: mockNotifier,
            builder: (state, keep) {
              capturedState = state;
              return Text(state);
            },
          ),
        ),
      );

      // Assert
      expect(find.text('initial'), findsOneWidget);
      expect(capturedState, equals('initial'));
    });

    testWidgets('should update when state changes',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ReactiveViewModelBuilder<String>(
            viewmodel: mockNotifier,
            builder: (state, keep) => Text(state),
          ),
        ),
      );

      // Act
      mockNotifier.updateValue('updated');
      // Esperamos el debounce
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(find.text('updated'), findsOneWidget);
    });

    testWidgets('should not rebuild kept widgets', (WidgetTester tester) async {
      // Arrange
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ReactiveViewModelBuilder<String>(
            viewmodel: mockNotifier,
            builder: (state, keep) {
              return Column(
                children: [
                  Text(state),
                  keep(
                    Builder(
                      builder: (context) {
                        buildCount++;
                        return const Text('Kept Widget');
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );

      // Initial build count
      final initialBuildCount = buildCount;

      // Act
      mockNotifier.updateValue('updated');
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(buildCount, equals(initialBuildCount));
      expect(find.text('Kept Widget'), findsOneWidget);
    });

    /// no more debouncing
    // testWidgets('should handle rapid updates with debouncing',
    //     (WidgetTester tester) async {
    //   await tester.pumpWidget(
    //     MaterialApp(
    //       home: ReactiveViewModelBuilder<String>(
    //         notifier: mockNotifier,
    //         builder: (state, keep) => Text(state),
    //       ),
    //     ),
    //   );
    //
    //   // Act - múltiples actualizaciones rápidas
    //   mockNotifier.updateValue('update1');
    //   mockNotifier.updateValue('update2');
    //   mockNotifier.updateValue('update3');
    //
    //   // Esperamos menos que el tiempo de debounce
    //   await tester.pump(const Duration(milliseconds: 50));
    //
    //   // No debería haber actualizado aún
    //   expect(find.text('initial'), findsOneWidget);
    //
    //   // Esperamos que complete el debounce
    //   await tester.pump(const Duration(milliseconds: 50));
    //
    //   // Assert - debería tener solo la última actualización
    //   expect(find.text('update3'), findsOneWidget);
    // });

    testWidgets('should cleanup properly when disposed',
        (WidgetTester tester) async {
      // Arrange
      final key = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: ReactiveViewModelBuilder<String>(
            key: key,
            viewmodel: mockNotifier,
            builder: (state, keep) => Text(state),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // Intentamos actualizar después de dispose
      mockNotifier.updateValue('after dispose');
      await tester.pump(const Duration(milliseconds: 100));

      // No debería causar errores
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle notifier changes', (WidgetTester tester) async {
      // Arrange
      final newNotifier = MockStateNotifier();

      await tester.pumpWidget(
        MaterialApp(
          home: ReactiveViewModelBuilder<String>(
            viewmodel: mockNotifier,
            builder: (state, keep) => Text(state),
          ),
        ),
      );

      // Act - cambiar el notifier
      await tester.pumpWidget(
        MaterialApp(
          home: ReactiveViewModelBuilder<String>(
            viewmodel: newNotifier,
            builder: (state, keep) => Text(state),
          ),
        ),
      );

      // El nuevo notifier debería funcionar
      newNotifier.updateValue('new notifier value');
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(find.text('new notifier value'), findsOneWidget);
    });
  });
}
