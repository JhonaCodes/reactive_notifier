# ReactiveNotifier DevTools Extension

A comprehensive debugging extension for the ReactiveNotifier state management library. This extension provides real-time monitoring, state inspection, performance analytics, and interactive debugging tools.

## Features

### 🎯 Dashboard
- **Real-time Overview**: Get an instant overview of all ReactiveNotifier instances
- **Performance Metrics**: Monitor state updates, widget rebuilds, and memory usage
- **Memory Leak Detection**: Automatically detect potential memory leaks
- **Quick Actions**: Force garbage collection, clear all instances, export debug data

### 🌳 Instance Tree
- **Instance Management**: View all active ReactiveNotifier instances in a hierarchical tree
- **Detailed Information**: See instance creation time, update count, memory usage, and current state
- **Interactive State Editing**: Modify instance state directly from the DevTools
- **Export/Import**: Export instance data for analysis or sharing

### 🔍 State Inspector
- **Real-time State Changes**: Monitor all state changes as they happen
- **State History**: View the complete history of state changes with timestamps
- **State Comparison**: See before/after values for each state change
- **Filter and Search**: Find specific state changes quickly
- **Rollback Support**: Rollback to previous states (when supported)

### 📊 Performance Panel
- **Live Performance Charts**: Real-time visualization of performance metrics
- **Memory Usage Tracking**: Monitor memory consumption over time
- **Update Frequency Analysis**: Track how often states are updated
- **Performance Insights**: Get recommendations for optimizing performance
- **Historical Data**: View performance trends over time

## Installation

### 1. Add to your pubspec.yaml

```yaml
dev_dependencies:
  reactive_notifier_devtools_extension:
    path: path/to/reactive_notifier/extension
```

### 2. Update your main app

No additional setup required! The extension automatically registers itself when running in debug mode.

### 3. Launch DevTools

```bash
flutter run
# Then open DevTools from your IDE or visit the URL shown in the console
```

## Usage

### Accessing the Extension

1. Start your Flutter app in debug mode
2. Open Flutter DevTools
3. Navigate to the "ReactiveNotifier" tab

### Dashboard Overview

The dashboard provides a quick overview of your application's state management:

- **Total Instances**: Number of active ReactiveNotifier instances
- **Active ViewModels**: Count of ViewModel and AsyncViewModelImpl instances  
- **Memory Usage**: Estimated memory consumption
- **Performance Metrics**: Update counts, rebuild frequencies, and timing data

### Inspecting Instances

Use the Instance Tree panel to:

1. **Browse Instances**: See all active instances organized by type
2. **View Details**: Click on any instance to see detailed information
3. **Edit State**: Use the built-in state editor to modify instance state
4. **Monitor Memory**: Check for potential memory leaks

### State Change Monitoring

The State Inspector provides:

1. **Live Monitoring**: See state changes as they happen
2. **Historical View**: Browse through previous state changes
3. **Filtering**: Search for specific instances or change types
4. **Detailed Analysis**: Compare before/after states

### Performance Analysis

The Performance panel offers:

1. **Real-time Charts**: Visualize performance metrics over time
2. **Memory Tracking**: Monitor memory usage patterns
3. **Performance Insights**: Get optimization recommendations
4. **Historical Analysis**: View performance trends

## Debugging Common Issues

### Memory Leaks

The extension automatically detects potential memory leaks:

- **Stale Instances**: Instances created but never updated
- **Excessive Listeners**: Instances with many active listeners
- **Undisposed ViewModels**: ViewModels that should be disposed but aren't

### Performance Issues

Look for these indicators:

- **High Update Frequency**: Too many state updates per second
- **Excessive Rebuilds**: Widget rebuilds significantly exceeding state updates
- **Memory Growth**: Steadily increasing memory usage
- **Slow Updates**: Average update time exceeding 16ms

### State Management Issues

Use the state inspector to:

- **Track State Flow**: Follow how state changes propagate
- **Identify Circular Updates**: Detect infinite update loops
- **Monitor Silent Updates**: See which updates don't trigger rebuilds
- **Verify State Consistency**: Ensure state changes are applied correctly

## API Reference

### Debug Service Integration

The extension communicates with your app through service extensions:

```dart
// Automatically available in debug mode
ReactiveNotifierDebugService.instance.recordStateChange(
  instanceId: 'MyViewModel_unique_key',
  type: 'MyViewModel',
  oldState: previousState,
  newState: currentState,
  source: 'updateState',
  isSilent: false,
);
```

### Manual Debug Triggers

You can trigger debug actions programmatically:

```dart
import 'package:reactive_notifier/reactive_notifier.dart';

// Force garbage collection
ReactiveNotifierDebugService.instance.triggerGarbageCollection();

// Export debug data
final debugData = ReactiveNotifierDebugService.instance.exportDebugData();

// Clear all instances
ReactiveNotifier.cleanup();
```

## Best Practices

### For Development

1. **Use Meaningful Names**: Give your services and ViewModels descriptive names
2. **Monitor Performance**: Keep an eye on the performance panel during development
3. **Test Memory Management**: Verify that instances are properly disposed
4. **Check State Flow**: Use the state inspector to verify your state management logic

### For Production

1. **Remove Debug Code**: The debug service is only active in debug mode
2. **Optimize Based on Insights**: Use the performance recommendations
3. **Document State Flow**: Use insights from the extension to document your state architecture

## Troubleshooting

### Extension Not Showing

- Ensure you're running in debug mode
- Check that the ReactiveNotifier library is properly imported
- Verify Flutter DevTools is up to date

### No Data Appearing

- Make sure your app is using ReactiveNotifier instances
- Check that debug service is initialized (automatic in debug mode)
- Verify that your app has active ReactiveNotifier instances

### Performance Issues in Extension

- Reduce the number of state changes being monitored
- Use filtering to focus on specific instances
- Clear history periodically using the clear button

## Contributing

Contributions are welcome! Please see the main ReactiveNotifier repository for contribution guidelines.

## License

This extension is part of the ReactiveNotifier library and follows the same license terms.