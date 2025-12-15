# onStateChanged() Hook

## Signature

```dart
@protected
void onStateChanged(T previous, T next)
```

## Type

A protected hook method that receives the previous and next state values after any state update.

## Description

The `onStateChanged()` hook is called automatically after every state change in a ViewModel. It provides access to both the previous and new state values, enabling reactive internal logic, logging, validation, and side effects based on state transitions.

### Source Implementation

```dart
/// Hook that executes automatically after every state change
///
/// This method is called immediately after the state is updated via
/// updateState(), transformState(), or transformStateSilently().
@protected
void onStateChanged(T previous, T next) {
  // Base implementation does nothing
  // Override in subclasses to react to state changes
}
```

The hook is invoked from all state update methods:

```dart
void updateState(T newState) {
  _checkDisposed();
  final previous = _data;
  _data = newState;
  _updateCount++;
  notifyListeners();
  onStateChanged(previous, newState);  // Called here
}

void updateSilently(T newState) {
  _checkDisposed();
  final previous = _data;
  _data = newState;
  onStateChanged(previous, newState);  // Called even for silent updates
}

void transformState(T Function(T data) transformer) {
  _checkDisposed();
  final previous = _data;
  final newState = transformer(_data);
  _data = newState;
  _updateCount++;
  notifyListeners();
  onStateChanged(previous, newState);  // Called here
}

void transformStateSilently(T Function(T data) transformer) {
  _checkDisposed();
  final previous = _data;
  final newState = transformer(_data);
  _data = newState;
  _updateCount++;
  onStateChanged(previous, newState);  // Called here
}
```

## Usage Example

```dart
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel.guest());

  @override
  void init() {
    updateSilently(UserModel.guest());
  }

  @override
  void onStateChanged(UserModel previous, UserModel next) {
    // Log authentication changes
    if (previous.isLoggedIn != next.isLoggedIn) {
      if (next.isLoggedIn) {
        analytics.logEvent('user_logged_in', {'userId': next.id});
      } else {
        analytics.logEvent('user_logged_out');
      }
    }

    // Validate email changes
    if (previous.email != next.email && next.email.isNotEmpty) {
      if (!_isValidEmail(next.email)) {
        // Trigger validation error (don't update state here - infinite loop!)
        _showEmailValidationError();
      }
    }

    // Sync preferences when user changes
    if (previous.id != next.id && next.isLoggedIn) {
      _loadUserPreferences(next.id);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
```

## When to Use

### Logging and Analytics

```dart
@override
void onStateChanged(CartModel previous, CartModel next) {
  // Track cart value changes
  if (previous.totalValue != next.totalValue) {
    analytics.logEvent('cart_value_changed', {
      'previous': previous.totalValue,
      'next': next.totalValue,
      'difference': next.totalValue - previous.totalValue,
    });
  }

  // Track item additions
  if (next.items.length > previous.items.length) {
    final newItems = next.items.length - previous.items.length;
    analytics.logEvent('items_added', {'count': newItems});
  }
}
```

### Automatic Validation

```dart
@override
void onStateChanged(FormModel previous, FormModel next) {
  // Auto-validate on changes
  final errors = <String, String>{};

  if (next.email.isNotEmpty && !isValidEmail(next.email)) {
    errors['email'] = 'Invalid email format';
  }

  if (next.phone.isNotEmpty && !isValidPhone(next.phone)) {
    errors['phone'] = 'Invalid phone format';
  }

  // Store errors separately (not in state to avoid loop)
  _validationErrors = errors;
}
```

### Side Effects

```dart
@override
void onStateChanged(SettingsModel previous, SettingsModel next) {
  // Theme change
  if (previous.themeMode != next.themeMode) {
    SystemChrome.setSystemUIOverlayStyle(
      next.themeMode == ThemeMode.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark,
    );
  }

  // Locale change
  if (previous.locale != next.locale) {
    LocalizationService.setLocale(next.locale);
  }

  // Persist settings
  if (previous != next) {
    SettingsRepository.save(next);
  }
}
```

### Derived State Updates

```dart
@override
void onStateChanged(OrderModel previous, OrderModel next) {
  // Update derived calculations
  if (previous.items != next.items || previous.discount != next.discount) {
    _recalculateTotals();
  }

  // Update dependent services
  if (previous.status != next.status) {
    NotificationService.updateOrderStatus(next.id, next.status);
  }
}
```

## Best Practices

1. **Never call updateState inside onStateChanged** - This creates infinite loops:
   ```dart
   // BAD - Infinite loop!
   @override
   void onStateChanged(T previous, T next) {
     updateState(next.copyWith(validated: true));
   }

   // GOOD - Use separate variables or external services
   @override
   void onStateChanged(T previous, T next) {
     _isValidated = validateData(next);
   }
   ```

2. **Keep it lightweight** - Heavy operations should be deferred:
   ```dart
   @override
   void onStateChanged(DataModel previous, DataModel next) {
     // Quick synchronous operations only
     _logChange(previous, next);

     // Defer heavy operations
     if (previous.needsSync != next.needsSync && next.needsSync) {
       Future.microtask(() => _performSync());
     }
   }
   ```

3. **Use for cross-cutting concerns**:
   - Logging
   - Analytics
   - Validation
   - Persistence
   - External service notifications

4. **Check specific field changes** - Don't react to every update:
   ```dart
   @override
   void onStateChanged(UserModel previous, UserModel next) {
     // Only react to specific changes
     if (previous.role != next.role) {
       _handleRoleChange(next.role);
     }
   }
   ```

5. **Called for both silent and notifying updates**:
   ```dart
   updateState(newState);          // Calls onStateChanged
   updateSilently(newState);       // Also calls onStateChanged
   transformState((s) => s);       // Calls onStateChanged
   transformStateSilently((s) => s); // Also calls onStateChanged
   ```

## Comparison with listenVM

| Feature | onStateChanged | listenVM |
|---------|----------------|----------|
| Scope | Internal to ViewModel | Cross-ViewModel |
| Access | Previous + Next state | Current state only |
| Purpose | Internal reactions | External communication |
| Setup | Override method | Call in init() |

## Related

- [onAsyncStateChanged()](/doc/features/async-viewmodel/on-async-state-changed.md) - Hook for AsyncViewModelImpl
- [updateState()](/doc/features/viewmodel/methods/update-state.md) - State update with notification
- [listenVM()](/doc/features/viewmodel/methods/listen-vm.md) - Cross-ViewModel communication
