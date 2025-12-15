# stopSpecificListener() - Remove a Single Listener

## Method Signature

```dart
void stopSpecificListener(String listenerKey)
```

## Purpose

`stopSpecificListener()` removes a single listener by its unique key while preserving all other active listeners. This provides granular control over listener management when you need to disconnect from one specific source without affecting other listener relationships.

This method is useful when a ViewModel listens to multiple services but needs to selectively disconnect from just one, such as stopping updates from an expensive service while maintaining essential listeners.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `listenerKey` | `String` | Yes | The unique identifier for the listener to remove. Keys are generated in the format `'vm_${hashCode}_${microsecondsSinceEpoch}'` |

## Return Type

**`void`** - This method does not return a value.

## Usage Example: Cross-Service Selective Disconnection

```dart
// Service definitions
mixin UserService {
  static final ReactiveNotifier<UserViewModel> userState =
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

mixin AnalyticsService {
  static final ReactiveNotifier<AnalyticsViewModel> analytics =
    ReactiveNotifier<AnalyticsViewModel>(() => AnalyticsViewModel());
}

mixin ExpensiveDataService {
  static final ReactiveNotifier<ExpensiveDataViewModel> expensiveData =
    ReactiveNotifier<ExpensiveDataViewModel>(() => ExpensiveDataViewModel());
}

// ViewModel with selective listener management
class DashboardViewModel extends ViewModel<DashboardModel> {
  DashboardViewModel() : super(DashboardModel.initial());

  // Store listener keys for granular control
  String? _userListenerKey;
  String? _analyticsListenerKey;
  String? _expensiveDataListenerKey;

  UserModel? currentUser;
  AnalyticsModel? currentAnalytics;
  ExpensiveDataModel? expensiveData;

  @override
  void init() {
    // Track listener keys by capturing them during setup
    _setupUserListener();
    _setupAnalyticsListener();
    _setupExpensiveDataListener();
  }

  void _setupUserListener() {
    // Generate key before setup
    _userListenerKey = _generateListenerKey();

    currentUser = UserService.userState.notifier.listenVM((user) {
      currentUser = user;
      _updateDashboard();
    });
  }

  void _setupAnalyticsListener() {
    _analyticsListenerKey = _generateListenerKey();

    currentAnalytics = AnalyticsService.analytics.notifier.listenVM((analytics) {
      currentAnalytics = analytics;
      _updateDashboard();
    });
  }

  void _setupExpensiveDataListener() {
    _expensiveDataListenerKey = _generateListenerKey();

    expensiveData = ExpensiveDataService.expensiveData.notifier.listenVM((data) {
      expensiveData = data;
      _updateDashboard();
    });
  }

  String _generateListenerKey() {
    return 'vm_${hashCode}_${DateTime.now().microsecondsSinceEpoch}';
  }

  void _updateDashboard() {
    if (currentUser == null) return;

    transformState((state) => state.copyWith(
      userName: currentUser!.name,
      pageViews: currentAnalytics?.pageViews ?? 0,
      heavyDataLoaded: expensiveData != null,
    ));
  }

  /// Stop only the expensive data listener to save resources
  void pauseExpensiveDataUpdates() {
    if (_expensiveDataListenerKey != null) {
      stopSpecificListener(_expensiveDataListenerKey!);
      _expensiveDataListenerKey = null;
      expensiveData = null;  // Clear stale reference
    }
  }

  /// Resume expensive data updates
  void resumeExpensiveDataUpdates() {
    if (_expensiveDataListenerKey == null) {
      _setupExpensiveDataListener();
    }
  }

  /// Stop analytics listener (e.g., user opted out)
  void disableAnalytics() {
    if (_analyticsListenerKey != null) {
      stopSpecificListener(_analyticsListenerKey!);
      _analyticsListenerKey = null;
      currentAnalytics = null;
    }
  }
}
```

## Complete Usage Example: Conditional Listening Based on User Preferences

```dart
mixin PreferencesService {
  static final ReactiveNotifier<PreferencesViewModel> preferences =
    ReactiveNotifier<PreferencesViewModel>(() => PreferencesViewModel());
}

mixin RealTimeService {
  static final ReactiveNotifier<RealTimeViewModel> realTime =
    ReactiveNotifier<RealTimeViewModel>(() => RealTimeViewModel());
}

mixin BackgroundSyncService {
  static final ReactiveNotifier<BackgroundSyncViewModel> backgroundSync =
    ReactiveNotifier<BackgroundSyncViewModel>(() => BackgroundSyncViewModel());
}

class AppStateViewModel extends ViewModel<AppStateModel> {
  AppStateViewModel() : super(AppStateModel.initial());

  // Track listener keys for selective removal
  final Map<String, String> _listenerKeys = {};

  PreferencesModel? currentPreferences;

  @override
  void init() {
    // Always listen to preferences
    currentPreferences = PreferencesService.preferences.notifier.listenVM((prefs) {
      currentPreferences = prefs;
      _handlePreferencesChange(prefs);
    }, callOnInit: true);
  }

  void _handlePreferencesChange(PreferencesModel prefs) {
    // Enable/disable real-time updates based on user preference
    if (prefs.enableRealTimeUpdates) {
      _enableRealTimeListener();
    } else {
      _disableRealTimeListener();
    }

    // Enable/disable background sync based on user preference
    if (prefs.enableBackgroundSync) {
      _enableBackgroundSyncListener();
    } else {
      _disableBackgroundSyncListener();
    }
  }

  void _enableRealTimeListener() {
    if (_listenerKeys.containsKey('realTime')) return;  // Already listening

    final key = 'vm_${hashCode}_${DateTime.now().microsecondsSinceEpoch}';
    _listenerKeys['realTime'] = key;

    RealTimeService.realTime.notifier.listenVM((realTimeData) {
      transformState((state) => state.copyWith(
        realTimeData: realTimeData,
        lastRealTimeUpdate: DateTime.now(),
      ));
    });
  }

  void _disableRealTimeListener() {
    final key = _listenerKeys['realTime'];
    if (key != null) {
      stopSpecificListener(key);
      _listenerKeys.remove('realTime');
    }
  }

  void _enableBackgroundSyncListener() {
    if (_listenerKeys.containsKey('backgroundSync')) return;

    final key = 'vm_${hashCode}_${DateTime.now().microsecondsSinceEpoch}';
    _listenerKeys['backgroundSync'] = key;

    BackgroundSyncService.backgroundSync.notifier.listenVM((syncData) {
      transformState((state) => state.copyWith(
        syncStatus: syncData.status,
        lastSyncTime: syncData.lastSyncTime,
      ));
    });
  }

  void _disableBackgroundSyncListener() {
    final key = _listenerKeys['backgroundSync'];
    if (key != null) {
      stopSpecificListener(key);
      _listenerKeys.remove('backgroundSync');
    }
  }
}
```

## Best Practices

### 1. Track Listener Keys When Setting Up

Since listener keys are generated internally, track them when setting up listeners:

```dart
class MyViewModel extends ViewModel<MyModel> {
  final Map<String, String> _activeListenerKeys = {};

  void _setupListener(String serviceName, VoidCallback setupFn) {
    // Generate key before setup
    final key = 'vm_${hashCode}_${DateTime.now().microsecondsSinceEpoch}';
    _activeListenerKeys[serviceName] = key;
    setupFn();
  }

  void _removeListener(String serviceName) {
    final key = _activeListenerKeys[serviceName];
    if (key != null) {
      stopSpecificListener(key);
      _activeListenerKeys.remove(serviceName);
    }
  }
}
```

### 2. Check If Listener Exists Before Stopping

Always verify the listener key exists before attempting removal:

```dart
void stopUserListener() {
  if (_userListenerKey != null) {
    stopSpecificListener(_userListenerKey!);
    _userListenerKey = null;
    currentUser = null;
  }
}
```

### 3. Clear Associated Instance Variables

After stopping a listener, clear the associated instance variable to avoid stale data:

```dart
void pauseAnalytics() {
  if (_analyticsListenerKey != null) {
    stopSpecificListener(_analyticsListenerKey!);
    _analyticsListenerKey = null;
    currentAnalytics = null;  // Prevent using stale data
  }
}
```

### 4. Consider stopListeningVM() for Full Cleanup

If you need to stop all listeners, use `stopListeningVM()` instead:

```dart
// Stop one listener
stopSpecificListener(specificKey);

// Stop all listeners
stopListeningVM();
```

### 5. Use Descriptive Key Names in Tracking Map

Use meaningful names when tracking multiple listener keys:

```dart
final Map<String, String> _listenerKeys = {};

// Use descriptive names
_listenerKeys['userService'] = key;
_listenerKeys['cartService'] = key;
_listenerKeys['settingsService'] = key;
```

## Memory Considerations

### What Gets Cleaned Up

When `stopSpecificListener()` is called with a valid key:

1. **ChangeNotifier Listener Removed**: The specific callback is removed from the underlying ChangeNotifier
2. **Internal Tracking Updated**: The entry is removed from both `_listeners` and `_listeningTo` maps
3. **Reference Released**: The specific callback closure is released for garbage collection

### Partial Cleanup

Unlike `stopListeningVM()` which clears all listeners, this method only affects one:

```dart
// Before: 3 active listeners
log('Active: ${activeListenerCount}');  // 3

stopSpecificListener(analyticsKey);

// After: 2 active listeners remain
log('Active: ${activeListenerCount}');  // 2
```

### Safe No-Op Behavior

If the key does not exist, the method safely does nothing:

```dart
// This is safe - no error thrown if key doesn't exist
stopSpecificListener('non_existent_key');
```

### Monitoring Listener Count

Use `activeListenerCount` to verify cleanup:

```dart
void debugListenerStatus() {
  log('Before removal: ${activeListenerCount}');
  stopSpecificListener(someKey);
  log('After removal: ${activeListenerCount}');
}
```

## Source Reference

**File**: `lib/src/viewmodel/viewmodel_impl.dart`

**Lines**: 641-659

```dart
void stopSpecificListener(String listenerKey) {
  final callback = _listeners[listenerKey];
  if (callback != null) {
    removeListener(callback);
    _listeners.remove(listenerKey);
    _listeningTo.remove(listenerKey);

    assert(() {
      log('''
      ViewModel<${T.toString()}> stopped specific listener
      Listener key: $listenerKey
      Remaining listeners: ${_listeners.length}
      ''', level: 5);
      return true;
    }());
  }
}
```

## Related Methods

- [listenVM()](listen-vm.md) - Register a listener for reactive communication
- [stopListeningVM()](stop-listening-vm.md) - Remove all listeners at once
