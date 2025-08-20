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
export 'package:reactive_notifier/src/viewmodel/async_viewmodel_impl.dart';

/// Export ReactiveContext functionality
export 'package:reactive_notifier/src/context/reactive_context_extensions.dart';
export 'package:reactive_notifier/src/context/reactive_context_preservation.dart';

/// Export ReactiveContext builder widget
export 'package:reactive_notifier/src/context/reactive_context_enhanced.dart'
    show ReactiveContextBuilder;

/// Export ViewModel Context Access (no need to import - works automatically)
/// ViewModelContextProvider mixin is already included in ViewModel and AsyncViewModelImpl
export 'package:reactive_notifier/src/context/viewmodel_context_notifier.dart'
    show ViewModelContextService;
