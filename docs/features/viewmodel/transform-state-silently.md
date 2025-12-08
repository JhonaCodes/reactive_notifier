# transformStateSilently()

Transforms the current state using a function without notifying listeners.

## Method Signature

```dart
void transformStateSilently(T Function(T data) transformer)
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `transformer` | `T Function(T data)` | A function that receives the current state and returns the new state |

## Purpose

`transformStateSilently()` combines the functional transformation approach of `transformState()` with the silent update behavior of `updateSilently()`. Use this when you need to modify state based on current values without triggering UI rebuilds.

## When to Use

Use `transformStateSilently()` when:

- Background processing that modifies existing state
- Accumulating data before a single UI update
- Internal state normalization or cleanup
- Preparing state for later notification
- Batch transformations where only the final result matters

Use alternatives when:

- **`updateState()`**: Replacing state entirely with immediate notification
- **`updateSilently()`**: Setting state without needing current value
- **`transformState()`**: Transforming state with immediate notification

## Triggers onStateChanged?

**Yes** - The `onStateChanged(previous, next)` hook is still called, allowing internal reactions even without UI notification.

## Usage Example

```dart
class AnalyticsViewModel extends ViewModel<AnalyticsModel> {
  AnalyticsViewModel() : super(AnalyticsModel.empty());

  @override
  void init() {
    updateSilently(AnalyticsModel.empty());
  }

  // Accumulate events without UI updates
  void trackEvent(AnalyticsEvent event) {
    transformStateSilently((state) => state.copyWith(
      events: [...state.events, event],
      lastEventAt: DateTime.now(),
    ));
  }

  // Batch process multiple events silently
  void processBatchEvents(List<AnalyticsEvent> events) {
    for (final event in events) {
      transformStateSilently((state) => state.copyWith(
        events: [...state.events, event],
        eventCount: state.eventCount + 1,
      ));
    }
    // Single notification after all processing
    notifyListeners();
  }

  // Background aggregation
  void aggregateMetrics() {
    transformStateSilently((state) {
      final totalDuration = state.events
          .map((e) => e.duration)
          .fold(Duration.zero, (a, b) => a + b);

      return state.copyWith(
        aggregatedDuration: totalDuration,
        averageDuration: totalDuration ~/ state.events.length,
      );
    });
  }

  // Normalize data without UI flicker
  void normalizeData() {
    transformStateSilently((state) => state.copyWith(
      events: state.events
          .where((e) => e.isValid)
          .map((e) => e.normalized())
          .toList(),
    ));
  }

  // Flush accumulated data with single UI update
  void flushAndNotify() {
    aggregateMetrics();
    normalizeData();
    notifyListeners(); // Single rebuild with all changes
  }
}
```

## Best Practices

1. **Use for accumulation patterns** - Collect multiple changes before notification:

```dart
class FormViewModel extends ViewModel<FormModel> {
  void validateAllFields() {
    // Validate each field silently
    transformStateSilently((s) => s.copyWith(
      nameError: validateName(s.name),
    ));
    transformStateSilently((s) => s.copyWith(
      emailError: validateEmail(s.email),
    ));
    transformStateSilently((s) => s.copyWith(
      phoneError: validatePhone(s.phone),
    ));

    // Single notification with all validation results
    notifyListeners();
  }
}
```

2. **Combine with explicit notification**:

```dart
void processAndShow() {
  // Multiple silent transformations
  transformStateSilently((s) => s.copyWith(step1: process1(s)));
  transformStateSilently((s) => s.copyWith(step2: process2(s)));
  transformStateSilently((s) => s.copyWith(step3: process3(s)));

  // Update UI once
  updateState(data);
}
```

3. **Background data preparation**:

```dart
Future<void> prepareDataInBackground() async {
  for (final item in await fetchItems()) {
    transformStateSilently((s) => s.copyWith(
      items: [...s.items, item],
      loadedCount: s.loadedCount + 1,
    ));

    // Allow other operations to run
    await Future.delayed(Duration.zero);
  }
}
```

4. **State normalization**:

```dart
void normalizeBeforeSave() {
  transformStateSilently((state) => state.copyWith(
    name: state.name.trim(),
    email: state.email.toLowerCase().trim(),
    phone: normalizePhoneNumber(state.phone),
  ));

  // Save normalized data
  repository.save(data);
}
```

## Internal Behavior

When `transformStateSilently()` is called:

1. Checks if ViewModel is disposed (reinitializes if needed)
2. Stores the previous state
3. Executes the transformer function with current state
4. Assigns the returned value as new state
5. Increments the update counter
6. Executes `onStateChanged(previous, newState)` hook
7. Does NOT call `notifyListeners()`

## Common Patterns

### Accumulation Pattern

```dart
void accumulateResults(List<Result> results) {
  for (final result in results) {
    transformStateSilently((s) => s.copyWith(
      results: [...s.results, result],
    ));
  }
  notifyListeners(); // Single notification
}
```

### Pre-processing Pattern

```dart
void processAndDisplay(RawData raw) {
  // Silent preprocessing
  transformStateSilently((s) => s.copyWith(rawData: raw));
  transformStateSilently((s) => s.copyWith(parsed: parse(s.rawData)));
  transformStateSilently((s) => s.copyWith(validated: validate(s.parsed)));

  // Show final result
  transformState((s) => s.copyWith(displayData: s.validated));
}
```

### Cleanup Pattern

```dart
void cleanupOldData() {
  transformStateSilently((state) => state.copyWith(
    items: state.items.where((i) => !i.isExpired).toList(),
    lastCleanup: DateTime.now(),
  ));
}
```

## Related Methods

- [`updateState()`](./update-state.md) - Update with notification
- [`updateSilently()`](./update-silently.md) - Update without notification
- [`transformState()`](./transform-state.md) - Transform with notification
- [`cleanState()`](./clean-state.md) - Reset to empty state
