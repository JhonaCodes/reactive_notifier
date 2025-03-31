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
- Reduced memory footprint
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
