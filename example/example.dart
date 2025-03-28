import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';


/// My object for state.
class CounterState {
  final int count;
  final String message;

  const CounterState({
    required this.count,
    required this.message,
  });

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


/// Mixin namespace.
mixin CounterService {
  static final ReactiveNotifier<CounterState> _instance = ReactiveNotifier<CounterState>(
        () => const CounterState(count: 0, message: 'Inicial'),
    related: [_messageNotifier],
  );

  static final ReactiveNotifier<String> _messageNotifier = ReactiveNotifier<String>(
        () => 'Mensaje inicial',
  );

  static ReactiveNotifier<CounterState> get instance => _instance;
  static ReactiveNotifier<String> get messageInstance => _messageNotifier;

  static void increment() {
    final currentState = _instance.notifier;
    _instance.updateState(
      CounterState(
        count: currentState.count + 1,
        message: 'Incrementado a ${currentState.count + 1}',
      ),
    );
  }

  static void decrement() {
    final currentState = _instance.notifier;
    _instance.updateState(
      CounterState(
        count: currentState.count - 1,
        message: 'Decrementado a ${currentState.count - 1}',
      ),
    );
  }

  static void updateMessage(String newMessage) {
    _messageNotifier.updateState(newMessage);
  }
}



/// Widget.
class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplo Simple de ReactiveNotifier'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Contador principal
            ReactiveBuilder<CounterState>(
              notifier: CounterService.instance,
              builder: (state, keep) => Column(
                children: [
                  Text(
                    'Contador: ${state.count}',
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
            // Mensaje relacionado
            ReactiveBuilder<String>(
              notifier: CounterService.messageInstance,
              builder: (message, keep) => Text(
                'Mensaje relacionado: $message',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 20),
            // Botones de control
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: CounterService.decrement,
                  child: Text('-'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: CounterService.increment,
                  child: Text('+'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => CounterService.updateMessage('Mensaje actualizado: ${DateTime.now()}'),
                  child: const Text('Actualizar Mensaje'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


