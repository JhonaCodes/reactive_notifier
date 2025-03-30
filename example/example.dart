import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';


/// Immutable model representing the counter state.
///
/// Contains a numeric [count] value and a descriptive [message].
/// This class implements an immutable design with final properties
/// and a [copyWith] method to facilitate state updates without
/// modifying the original instance.
class CounterState {
  /// The current numeric value of the counter.
  final int count;

  /// Descriptive message associated with the counter.
  /// Used to display contextual information about the state.
  final String message;

  /// Constant constructor that initializes the required properties.
  const CounterState({
    required this.count,
    required this.message,
  });

  /// Creates a copy of this object with the specified values replaced.
  ///
  /// This method facilitates partial state updates while maintaining
  /// immutability, as it returns a new instance with the changes
  /// applied without modifying the original instance.
  ///
  /// [count]: New value for the counter (optional).
  /// [message]: New descriptive message (optional).
  CounterState copyWith({
    int? count,
    String? message,
  }) {
    return CounterState(
      count: count ?? this.count,
      message: message ?? this.message,
    );
  }
}


/// Mixin that encapsulates all the counter's state logic and business rules.
///
/// Implements a stateless service that manages [ReactiveNotifier] instances
/// and exposes methods to modify the state. Follows the singleton pattern
/// to maintain a single source of truth for the counter and related message states.
mixin CounterService {
  /// Main instance of the counter state.
  ///
  /// This instance is initialized with a counter at 0 and an initial message.
  /// It is related to [_messageNotifier] to create a composite state model.
  static final ReactiveNotifier<CounterState> _instance = ReactiveNotifier<CounterState>(
        () => const CounterState(count: 0, message: 'Initial'),
    related: [_messageNotifier],
  );

  /// Independent state for the related message.
  ///
  /// This notifier maintains a text message that can be updated
  /// independently of the counter state.
  static final ReactiveNotifier<String> _messageNotifier = ReactiveNotifier<String>(
        () => 'Initial message',
  );

  /// Accesses the counter notifier instance.
  ///
  /// Provides public access to the counter state instance
  /// so the UI can subscribe to changes.
  static ReactiveNotifier<CounterState> get instance => _instance;

  /// Accesses the message notifier instance.
  ///
  /// Provides public access to the message state instance
  /// so the UI can subscribe to changes independently of the counter.
  static ReactiveNotifier<String> get messageInstance => _messageNotifier;

  /// Increments the counter value by one unit.
  ///
  /// Gets the current state, increases the [count] value by 1,
  /// updates the descriptive message, and notifies all listeners
  /// using [updateState].
  static void increment() {
    final currentState = _instance.notifier;
    _instance.updateState(
      CounterState(
        count: currentState.count + 1,
        message: 'Incremented to ${currentState.count + 1}',
      ),
    );
  }

  /// Decrements the counter value by one unit.
  ///
  /// Gets the current state, decreases the [count] value by 1,
  /// updates the descriptive message, and notifies all listeners
  /// using [updateState].
  static void decrement() {
    final currentState = _instance.notifier;
    _instance.updateState(
      CounterState(
        count: currentState.count - 1,
        message: 'Decremented to ${currentState.count - 1}',
      ),
    );
  }

  /// Updates the related message state with a new value.
  ///
  /// This method directly updates the [_messageNotifier] with the provided
  /// [newMessage] and triggers UI updates for components listening to this state.
  static void updateMessage(String newMessage) {
    _messageNotifier.updateState(newMessage);
  }
}


/// Widget that displays the counter and provides user interaction controls.
///
/// This stateless widget uses [ReactiveBuilder] to listen to state changes
/// from [CounterService] and efficiently rebuild only when necessary.
/// It demonstrates a clean separation between UI and business logic.
class CounterScreen extends StatelessWidget {
  /// Creates a counter screen with default parameters.
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple ReactiveNotifier Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main counter display - rebuilds when counter state changes
            ReactiveBuilder<CounterState>(
              notifier: CounterService.instance,
              builder: (state, keep) => Column(
                children: [
                  Text(
                    'Counter: ${state.count}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Related message display - rebuilds independently when message changes
            ReactiveBuilder<String>(
              notifier: CounterService.messageInstance,
              builder: (message, keep) => Text(
                'Related message: $message',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 20),
            // Control buttons - direct integration with service methods
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ElevatedButton(
                  onPressed: CounterService.decrement,
                  child: Text('-'),
                ),
                const SizedBox(width: 20),
                const ElevatedButton(
                  onPressed: CounterService.increment,
                  child: Text('+'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => CounterService.updateMessage('Updated message: ${DateTime.now()}'),
                  child: const Text('Update Message'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


