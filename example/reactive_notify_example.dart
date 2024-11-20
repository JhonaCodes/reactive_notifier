import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

enum ConnectionState {
  connected,
  unconnected,
  connecting,
  error,
  uploading,
  waiting,
  signalOff,
  errorOnSynchronized,
  synchronizing,
  synchronized,
  waitingForSynchronization
}

/// Test for current state [ReactiveNotifier].
final ReactiveNotifier<ConnectionState> reactiveConnectionState =
    ReactiveNotifier<ConnectionState>(() {
  /// You can put any code for initial value.
  return ConnectionState.signalOff;
});

void main() {
  /// Ensure flutter initialized.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (BuildContext context) => const MyApp(),
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReactiveNotifier'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 1. [ReactiveNotifier] Current connection state
            ReactiveBuilder<ConnectionState>(
              valueListenable: reactiveConnectionState,
              builder: (context, state, keep) {
                bool isConnected = state == ConnectionState.connected;
                return Column(
                  children: [
                    /// Prevents the widget from rebuilding.
                    /// Useful when you want to reuse it in another ReactiveBuilder.
                    keep(Text("No state update")),

                    Chip(
                      label: Text(
                        state.name,
                      ),
                      deleteIcon: Icon(Icons.remove_circle),
                      avatar: Icon(
                        Icons.wifi,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: OutlinedButton(
        onPressed: () {
          /// Variation unconnected and connected.
          reactiveConnectionState.updateState(
              reactiveConnectionState.value == ConnectionState.connected
                  ? ConnectionState.unconnected
                  : ConnectionState.connected);
        },
        child: const Text('ReactiveNotifier'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
