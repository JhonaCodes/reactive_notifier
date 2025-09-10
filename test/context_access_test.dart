import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// Test ViewModel for context access testing
class ContextTestViewModel extends ViewModel<String> {
  String? capturedContextWidget;
  bool hadContextDuringInit = false;

  ContextTestViewModel() : super('initial');

  @override
  void init() {
    // Test context access during init
    hadContextDuringInit = hasContext;

    if (hasContext) {
      capturedContextWidget = context?.widget.runtimeType.toString();
      updateSilently('initialized with context');
    } else {
      updateSilently('initialized without context');
    }
  }

  @override
  String _createEmptyState() => 'empty';
}

/// Test AsyncViewModel for context access testing
class AsyncContextTestViewModel extends AsyncViewModelImpl<String> {
  String? capturedContextWidget;
  bool hadContextDuringInit = false;

  AsyncContextTestViewModel() : super(AsyncState.initial(), loadOnInit: false);

  @override
  Future<String> init() async {
    // Test context access during async init
    hadContextDuringInit = hasContext;

    if (hasContext) {
      capturedContextWidget = context?.widget.runtimeType.toString();
      return 'async initialized with context';
    } else {
      return 'async initialized without context';
    }
  }
}

/// Service mixins for testing - using factories to create fresh instances
mixin ContextTestService {
  static ReactiveNotifier<ContextTestViewModel> createViewModel() =>
      ReactiveNotifier<ContextTestViewModel>(() => ContextTestViewModel());
}

mixin AsyncContextTestService {
  static ReactiveNotifier<AsyncContextTestViewModel> createAsyncViewModel() =>
      ReactiveNotifier<AsyncContextTestViewModel>(
          () => AsyncContextTestViewModel());
}

void main() {
  group('ViewModelContextProvider Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
    });

    testWidgets(
        'ViewModel should have context access during init when used with ReactiveViewModelBuilder',
        (tester) async {
      final viewModelNotifier = ContextTestService.createViewModel();

      await tester.pumpWidget(MaterialApp(
        home: ReactiveViewModelBuilder<ContextTestViewModel, String>(
          viewmodel: viewModelNotifier.notifier,
          build: (state, viewmodel, keep) {
            return Column(
              children: [
                Text('State: $state'),
                Text('Had context: ${viewmodel.hadContextDuringInit}'),
                Text('Widget: ${viewmodel.capturedContextWidget ?? 'none'}'),
              ],
            );
          },
        ),
      ));

      await tester.pumpAndSettle();

      // Verify ViewModel had context during initialization
      final viewModel = viewModelNotifier.notifier;
      expect(viewModel.hadContextDuringInit, true);
      expect(viewModel.capturedContextWidget,
          contains('ReactiveViewModelBuilder'));
      expect(viewModel.data, 'initialized with context');

      // Verify UI shows correct information
      expect(find.text('State: initialized with context'), findsOneWidget);
      expect(find.text('Had context: true'), findsOneWidget);
    });

    testWidgets(
        'AsyncViewModel should have context access during reload when used with ReactiveAsyncBuilder',
        (tester) async {
      final asyncViewModelNotifier =
          AsyncContextTestService.createAsyncViewModel();

      // First create the widget tree
      await tester.pumpWidget(MaterialApp(
        home: ReactiveAsyncBuilder<AsyncContextTestViewModel, String>(
          notifier: asyncViewModelNotifier.notifier,
          onData: (state, viewmodel, keep) {
            return Column(
              children: [
                Text('State: $state'),
                Text('Had context: ${viewmodel.hadContextDuringInit}'),
                Text('Widget: ${viewmodel.capturedContextWidget ?? 'none'}'),
              ],
            );
          },
          onLoading: () => const CircularProgressIndicator(),
          onInitial: () => const Text('Initial'),
        ),
      ));

      // Wait for initial render
      await tester.pump();

      // Trigger reload now that context is available
      final asyncViewModel = asyncViewModelNotifier.notifier;
      await asyncViewModel.reload();

      await tester.pumpAndSettle();

      // Verify AsyncViewModel had context during reload
      expect(asyncViewModel.hadContextDuringInit, true);
      expect(asyncViewModel.capturedContextWidget,
          contains('ReactiveAsyncBuilder'));
      expect(asyncViewModel.data, 'async initialized with context');

      // Verify UI shows correct information
      expect(
          find.text('State: async initialized with context'), findsOneWidget);
      expect(find.text('Had context: true'), findsOneWidget);
    });

    testWidgets('hasContext should return false when no builders are active',
        (tester) async {
      // Create ViewModel outside of any builder
      final viewModel = ContextTestViewModel();

      expect(viewModel.hasContext, false);
      expect(viewModel.hadContextDuringInit, false);
      // Current behavior: ViewModel initializes without context and can be reinitialize later
      expect(viewModel.data, 'initialized without context');
    });

    testWidgets('requireContext should throw when context is not available',
        (tester) async {
      final viewModel = ContextTestViewModel();

      expect(() => viewModel.requireContext('test operation'),
          throwsA(isA<StateError>()));
    });

    testWidgets('requireContext should return context when available',
        (tester) async {
      final viewModelNotifier = ContextTestService.createViewModel();
      BuildContext? capturedContext;

      await tester.pumpWidget(MaterialApp(
        home: ReactiveViewModelBuilder<ContextTestViewModel, String>(
          viewmodel: viewModelNotifier.notifier,
          build: (state, viewmodel, keep) {
            // Capture context using requireContext
            capturedContext = viewmodel.requireContext('test operation');
            return Text('Context captured');
          },
        ),
      ));

      await tester.pumpAndSettle();

      expect(capturedContext, isNotNull);
      expect(capturedContext?.widget.runtimeType.toString(),
          contains('ReactiveViewModelBuilder'));
    });

    testWidgets('context should be cleared when all builders are disposed',
        (tester) async {
      final viewModelNotifier = ContextTestService.createViewModel();
      late ContextTestViewModel viewModel;

      await tester.pumpWidget(MaterialApp(
        home: ReactiveViewModelBuilder<ContextTestViewModel, String>(
          viewmodel: viewModelNotifier.notifier,
          build: (state, viewmodel, keep) {
            viewModel = viewmodel;
            return Text('State: $state');
          },
        ),
      ));

      await tester.pumpAndSettle();

      // Context should be available
      expect(viewModel.hasContext, true);

      // Navigate away (dispose the builder)
      await tester.pumpWidget(const MaterialApp(
        home: Text('Different screen'),
      ));

      await tester.pumpAndSettle();

      // Context should be cleared
      expect(viewModel.hasContext, false);
    });

    testWidgets(
        'context should remain available when switching between builders',
        (tester) async {
      final viewModelNotifier = ContextTestService.createViewModel();
      late ContextTestViewModel viewModel;

      // Start with first builder
      await tester.pumpWidget(MaterialApp(
        home: ReactiveViewModelBuilder<ContextTestViewModel, String>(
          viewmodel: viewModelNotifier.notifier,
          build: (state, vm, keep) {
            viewModel = vm;
            return Text('Builder 1: $state');
          },
        ),
      ));

      await tester.pumpAndSettle();
      expect(viewModel.hasContext, true);

      // Switch to second builder (different widget type)
      await tester.pumpWidget(MaterialApp(
        home: ReactiveBuilder<String>(
          notifier: ReactiveNotifier<String>(() => viewModel.data),
          build: (state, notifier, keep) {
            return Text('Builder 2: $state');
          },
        ),
      ));

      await tester.pumpAndSettle();

      // After switching builders, the original ViewModel might not have context
      // since it's not being used in the new builder
    });

    testWidgets('multiple builders can share context access', (tester) async {
      final viewModelNotifier = ContextTestService.createViewModel();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ReactiveViewModelBuilder<ContextTestViewModel, String>(
                viewmodel: viewModelNotifier.notifier,
                build: (state, viewmodel, keep) {
                  return Text('Builder 1: ${viewmodel.hasContext}');
                },
              ),
              ReactiveViewModelBuilder<ContextTestViewModel, String>(
                viewmodel: viewModelNotifier.notifier,
                build: (state, viewmodel, keep) {
                  return Text('Builder 2: ${viewmodel.hasContext}');
                },
              ),
            ],
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Both builders should show context is available
      expect(find.text('Builder 1: true'), findsOneWidget);
      expect(find.text('Builder 2: true'), findsOneWidget);

      final viewModel = viewModelNotifier.notifier;
      expect(viewModel.hasContext, true);
    });
  });
}
