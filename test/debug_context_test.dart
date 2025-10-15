import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'package:reactive_notifier/src/context/viewmodel_context_notifier.dart';

/// Debug test to understand the timing issues
class DebugAsyncVM extends AsyncViewModelImpl<String> {
  DebugAsyncVM()
      : super(AsyncState.initial(), loadOnInit: false); // Don't auto-initialize

  @override
  Future<String> init() async {
    log('DebugAsyncVM.init() called, hasContext: $hasContext');
    if (hasContext) {
      log('Context available: ${context!.widget.runtimeType}');
      return 'init with context';
    }
    return 'init without context';
  }

  // Manual initialization method
  Future<void> manualInit() async {
    await reload(); // This will call init()
  }
}

mixin DebugService {
  static final ReactiveNotifier<DebugAsyncVM> instance =
      ReactiveNotifier<DebugAsyncVM>(DebugAsyncVM.new);
}

void main() {
  group('Debug Context Timing', () {
    setUp(() {
      ReactiveNotifier.cleanup();
    });

    testWidgets('Debug context registration timing', (tester) async {
      log('\n=== Starting test ===');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                log('Builder context: ${context.widget.runtimeType}');

                // Manually register context first
                context.registerForViewModels('DebugBuilder');

                // Now get the ViewModel
                final vm = DebugService.instance.notifier;
                log('ViewModel created, hasContext: ${vm.hasContext}');

                // Manually initialize now that context is available
                vm.manualInit();

                return ReactiveAsyncBuilder<DebugAsyncVM, String>(
                  notifier: vm,
                  onData: (data, viewModel, keep) {
                    log('onData called with: $data');
                    return Text(data);
                  },
                  onLoading: () {
                    log('onLoading called');
                    return const Text('Loading...');
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      log('=== Test completed ===\n');
    });
  });
}
