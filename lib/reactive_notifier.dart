/// A library for managing reactive state in Flutter applications.
///
/// This library provides classes and widgets to manage state reactively,
/// ensuring a single instance of state per type and allowing for state
/// changes to trigger UI updates efficiently.

library reactive_notifier;

/// Export [ReactiveAsyncBuilder] and [ReactiveStreamBuilder]
/// Export the [ReactiveBuilder] widget which listens to a [ReactiveNotifier] and rebuilds
/// itself whenever the value changes.
export 'package:reactive_notifier/src/builder/builder.dart';



/// Export the [AsyncState]
export 'package:reactive_notifier/src/handler/async_state.dart';

/// Export the base [ReactiveNotifier] class which provides basic state management functionality.
export 'package:reactive_notifier/src/notifier/reactive_notifier.dart';
export 'package:reactive_notifier/src/builder/reactive_viewmodel_builder.dart';
export 'package:reactive_notifier/src/notifier/reactive_notifier_viewmodel.dart';

/// Export ViewModelImpl
export 'package:reactive_notifier/src/viewmodel/viewmodel_impl.dart';
