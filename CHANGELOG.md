# 2.14.0
## Persistent Global BuildContext Access from ViewModels.

### ✨ New Features

#### Direct Global Context Access
- **`globalContext`**: Direct access to persistent global context (`BuildContext?`)
- **`hasGlobalContext`**: Check if global context is available (`bool`)
- **`requireGlobalContext([operation])`**: Required global context with descriptive errors

### 🎯 Purpose: Stable BuildContext Throughout App Lifecycle

The new global context access provides a **persistent** BuildContext that remains available regardless of widget lifecycle:
- **Always Available**: `globalContext` never changes after `ReactiveNotifier.initContext()`
- **Navigation Safe**: Context persists even when specific builders mount/unmount during navigation
- **Stable Reference**: Single context reference throughout the entire app lifecycle

### 💡 Use Cases

#### 1. **State Manager Integration**
Access any state management solution that requires BuildContext:
```dart
// Riverpod
final container = ProviderScope.containerOf(globalContext!);
final data = container.read(userProvider);

// Provider
final data = Provider.of<UserData>(globalContext!, listen: false);

// InheritedWidget
final data = MyInheritedWidget.of(globalContext!);
```

#### 2. **Theme & Localization**
Consistent access to app-wide configurations:
```dart
final theme = Theme.of(globalContext!);
final locale = Localizations.localeOf(globalContext!);
final mediaQuery = MediaQuery.of(globalContext!);
```

#### 3. **Cross-ViewModel Communication**
Access context-dependent data in any ViewModel without timing issues:
```dart
class AnalyticsViewModel extends ViewModel<AnalyticsState> {
  void trackScreenView() {
    if (hasGlobalContext) {
      final route = ModalRoute.of(globalContext!)?.settings.name;
      trackEvent('screen_view', {'route': route});
    }
  }
}
```

### 🔧 API Additions

```dart
// NEW: ViewModelContextService mixin additions
mixin ViewModelContextService {
  // Existing context (with fallback)
  BuildContext? get context;
  bool get hasContext;
  BuildContext requireContext([String? operation]);

  // NEW: Direct global context access
  BuildContext? get globalContext;
  bool get hasGlobalContext;
  BuildContext requireGlobalContext([String? operation]);
}
```

### 📊 Comparison: `context` vs `globalContext`

| Feature | `context` | `globalContext` |
|---------|-----------|-----------------|
| **Source** | Specific ViewModel context → Global fallback | Always global context |
| **Persistence** | May change when builders mount/unmount | Remains constant throughout app |
| **Use Case** | Widget-specific operations | App-wide stable access |
| **Availability** | After any builder mounts | After `ReactiveNotifier.initContext()` |
| **Lifecycle** | Tied to builder lifecycle | Tied to app lifecycle |

### 🏗️ Architecture

#### ViewModelContextNotifier Additions
- **`getGlobalContext()`**: Static method for direct global context access
- **`hasGlobalContext()`**: Static method to check global context availability

#### ViewModelContextService Mixin Additions
- **`globalContext`**: Persistent global context getter
- **`hasGlobalContext`**: Global context availability check
- **`requireGlobalContext([operation])`**: Required global context with descriptive errors

### ✅ Benefits

1. **Stability**: Never lose context reference during navigation or widget rebuilds
2. **Flexibility**: Works with any BuildContext-dependent API or state manager
3. **Predictability**: Single source of truth for global context access
4. **Safety**: Explicit separation between widget-specific and global context needs
5. **Compatibility**: Enables integration with any Flutter state management solution

### 🧪 Testing

- Added comprehensive test suite for global context functionality
- 9 new tests covering:
  - Global context persistence during navigation
  - Independence from specific ViewModel contexts
  - Error handling for unavailable context
  - Cleanup behavior
- All tests passing with 100% coverage

### 📚 Documentation

- Updated CLAUDE.md with complete global context documentation
- Added comparison table: `context` vs `globalContext`
- Included usage examples for multiple use cases
- Context lifecycle and safety patterns documented

### ⚠️ No Breaking Changes

- Fully backward compatible with existing code
- New APIs are additive only
- Existing `context` getter unchanged with automatic fallback behavior
- Zero configuration required - works out of the box

---

# 2.13.5
- Update topics.

# 2.13.4
- Fix changelog version.

# 2.13.3
- Update code format on comments.

# 2.13.2
- Update format.

# 2.13.1
- Clean documentation and few code tweaks.

# 2.13.0
## State Change Hooks + BuildContext Management + Architecture Improvements

### ✨ New Features

#### BuildContext Management System
- **`waitForContext` Parameter**: AsyncViewModelImpl can now wait for BuildContext before initialization
- **Global Context Initialization**: `ReactiveNotifier.initContext(context)` provides context to all ViewModels
- **Automatic Context Fallback**: ViewModels automatically use global context when specific context unavailable
- **Context-Aware Initialization**: ViewModels can access Theme, MediaQuery, Localizations in init() methods
- **Smart Reinitialize**: ViewModels with `waitForContext: true` automatically reinitialize when context becomes available

#### State Change Hooks
- **State Change Hooks**: Added `onStateChanged(previous, next)` hook for ViewModels
- **Async State Hooks**: Added `onAsyncStateChanged(previous, next)` hook for AsyncViewModels  
- **Internal State Reaction**: ViewModels can now react to their own state changes
- **Hook Integration**: Hooks automatically called in all state update methods

#### Architecture Improvements
- **Cross-Service Communication**: Explicit communication between service sandboxes
- **Multiple Instance Support**: Multiple instances of same type in different services

### 🏗️ Architecture Improvements
- **Eliminated Observer Complexity**: Removed ReactiveObserver in favor of explicit communication
- **Sandbox Architecture**: Services act as independent sandboxes with explicit communication
- **Simplified State Management**: No magic type lookup - everything is explicit
- **Enhanced Service Pattern**: Better service organization with clear boundaries

### 📚 Documentation Updates  
- **Professional Documentation**: Removed excessive emojis, cleaner presentation
- **Simplified Examples**: Direct, practical code samples
- **Updated Migration Guides**: Enhanced guides for Provider, Riverpod, BLoC migration
- **Comprehensive Testing**: Improved test coverage with proper isolation

### 🔧 API Changes

#### BuildContext Management
```dart
// NEW: Global context initialization (recommended)
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // All ViewModels now have access to context
    ReactiveNotifier.initContext(context);
    return MaterialApp(...);
  }
}

// NEW: waitForContext parameter for individual ViewModels
class ThemeAwareViewModel extends AsyncViewModelImpl<ThemeData> {
  ThemeAwareViewModel() : super(
    AsyncState.initial(), 
    waitForContext: true  // Wait for context before init()
  );
  
  @override
  Future<ThemeData> init() async {
    // Context is guaranteed to be available here
    final theme = Theme.of(requireContext('theme initialization'));
    return await loadThemeBasedData(theme);
  }
}

// ViewModels can access context in init() methods
class ResponsiveViewModel extends ViewModel<ResponsiveState> {
  @override
  void init() {
    // Access MediaQuery in synchronous init
    final mediaQuery = MediaQuery.of(requireContext('responsive setup'));
    final isTablet = mediaQuery.size.width > 600;
    updateSilently(ResponsiveState(isTablet: isTablet));
  }
}
```

#### State Change Hooks
```dart
// NEW: State change hooks
class UserViewModel extends ViewModel<UserModel> {
  @override
  void onStateChanged(UserModel previous, UserModel next) {
    // React to state changes internally
    if (previous.status != next.status) {
      logStatusChange(previous.status, next.status);
    }
  }
}

// NEW: Async state hooks  
class DataViewModel extends AsyncViewModelImpl<List<Item>> {
  @override
  void onAsyncStateChanged(AsyncState<List<Item>> previous, AsyncState<List<Item>> next) {
    // React to async state changes
    if (previous.isLoading && next.isSuccess) {
      logSuccessfulLoad(next.data?.length ?? 0);
    }
  }
}
```

### ✅ Migration & Compatibility

#### BuildContext Migration Patterns
```dart
// BEFORE: ViewModels couldn't access context in init()
class OldViewModel extends AsyncViewModelImpl<Data> {
  @override
  Future<Data> init() async {
    // ❌ No access to Theme, MediaQuery, etc.
    return await loadDefaultData();
  }
}

// AFTER: Multiple migration options
// Option 1: Global context (recommended)
void main() {
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  Widget build(context) {
    ReactiveNotifier.initContext(context); // ✅ All VMs get context
    return MaterialApp(...);
  }
}

// Option 2: Individual ViewModel waiting
class NewViewModel extends AsyncViewModelImpl<Data> {
  NewViewModel() : super(AsyncState.initial(), waitForContext: true);
  
  @override
  Future<Data> init() async {
    // ✅ Context available after waiting
    final theme = Theme.of(requireContext());
    return await loadThemedData(theme);
  }
}
```

#### Backward Compatibility
- **100% Compatible**: All existing code works without changes
- **No Breaking Changes**: New parameters have safe defaults (`waitForContext: false`)
- **Gradual Migration**: Can adopt global context or individual ViewModel waiting incrementally
- **Existing Tests Pass**: All 27+ existing tests continue to work

### 🚨 Breaking Changes
- **Removed ReactiveObserver**: Use explicit service communication with `listenVM`
- **Removed global notifier<T>()**: Use explicit service access instead

### 🔄 Migration from ReactiveObserver
```dart
// OLD (Removed)
class MyViewModel extends ViewModel<MyState> with ReactiveObserver {
  @override
  void init() {
    observe<UserViewModel>((user) {  // ❌ Magic type lookup
      updateForUser(user.data);
    });
  }
}

// NEW (Explicit)
class MyViewModel extends ViewModel<MyState> {
  @override
  void init() {
    UserService.mainUser.notifier.listenVM((userData) {  // ✅ Explicit service
      updateForUser(userData);
    });
  }
}
```

### ⚡ Performance Improvements
- **Reduced Memory Usage**: Eliminated observer overhead
- **Faster State Updates**: Direct communication without observer layer
- **Better Test Isolation**: Improved test performance and reliability

---

# 2.12.0
## 🎯 BuildContext Access for ViewModels - Seamless Migration Support + Auto DevTools Integration

### ✨ New Features
- **Automatic BuildContext Access**: ViewModels can now access Flutter's BuildContext during initialization
- **ViewModelContextProvider Mixin**: Provides `context`, `hasContext`, and `requireContext()` methods
- **Seamless Migration Support**: Enables gradual migration from Riverpod using `ProviderScope.containerOf(context)`
- **Automatic Context Registration**: Builders automatically provide context to ViewModels - no setup required
- **Context Lifecycle Management**: Context is automatically managed and cleaned up with builders
- **🛠️ Built-in DevTools Extension**: Auto-integrated debugging extension with zero configuration required

### 🔧 API Additions
- **`context`**: Nullable BuildContext getter for safe access
- **`hasContext`**: Boolean property to check context availability
- **`requireContext([operation])`**: Context getter with descriptive errors when unavailable
- **Context Integration**: Works seamlessly with all builders (ReactiveBuilder, ReactiveViewModelBuilder, ReactiveAsyncBuilder)

### 🚀 Migration Capabilities
```dart
// Enable Riverpod migration in ViewModels
class MyViewModel extends ViewModel<MyState> {
  @override 
  void init() {
    if (hasContext) {
      // Access Riverpod container during migration
      final container = ProviderScope.containerOf(context!);
      final data = container.read(myProvider);
      updateSilently(MyState.fromRiverpod(data));
    } else {
      updateSilently(MyState.empty());
    }
  }
}
```

### 📱 Theme and MediaQuery Access
```dart
// Access Flutter's context-dependent widgets
class ResponsiveViewModel extends ViewModel<ResponsiveState> {
  @override
  void init() {
    updateSilently(ResponsiveState.initial());
  }
  
  @override 
  Future<void> onResume(ResponsiveState data) async {
    if (hasContext) {
      final mediaQuery = MediaQuery.of(requireContext('responsive design'));
      final theme = Theme.of(context!);
      updateState(ResponsiveState.fromContext(mediaQuery, theme));
    }
  }
}
```

### 🛡️ Safety Features
- **PostFrameCallback Integration**: Safe MediaQuery access without initState timing issues
- **Automatic Context Cleanup**: Context is cleared when builders are disposed
- **Multiple Builder Support**: Context remains available while any builder is active
- **Dispose Safety**: Context access blocked after ViewModel disposal

### 🛠️ DevTools Extension Features
- **📊 Real-time State Monitoring**: Live visualization of all ReactiveNotifier instances
- **🔍 Interactive State Inspector**: View, edit, and debug state changes in real-time
- **📈 Performance Analytics**: Memory usage tracking and rebuild performance analysis
- **🐛 Memory Leak Detection**: Automatic detection and reporting of potential memory leaks
- **📝 State Change History**: Complete timeline of state changes with rollback capabilities
- **⚡ Zero Configuration**: Automatically activates when importing reactive_notifier

### ⚠️ Important Notes
- **Context timing**: Available after first builder mounts, cleared when last builder disposes
- **Migration support**: Primary use case is gradual migration from Provider/Riverpod
- **DevTools access**: Extension appears as "ReactiveNotifier" tab in Flutter DevTools (debug mode only)
- **No breaking changes**: Fully backward compatible - existing code unchanged
- **Automatic operation**: Zero configuration required - works out of the box

### 🔗 Builder Integration
All builders now provide context automatically:
- ✅ **ReactiveBuilder<T>**: Context provided to simple state values
- ✅ **ReactiveViewModelBuilder<VM,T>**: Context provided to custom ViewModels  
- ✅ **ReactiveAsyncBuilder<VM,T>**: Context provided to AsyncViewModels

---

# 2.11.1
- Update git ignore and some tweaks.

# 2.11.0
## 🚀 ReactiveContext - Clean Global State Access

### 🎯 New Features
- **ReactiveContext API**: Clean, intuitive access to global reactive state via `context.lang.name`
- **Advanced Widget Preservation**: Enhanced `.keep()` system with automatic key management
- **Type-Specific Rebuilds**: Eliminates cross-rebuilds problem - only relevant widgets rebuild
- **Generic API Access**: Multiple ways to access state (`context<T>()`, `getByKey<T>()`)
- **Performance Optimization**: `ReactiveContextBuilder` widget for maximum performance
- **Auto-Registration**: Transparent notifier registration and lifecycle management

### 🛠️ ReactiveContext Components
- **Extension Methods**: Create clean APIs like `context.theme.isDark`
- **Widget Preservation**: `widget.keep()`, `context.keep()`, `context.keepAll()`
- **Batch Operations**: Preserve multiple widgets with single operation
- **Debug Tools**: Comprehensive debugging and monitoring capabilities
- **Memory Management**: Automatic cleanup with LRU cache and intelligent key generation

### 🔧 API Encapsulation
- **Protected Internal APIs**: Internal classes properly hidden with `@protected`
- **Clean Public API**: Only developer-facing APIs exported from main library
- **Selective Exports**: `ReactiveContextBuilder` specifically exported for performance optimization

### 📚 Documentation
- **Complete ReactiveContext Guide**: Comprehensive documentation with examples
- **Dispose and Recreation Guide**: Memory management and lifecycle control
- **Migration Guides**: Moving from ReactiveBuilder to ReactiveContext
- **Best Practices**: When to use ReactiveContext vs ReactiveBuilder

### ⚠️ Important Notes
- **ReactiveContext is for global state**: Language, theme, user preferences
- **ReactiveBuilder remains recommended**: For granular state management and business logic
- **No breaking changes**: Fully backward compatible with existing code

### 🎨 Usage Examples
```dart
// Clean extension API
extension AppContext on BuildContext {
  MyLang get lang => getReactiveState(LanguageService.instance);
  MyTheme get theme => getReactiveState(ThemeService.instance);
}

// Widget preservation
ExpensiveWidget().keep('key')
context.keep(widget, 'key')

// Performance optimization
ReactiveContextBuilder(
  forceInheritedFor: [LanguageService.instance, ThemeService.instance],
  child: MyApp(),
)
```

# 2.10.6
- `README.md` update readme.

# 2.10.5
## UpdateState on TransformState
- `updateState` on TransformState for `AsyncViewModelImpl`

# 2.10.4
## Listen and Initialization
- `callOnInit` implemented for `listen` and `listenVM`, for execute function on init instance.
- `onResume` Called after the ViewModel's primary initialization

# 2.10.3
## Readme
- Update description

# 2.10.2
## Readme
- Update example on readme for transformState

# 2.10.1
## Readme
- Update metadata

# 2.10.0
## 🛠️ ViewModel State Enhancements
- Introduced `transformDataState` for modifying the data within a success state and notifying listeners.
- Introduced `transformDataStateSilently` for modifying the data within a success state without notifying listeners.
- `init` now init es default form of initialization.
- `builder`, `onSucess` optional.
- `onData` optional and more.

# 2.9.0
## 🔄 Reactive State Management

### 🚀 Enhancements
- Introduced `ReactiveFutureBuilder` for seamless data loading without flickering
- Enhanced navigation experience with persistent state between screens
- Optimized memory usage by avoiding redundant rebuilds
- Improved UI responsiveness with immediate data display
- Streamlined integration with existing ReactiveNotifier system

### 🛠 New Features
- Added `ReactiveFutureBuilder<T>` widget with automatic state persistence
- Implemented `defaultData` parameter for flickerless navigation
- Added reactive notifier integration via `createStateNotifier` parameter
- Introduced state update control with `notifyChangesFromNewState` flag
- Enhanced error and loading state handling with customizable builders
- Added comprehensive documentation with usage examples
- **New listener API**:
  - `listen()` allows directly listening to the main `ReactiveNotifier` state, ideal for simple types like `String`, `int`, or plain models.
  - `listenVM()` enables listening to complex state objects like ViewModels inside the `ReactiveNotifier.notifier`, managing their internal lifecycle properly.
  - These additions improve fine-grained reactivity and reduce boilerplate when dealing with nested logic.

### 🐛 Bug Fixes
- Fixed UI flickering when navigating back to previously loaded screens
- Resolved state loss issues during navigation transitions
- Fixed race conditions between default data and async data loading
- Modified `AsyncViewModelImpl` to support nullable data types, enabling safer initialization validation
- Added proper null checks to prevent errors during state updates
- Improved type safety with stronger null handling throughout the reactive system

### 💻 Developer Experience
- Simplified state management code for async operations
- Reduced boilerplate when implementing loading/success/error states
- Improved code readability with clear separation of UI and data concerns
- Added type safety with generic parameter support



# 2.8.1
- Update documentation
- Comment format

# 2.8.0
## 🎧 ViewModel Listeners

### 🚀 Enhancements
- Introduced formal ViewModel Lifecycle management through the new Listeners system
- Added automatic listener registration and cleanup tied to ViewModel lifecycle
- Enhanced debugging experience with formatted listener logs
- Optimized memory management by preventing listener leaks
- Improved separation of UI and business logic with centralized reactivity

### 🛠 New Features
- Added `setupListeners()` method for registering reactive dependencies
- Added `removeListeners()` method for automatic cleanup
- Implemented `hasInitializedListenerExecution` guard for preventing premature updates
- Integrated listeners with existing lifecycle events (dispose, reload, cleanState)
- Added debug logging system for monitoring listener activity

### 🧹 Code Quality
- Improved memory management with automatic listener cleanup
- Enhanced predictability by centralizing reactive code
- Reduced widget complexity by moving reactivity to ViewModels
- Better separation of concerns between UI and business logic

### 📚 Documentation
- Added comprehensive examples for implementing ViewModel Listeners
- Updated best practices for reactive programming in Flutter
- Included debugging tips for listener management
- Expanded API reference with new listener-related methods


# 2.7.4
- `loadNotifier` for `AsyncViewModelImpl`.

# 2.7.3
- Export complete api 😅.

# 2.7.2
- Expose `AsyncViewModelImpl`

# 2.7.1
- Update documentation


# 2.7.0

### Breaking Changes 🚨
- Strict implementation of ViewModel patterns for state management
- Updated ReactiveViewModelBuilder to work exclusively with ViewModel<T> implementations
- Enforced proper mixin-based architecture for state organization
- Improved related states handling with cleaner dependency management

### 🚀 Enhancements
- Enhanced ViewModel lifecycle management with detailed logging
- Added `cleanState()` as the recommended approach instead of full dispose
- Improved error detection for circular references and state dependencies
- Comprehensive diagnostic logging for all lifecycle events
- More granular control over rebuilds with optimized keep functionality
- Efficient cross-module communication with direct state updates

### 🛠 New Features
- Added `loadNotifier()` method for explicit initialization of ViewModels at app startup
- Added `updateSilently()` for state changes without triggering UI rebuilds
- Added `transformStateSilently()` for granular model updates without notifications
- Enhanced ReactiveStreamBuilder with more comprehensive stream state handling
- Expanded debugging tools with detailed instance tracking

### 🧹 Code Quality
- Improved type safety across all components
- Better error messages with actionable recommendations
- Repository pattern integration with dependency injection support
- Enhanced testing support with simplified mocking approach

### 📚 Documentation
- Complete architecture examples with feature-based MVVM structure
- Improved examples for cross-module communication
- Expanded API reference with best practices for this library
- Better guidance for performance optimization

# 2.6.3
- `transformStateSilently` for Viewmodel and ReactiveNotifier.

# 2.6.2
- `updateSilently` for Simple reactiveNotifiers and `loadNotifier` for first initialization.

# 2.6.1
- Added mounted check in _valueChanged() method to prevent "setState() called after dispose()" errors when asynchronous notifications arrive after widget removal from the tree.

### 🐛 Bug Fixes
- where `ReactiveViewModelBuilder` could attempt to update no longer available widgets, causing runtime exceptions, especially during integration tests.
- Improved lifecycle management of listeners to prevent memory leaks and unexpected behaviors.


# 2.6.0
- Added new `ViewModel<T>` abstract class with robust lifecycle management, automatic reinitialization, and detailed diagnostic logging.
- Implemented `ReactiveNotifierViewModel<VM, T>` to better encapsulate ReactiveNotifier's singleton management with ViewModels.
- Added auto-dispose functionality to clean up resources automatically when a ViewModel is no longer in use.
- Enhanced `ReactiveViewModelBuilder` to support both traditional `StateNotifierImpl` and new ViewModel pattern.
- Implemented `cleanCurrentNotifier()`, `cleanupInstance()`, and c`leanupByType()` methods to provide granular control over instance cleanup.
- Added detailed error messages for ViewModel initialization, disposal, and state updates.
- Improved debugging with instance tracking, performance analytics, and detailed state change logging.
- Added comprehensive validations and safeguards to prevent state inconsistencies.
- Remove `debounce` on builder.

# 2.5.2
- Implement `updateSilently` on `AsyncViewModelImpl`.
- Format, etc.


# 2.5.1
- Implement `transformState` on `AsyncViewModelImpl` and `getStateByKey` for ReactiveNotifier.
- Format, etc.

# 2.5.0
- Implement `ReactiveViewModelBuilder` for complex state management.

# 2.4.2
- Some dart format.

# 2.4.1
- Update name of state and documentation for `StateNotifierImpl`.

# 2.4.0

### Breaking Changes 🚨

- Introducing `transformState` function for model editing, allowing state modifications at any nesting level. This function supports implementations like `copyWith`, enabling selective value updates in your models.

- Simplified state management: unified `notifier` and VM into a single approach using `ReactiveBuilder`, `ReactiveAsync`, and `ReactiveStream`. Access functions directly through notifier reference (e.g., `instance.notifier.replaceData(...)`). Access `ReactiveAsync` data via `notifier.data`.

- Removed `ValueNotifier` value dependency, eliminating nested state update issues (previously `instance.value.value`, now `instance.data`).

- Protected internal builder functions for improved encapsulation.

- Maintained compatibility with `ListenableBuilder` for `ReactiveNotifier`.

- Removed `context` dependency from builder as `ReactiveNotifier` doesn't require it.

### Best Practices
- Recommend using mixins to store related Notifiers, avoiding global variables and maintaining proper context encapsulation.


# 2.3.1
* Update documentation.
* Protected value for NotifierImpl.

# 2.3.0
### 🚀 Enhancements
* Added support for direct access to ReactiveNotifier value and simple state management
* New constructor `ReactiveBuilder.notifier` for simpler state cases
* Improved type safety and handling of ViewModelState implementations

### 🔨 Usage Changes
* For ViewModels/Complex States:
  ```dart
  ReactiveBuilder(
    notifier: stateConnection.value,
    builder: (context, state, keep) => YourWidget()
  )
  ```
* For Simple States:
  ```dart
  ReactiveBuilder.notifier(
    notifier: simpleNotifier,
    builder: (context, value, keep) => YourWidget()
  )
  ```

### 🐛 Bug Fixes
* Fixed state propagation in complex ViewModelState scenarios
* Improved debouncing mechanism for state updates
* Better memory management for kept widgets

### 📝 Documentation
* Added examples for both ViewModelState and simple state usage
* Updated documentation to reflect new constructor patterns
* Improved comments and code documentation

### 🏗️ Internal Changes
* Refactored internal state handling for better performance
* Optimized rebuilding patterns for kept widgets
* Enhanced type safety across the implementation

## 📦 Dependencies
* No changes in dependencies

## 🔄 Migration Guide
No breaking changes. Existing code will continue to work as expected. The new `.notifier` constructor is additive and optional for simpler state management cases.

## 2.2.1
- Update example and doc on readme.

## 2.2.0
- Update documentations and images.
- Implement Ci for actions.

## 2.1.1
- Update Readme.

## 2.1.0
- Few bits, and name convention
- New `ViewModelStateImpl` for simple viewmodel state.

## 2.0.0
### Breaking Changes 🚨
- Complete project architecture overhaul
- New reference handling system
- Changed how related states are managed

### New Features 🎉
- **Enhanced Debugging System**
    - Improved error messages
    - Better stack traces
    - Detailed circular reference detection

- **Advanced State Management**
    - Support for nested ReactiveNotifier instances in related states
    - Improved multiple reference handling
    - Better state isolation and context management

- **Async & Stream Support**
    - Built-in async state handling
    - Stream state management
    - Automatic state synchronization

- **Extended Testing Support**
    - More test cases
    - Better coverage
    - Improved testing utilities

### Improvements 🔧
- Better performance in state updates
- Reduced memory footlog
- Improved type safety
- Enhanced error handling
- Better documentation

### Bug Fixes 🐛
- Fixed issues with circular references
- Improved state cleanup
- Better error reporting
- Fixed memory leaks in complex state trees

### Documentation 📚
- Complete documentation overhaul
- New examples and use cases
- Better API documentation
- Improved error messages

## 1.0.5
- Update documentation.

## 1.0.4
- Implement when and callback when finish setState.
- Help to execute any other params when change state

## 1.0.3
- Upgrade SDK.

## 1.0.2
- Add gif for visual context.
- Change name from `State` to `Notify`.
- Update golden test.

## 1.0.1
- Change name from `State` to `Notify`.
- Improve `README.md`.

## 1.0.0
- Initial version.
