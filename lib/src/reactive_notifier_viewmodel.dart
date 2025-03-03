import 'package:reactive_notifier/reactive_notifier.dart';

/// This class is used similarly to `ReactiveNotifier`, but it requires calling the `ViewModel` and the type of data it returns.
/// It provides a wrapper around the ViewModel to manage state and updates via a `ReactiveNotifier`.
class ReactiveNotifierViewModel<VM extends ViewModel<T>, T> {
  final ReactiveNotifier<VM> _container;
  final bool autoDispose;

  /// Constructor that initializes the `ReactiveNotifier` container with a factory function
  /// that creates the `ViewModel`. Optionally, you can enable auto-disposal.
  ReactiveNotifierViewModel(VM Function() create, {this.autoDispose = false})
      : _container = ReactiveNotifier<VM>(create);

  /// Returns the `notifier` of the `ViewModel`, which is used to manage state and notify listeners of changes.
  /// This allows you to interact with the `ViewModel` directly.
  VM get notifier => _container.notifier;

  /// Returns the current state of the `ViewModel` by accessing its `data`.
  T get state => notifier.data;

  /// Disposes the `notifier` and cleans up the current instance in the container.
  /// This method is called to release resources when no longer needed.
  void dispose() {
    notifier.dispose();
    _container.cleanCurrentNotifier();
  }
}
