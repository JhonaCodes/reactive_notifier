# data Getter

## Signature

```dart
T get data
```

## Type

Returns the current state of type `T` held by the ViewModel.

## Description

The `data` getter provides read access to the current state managed by the ViewModel. It includes an automatic disposed-state check that triggers reinitialization if the ViewModel was previously disposed.

### Source Implementation

```dart
T get data {
  _checkDisposed();
  return _data;
}
```

The `_checkDisposed()` method automatically handles reinitialization if the ViewModel was disposed, enabling the "create once, reuse always" philosophy.

## Usage Example

```dart
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel.empty());

  @override
  void init() {
    updateSilently(UserModel(name: 'Guest', email: ''));
  }

  // Access current state
  String get userName => data.name;
  bool get hasEmail => data.email.isNotEmpty;
}

// In widget (NOT recommended - use ReactiveBuilder instead)
final currentName = UserService.userState.notifier.data.name;
```

## When to Use

### Recommended Usage

1. **Inside ViewModel methods** - Access current state for business logic:
   ```dart
   void updateEmail(String email) {
     if (data.email != email) {
       updateState(data.copyWith(email: email));
     }
   }
   ```

2. **Computed properties** - Create derived values:
   ```dart
   bool get isComplete => data.name.isNotEmpty && data.email.isNotEmpty;
   ```

3. **Inside `listenVM` callbacks** - React to state from other ViewModels:
   ```dart
   OtherService.viewModel.notifier.listenVM((otherData) {
     updateState(data.copyWith(relatedField: otherData.value));
   });
   ```

### Not Recommended

- **Direct access in widgets** - Changes will not trigger rebuilds:
  ```dart
  // BAD: Won't update when state changes
  Text(UserService.userState.notifier.data.name)

  // GOOD: Always receives updates
  ReactiveViewModelBuilder<UserViewModel, UserModel>(
    viewmodel: UserService.userState.notifier,
    build: (user, vm, keep) => Text(user.name),
  )
  ```

## Best Practices

1. **Use ReactiveBuilder for UI** - Always access `data` through builders for automatic updates
2. **Use for internal logic** - Access `data` directly inside ViewModel methods
3. **Avoid storing references** - Do not cache `data` in variables; always access fresh
4. **Trust auto-reinitialization** - The getter handles disposed state automatically

## Related

- [updateState()](/docs/features/viewmodel/methods/update-state.md) - Update state with notification
- [updateSilently()](/docs/features/viewmodel/methods/update-silently.md) - Update state without notification
- [transformState()](/docs/features/viewmodel/methods/transform-state.md) - Transform current state
