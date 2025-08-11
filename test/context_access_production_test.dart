import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// PRODUCTION-REALISTIC TESTS
/// These tests simulate real production scenarios without fallbacks
/// that could hide actual issues

/// Production-like ViewModel that REQUIRES context (no fallback)
class ProductionAuthViewModel extends ViewModel<AuthState> {
  ProductionAuthViewModel() : super(AuthState.initial());

  @override
  void init() {
    // Real production code would REQUIRE context for Riverpod migration
    if (!hasContext) {
      throw StateError('ProductionAuthViewModel REQUIRES context for Riverpod migration');
    }
    
    // Initialize with basic state first
    updateSilently(AuthState(
      isAuthenticated: false,
      userTheme: 'initializing',
      contextAvailable: true,
    ));
    
    // Use postFrameCallback for safe context access (PRODUCTION PATTERN)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isDisposed && hasContext) {
        try {
          // NOW we can safely access Theme and other InheritedWidgets
          final theme = Theme.of(requireContext('Riverpod migration'));
          final isDarkMode = theme.brightness == Brightness.dark;
          
          updateState(AuthState(
            isAuthenticated: false,
            userTheme: isDarkMode ? 'dark' : 'light',
            contextAvailable: true,
          ));
        } catch (e) {
          // In production, handle context access errors properly
          updateState(AuthState(
            isAuthenticated: false,
            userTheme: 'error',
            contextAvailable: false,
          ));
        }
      }
    });
  }
}

/// Production-like AsyncViewModel that REQUIRES context
class ProductionDataViewModel extends AsyncViewModelImpl<UserData> {
  ProductionDataViewModel() : super(AsyncState.initial());

  @override
  Future<UserData> init() async {
    // Real production: MUST have context for migration
    if (!hasContext) {
      throw StateError('ProductionDataViewModel REQUIRES context for Provider migration');
    }

    // Return a completer that will be resolved after postFrameCallback
    final completer = Completer<UserData>();
    
    // Use postFrameCallback for safe context access (PRODUCTION PATTERN)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!isDisposed && hasContext) {
        try {
          // NOW we can safely access MediaQuery and other InheritedWidgets
          final mediaQuery = MediaQuery.of(requireContext('Provider migration'));
          final screenSize = mediaQuery.size;
          
          // Simulate sync operation (no timers in test)
          // In real production, this would be an async API call
          
          final userData = UserData(
            name: 'Test User',
            screenWidth: screenSize.width,
            screenHeight: screenSize.height,
          );
          
          if (!completer.isCompleted) {
            completer.complete(userData);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      }
    });
    
    return completer.future;
  }
}

/// Data models
class AuthState {
  final bool isAuthenticated;
  final String userTheme;
  final bool contextAvailable;
  
  const AuthState({
    required this.isAuthenticated,
    required this.userTheme,
    required this.contextAvailable,
  });
  
  static AuthState initial() => const AuthState(
    isAuthenticated: false,
    userTheme: 'unknown',
    contextAvailable: false,
  );
}

class UserData {
  final String name;
  final double screenWidth;
  final double screenHeight;
  
  UserData({
    required this.name,
    required this.screenWidth,
    required this.screenHeight,
  });
}

/// Services
mixin ProductionAuthService {
  static ReactiveNotifier<ProductionAuthViewModel>? _instance;
  
  static ReactiveNotifier<ProductionAuthViewModel> get instance {
    _instance ??= ReactiveNotifier<ProductionAuthViewModel>(ProductionAuthViewModel.new);
    return _instance!;
  }
  
  static ReactiveNotifier<ProductionAuthViewModel> createNew() {
    _instance = ReactiveNotifier<ProductionAuthViewModel>(ProductionAuthViewModel.new);
    return _instance!;
  }
}

mixin ProductionDataService {
  static ReactiveNotifier<ProductionDataViewModel>? _instance;
  
  static ReactiveNotifier<ProductionDataViewModel> get instance {
    _instance ??= ReactiveNotifier<ProductionDataViewModel>(ProductionDataViewModel.new);
    return _instance!;
  }
  
  static ReactiveNotifier<ProductionDataViewModel> createNew() {
    _instance = ReactiveNotifier<ProductionDataViewModel>(ProductionDataViewModel.new);
    return _instance!;
  }
}

void main() {
  group('Production Context Access Tests - NO FALLBACKS', () {
    setUp(() {
      ReactiveNotifier.cleanup();
      ProductionAuthService.createNew();
      ProductionDataService.createNew();
    });

    testWidgets('ViewModel MUST receive context in production scenario', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Scaffold(
            body: ReactiveViewModelBuilder<ProductionAuthViewModel, AuthState>(
              viewmodel: ProductionAuthService.instance.notifier,
              build: (state, viewModel, keep) {
                return Column(
                  children: [
                    Text('Theme: ${state.userTheme}'),
                    Text('Context Available: ${state.contextAvailable}'),
                    Text('HasContext VM: ${viewModel.hasContext}'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Wait for postFrameCallback to complete
      await tester.pump();
      
      // STRICT assertions - must work exactly as expected
      expect(find.text('Theme: dark'), findsOneWidget);
      expect(find.text('Context Available: true'), findsOneWidget);
      expect(find.text('HasContext VM: true'), findsOneWidget);
      
      // Verify ViewModel actually has context
      final vm = ProductionAuthService.instance.notifier;
      expect(vm.hasContext, isTrue);
      expect(vm.context, isNotNull);
    });

    testWidgets('AsyncViewModel MUST receive context in production scenario', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: Scaffold(
              body: ReactiveAsyncBuilder<ProductionDataViewModel, UserData>(
                notifier: ProductionDataService.instance.notifier,
                onData: (data, viewModel, keep) {
                  return Column(
                    children: [
                      Text('Name: ${data.name}'),
                      Text('Width: ${data.screenWidth.toInt()}'),
                      Text('Height: ${data.screenHeight.toInt()}'),
                      Text('HasContext: ${viewModel.hasContext}'),
                    ],
                  );
                },
                onLoading: () => const CircularProgressIndicator(),
                onError: (error, stack) => Text('ERROR: $error'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // STRICT assertions - must work exactly as expected
      expect(find.text('Name: Test User'), findsOneWidget);
      expect(find.text('Width: 800'), findsOneWidget);
      expect(find.text('Height: 600'), findsOneWidget);
      expect(find.text('HasContext: true'), findsOneWidget);
      
      // Verify AsyncViewModel actually has context
      final vm = ProductionDataService.instance.notifier;
      expect(vm.hasContext, isTrue);
      expect(vm.context, isNotNull);
    });

    test('ViewModel WITHOUT builder stores context requirement', () {
      // Create ViewModel outside widget tree - it should not fail immediately
      // But should be marked as needing context
      final vm = ProductionAuthViewModel();
      
      // Should not have context
      expect(vm.hasContext, isFalse);
      expect(vm.context, isNull);
      
      // Should fail when trying to access context
      expect(
        () => vm.requireContext('test operation'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('BuildContext Required But Not Available'),
        )),
      );
    });

    testWidgets('AsyncViewModel WITHOUT builder MUST fail gracefully', (tester) async {
      // Create AsyncViewModel outside widget tree
      final vm = ProductionDataViewModel();
      
      // Should fail when trying to initialize without context
      expect(
        () => vm.init(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('REQUIRES context'),
        )),
      );
    });

    testWidgets('Context cleanup works correctly in production', (tester) async {
      // Build widget with context
      await tester.pumpWidget(
        MaterialApp(
          home: ReactiveViewModelBuilder<ProductionAuthViewModel, AuthState>(
            viewmodel: ProductionAuthService.instance.notifier,
            build: (state, viewModel, keep) => Text('Test'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      final vm = ProductionAuthService.instance.notifier;
      expect(vm.hasContext, isTrue);

      // Remove widget - context should be cleaned up
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Text('No Builder')),
      ));

      await tester.pumpAndSettle();
      
      // Context should now be null
      expect(vm.hasContext, isFalse);
      expect(vm.context, isNull);
    });

    testWidgets('Multiple builders share context correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Expanded(
                child: ReactiveViewModelBuilder<ProductionAuthViewModel, AuthState>(
                  viewmodel: ProductionAuthService.instance.notifier,
                  build: (state, viewModel, keep) => Text('Auth: ${state.userTheme}'),
                ),
              ),
              Expanded(
                child: ReactiveAsyncBuilder<ProductionDataViewModel, UserData>(
                  notifier: ProductionDataService.instance.notifier,
                  onData: (data, viewModel, keep) => Text('Data: ${data.name}'),
                  onLoading: () => const Text('Loading'),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      final authVM = ProductionAuthService.instance.notifier;
      final dataVM = ProductionDataService.instance.notifier;
      
      // Both should have context
      expect(authVM.hasContext, isTrue);
      expect(dataVM.hasContext, isTrue);
      
      // Context should be the same instance
      expect(authVM.context, equals(dataVM.context));
    });

    test('requireContext provides descriptive errors', () {
      final vm = ProductionAuthViewModel();
      
      expect(
        () => vm.requireContext('test operation'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('BuildContext Required But Not Available'),
            contains('test operation'),
          ),
        )),
      );
    });
  });
}