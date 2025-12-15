# cleanState()

Resets the ViewModel to an empty state without disposing it.

## Method Signature

```dart
void cleanState()
```

## Parameters

None.

## Purpose

`cleanState()` resets the ViewModel to a fresh, empty state while keeping the ViewModel instance alive. This is useful for scenarios like user logout, form reset, or clearing cached data without destroying the ViewModel's singleton instance.

## When to Use

Use `cleanState()` when:

- User logs out and data should be cleared
- Resetting a form to initial empty state
- Clearing cached data while keeping the ViewModel ready
- Preparing for a new session without app restart
- Memory optimization by releasing held data

Use alternatives when:

- **`updateState()`**: Setting specific new values
- **`dispose()`**: Permanently destroying the ViewModel
- **`transformState()`**: Modifying existing state rather than clearing

## Triggers onStateChanged?

**Yes** - The `onStateChanged(previous, next)` hook is triggered via the internal `updateState()` call with the empty state.

## Usage Example

```dart
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel.empty());

  @override
  void init() {
    // Load user if authenticated
    final savedUser = authService.currentUser;
    if (savedUser != null) {
      updateSilently(savedUser);
    }
  }

  // Override to provide empty state definition
  @override
  UserModel _createEmptyState() => UserModel.empty();

  // Call cleanState on logout
  void logout() {
    // Clear auth tokens
    authService.clearTokens();

    // Reset to empty state
    cleanState();
  }
}

// Usage in logout flow
class LogoutController {
  void performLogout() {
    // Clear all user-related ViewModels
    UserService.userState.notifier.cleanState();
    CartService.cartState.notifier.cleanState();
    PreferencesService.prefsState.notifier.cleanState();

    // Navigate to login
    navigator.pushReplacementNamed('/login');
  }
}
```

## Implementation Requirements

For `cleanState()` to work correctly, override `_createEmptyState()` in your ViewModel:

```dart
class CartViewModel extends ViewModel<CartModel> {
  CartViewModel() : super(CartModel.empty());

  @override
  void init() {
    updateSilently(CartModel.empty());
  }

  // Required: Define what "empty" means for this ViewModel
  @override
  CartModel _createEmptyState() => CartModel(
    items: [],
    total: 0.0,
    discount: 0.0,
    createdAt: DateTime.now(),
  );

  void clearCart() {
    cleanState(); // Uses _createEmptyState()
  }
}
```

## Best Practices

1. **Always override _createEmptyState()** - Provide meaningful empty state:

```dart
@override
UserModel _createEmptyState() => UserModel(
  id: '',
  name: '',
  email: '',
  isGuest: true,
  createdAt: DateTime.now(),
);
```

2. **Use for logout flows** - Clear sensitive data:

```dart
void secureLogout() {
  // Remove listeners first
  removeListeners();

  // Clear state
  cleanState();

  // Additional cleanup
  secureStorage.deleteAll();
}
```

3. **Coordinate across services** - Clean related ViewModels together:

```dart
mixin AppService {
  static void clearAllUserData() {
    UserService.userState.notifier.cleanState();
    SessionService.sessionState.notifier.cleanState();
    NotificationService.notificationState.notifier.cleanState();
    // ViewModels remain alive but empty
  }
}
```

4. **Combine with listener cleanup**:

```dart
void resetForNewUser() {
  // Remove external listeners
  removeListeners();

  // Clear state
  cleanState();

  // Reinitialize for new user
  init();
  setupListeners();
}
```

5. **Use for form reset**:

```dart
class FormViewModel extends ViewModel<FormModel> {
  @override
  FormModel _createEmptyState() => FormModel(
    fields: {},
    errors: {},
    isDirty: false,
    isSubmitting: false,
  );

  void resetForm() {
    cleanState(); // Back to initial empty form
  }
}
```

## Internal Behavior

When `cleanState()` is called:

1. Checks if ViewModel is disposed (reinitializes if needed)
2. Calls `removeListeners()` asynchronously
3. Creates empty state via `_createEmptyState()`
4. Calls `updateState(emptyState)` which:
   - Updates internal `_data`
   - Increments update counter
   - Calls `notifyListeners()`
   - Executes `onStateChanged(previous, emptyState)` hook

## Important Notes

- The ViewModel instance remains alive and can be reused
- Listeners are removed to prevent stale callbacks
- UI will rebuild with the empty state
- The `onStateChanged` hook receives the previous state and empty state
- Default `_createEmptyState()` returns current data - always override for meaningful behavior

## Difference from dispose()

| Aspect | cleanState() | dispose() |
|--------|--------------|-----------|
| Instance | Kept alive | Destroyed |
| Listeners | Removed | Removed |
| State | Reset to empty | N/A |
| Reusable | Yes, immediately | Requires reinitialization |
| UI notification | Yes | No |

## Related Methods

- [`updateState()`](./update-state.md) - Update with notification
- [`updateSilently()`](./update-silently.md) - Update without notification
- [`transformState()`](./transform-state.md) - Transform with notification
- [`transformStateSilently()`](./transform-state-silently.md) - Transform without notification
