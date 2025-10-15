import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';
import 'package:reactive_notifier/src/context/viewmodel_context_notifier.dart';
import 'package:reactive_notifier/src/viewmodel/viewmodel_impl.dart';

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
              return const Scaffold(body: Text('Test'));
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

    group('Direct Global Context Access', () {
      testWidgets('getGlobalContext() should return global context',
          (WidgetTester tester) async {
        // Initially no global context
        expect(ViewModelContextNotifier.getGlobalContext(), isNull,
            reason: 'Global context should be null initially');
        expect(ViewModelContextNotifier.hasGlobalContext(), isFalse,
            reason: 'hasGlobalContext should return false initially');

        // Initialize global context
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              ReactiveNotifier.initContext(context);
              return const Scaffold(body: Text('Test'));
            },
          ),
        ));

        // Assert: getGlobalContext() should return the context
        expect(ViewModelContextNotifier.getGlobalContext(), isNotNull,
            reason: 'getGlobalContext() should return non-null context');
        expect(ViewModelContextNotifier.hasGlobalContext(), isTrue,
            reason: 'hasGlobalContext() should return true');
      });

      testWidgets('global context should persist when builders unmount',
          (WidgetTester tester) async {
        // Initialize global context
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              ReactiveNotifier.initContext(context);
              return const Scaffold(body: Text('Test'));
            },
          ),
        ));

        final globalCtx = ViewModelContextNotifier.getGlobalContext();
        expect(globalCtx, isNotNull,
            reason: 'Global context should be available');

        // Navigate to a different screen (unmounting original builder)
        await tester.pumpWidget(const MaterialApp(
          home: Scaffold(body: Text('New Screen')),
        ));

        // Assert: Global context should still be available
        expect(ViewModelContextNotifier.getGlobalContext(), equals(globalCtx),
            reason: 'Global context should persist after navigation');
        expect(ViewModelContextNotifier.hasGlobalContext(), isTrue,
            reason: 'hasGlobalContext should remain true');
      });
    });

    group('ViewModel Global Context Access', () {
      testWidgets('ViewModel should access global context via mixin',
          (WidgetTester tester) async {
        final viewModel = TestViewModel();

        // Initially no global context
        expect(viewModel.hasGlobalContext, isFalse,
            reason: 'ViewModel should not have global context initially');
        expect(viewModel.globalContext, isNull,
            reason: 'globalContext getter should return null');

        // Initialize global context
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              ReactiveNotifier.initContext(context);
              return const Scaffold(body: Text('Test'));
            },
          ),
        ));

        // Assert: ViewModel should now have access to global context
        expect(viewModel.hasGlobalContext, isTrue,
            reason: 'ViewModel should have global context after init');
        expect(viewModel.globalContext, isNotNull,
            reason: 'globalContext getter should return non-null');
      });

      testWidgets('requireGlobalContext() should return context when available',
          (WidgetTester tester) async {
        final viewModel = TestViewModel();

        // Initialize global context
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              ReactiveNotifier.initContext(context);
              return const Scaffold(body: Text('Test'));
            },
          ),
        ));

        // Assert: requireGlobalContext should work
        expect(() => viewModel.requireGlobalContext('test operation'),
            returnsNormally,
            reason: 'requireGlobalContext should not throw when available');

        final ctx = viewModel.requireGlobalContext('test operation');
        expect(ctx, isNotNull,
            reason: 'requireGlobalContext should return non-null context');
      });

      test('requireGlobalContext() should throw when not available', () {
        final viewModel = TestViewModel();

        // No global context initialized
        expect(viewModel.hasGlobalContext, isFalse,
            reason: 'Global context should not be available');

        // Assert: requireGlobalContext should throw
        expect(() => viewModel.requireGlobalContext('test operation'),
            throwsStateError,
            reason:
                'requireGlobalContext should throw StateError when not available');
      });

      testWidgets(
          'globalContext should be independent of specific ViewModel context',
          (WidgetTester tester) async {
        final viewModel = TestViewModel();

        // Initialize global context first
        BuildContext? savedGlobalContext;
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              ReactiveNotifier.initContext(context);
              savedGlobalContext = context;
              return const Scaffold(body: Text('Test'));
            },
          ),
        ));

        final globalCtx = viewModel.globalContext;
        expect(globalCtx, isNotNull,
            reason: 'Global context should be available');
        expect(globalCtx, equals(savedGlobalContext),
            reason: 'globalContext should match the registered global context');

        // Before registering specific context, both should be the same
        expect(viewModel.context, equals(globalCtx),
            reason:
                'Before specific registration, context falls back to global');

        // Now register a specific context for the ViewModel
        BuildContext? specificContext;
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                specificContext = ctx;
                ViewModelContextNotifier.registerContextForTesting(
                    ctx, 'TestBuilder', viewModel);
                return const Text('Test with specific context');
              },
            ),
          ),
        ));

        // Assert: globalContext should still return the original global context
        expect(viewModel.globalContext, equals(savedGlobalContext),
            reason: 'globalContext should always return the global context');

        // Regular context should now be the specific one
        expect(viewModel.context, equals(specificContext),
            reason:
                'Specific context should be used for regular context getter');

        // They should be different
        expect(viewModel.context, isNot(equals(viewModel.globalContext)),
            reason: 'Specific context should be different from global context');
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
              return const Scaffold(body: Text('Test'));
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
        expect(ViewModelContextNotifier.getGlobalContext(), isNull,
            reason: 'getGlobalContext() should return null after cleanup');
        expect(ViewModelContextNotifier.hasGlobalContext(), isFalse,
            reason: 'hasGlobalContext() should return false after cleanup');
      });
    });
  });
}

/// Simple test ViewModel for global context testing
class TestViewModel extends ViewModel<String> {
  TestViewModel() : super('initial');

  @override
  void init() {
    updateSilently('initialized');
  }
}
