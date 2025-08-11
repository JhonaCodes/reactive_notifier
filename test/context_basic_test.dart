import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// Ultra simple test para validar que el context access funciona
class SimpleTestVM extends AsyncViewModelImpl<String> {
  SimpleTestVM() : super(AsyncState.initial());

  @override
  Future<String> init() async {
    if (hasContext) {
      return 'HAS_CONTEXT';
    }
    return 'NO_CONTEXT';
  }
}

void main() {
  testWidgets('Context access works in AsyncViewModel', (tester) async {
    // No cleanup - solo test directo
    
    final vm = SimpleTestVM();
    final notifier = ReactiveNotifier<SimpleTestVM>(() => vm);
    
    await tester.pumpWidget(
      MaterialApp(
        home: ReactiveAsyncBuilder<SimpleTestVM, String>(
          notifier: notifier.notifier,
          onData: (data, viewModel, keep) => Text(data),
          onLoading: () => const Text('Loading'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    // Si funciona, deberíamos ver "HAS_CONTEXT"
    expect(find.text('HAS_CONTEXT'), findsOneWidget);
  });
}