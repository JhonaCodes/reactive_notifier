import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// Simple test to verify ViewModelContextNotifier works
class TestItem {
  final String message;
  final bool hasContextAccess;

  TestItem({required this.message, required this.hasContextAccess});

  factory TestItem.withContext() => TestItem(
    message: 'Created with context access',
    hasContextAccess: true,
  );

  factory TestItem.withoutContext() => TestItem(
    message: 'Created without context access',
    hasContextAccess: false,
  );

  @override
  String toString() => 'TestItem(message: $message, hasContext: $hasContextAccess)';
}

/// Test AsyncViewModel that uses context
class TestAsyncVM extends AsyncViewModelImpl<TestItem> {
  TestAsyncVM() : super(AsyncState.initial());

  @override
  Future<TestItem> init() async {
    // Simple context access test
    if (hasContext) {
      return TestItem.withContext();
    }
    return TestItem.withoutContext();
  }
}

/// Test regular ViewModel
class TestVM extends ViewModel<TestItem> {
  TestVM() : super(TestItem.withoutContext());

  @override
  void init() {
    // Test context access
    if (hasContext) {
      updateSilently(TestItem.withContext());
    } else {
      updateSilently(TestItem.withoutContext());
    }
  }
}

/// Test services
mixin TestAsyncService {
  static final ReactiveNotifier<TestAsyncVM> instance = 
    ReactiveNotifier<TestAsyncVM>(TestAsyncVM.new);
}

mixin TestService {
  static final ReactiveNotifier<TestVM> instance = 
    ReactiveNotifier<TestVM>(TestVM.new);
}

void main() {
  group('ViewModelContextNotifier Simple Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
    });

    testWidgets('AsyncViewModel receives context during init', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncVM, TestItem>(
              notifier: TestAsyncService.instance.notifier,
              onData: (item, vm, keep) {
                return Text(item.message);
              },
              onLoading: () => const Text('Loading...'),
            ),
          ),
        ),
      );

      // Wait for async init
      await tester.pumpAndSettle();

      // Verify context was available during init
      expect(find.text('Created with context access'), findsOneWidget);
      
      final vm = TestAsyncService.instance.notifier;
      expect(vm.hasContext, isTrue);
    });

    testWidgets('Regular ViewModel receives context during init', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactiveViewModelBuilder<TestVM, TestItem>(
              viewmodel: TestService.instance.notifier,
              build: (item, vm, keep) {
                return Text(item.message);
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify context was available during init
      expect(find.text('Created with context access'), findsOneWidget);
      
      final vm = TestService.instance.notifier;
      expect(vm.hasContext, isTrue);
    });

    test('ViewModel without UI has no context', () {
      final vm = TestVM();
      expect(vm.hasContext, isFalse);
      expect(vm.context, isNull);
      
      // Should have initialized with no context
      expect(vm.data.hasContextAccess, isFalse);
    });

    test('requireContext throws when no context available', () {
      final vm = TestVM();
      expect(
        () => vm.requireContext('test'),
        throwsA(isA<StateError>()),
      );
    });
  });
}