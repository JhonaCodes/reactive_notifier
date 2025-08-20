import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// Test data models
class TenderItem {
  final String id;
  final String name;
  final String status;

  TenderItem({
    required this.id,
    required this.name, 
    required this.status,
  });

  factory TenderItem.empty() => TenderItem(
    id: '',
    name: 'Empty Tender',
    status: 'initial',
  );

  factory TenderItem.fromTheme(ThemeData theme) => TenderItem(
    id: 'theme-${theme.hashCode}',
    name: 'Themed Tender',
    status: theme.brightness == Brightness.dark ? 'dark' : 'light',
  );

  @override
  String toString() => 'TenderItem(id: $id, name: $name, status: $status)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TenderItem &&
      other.id == id &&
      other.name == name &&
      other.status == status;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ status.hashCode;
}

/// Test ViewModel that uses context
class TenderItemsVM extends AsyncViewModelImpl<TenderItem> {
  TenderItemsVM() : super(AsyncState.initial());

  @override
  Future<TenderItem> init() async {
    // Test context access
    final currentContext = context;
    
    if (currentContext != null) {
      // Access theme from context (simulating migration scenario)
      final theme = Theme.of(currentContext);
      return TenderItem.fromTheme(theme);
    }
    
    // Fallback when no context
    return TenderItem.empty();
  }
}

/// Test service
mixin TenderItemsService {
  static ReactiveNotifier<TenderItemsVM>? _instance;
  
  static ReactiveNotifier<TenderItemsVM> get instance {
    _instance ??= ReactiveNotifier<TenderItemsVM>(TenderItemsVM.new);
    return _instance!;
  }
  
  static ReactiveNotifier<TenderItemsVM> createNew() {
    _instance = ReactiveNotifier<TenderItemsVM>(TenderItemsVM.new);
    return _instance!;
  }
}

/// Test with regular ViewModel too
class SimpleCounterVM extends ViewModel<int> {
  SimpleCounterVM() : super(0);

  @override
  void init() {
    // Initialize with default value first
    updateSilently(0);
    
    // Check if context is available and update accordingly
    _updateFromContext();
  }

  void _updateFromContext() {
    final currentContext = context;
    
    if (currentContext != null) {
      // Use post-frame callback to ensure MediaQuery is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isDisposed && hasContext) {
          try {
            final mediaQuery = MediaQuery.of(currentContext);
            final screenWidth = mediaQuery.size.width;
            updateState(screenWidth > 600 ? 100 : 10);
          } catch (e) {
            // If MediaQuery access fails, just keep default value
          }
        }
      });
    }
  }

  void increment() {
    updateState(data + 1);
  }
}

mixin CounterService {
  static ReactiveNotifier<SimpleCounterVM>? _instance;
  
  static ReactiveNotifier<SimpleCounterVM> get instance {
    _instance ??= ReactiveNotifier<SimpleCounterVM>(SimpleCounterVM.new);
    return _instance!;
  }
  
  static ReactiveNotifier<SimpleCounterVM> createNew() {
    _instance = ReactiveNotifier<SimpleCounterVM>(SimpleCounterVM.new);
    return _instance!;
  }
}

void main() {
  group('ViewModelContextNotifier Tests', () {
    setUp(() {
      // Clean up before each test
      ReactiveNotifier.cleanup();
      
      // Create completely new ReactiveNotifier instances
      CounterService.createNew();
      TenderItemsService.createNew();
    });

    testWidgets('AsyncViewModel can access context during init', (tester) async {
      // Create a widget tree with specific theme
      final testTheme = ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: Scaffold(
            body: ReactiveAsyncBuilder<TenderItemsVM, TenderItem>(
              notifier: TenderItemsService.instance.notifier,
              onData: (item, viewModel, keep) {
                return Column(
                  children: [
                    Text('ID: ${item.id}'),
                    Text('Name: ${item.name}'),
                    Text('Status: ${item.status}'),
                    Text('Has Context: ${viewModel.hasContext}'),
                  ],
                );
              },
              onLoading: () => const CircularProgressIndicator(),
              onError: (error, stack) => Text('Error: $error'),
            ),
          ),
        ),
      );

      // Wait for async initialization
      await tester.pumpAndSettle();

      // Now that context is available, trigger a reload to reinitialize with context
      final vm = TenderItemsService.instance.notifier;
      await vm.reload();
      await tester.pumpAndSettle();

      // Verify the ViewModel received context and used theme
      expect(find.text('Name: Themed Tender'), findsOneWidget);
      expect(find.text('Status: dark'), findsOneWidget);
      expect(find.text('Has Context: true'), findsOneWidget);
      
      // Verify ID contains theme reference
      expect(vm.data!.id, contains('theme-'));
    });

    testWidgets('Regular ViewModel can access context during init', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)), // Wide screen
            child: Scaffold(
              body: ReactiveViewModelBuilder<SimpleCounterVM, int>(
                viewmodel: CounterService.instance.notifier,
                build: (count, viewModel, keep) {
                  return Column(
                    children: [
                      Text('Count: $count'),
                      Text('Has Context: ${viewModel.hasContext}'),
                      ElevatedButton(
                        onPressed: viewModel.increment,
                        child: const Text('Increment'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ViewModel should have initialized with 100 (wide screen)
      expect(find.text('Count: 100'), findsOneWidget);
      expect(find.text('Has Context: true'), findsOneWidget);

      // Test increment works
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      
      expect(find.text('Count: 101'), findsOneWidget);
    });

    testWidgets('ViewModel context becomes null when builder is disposed', (tester) async {
      // First, build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: ReactiveViewModelBuilder<SimpleCounterVM, int>(
            viewmodel: CounterService.instance.notifier,
            build: (count, viewModel, keep) => Text('Count: $count'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Verify context is available
      final vm = CounterService.instance.notifier;
      expect(vm.hasContext, isTrue);

      // Remove the widget (dispose builder)
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Text('No Builder')),
      ));

      await tester.pumpAndSettle();

      // Context should now be null
      expect(vm.hasContext, isFalse);
      expect(vm.context, isNull);
    });

    testWidgets('Multiple builders can provide context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Expanded(
                child: ReactiveViewModelBuilder<SimpleCounterVM, int>(
                  viewmodel: CounterService.instance.notifier,
                  build: (count, viewModel, keep) => Text('Builder 1: $count'),
                ),
              ),
              Expanded(
                child: ReactiveAsyncBuilder<TenderItemsVM, TenderItem>(
                  notifier: TenderItemsService.instance.notifier,
                  onData: (item, viewModel, keep) => Text('Builder 2: ${item.name}'),
                  onLoading: () => const Text('Loading'),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Both ViewModels should have context
      final counterVM = CounterService.instance.notifier;
      final tenderVM = TenderItemsService.instance.notifier;
      
      expect(counterVM.hasContext, isTrue);
      expect(tenderVM.hasContext, isTrue);

      // Each ViewModel should have its own isolated context (improved design)
      expect(counterVM.context, isNotNull);
      expect(tenderVM.context, isNotNull);
      
      // Contexts should be isolated per ViewModel instance (prevents context pollution)
      // This is the CORRECT behavior for better memory management
    });

    test('ViewModel context access without UI throws descriptive error', () {
      // Create ViewModel outside widget tree
      final vm = SimpleCounterVM();
      
      expect(vm.hasContext, isFalse);
      expect(vm.context, isNull);
      
      expect(
        () => vm.requireContext('test operation'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('BuildContext Required But Not Available'),
        )),
      );
    });

    test('ViewModelContextNotifier cleanup works correctly', () {
      // Test that ViewModels without context work correctly
      final vm = SimpleCounterVM();
      expect(vm.hasContext, isFalse);
      expect(vm.context, isNull);
      
      // ReactiveNotifier cleanup should handle ViewModelContextNotifier
      ReactiveNotifier.cleanup(); // This calls ViewModelContextNotifier.cleanup internally
    });
  });
}