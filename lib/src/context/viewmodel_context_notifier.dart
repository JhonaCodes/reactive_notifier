import 'dart:developer';
import 'package:flutter/widgets.dart';

/// Context notifier for ViewModels - provides automatic BuildContext access
/// Enables seamless migration from other state managers like Riverpod
/// No initialization required - works automatically with ReactiveBuilder widgets
class ViewModelContextNotifier {
  static BuildContext? _currentContext;
  static final Set<String> _activeBuilders = {};
  
  /// Internal method called by builders when they mount
  /// Automatically registers context without user intervention
  static void _registerContext(BuildContext context, String builderType) {
    _currentContext = context;
    _activeBuilders.add(builderType);
    
    assert(() {
      log('''
📱 ViewModelContextNotifier: Context registered
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Builder: $builderType
Widget: ${context.widget.runtimeType}
Active builders: ${_activeBuilders.length}
Context available: ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
      return true;
    }());
  }
  
  /// Internal method called by builders when they dispose
  /// Automatically cleans up context when no builders are active
  static void _unregisterContext(String builderType) {
    _activeBuilders.remove(builderType);
    
    assert(() {
      log('''
🗑️ ViewModelContextNotifier: Builder unregistered
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Builder: $builderType
Remaining builders: ${_activeBuilders.length}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
      return true;
    }());
    
    // Clear context only when no builders are active
    if (_activeBuilders.isEmpty) {
      _currentContext = null;
      
      assert(() {
        log('''
🔄 ViewModelContextNotifier: Context cleared
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Reason: No active builders remaining
Context available: ✗
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
        return true;
      }());
    }
  }
  
  /// Get current BuildContext - used by ViewModels
  /// Returns null if no ReactiveBuilder is currently active
  static BuildContext? get currentContext => _currentContext;
  
  /// Check if context is available
  static bool get hasContext => _currentContext != null;
  
  /// Get active builders count for debugging
  static int get activeBuilders => _activeBuilders.length;
  
  /// Global cleanup for testing and disposal
  static void cleanup() {
    final hadContext = _currentContext != null;
    final builderCount = _activeBuilders.length;
    
    _currentContext = null;
    _activeBuilders.clear();
    
    assert(() {
      log('''
🧹 ViewModelContextNotifier: Global cleanup completed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Context cleared: ${hadContext ? '✓' : 'already null'}
Builders cleared: $builderCount
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());
  }
}

/// Mixin that provides organic context access to ViewModels
/// Add this to ViewModel<T> and AsyncViewModelImpl<T> base classes
/// No setup required - context is automatically available when builders are active
mixin ViewModelContextProvider {
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
  BuildContext? get context => ViewModelContextNotifier.currentContext;
  
  /// Check if context is currently available
  /// Useful for conditional context-dependent operations
  bool get hasContext => ViewModelContextNotifier.hasContext;
  
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
ViewModel: ${runtimeType}

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
}

/// Internal extensions for builder integration
/// These methods are called automatically by ReactiveBuilder widgets
extension ViewModelContextBuilderIntegration on BuildContext {
  /// Register this context for ViewModel access
  /// Called automatically by builders on initState()
  void registerForViewModels(String builderType) {
    ViewModelContextNotifier._registerContext(this, builderType);
  }
  
  /// Unregister this context from ViewModel access  
  /// Called automatically by builders on dispose()
  void unregisterFromViewModels(String builderType) {
    ViewModelContextNotifier._unregisterContext(builderType);
  }
}