import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReactiveNotifier Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CounterScreen(),
    );
  }
}

/// Complex business state with validation and business logic
class CounterState {
  final int count;
  final String message;
  final bool isEven;
  final bool isAtLimit;

  const CounterState({
    required this.count,
    required this.message,
    required this.isEven,
    required this.isAtLimit,
  });

  CounterState copyWith({
    int? count,
    String? message,
    bool? isEven,
    bool? isAtLimit,
  }) {
    return CounterState(
      count: count ?? this.count,
      message: message ?? this.message,
      isEven: isEven ?? this.isEven,
      isAtLimit: isAtLimit ?? this.isAtLimit,
    );
  }
}

/// Simple language model for global state
class MyLang {
  final String name;
  final String code;

  MyLang(this.name, this.code);

  @override
  String toString() => 'MyLang(name: $name, code: $code)';
}

/// Simple theme model for global state
class MyTheme {
  final bool isDark;
  final Color primaryColor;

  MyTheme(this.isDark, this.primaryColor);

  @override
  String toString() => 'MyTheme(isDark: $isDark, primaryColor: $primaryColor)';
}

/// Counter service with complex business logic - USE REACTIVEBUILDER
mixin CounterService {
  static final ReactiveNotifier<CounterState> instance =
      ReactiveNotifier<CounterState>(
    () => const CounterState(
        count: 0, message: 'Initial', isEven: true, isAtLimit: false),
  );

  static void increment() {
    final currentState = instance.notifier;
    final newCount = currentState.count + 1;

    // Complex business logic
    instance.updateState(
      CounterState(
        count: newCount,
        message: 'Incremented to $newCount',
        isEven: newCount % 2 == 0,
        isAtLimit: newCount >= 10,
      ),
    );
  }

  static void decrement() {
    final currentState = instance.notifier;
    final newCount = currentState.count - 1;

    // Complex business logic
    instance.updateState(
      CounterState(
        count: newCount,
        message: 'Decremented to $newCount',
        isEven: newCount % 2 == 0,
        isAtLimit: newCount >= 10,
      ),
    );
  }

  static void reset() {
    instance.updateState(
      const CounterState(
          count: 0, message: 'Reset to 0', isEven: true, isAtLimit: false),
    );
  }
}

/// Language service for simple global state - USE REACTIVECONTEXT
mixin LanguageService {
  static final ReactiveNotifier<MyLang> instance = ReactiveNotifier<MyLang>(
    () => MyLang('English', 'en'),
  );

  static void switchLanguage(String name, String code) {
    instance.updateState(MyLang(name, code));
  }
}

/// Theme service for simple global state - USE REACTIVECONTEXT
mixin ThemeService {
  static final ReactiveNotifier<MyTheme> instance = ReactiveNotifier<MyTheme>(
    () => MyTheme(false, Colors.blue),
  );

  static void toggleTheme() {
    final current = instance.notifier;
    instance.updateState(MyTheme(!current.isDark, current.primaryColor));
  }

  static void changeColor(Color color) {
    final current = instance.notifier;
    instance.updateState(MyTheme(current.isDark, color));
  }
}

/// ReactiveContext extensions - For GLOBAL state (language, theme, etc.)
extension LanguageContext on BuildContext {
  MyLang get lang => getReactiveState(LanguageService.instance);
}

extension ThemeContext on BuildContext {
  MyTheme get theme => getReactiveState(ThemeService.instance);
}

/// Main screen demonstrating when to use ReactiveBuilder vs ReactiveContext
class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReactiveNotifier Examples'),
        backgroundColor: context.theme.primaryColor,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ReactiveContext for global state
            GlobalStateSection(),

            SizedBox(height: 30),

            // ReactiveBuilder for complex business logic
            ComplexStateSection(),

            SizedBox(height: 30),

            // Control buttons
            ControlButtonsSection(),
          ],
        ),
      ),
    );
  }
}

class GlobalStateSection extends StatelessWidget {
  const GlobalStateSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ReactiveContext - Global State',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use for: Language, Theme, User preferences, Global settings',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 16),

            // Clean, simple access to global state
            Text(
              'Current Language: ${context.lang.name} (${context.lang.code})',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              'Current Theme: ${context.theme.isDark ? 'Dark' : 'Light'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 16),

            // Widget preservation example
            const _ExpensiveWidget(
              title: 'Preserved Widget',
              subtitle: 'Never rebuilds when global state changes',
              color: Colors.green,
            ).keep('preserved_widget'),

            const SizedBox(height: 8),

            Text(
              'Generic API: ${context<MyLang>().name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class ComplexStateSection extends StatelessWidget {
  const ComplexStateSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ReactiveBuilder - Complex Business Logic',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use for: Business logic, Validation, Complex state, API calls',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 16),
            ReactiveBuilder<CounterState>(
              notifier: CounterService.instance,
              build: (state, notifier, keep) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Counter: ${state.count}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      'Message: ${state.message}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),

                    // Business logic indicators
                    if (state.isEven)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Even number!'),
                      ),

                    if (state.isAtLimit)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('At limit!'),
                      ),

                    const SizedBox(height: 8),

                    // Expensive widget preserved with keep()
                    keep(const _ExpensiveWidget(
                      title: 'Preserved Chart',
                      subtitle: 'Complex chart that never rebuilds',
                      color: Colors.orange,
                    )),
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

class ControlButtonsSection extends StatelessWidget {
  const ControlButtonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controls',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Counter controls (complex business logic)
            Text(
              'Complex Business Logic:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: CounterService.decrement,
                  child: Text('-'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: CounterService.increment,
                  child: Text('+'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: CounterService.reset,
                  child: Text('Reset'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Global state controls
            Text(
              'Global State:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () =>
                      LanguageService.switchLanguage('English', 'en'),
                  child: const Text('English'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      LanguageService.switchLanguage('Español', 'es'),
                  child: const Text('Español'),
                ),
                const ElevatedButton(
                  onPressed: ThemeService.toggleTheme,
                  child: Text('Toggle Theme'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Example expensive widget for demonstrating preservation
class _ExpensiveWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _ExpensiveWidget({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buildTime = DateTime.now().millisecondsSinceEpoch;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Built at: $buildTime',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
