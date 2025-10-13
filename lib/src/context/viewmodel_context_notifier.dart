import 'dart:developer';
import 'package:flutter/widgets.dart';

/// Context notifier for ViewModels - provides automatic BuildContext access
/// Enables seamless migration from other state managers like Riverpod
/// No initialization required - works automatically with ReactiveBuilder widgets
class ViewModelContextNotifier {
  // Map of ViewModel instance hashCode to its BuildContext
  static final Map<int, BuildContext> _contexts = {};

  // Map of ViewModel instance hashCode to Set of builder types using it
  static final Map<int, Set<String>> _viewModelBuilders = {};

  // For backward compatibility - keeps track of last registered context
  static BuildContext? _lastRegisteredContext;

  // Global context initialized via ReactiveNotifier.initContext()
  static BuildContext? _globalContext;

  /// Internal method called by builders when they mount
  /// Automatically registers context without user intervention
  static void _registerContext(
      BuildContext context, String builderType, Object? viewModel) {
    final vmKey = viewModel?.hashCode ?? 0;

    // Handle global context registration (when viewModel is null and builderType indicates global init)
    if (viewModel == null && builderType == 'ReactiveNotifier.initContext') {
      _globalContext = context;
      _lastRegisteredContext = context;
      assert(() {
        log('''
🌍 ViewModelContextNotifier: Global context registered
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Builder: $builderType
Widget: ${context.widget.runtimeType}
Global context now available for all ViewModels
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
        return true;
      }());
      return;
    }

    // Store context for this specific ViewModel
    _contexts[vmKey] = context;
    _lastRegisteredContext = context;

    // Track which builders are using this ViewModel
    _viewModelBuilders[vmKey] ??= {};
    _viewModelBuilders[vmKey]!.add(builderType);

    assert(() {
      log('''
📱 ViewModelContextNotifier: Context registered
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Builder: $builderType
Widget: ${context.widget.runtimeType}
ViewModel: ${viewModel?.runtimeType ?? 'None'} (key: $vmKey)
Active builders for VM: ${_viewModelBuilders[vmKey]?.length ?? 0}
Total contexts: ${_contexts.length}
Context available: ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
      return true;
    }());
  }

  /// Internal method called by builders when they dispose
  /// Automatically cleans up context when no builders are active
  static void _unregisterContext(String builderType, Object? viewModel) {
    final vmKey = viewModel?.hashCode ?? 0;

    // Remove this builder from the ViewModel's builder set
    _viewModelBuilders[vmKey]?.remove(builderType);

    assert(() {
      log('''
🗑️ ViewModelContextNotifier: Builder unregistered
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Builder: $builderType
ViewModel: ${viewModel?.runtimeType ?? 'None'} (key: $vmKey)
Remaining builders for VM: ${_viewModelBuilders[vmKey]?.length ?? 0}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
      return true;
    }());

    // Clear context only when no builders are active for this ViewModel
    if (_viewModelBuilders[vmKey]?.isEmpty ?? true) {
      _contexts.remove(vmKey);
      _viewModelBuilders.remove(vmKey);

      // Clear last registered if it was this one
      if (_contexts.isEmpty) {
        _lastRegisteredContext = null;
      }

      assert(() {
        log('''
🔄 ViewModelContextNotifier: Context cleared for ViewModel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ViewModel key: $vmKey
Reason: No active builders remaining for this ViewModel
Total contexts remaining: ${_contexts.length}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
        return true;
      }());
    }
  }

  /// Get BuildContext for a specific ViewModel instance
  static BuildContext? getContextForViewModel(Object? viewModel) {
    if (viewModel == null) return _lastRegisteredContext ?? _globalContext;
    // Try specific ViewModel context first, then fall back to global context
    return _contexts[viewModel.hashCode] ?? _globalContext;
  }

  /// Check if context is available for a specific ViewModel
  static bool hasContextForViewModel(Object? viewModel) {
    if (viewModel == null) {
      return _lastRegisteredContext != null || _globalContext != null;
    }
    // Check if specific ViewModel has context or if global context is available
    return _contexts.containsKey(viewModel.hashCode) || _globalContext != null;
  }

  /// Get global context directly (bypassing specific ViewModel context)
  /// Useful for Riverpod/Provider migration where persistent context is needed
  /// Returns the context initialized via ReactiveNotifier.initContext()
  ///
  /// Usage:
  /// ```dart
  /// if (ViewModelContextNotifier.hasGlobalContext()) {
  ///   final ctx = ViewModelContextNotifier.getGlobalContext()!;
  ///   final container = ProviderScope.containerOf(ctx);
  /// }
  /// ```
  static BuildContext? getGlobalContext() => _globalContext;

  /// Check if global context is available
  /// Global context is set via ReactiveNotifier.initContext()
  /// and remains available throughout the app lifecycle
  static bool hasGlobalContext() => _globalContext != null;

  /// Get current BuildContext - for backward compatibility
  /// Returns the last registered context or global context
  static BuildContext? get currentContext =>
      _lastRegisteredContext ?? _globalContext;

  /// Check if any context is available - for backward compatibility
  static bool get hasContext => _contexts.isNotEmpty || _globalContext != null;

  /// Get active builders count for debugging
  static int get activeBuilders =>
      _viewModelBuilders.values.fold<int>(0, (sum, set) => sum + set.length);

  /// Register context globally - used by ReactiveNotifier.initContext()
  /// This is a public method to allow external initialization
  static void registerGlobalContext(BuildContext context) {
    _registerContext(context, 'ReactiveNotifier.initContext', null);
  }

  /// Register context for specific ViewModel - used for testing
  /// This is a public method to allow test-specific registrations
  static void registerContextForTesting(
      BuildContext context, String builderType, Object? viewModel) {
    _registerContext(context, builderType, viewModel);
  }

  /// Global cleanup for testing and disposal
  static void cleanup() {
    final contextsCount = _contexts.length;
    final buildersCount = activeBuilders;
    final hasGlobalContext = _globalContext != null;

    _contexts.clear();
    _viewModelBuilders.clear();
    _lastRegisteredContext = null;
    _globalContext = null;

    assert(() {
      log('''
🧹 ViewModelContextNotifier: Global cleanup completed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Contexts cleared: $contextsCount
Builders cleared: $buildersCount
Global context cleared: $hasGlobalContext
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());
  }
}

/// Mixin that provides organic context access to ViewModels
/// Add this to ```ViewModel<T> and AsyncViewModelImpl<T>``` base classes
/// No setup required - context is automatically available when builders are active
mixin ViewModelContextService {
  /// Get current BuildContext if available
  /// Automatically provided when any ReactiveBuilder is mounted
  ///
  /// Usage in ViewModel:
  /// ```dart
  /// @override
  /// Future<TenderItem> init() async {
  ///   final currentContext = context;
  ///   if (currentContext != null) {
  ///     // Migration from Riverpod
  ///     final container = ProviderScope.containerOf(currentContext);
  ///     final data = container.read(myProvider);
  ///     return TenderItem.fromRiverpod(data);
  ///   }
  ///   return TenderItem.empty();
  /// }
  /// ```
  BuildContext? get context =>
      ViewModelContextNotifier.getContextForViewModel(this);

  /// Check if context is currently available
  /// Useful for conditional context-dependent operations
  bool get hasContext => ViewModelContextNotifier.hasContextForViewModel(this);

  /// Get context with descriptive error if unavailable
  /// Use when context is absolutely required for the operation
  ///
  /// ```dart
  /// @override
  /// Future<TenderItem> init() async {
  ///   final ctx = requireContext('Tender initialization');
  ///   final container = ProviderScope.containerOf(ctx);
  ///   return TenderItem.fromContainer(container);
  /// }
  /// ```
  BuildContext requireContext([String? operation]) {
    final currentContext = context;
    if (currentContext == null) {
      throw StateError('''
⚠️ BuildContext Required But Not Available
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Operation: ${operation ?? 'ViewModel operation'}
ViewModel: $runtimeType

💡 Context is not available when:
  1. No ReactiveBuilder widgets are currently mounted
  2. ViewModel.init() runs before any builder is active
  3. All builders have been disposed

✅ Solutions:
  1. Check hasContext first: if (hasContext) { ... }
  2. Move context logic to onResume() method
  3. Make context usage optional with null safety

🔍 Context is automatically provided by:
  - ReactiveBuilder<T>
  - ReactiveViewModelBuilder<VM,T>
  - ReactiveAsyncBuilder<VM,T>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');
    }
    return currentContext;
  }

  /// Get global BuildContext directly (bypassing specific ViewModel context)
  /// This context is persistent and remains available throughout app lifecycle
  /// Ideal for Riverpod/Provider migration where context stability is needed
  ///
  /// Usage in ViewModel:
  /// ```dart
  /// @override
  /// void init() {
  ///   if (hasGlobalContext) {
  ///     WidgetsBinding.instance.addPostFrameCallback((_) {
  ///       final container = ProviderScope.containerOf(globalContext!);
  ///       final data = container.read(userProvider);
  ///       updateState(UserModel.fromRiverpod(data));
  ///     });
  ///   }
  /// }
  /// ```
  BuildContext? get globalContext =>
      ViewModelContextNotifier.getGlobalContext();

  /// Check if global context is available
  /// Global context is set via ReactiveNotifier.initContext()
  /// and persists throughout the app lifecycle regardless of builder state
  bool get hasGlobalContext => ViewModelContextNotifier.hasGlobalContext();

  /// Get global context with descriptive error if unavailable
  /// Use when global context is absolutely required (e.g., Riverpod migration)
  ///
  /// ```dart
  /// @override
  /// void init() {
  ///   final container = ProviderScope.containerOf(
  ///     requireGlobalContext('Riverpod migration')
  ///   );
  ///   final userData = container.read(userProvider);
  ///   updateState(UserModel.fromRiverpod(userData));
  /// }
  /// ```
  BuildContext requireGlobalContext([String? operation]) {
    final ctx = globalContext;
    if (ctx == null) {
      throw StateError('''
⚠️ Global BuildContext Not Available
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Operation: ${operation ?? 'ViewModel operation'}
ViewModel: $runtimeType

💡 Global context is not available because:
  ReactiveNotifier.initContext(context) has not been called yet

✅ Solution - Initialize global context in your app root:
  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      // Initialize global context for all ViewModels
      ReactiveNotifier.initContext(context);

      return MaterialApp(
        home: HomePage(),
      );
    }
  }

🎯 Use Case - Perfect for Riverpod/Provider migration:
  Global context remains available throughout app lifecycle,
  even when specific builders mount/unmount during navigation.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');
    }
    return ctx;
  }
}

/// Internal extensions for builder integration
/// These methods are called automatically by ReactiveBuilder widgets
extension ViewModelContextBuilderIntegration on BuildContext {
  /// Register this context for ViewModel access
  /// Called automatically by builders on initState()
  void registerForViewModels(String builderType, [Object? viewModel]) {
    ViewModelContextNotifier._registerContext(this, builderType, viewModel);
  }

  /// Unregister this context from ViewModel access
  /// Called automatically by builders on dispose()
  void unregisterFromViewModels(String builderType, [Object? viewModel]) {
    ViewModelContextNotifier._unregisterContext(builderType, viewModel);
  }
}
