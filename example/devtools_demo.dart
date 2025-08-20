import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

void main() {
  runApp(const DevToolsAutoDemo());
}

class DevToolsAutoDemo extends StatelessWidget {
  const DevToolsAutoDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReactiveNotifier DevTools Auto-Integration Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DemoScreen(),
    );
  }
}

// Simple counter model
class CounterModel {
  final int value;
  final String label;

  CounterModel({required this.value, required this.label});

  CounterModel copyWith({int? value, String? label}) {
    return CounterModel(
      value: value ?? this.value,
      label: label ?? this.label,
    );
  }

  @override
  String toString() => 'CounterModel(value: $value, label: $label)';
}

// Simple ViewModel
class CounterViewModel extends ViewModel<CounterModel> {
  CounterViewModel() : super(CounterModel(value: 0, label: 'Auto DevTools Demo'));

  @override
  void init() {
    // ViewModel initialization
  }

  void increment() {
    transformState((current) => current.copyWith(value: current.value + 1));
  }

  void decrement() {
    transformState((current) => current.copyWith(value: current.value - 1));
  }

  void reset() {
    updateState(CounterModel(value: 0, label: data.label));
  }
}

// Service with ReactiveNotifier
mixin CounterService {
  static final ReactiveNotifier<CounterViewModel> instance = 
    ReactiveNotifier<CounterViewModel>(() => CounterViewModel());
}

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReactiveNotifier DevTools Auto-Demo'),
        backgroundColor: Colors.blue[100],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.developer_mode,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'ReactiveNotifier DevTools Extension',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Auto-integrated! No setup required.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ReactiveViewModelBuilder<CounterViewModel, CounterModel>(
              viewmodel: CounterService.instance.notifier,
              build: (counter, viewModel, keep) {
                return Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              counter.label,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${counter.value}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: viewModel.decrement,
                                  child: const Icon(Icons.remove),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: viewModel.increment,
                                  child: const Icon(Icons.add),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: viewModel.reset,
                                  child: const Icon(Icons.refresh),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Card(
                      color: Colors.green,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 32),
                            SizedBox(height: 8),
                            Text(
                              'DevTools Extension Active!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Open Flutter DevTools to see the "ReactiveNotifier" tab',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}