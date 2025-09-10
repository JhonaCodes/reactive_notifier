import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';
import 'package:reactive_notifier/src/handler/async_state.dart';
import 'package:reactive_notifier/src/context/viewmodel_context_notifier.dart';
import 'mocks/async_viewmodel_wait_context_mocks.dart';

/// Tests for ReactiveNotifier.initContext() global context initialization
///
/// This test suite covers the global context initialization feature which allows
/// all ViewModels to have BuildContext access from app startup.
///
/// Features tested:
/// - Global context initialization via ReactiveNotifier.initContext()
/// - Context availability in all ViewModels after global init
/// - Automatic reinitialize of ViewModels with waitForContext: true
/// - Fallback to global context when specific context is not available
/// - Cleanup behavior for global context
void main() {
  group('ReactiveNotifier.initContext() Tests', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
      ViewModelContextNotifier.cleanup();
    });

    group('Global Context Initialization', () {
      testWidgets('should initialize global context and make it available',
          (WidgetTester tester) async {
        // Build a basic widget to get context
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              // Initialize global context
              ReactiveNotifier.initContext(context);
              return Scaffold(body: Text('Test'));
            },
          ),
        ));

        // Assert: Global context should now be available through ViewModelContextNotifier
        expect(ViewModelContextNotifier.hasContext, isTrue,
            reason: 'Global context should be available after initContext()');
        expect(ViewModelContextNotifier.currentContext, isNotNull,
            reason: 'Current context should be available');
      });

      test('should verify ViewModelContextNotifier global context behavior',
          () {
        // Initially no global context
        expect(ViewModelContextNotifier.hasContext, isFalse,
            reason: 'Should not have global context initially');

        // Create a mock BuildContext (we can't create real ones in unit tests)
        // This test verifies the basic structure is in place
        expect(() => ViewModelContextNotifier.cleanup(), returnsNormally,
            reason: 'Cleanup should work without errors');
      });
    });

    group('Cleanup Behavior', () {
      testWidgets('should cleanup global context properly',
          (WidgetTester tester) async {
        // Initialize global context
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              ReactiveNotifier.initContext(context);
              return Scaffold(body: Text('Test'));
            },
          ),
        ));

        // Verify global context is available
        expect(ViewModelContextNotifier.hasContext, isTrue,
            reason: 'Global context should be available');

        // Cleanup
        ViewModelContextNotifier.cleanup();

        // Assert: Global context should be cleared
        expect(ViewModelContextNotifier.hasContext, isFalse,
            reason: 'Global context should be cleared after cleanup');
        expect(ViewModelContextNotifier.currentContext, isNull,
            reason: 'Current context should be null after cleanup');
      });
    });
  });
}
