/// A library for managing reactive state in Flutter applications.
///
/// This library provides classes and widgets to manage state reactively,
/// ensuring a single instance of state per type and allowing for state
/// changes to trigger UI updates efficiently.

library reactive_notifier;

/// Export the base [ReactiveNotifier] class which provides basic state management functionality.
export 'package:reactive_notifier/src/reactive_notifier.dart';

/// Export the [ReactiveBuilder] widget which listens to a [ReactiveNotifier] and rebuilds
/// itself whenever the value changes.
export 'package:reactive_notifier/src/builder/reactive_builder.dart';

/// Export the [AsyncState]
export 'package:reactive_notifier/src/handler/async_state.dart';

/// Export [ReactiveAsyncBuilder] and [ReactiveStreamBuilder]
export 'package:reactive_notifier/src/builder/reactive_async_builder.dart';
export 'package:reactive_notifier/src/builder/reactive_stream_builder.dart';

/// Export ViewModelImpl
export 'package:reactive_notifier/src/viewmodel/async_viewmodel_impl.dart';
export 'package:reactive_notifier/src/viewmodel/viewmodel_impl.dart';

/// Export RepositoryImpl
export 'package:reactive_notifier/src/implements/repository_impl.dart';

/// Export ServiceImpl
export 'package:reactive_notifier/src/implements/service_impl.dart';
