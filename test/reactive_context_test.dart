import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// Test models
class TestLang {
  final String name;
  final String code;

  TestLang(this.name, this.code);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestLang &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          code == other.code;

  @override
  int get hashCode => name.hashCode ^ code.hashCode;
}

class TestTheme {
  final bool isDark;
  final Color primaryColor;

  TestTheme(this.isDark, this.primaryColor);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestTheme &&
          runtimeType == other.runtimeType &&
          isDark == other.isDark &&
          primaryColor == other.primaryColor;

  @override
  int get hashCode => isDark.hashCode ^ primaryColor.hashCode;
}

/// Test services
mixin TestLanguageService {
  static ReactiveNotifier<TestLang>? _instance;

  static ReactiveNotifier<TestLang> get instance {
    return _instance ??= ReactiveNotifier<TestLang>(
      () => TestLang('English', 'en'),
    );
  }

  static void switchLanguage(String name, String code) {
    instance.updateState(TestLang(name, code));
  }

  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}

mixin TestThemeService {
  static ReactiveNotifier<TestTheme>? _instance;

  static ReactiveNotifier<TestTheme> get instance {
    return _instance ??= ReactiveNotifier<TestTheme>(
      () => TestTheme(false, Colors.blue),
    );
  }

  static void toggleTheme() {
    final current = instance.notifier;
    instance.updateState(TestTheme(!current.isDark, current.primaryColor));
  }

  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}

/// Test extensions
extension TestLanguageContext on BuildContext {
  TestLang get lang => getReactiveState(TestLanguageService.instance);
}

extension TestThemeContext on BuildContext {
  TestTheme get theme => getReactiveState(TestThemeService.instance);
}

/// Test widgets
class TestWidget extends StatelessWidget {
  final String text;

  const TestWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text);
  }
}

class ReactiveContextTestWidget extends StatelessWidget {
  const ReactiveContextTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Language: ${context.lang.name}'),
        Text('Theme: ${context.theme.isDark ? 'Dark' : 'Light'}'),
        Text('Generic API: ${context<TestLang>().code}'),
      ],
    );
  }
}

class PreservationTestWidget extends StatelessWidget {
  const PreservationTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Language: ${context.lang.name}'),
        const TestWidget(text: 'Preserved Widget').keep('test_preserved'),
        const TestWidget(text: 'Normal Widget'),
      ],
    );
  }
}

void main() {
  group('ReactiveContext Core Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
      TestLanguageService.reset();
      TestThemeService.reset();
      // Add reactive context cleanup
      try {
        cleanupPreservedWidgets();
      } catch (e) {
        // Ignore if not available
      }
    });

    tearDown(() {
      ReactiveNotifier.cleanup();
      TestLanguageService.reset();
      TestThemeService.reset();
    });

    testWidgets('should provide reactive state through context extensions',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReactiveContextTestWidget(),
            ),
          ),
        ),
      );

      // Check initial state
      expect(find.text('Language: English'), findsOneWidget);
      expect(find.text('Theme: Light'), findsOneWidget);
      expect(find.text('Generic API: en'), findsOneWidget);

      // Change language
      TestLanguageService.switchLanguage('Spanish', 'es');
      await tester.pump();

      // Check updated state
      expect(find.text('Language: Spanish'), findsOneWidget);
      expect(find.text('Generic API: es'), findsOneWidget);

      // Change theme
      TestThemeService.toggleTheme();
      await tester.pump();

      // Check updated theme
      expect(find.text('Theme: Dark'), findsOneWidget);
    });

    testWidgets('should update only relevant widgets when state changes',
        (tester) async {
      int languageWidgetBuilds = 0;
      int themeWidgetBuilds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Builder(
                  builder: (context) {
                    languageWidgetBuilds++;
                    return Text('Language: ${context.lang.name}');
                  },
                ),
                Builder(
                  builder: (context) {
                    themeWidgetBuilds++;
                    return Text(
                        'Theme: ${context.theme.isDark ? 'Dark' : 'Light'}');
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Initial builds
      expect(languageWidgetBuilds, 1);
      expect(themeWidgetBuilds, 1);

      // Change language - should only rebuild language widget
      TestLanguageService.switchLanguage('French', 'fr');
      await tester.pump();

      expect(languageWidgetBuilds, 2);
      expect(themeWidgetBuilds, 1); // Should not rebuild

      // Change theme - should only rebuild theme widget
      TestThemeService.toggleTheme();
      await tester.pump();

      expect(languageWidgetBuilds, 2); // Should not rebuild
      expect(themeWidgetBuilds, 2);
    });

    testWidgets('should work with generic API context<T>()', (tester) async {
      // Ensure services exist for generic API testing
      TestLanguageService.instance.notifier; // Creates instance
      TestThemeService.instance.notifier; // Creates instance

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final lang = context<TestLang>();
                final theme = context<TestTheme>();
                return Column(
                  children: [
                    Text('Lang: ${lang.name}'),
                    Text('Theme: ${theme.isDark}'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Lang: English'), findsOneWidget);
      expect(find.text('Theme: false'), findsOneWidget);

      // Update state
      TestLanguageService.switchLanguage('German', 'de');
      TestThemeService.toggleTheme();
      await tester.pump();

      expect(find.text('Lang: German'), findsOneWidget);
      expect(find.text('Theme: true'), findsOneWidget);
    });

    testWidgets('should work with getByKey API', (tester) async {
      // Ensure services exist for getByKey testing
      TestLanguageService.instance.notifier; // Creates instance
      TestThemeService.instance.notifier; // Creates instance

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final lang = context.getByKey<TestLang>('lang');
                final theme = context.getByKey<TestTheme>('theme');
                return Column(
                  children: [
                    Text('Lang: ${lang.name}'),
                    Text('Theme: ${theme.isDark}'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Lang: English'), findsOneWidget);
      expect(find.text('Theme: false'), findsOneWidget);
    });

    testWidgets('should handle multiple state changes efficiently',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReactiveContextTestWidget(),
            ),
          ),
        ),
      );

      // Rapid state changes
      for (int i = 0; i < 5; i++) {
        TestLanguageService.switchLanguage('Lang$i', 'l$i');
        TestThemeService.toggleTheme();
      }

      await tester.pump();

      expect(find.text('Language: Lang4'), findsOneWidget);
      expect(find.text('Theme: Dark'),
          findsOneWidget); // Toggled 5 times: false->true->false->true->false->true (Dark)
    });
  });

  group('Widget Preservation Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
      TestLanguageService.reset();
      TestThemeService.reset();
      // Add reactive context cleanup
      try {
        cleanupPreservedWidgets();
      } catch (e) {
        // Ignore if not available
      }
    });

    tearDown(() {
      ReactiveNotifier.cleanup();
      TestLanguageService.reset();
      TestThemeService.reset();
    });

    testWidgets('should preserve widgets with .keep() extension',
        (tester) async {
      int normalWidgetBuilds = 0;
      int preservedWidgetBuilds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Builder(
                  builder: (context) {
                    normalWidgetBuilds++;
                    return Text('Language: ${context.lang.name}');
                  },
                ),
                Builder(
                  builder: (context) {
                    preservedWidgetBuilds++;
                    return const Text('Preserved Widget');
                  },
                ).keep('preserved_test'),
              ],
            ),
          ),
        ),
      );

      // Initial builds
      expect(normalWidgetBuilds, 1);
      expect(preservedWidgetBuilds, 1);

      // Change language - normal widget should rebuild, preserved should not
      TestLanguageService.switchLanguage('Spanish', 'es');
      await tester.pump();

      expect(normalWidgetBuilds, 2);
      expect(preservedWidgetBuilds, 1); // Should not rebuild
    });

    testWidgets('should handle context.keep() method', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    Text('Language: ${context.lang.name}'),
                    context.keep(
                      const TestWidget(text: 'Context Preserved'),
                      'context_preserved',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Context Preserved'), findsOneWidget);

      // Change state
      TestLanguageService.switchLanguage('Italian', 'it');
      await tester.pump();

      expect(find.text('Language: Italian'), findsOneWidget);
      expect(find.text('Context Preserved'), findsOneWidget);
    });

    testWidgets('should handle keepAll() for multiple widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    Text('Language: ${context.lang.name}'),
                    ...context.keepAll([
                      const TestWidget(text: 'Preserved 1'),
                      const TestWidget(text: 'Preserved 2'),
                    ], 'batch_preserved'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Preserved 1'), findsOneWidget);
      expect(find.text('Preserved 2'), findsOneWidget);

      // Change state
      TestLanguageService.switchLanguage('Portuguese', 'pt');
      await tester.pump();

      expect(find.text('Language: Portuguese'), findsOneWidget);
      expect(find.text('Preserved 1'), findsOneWidget);
      expect(find.text('Preserved 2'), findsOneWidget);
    });
  });

  group('Performance Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
      TestLanguageService.reset();
      TestThemeService.reset();
      // Add reactive context cleanup
      try {
        cleanupPreservedWidgets();
      } catch (e) {
        // Ignore if not available
      }
    });

    tearDown(() {
      ReactiveNotifier.cleanup();
      TestLanguageService.reset();
      TestThemeService.reset();
    });

    testWidgets('should handle ReactiveContextBuilder', (tester) async {
      await tester.pumpWidget(
        ReactiveContextBuilder(
          forceInheritedFor: [TestLanguageService.instance],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ReactiveContextTestWidget(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Language: English'), findsOneWidget);
      expect(find.text('Theme: Light'), findsOneWidget);

      // State changes should still work
      TestLanguageService.switchLanguage('Optimized', 'opt');
      await tester.pump();

      expect(find.text('Language: Optimized'), findsOneWidget);
    });

    testWidgets('should handle high-frequency updates', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReactiveContextTestWidget(),
            ),
          ),
        ),
      );

      // High-frequency updates
      for (int i = 0; i < 100; i++) {
        TestLanguageService.switchLanguage('FastLang$i', 'fl$i');
        if (i % 10 == 0) {
          await tester.pump();
        }
      }

      await tester.pump();
      expect(find.text('Language: FastLang99'), findsOneWidget);
    });
  });

  group('Error Handling Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
      TestLanguageService.reset();
      TestThemeService.reset();
      // Add reactive context cleanup
      try {
        cleanupPreservedWidgets();
      } catch (e) {
        // Ignore if not available
      }
    });

    tearDown(() {
      ReactiveNotifier.cleanup();
      TestLanguageService.reset();
      TestThemeService.reset();
    });

    testWidgets('should handle missing state gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                try {
                  // This should fail gracefully since no service is registered
                  final lang = context<TestLang>();
                  return Text('Lang: ${lang.name}');
                } catch (e) {
                  return const Text('Error: Missing state handled gracefully');
                }
              },
            ),
          ),
        ),
      );

      expect(
          find.text('Error: Missing state handled gracefully'), findsOneWidget);
      expect(find.text('Lang: English'), findsNothing);
    });

    testWidgets('should handle widget tree changes', (tester) async {
      bool showWidget = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => showWidget = !showWidget),
                        child: const Text('Toggle'),
                      ),
                      if (showWidget)
                        Builder(
                          builder: (context) {
                            return Column(
                              children: [
                                Text('Language: ${context.lang.name}'),
                                Text(
                                    'Theme: ${context.theme.isDark ? 'Dark' : 'Light'}'),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Language: English'), findsOneWidget);

      // Hide widget
      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(find.text('Language: English'), findsNothing);

      // Show widget again
      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(find.text('Language: English'), findsOneWidget);
    });
  });
}
