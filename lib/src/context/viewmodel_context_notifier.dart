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
  
  /// Internal method called by builders when they mount
  /// Automatically registers context without user intervention
  static void _registerContext(BuildContext context, String builderType, Object? viewModel) {
    final vmKey = viewModel?.hashCode ?? 0;
    
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
    if (viewModel == null) return _lastRegisteredContext;
    return _contexts[viewModel.hashCode];
  }
  
  /// Check if context is available for a specific ViewModel
  static bool hasContextForViewModel(Object? viewModel) {
    if (viewModel == null) return _lastRegisteredContext != null;
    return _contexts.containsKey(viewModel.hashCode);
  }
  
  /// Get current BuildContext - for backward compatibility
  /// Returns the last registered context or null
  static BuildContext? get currentContext => _lastRegisteredContext;
  
  /// Check if any context is available - for backward compatibility
  static bool get hasContext => _contexts.isNotEmpty;
  
  /// Get active builders count for debugging
  static int get activeBuilders => _viewModelBuilders.values
      .fold<int>(0, (sum, set) => sum + set.length);
  
  /// Global cleanup for testing and disposal
  static void cleanup() {
    final contextsCount = _contexts.length;
    final buildersCount = activeBuilders;
    
    _contexts.clear();
    _viewModelBuilders.clear();
    _lastRegisteredContext = null;
    
    assert(() {
      log('''
🧹 ViewModelContextNotifier: Global cleanup completed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Contexts cleared: $contextsCount
Builders cleared: $buildersCount
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());
  }
}

/// Mixin that provides organic context access to ViewModels
/// Add this to ViewModel<T> and AsyncViewModelImpl<T> base classes
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
  BuildContext? get context => ViewModelContextNotifier.getContextForViewModel(this);
  
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
  void registerForViewModels(String builderType, [Object? viewModel]) {
    ViewModelContextNotifier._registerContext(this, builderType, viewModel);
  }
  
  /// Unregister this context from ViewModel access  
  /// Called automatically by builders on dispose()
  void unregisterFromViewModels(String builderType, [Object? viewModel]) {
    ViewModelContextNotifier._unregisterContext(builderType, viewModel);
  }
}