import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

/// Tests for ReactiveNotifier computed states and derived values
/// 
/// This test suite covers computed state capabilities of ReactiveNotifier:
/// - Basic computed states derived from other states
/// - Multiple dependent states and complex dependency chains
/// - Efficient updates for computed state hierarchies
/// - Dependency injection patterns with reactive states
/// - Performance optimization for computed state networks
/// 
/// These tests verify that ReactiveNotifier can handle derived state patterns
/// where one state's value is computed from other states, creating reactive
/// dependency chains essential for complex state management architectures.
void main() {
  group('ReactiveNotifier Computed States', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('Basic Computed States', () {
      test('should handle simple computed states correctly', () {
        // Setup: Create base state and computed state
        final baseState = ReactiveNotifier<int>(() => 1);
        final computedState = ReactiveNotifier<int>(() => baseState.notifier * 2);

        // Setup: Link base state to computed state
        baseState.addListener(() => computedState.updateState(baseState.notifier * 2));

        // Assert: Initial computed state should be correct
        expect(computedState.notifier, 2,
            reason: 'Initial computed state should be base * 2 (1 * 2 = 2)');

        // Act: Update base state
        baseState.updateState(5);

        // Assert: Computed state should update automatically
        expect(baseState.notifier, 5,
            reason: 'Base state should be updated to 5');
        expect(computedState.notifier, 10,
            reason: 'Computed state should be updated to base * 2 (5 * 2 = 10)');
      });

      test('should handle computed states with complex transformations', () {
        // Setup: Create input state and computed states with different transformations
        final inputState = ReactiveNotifier<double>(() => 10.0);
        final squaredState = ReactiveNotifier<double>(() => 100.0);
        final sqrtState = ReactiveNotifier<double>(() => 0.0);
        final formattedState = ReactiveNotifier<String>(() => '');

        // Setup: Create computed state dependencies
        inputState.addListener(() {
          final input = inputState.notifier;
          squaredState.updateState(input * input);
          sqrtState.updateState(input > 0 ? sqrt(input) : 0.0);
          formattedState.updateState('Input: ${input.toStringAsFixed(2)}');
        });

        // Assert: Initial computed states should be correct
        expect(squaredState.notifier, 100.0,
            reason: 'Initial squared state should be 10² = 100');

        // Act: Update input state
        inputState.updateState(4.0);

        // Assert: All computed states should update with transformations
        expect(inputState.notifier, 4.0,
            reason: 'Input state should be updated to 4.0');
        expect(squaredState.notifier, 16.0,
            reason: 'Squared state should be updated to 4² = 16');
        expect(sqrtState.notifier, 2.0,
            reason: 'Square root state should be updated to √4 = 2');
        expect(formattedState.notifier, 'Input: 4.00',
            reason: 'Formatted state should be updated with new input');
      });

      test('should handle computed states with conditional logic', () {
        // Setup: Create input and computed states with conditional logic
        final scoreState = ReactiveNotifier<int>(() => 75);
        final gradeState = ReactiveNotifier<String>(() => 'B');
        final passFailState = ReactiveNotifier<bool>(() => true);
        final messageState = ReactiveNotifier<String>(() => '');

        // Setup: Conditional computed state logic
        scoreState.addListener(() {
          final score = scoreState.notifier;
          
          // Grade computation
          String grade;
          if (score >= 90) {
            grade = 'A';
          } else if (score >= 80) {
            grade = 'B';
          } else if (score >= 70) {
            grade = 'C';
          } else if (score >= 60) {
            grade = 'D';
          } else {
            grade = 'F';
          }
          gradeState.updateState(grade);
          
          // Pass/fail computation
          passFailState.updateState(score >= 60);
          
          // Message computation
          final status = score >= 60 ? 'PASSED' : 'FAILED';
          messageState.updateState('Score: $score, Grade: $grade, Status: $status');
        });

        // Act: Test different score ranges
        scoreState.updateState(95); // A grade

        // Assert: Computed states should reflect A grade
        expect(scoreState.notifier, 95, reason: 'Score should be 95');
        expect(gradeState.notifier, 'A', reason: 'Grade should be A for score 95');
        expect(passFailState.notifier, true, reason: 'Should pass with score 95');
        expect(messageState.notifier, 'Score: 95, Grade: A, Status: PASSED',
            reason: 'Message should reflect A grade pass');

        // Act: Test failing score
        scoreState.updateState(45); // F grade

        // Assert: Computed states should reflect F grade
        expect(gradeState.notifier, 'F', reason: 'Grade should be F for score 45');
        expect(passFailState.notifier, false, reason: 'Should fail with score 45');
        expect(messageState.notifier, 'Score: 45, Grade: F, Status: FAILED',
            reason: 'Message should reflect F grade fail');

        // Act: Test borderline passing score
        scoreState.updateState(60); // D grade

        // Assert: Computed states should reflect D grade pass
        expect(gradeState.notifier, 'D', reason: 'Grade should be D for score 60');
        expect(passFailState.notifier, true, reason: 'Should pass with score 60');
        expect(messageState.notifier, 'Score: 60, Grade: D, Status: PASSED',
            reason: 'Message should reflect D grade pass');
      });
    });

    group('Multi-Level Computed State Dependencies', () {
      test('should efficiently update multiple dependent states', () {
        // Setup: Create multi-level dependency chain
        final rootState = ReactiveNotifier<int>(() => 0);
        final computed1 = ReactiveNotifier<int>(() => 1);  // root + 1
        final computed2 = ReactiveNotifier<int>(() => 0);  // root * 2
        final computed3 = ReactiveNotifier<int>(() => 1);  // computed1 + computed2

        var rootUpdateCount = 0;
        var computed1UpdateCount = 0;
        var computed2UpdateCount = 0;
        var computed3UpdateCount = 0;

        // Setup: First level dependencies (root -> computed1, computed2)
        rootState.addListener(() {
          rootUpdateCount++;
          computed1.updateState(rootState.notifier + 1);
          computed2.updateState(rootState.notifier * 2);
        });

        // Setup: Second level dependencies (computed1, computed2 -> computed3)
        computed1.addListener(() {
          computed1UpdateCount++;
          computed3.updateState(computed1.notifier + computed2.notifier);
        });
        
        computed2.addListener(() {
          computed2UpdateCount++;
          computed3.updateState(computed1.notifier + computed2.notifier);
        });

        computed3.addListener(() {
          computed3UpdateCount++;
        });

        // Act: Update root state
        rootState.updateState(5);

        // Assert: All levels should update correctly
        expect(rootState.notifier, 5, reason: 'Root state should be 5');
        expect(computed1.notifier, 6, reason: 'Computed1 should be root + 1 (5 + 1 = 6)');
        expect(computed2.notifier, 10, reason: 'Computed2 should be root * 2 (5 * 2 = 10)');
        expect(computed3.notifier, 16, reason: 'Computed3 should be computed1 + computed2 (6 + 10 = 16)');

        // Assert: Update counts should be reasonable
        expect(rootUpdateCount, 1, reason: 'Root should update once');
        expect(computed1UpdateCount, 1, reason: 'Computed1 should update once');
        expect(computed2UpdateCount, 1, reason: 'Computed2 should update once');
        expect(computed3UpdateCount, 2, reason: 'Computed3 should update twice (once for each dependency)');
      });

      test('should handle complex dependency networks correctly', () {
        // Setup: Create complex dependency network
        final inputA = ReactiveNotifier<int>(() => 2);
        final inputB = ReactiveNotifier<int>(() => 3);
        final sumAB = ReactiveNotifier<int>(() => 5);       // A + B
        final productAB = ReactiveNotifier<int>(() => 6);   // A * B
        final powerSum = ReactiveNotifier<int>(() => 25);   // sum²
        final finalResult = ReactiveNotifier<String>(() => ''); // Complex combination

        // Setup: First level computations
        inputA.addListener(() {
          sumAB.updateState(inputA.notifier + inputB.notifier);
          productAB.updateState(inputA.notifier * inputB.notifier);
        });

        inputB.addListener(() {
          sumAB.updateState(inputA.notifier + inputB.notifier);
          productAB.updateState(inputA.notifier * inputB.notifier);
        });

        // Setup: Second level computations
        sumAB.addListener(() {
          powerSum.updateState(sumAB.notifier * sumAB.notifier);
        });

        // Setup: Final computation combining all intermediate results
        void updateFinalResult() {
          final a = inputA.notifier;
          final b = inputB.notifier;
          final sum = sumAB.notifier;
          final product = productAB.notifier;
          final power = powerSum.notifier;
          finalResult.updateState('A:$a, B:$b, Sum:$sum, Product:$product, Power:$power');
        }

        sumAB.addListener(updateFinalResult);
        productAB.addListener(updateFinalResult);
        powerSum.addListener(updateFinalResult);

        // Act: Update input A
        inputA.updateState(4);

        // Assert: All dependent computations should update
        expect(inputA.notifier, 4, reason: 'Input A should be 4');
        expect(inputB.notifier, 3, reason: 'Input B should remain 3');
        expect(sumAB.notifier, 7, reason: 'Sum should be A + B (4 + 3 = 7)');
        expect(productAB.notifier, 12, reason: 'Product should be A * B (4 * 3 = 12)');
        expect(powerSum.notifier, 49, reason: 'Power should be sum² (7² = 49)');
        expect(finalResult.notifier, 'A:4, B:3, Sum:7, Product:12, Power:49',
            reason: 'Final result should combine all computations');

        // Act: Update input B
        inputB.updateState(5);

        // Assert: Network should recompute correctly
        expect(sumAB.notifier, 9, reason: 'Sum should be updated (4 + 5 = 9)');
        expect(productAB.notifier, 20, reason: 'Product should be updated (4 * 5 = 20)');
        expect(powerSum.notifier, 81, reason: 'Power should be updated (9² = 81)');
        expect(finalResult.notifier, 'A:4, B:5, Sum:9, Product:20, Power:81',
            reason: 'Final result should reflect all updates');
      });

      test('should handle computed states with shared dependencies', () {
        // Setup: Create shared dependency scenario
        final sharedBase = ReactiveNotifier<int>(() => 10);
        final derivedA = ReactiveNotifier<int>(() => 20);   // base * 2
        final derivedB = ReactiveNotifier<int>(() => 100);  // base²
        final derivedC = ReactiveNotifier<int>(() => 50);   // base * 5
        final combinedResult = ReactiveNotifier<int>(() => 170); // A + B + C

        final updateHistory = <String>[];

        // Setup: All derived states depend on shared base
        sharedBase.addListener(() {
          updateHistory.add('base_updated');
          final base = sharedBase.notifier;
          derivedA.updateState(base * 2);
          derivedB.updateState(base * base);
          derivedC.updateState(base * 5);
        });

        // Setup: Combined result depends on all derived states
        void updateCombined() {
          updateHistory.add('combined_updated');
          combinedResult.updateState(
            derivedA.notifier + derivedB.notifier + derivedC.notifier
          );
        }

        derivedA.addListener(updateCombined);
        derivedB.addListener(updateCombined);
        derivedC.addListener(updateCombined);

        // Act: Update shared base
        sharedBase.updateState(6);

        // Assert: All derived states should update from shared dependency
        expect(sharedBase.notifier, 6, reason: 'Shared base should be 6');
        expect(derivedA.notifier, 12, reason: 'Derived A should be base * 2 (6 * 2 = 12)');
        expect(derivedB.notifier, 36, reason: 'Derived B should be base² (6² = 36)');
        expect(derivedC.notifier, 30, reason: 'Derived C should be base * 5 (6 * 5 = 30)');
        expect(combinedResult.notifier, 78, 
            reason: 'Combined result should be A + B + C (12 + 36 + 30 = 78)');

        // Assert: Update history should show correct sequence
        expect(updateHistory.contains('base_updated'), true,
            reason: 'Base update should be recorded');
        expect(updateHistory.where((h) => h == 'combined_updated').length, 3,
            reason: 'Combined should be updated 3 times (once for each derived state)');
      });
    });

    group('Dependency Injection and Service Patterns', () {
      test('should support dependency injection patterns', () {
        // Setup: Create dependency injection scenario
        const injectedDependency = 'Injected Value';
        final configState = ReactiveNotifier<String>(() => 'default_config');
        final serviceState = ReactiveNotifier<String>(() => 'Initial');
        final dependentState = ReactiveNotifier<String>(() => 'Initial');

        // Setup: Service depends on injected configuration
        configState.addListener(() {
          serviceState.updateState('Service with ${configState.notifier}');
        });

        // Setup: Dependent state uses both service and injected dependency
        serviceState.addListener(() {
          dependentState.updateState('${serviceState.notifier} and $injectedDependency');
        });

        // Assert: Initial state should use defaults
        expect(serviceState.notifier, 'Initial', reason: 'Service should start with initial state');
        expect(dependentState.notifier, 'Initial', reason: 'Dependent should start with initial state');

        // Act: Update configuration (simulating dependency injection)
        configState.updateState('production_config');

        // Assert: Service should use injected configuration
        expect(configState.notifier, 'production_config',
            reason: 'Configuration should be updated');
        expect(serviceState.notifier, 'Service with production_config',
            reason: 'Service should use injected configuration');
        expect(dependentState.notifier, 'Service with production_config and Injected Value',
            reason: 'Dependent should combine service state and injected dependency');
      });

      test('should handle service locator patterns with computed states', () {
        // Setup: Create service locator pattern
        final serviceRegistry = ReactiveNotifier<Map<String, String>>(() => {});
        final userService = ReactiveNotifier<String>(() => 'No User Service');
        final dataService = ReactiveNotifier<String>(() => 'No Data Service');
        final appState = ReactiveNotifier<String>(() => 'App Not Ready');

        // Setup: Services depend on registry
        serviceRegistry.addListener(() {
          final registry = serviceRegistry.notifier;
          
          if (registry.containsKey('userService')) {
            userService.updateState('User Service: ${registry['userService']}');
          }
          
          if (registry.containsKey('dataService')) {
            dataService.updateState('Data Service: ${registry['dataService']}');
          }
        });

        // Setup: App state depends on all services
        void updateAppState() {
          final user = userService.notifier;
          final data = dataService.notifier;
          if (!user.contains('No') && !data.contains('No')) {
            appState.updateState('App Ready with $user and $data');
          }
        }

        userService.addListener(updateAppState);
        dataService.addListener(updateAppState);

        // Act: Register services in the service locator
        serviceRegistry.updateState({
          'userService': 'Active',
          'dataService': 'Connected'
        });

        // Assert: All services should be resolved and app should be ready
        expect(userService.notifier, 'User Service: Active',
            reason: 'User service should be resolved from registry');
        expect(dataService.notifier, 'Data Service: Connected',
            reason: 'Data service should be resolved from registry');
        expect(appState.notifier, 'App Ready with User Service: Active and Data Service: Connected',
            reason: 'App state should reflect all resolved services');
      });

      test('should handle factory pattern with computed configurations', () {
        // Setup: Create factory pattern with computed configurations
        final environmentConfig = ReactiveNotifier<String>(() => 'development');
        final databaseConfig = ReactiveNotifier<Map<String, String>>(() => {});
        final apiConfig = ReactiveNotifier<Map<String, String>>(() => {});
        final factoryOutput = ReactiveNotifier<String>(() => 'Not Configured');

        // Setup: Configurations depend on environment
        environmentConfig.addListener(() {
          final env = environmentConfig.notifier;
          
          if (env == 'development') {
            databaseConfig.updateState({
              'host': 'localhost',
              'port': '5432',
              'name': 'dev_db'
            });
            apiConfig.updateState({
              'baseUrl': 'http://localhost:3000',
              'timeout': '5000'
            });
          } else if (env == 'production') {
            databaseConfig.updateState({
              'host': 'prod-server.com',
              'port': '5432',
              'name': 'prod_db'
            });
            apiConfig.updateState({
              'baseUrl': 'https://api.production.com',
              'timeout': '10000'
            });
          }
        });

        // Setup: Factory creates output based on configurations
        void updateFactory() {
          final dbConfig = databaseConfig.notifier;
          final apiConf = apiConfig.notifier;
          
          if (dbConfig.isNotEmpty && apiConf.isNotEmpty) {
            factoryOutput.updateState(
              'Factory configured for ${environmentConfig.notifier}: '
              'DB=${dbConfig['host']}:${dbConfig['port']}/${dbConfig['name']}, '
              'API=${apiConf['baseUrl']} (timeout=${apiConf['timeout']}ms)'
            );
          }
        }

        databaseConfig.addListener(updateFactory);
        apiConfig.addListener(updateFactory);

        // Act: Switch to production environment
        environmentConfig.updateState('production');

        // Assert: Factory should be configured for production
        expect(environmentConfig.notifier, 'production',
            reason: 'Environment should be set to production');
        expect(databaseConfig.notifier['host'], 'prod-server.com',
            reason: 'Database config should be for production');
        expect(apiConfig.notifier['baseUrl'], 'https://api.production.com',
            reason: 'API config should be for production');
        expect(factoryOutput.notifier, 
            'Factory configured for production: '
            'DB=prod-server.com:5432/prod_db, '
            'API=https://api.production.com (timeout=10000ms)',
            reason: 'Factory should output production configuration');

        // Act: Switch back to development
        environmentConfig.updateState('development');

        // Assert: Factory should reconfigure for development
        expect(databaseConfig.notifier['host'], 'localhost',
            reason: 'Database config should switch to development');
        expect(apiConfig.notifier['baseUrl'], 'http://localhost:3000',
            reason: 'API config should switch to development');
        expect(factoryOutput.notifier,
            'Factory configured for development: '
            'DB=localhost:5432/dev_db, '
            'API=http://localhost:3000 (timeout=5000ms)',
            reason: 'Factory should output development configuration');
      });
    });

    group('Performance Optimization for Computed Networks', () {
      test('should efficiently handle large computed state networks', () {
        // Setup: Create large network of computed states
        final sourceStates = List.generate(10, (i) => ReactiveNotifier<int>(() => i));
        final computedStates = List.generate(10, (i) => ReactiveNotifier<int>(() => 0));
        final finalAggregation = ReactiveNotifier<int>(() => 0);

        var totalUpdates = 0;

        // Setup: Each computed state depends on corresponding source state
        for (int i = 0; i < sourceStates.length; i++) {
          sourceStates[i].addListener(() {
            totalUpdates++;
            computedStates[i].updateState(sourceStates[i].notifier * (i + 1));
          });
        }

        // Setup: Final aggregation depends on all computed states
        for (final computedState in computedStates) {
          computedState.addListener(() {
            totalUpdates++;
            final sum = computedStates.fold<int>(0, (sum, state) => sum + state.notifier);
            finalAggregation.updateState(sum);
          });
        }

        // Act: Update all source states simultaneously
        final startTime = DateTime.now();
        for (int i = 0; i < sourceStates.length; i++) {
          sourceStates[i].updateState(i + 10);
        }
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Assert: Network should update efficiently
        expect(duration.inMilliseconds, lessThan(100),
            reason: 'Large computed network should update quickly');
        expect(totalUpdates, greaterThan(sourceStates.length),
            reason: 'Should have updates for sources and aggregations');

        // Verify final aggregation is correct
        final expectedSum = computedStates.fold<int>(0, (sum, state) => sum + state.notifier);
        expect(finalAggregation.notifier, expectedSum,
            reason: 'Final aggregation should be sum of all computed states');
      });

      test('should optimize redundant computations in computed networks', () {
        // Setup: Create scenario with potential redundant computations
        final baseValue = ReactiveNotifier<int>(() => 5);
        final expensiveComputation = ReactiveNotifier<int>(() => 25);
        final cheapComputation1 = ReactiveNotifier<int>(() => 10);
        final cheapComputation2 = ReactiveNotifier<int>(() => 15);
        final finalResult = ReactiveNotifier<String>(() => '');

        var expensiveComputationCount = 0;
        var cheapComputation1Count = 0;
        var cheapComputation2Count = 0;

        // Setup: Expensive computation (simulate with delay and counter)
        baseValue.addListener(() {
          expensiveComputationCount++;
          // Simulate expensive operation
          final result = baseValue.notifier * baseValue.notifier;
          expensiveComputation.updateState(result);
        });

        // Setup: Cheap computations
        baseValue.addListener(() {
          cheapComputation1Count++;
          cheapComputation1.updateState(baseValue.notifier * 2);
        });

        baseValue.addListener(() {
          cheapComputation2Count++;
          cheapComputation2.updateState(baseValue.notifier * 3);
        });

        // Setup: Final result combines all computations
        void updateFinalResult() {
          finalResult.updateState(
            'Base:${baseValue.notifier}, '
            'Expensive:${expensiveComputation.notifier}, '
            'Cheap1:${cheapComputation1.notifier}, '
            'Cheap2:${cheapComputation2.notifier}'
          );
        }

        expensiveComputation.addListener(updateFinalResult);
        cheapComputation1.addListener(updateFinalResult);
        cheapComputation2.addListener(updateFinalResult);

        // Act: Update base value once
        baseValue.updateState(8);

        // Assert: Each computation should run exactly once per base update
        expect(expensiveComputationCount, 1,
            reason: 'Expensive computation should run exactly once');
        expect(cheapComputation1Count, 1,
            reason: 'Cheap computation 1 should run exactly once');
        expect(cheapComputation2Count, 1,
            reason: 'Cheap computation 2 should run exactly once');
        expect(finalResult.notifier, 'Base:8, Expensive:64, Cheap1:16, Cheap2:24',
            reason: 'Final result should reflect all computations');
      });
    });
  });
}