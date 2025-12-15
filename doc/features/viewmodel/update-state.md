# updateState()

Updates the ViewModel state and notifies all listeners.

## Method Signature

```dart
void updateState(T newState)
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `newState` | `T` | The new state value to replace the current state |

## Purpose

`updateState()` is the primary method for updating ViewModel state when you want the UI to react immediately. It replaces the current state with a new value and triggers a rebuild of all widgets listening to this ViewModel.

## When to Use

Use `updateState()` when:

- User actions require immediate visual feedback
- Form submissions that should show updated data
- Any state change that the user should see immediately
- Completing an operation where the result needs to be displayed

Use alternatives when:

- **`updateSilently()`**: Background updates that should not trigger rebuilds
- **`transformState()`**: Modifying current state based on existing values
- **`transformStateSilently()`**: Modifying state without triggering rebuilds

## Triggers onStateChanged?

**Yes** - The `onStateChanged(previous, next)` hook is called after the state update and notification.

## Usage Example

```dart
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel.empty());

  @override
  void init() {
    // Initial setup
  }

  // Direct replacement of entire state
  void updateUser(UserModel newUser) {
    updateState(newUser);
  }

  // Update after validation
  void setUserName(String name) {
    if (name.isEmpty) return;

    final updated = UserModel(
      id: data.id,
      name: name,
      email: data.email,
    );
    updateState(updated);
  }

  // Update from API response
  Future<void> fetchAndUpdateUser(String userId) async {
    final response = await userRepository.getUser(userId);
    updateState(response);
  }
}
```

## Best Practices

1. **Create new state objects** - Do not mutate the existing state; always pass a new instance
2. **Validate before updating** - Perform validation before calling updateState()
3. **Keep updates atomic** - Each updateState() call should represent a complete, valid state
4. **Use copyWith patterns** - For immutable state updates, prefer copyWith:

```dart
void updateEmail(String email) {
  updateState(data.copyWith(email: email));
}
```

5. **Avoid rapid consecutive calls** - Multiple rapid updateState() calls trigger multiple rebuilds; batch changes when possible:

```dart
// Avoid
void updateUserDetails(String name, String email) {
  updateState(data.copyWith(name: name));   // Rebuild 1
  updateState(data.copyWith(email: email)); // Rebuild 2
}

// Prefer
void updateUserDetails(String name, String email) {
  updateState(data.copyWith(name: name, email: email)); // Single rebuild
}
```

## Internal Behavior

When `updateState()` is called:

1. Checks if ViewModel is disposed (reinitializes if needed)
2. Stores the previous state
3. Assigns the new state
4. Increments the update counter
5. Calls `notifyListeners()` to trigger UI rebuilds
6. Executes `onStateChanged(previous, newState)` hook

## Related Methods

- [`updateSilently()`](./update-silently.md) - Update without notification
- [`transformState()`](./transform-state.md) - Transform with notification
- [`transformStateSilently()`](./transform-state-silently.md) - Transform without notification
- [`cleanState()`](./clean-state.md) - Reset to empty state
