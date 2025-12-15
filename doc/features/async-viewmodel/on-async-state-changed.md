# onAsyncStateChanged()

## Method Signature

```dart
@protected
void onAsyncStateChanged(AsyncState<T> previous, AsyncState<T> next)
```

## Purpose

A hook that executes automatically after every async state change in the ViewModel. Override this method to react to state transitions, implement logging, trigger side effects, update analytics, or perform any action that should occur when the async state changes.

**Key Feature:** This hook is called even for silent updates (`updateSilently`, `transformStateSilently`, `transformDataStateSilently`), making it reliable for logging and analytics that should capture all state changes.

## Parameters

### previous

**Type:** `AsyncState<T>`

The state before the change occurred. Provides access to:
- `previous.status` - The previous `AsyncStatus` enum value
- `previous.data` - The previous data (if it was a success state)
- `previous.error` - The previous error (if it was an error state)
- `previous.stackTrace` - The previous stack trace (if available)
- State check properties: `previous.isInitial`, `previous.isLoading`, `previous.isSuccess`, `previous.isEmpty`, `previous.isError`

### next

**Type:** `AsyncState<T>`

The state after the change. Same properties as `previous`.

## Return Type

`void`

## Annotation

`@protected` - Intended to be overridden in subclasses, not called directly from external code.

## When It Is Called

The hook is triggered by the following methods:

| Method | Notifies Listeners | Triggers Hook |
|--------|-------------------|---------------|
| `updateState()` | Yes | Yes |
| `updateSilently()` | No | No* |
| `loadingState()` | Yes | Yes |
| `errorState()` | Yes | Yes |
| `cleanState()` | Yes | Yes |
| `transformState()` | Yes | Yes |
| `transformStateSilently()` | No | Yes |
| `transformDataState()` | Yes | Yes |
| `transformDataStateSilently()` | No | Yes |

*Note: `updateSilently()` does not trigger the hook, but `transformStateSilently()` and `transformDataStateSilently()` do.

## Usage Example

### Basic State Transition Logging

```dart
class UserViewModel extends AsyncViewModelImpl<User> {
  UserViewModel() : super(AsyncState.initial());

  @override
  Future<User> init() async {
    return await userRepository.getCurrentUser();
  }

  @override
  void onAsyncStateChanged(AsyncState<User> previous, AsyncState<User> next) {
    log('State transition: ${previous.status} -> ${next.status}');

    if (next.isSuccess) {
      log('User loaded: ${next.data?.name}');
    }

    if (next.isError) {
      log('Error occurred: ${next.error}');
    }
  }
}
```

### Analytics Tracking

```dart
class ProductViewModel extends AsyncViewModelImpl<Product> {
  final Analytics _analytics;

  ProductViewModel({Analytics? analytics})
      : _analytics = analytics ?? Analytics(),
        super(AsyncState.initial());

  @override
  void onAsyncStateChanged(AsyncState<Product> previous, AsyncState<Product> next) {
    // Track loading start
    if (previous.isInitial && next.isLoading) {
      _analytics.track('ProductLoad_Started');
    }

    // Track successful load
    if (previous.isLoading && next.isSuccess) {
      _analytics.track('ProductLoad_Success', {
        'productId': next.data?.id,
        'loadTimeMs': _calculateLoadTime(),
      });
    }

    // Track errors
    if (next.isError) {
      _analytics.track('ProductLoad_Error', {
        'errorType': next.error.runtimeType.toString(),
        'errorMessage': next.error.toString(),
      });
    }

    // Track data changes
    if (previous.isSuccess && next.isSuccess) {
      if (previous.data?.price != next.data?.price) {
        _analytics.track('ProductPrice_Changed', {
          'oldPrice': previous.data?.price,
          'newPrice': next.data?.price,
        });
      }
    }
  }
}
```

### Error Reporting

```dart
class OrderViewModel extends AsyncViewModelImpl<Order> {
  final ErrorReporter _errorReporter;

  OrderViewModel({ErrorReporter? errorReporter})
      : _errorReporter = errorReporter ?? ErrorReporter(),
        super(AsyncState.initial());

  @override
  void onAsyncStateChanged(AsyncState<Order> previous, AsyncState<Order> next) {
    if (next.isError) {
      _errorReporter.report(
        error: next.error!,
        stackTrace: next.stackTrace ?? StackTrace.current,
        context: {
          'viewModel': 'OrderViewModel',
          'previousStatus': previous.status.name,
          'orderId': previous.data?.id ?? 'unknown',
        },
      );
    }
  }
}
```

### Automatic Side Effects

```dart
class CartViewModel extends AsyncViewModelImpl<Cart> {
  @override
  void onAsyncStateChanged(AsyncState<Cart> previous, AsyncState<Cart> next) {
    // Auto-save cart when items change
    if (previous.isSuccess && next.isSuccess) {
      final prevCount = previous.data?.items.length ?? 0;
      final nextCount = next.data?.items.length ?? 0;

      if (prevCount != nextCount) {
        _persistCart(next.data!);
      }
    }

    // Show notification when cart becomes empty
    if (previous.isSuccess && next.isSuccess) {
      if (previous.data!.items.isNotEmpty && next.data!.items.isEmpty) {
        NotificationService.show('Your cart is now empty');
      }
    }

    // Trigger revalidation when cart changes
    if (next.isSuccess && next.data != previous.data) {
      _validateCartContents(next.data!);
    }
  }

  Future<void> _persistCart(Cart cart) async {
    await cartStorage.save(cart);
  }

  void _validateCartContents(Cart cart) {
    // Check for out-of-stock items, price changes, etc.
  }
}
```

### State Machine Validation

```dart
class CheckoutViewModel extends AsyncViewModelImpl<CheckoutState> {
  @override
  void onAsyncStateChanged(
    AsyncState<CheckoutState> previous,
    AsyncState<CheckoutState> next,
  ) {
    // Validate state transitions
    if (previous.isSuccess && next.isSuccess) {
      final prevStep = previous.data!.step;
      final nextStep = next.data!.step;

      // Ensure valid checkout flow
      if (!_isValidTransition(prevStep, nextStep)) {
        log('WARNING: Invalid checkout transition: $prevStep -> $nextStep');
        debugger(); // Break in debug mode
      }
    }

    // Track checkout progress
    if (next.isSuccess) {
      analytics.track('Checkout_StepReached', {
        'step': next.data!.step.name,
      });
    }
  }

  bool _isValidTransition(CheckoutStep from, CheckoutStep to) {
    const validTransitions = {
      CheckoutStep.cart: [CheckoutStep.shipping],
      CheckoutStep.shipping: [CheckoutStep.payment, CheckoutStep.cart],
      CheckoutStep.payment: [CheckoutStep.review, CheckoutStep.shipping],
      CheckoutStep.review: [CheckoutStep.confirmation, CheckoutStep.payment],
    };
    return validTransitions[from]?.contains(to) ?? false;
  }
}
```

## Complete Example

```dart
class AuthViewModel extends AsyncViewModelImpl<AuthState> {
  final AuthService _authService;
  final SessionManager _sessionManager;
  final Analytics _analytics;
  final ErrorReporter _errorReporter;
  final LocalStorage _storage;

  DateTime? _operationStartTime;

  AuthViewModel({
    AuthService? authService,
    SessionManager? sessionManager,
    Analytics? analytics,
    ErrorReporter? errorReporter,
    LocalStorage? storage,
  })  : _authService = authService ?? AuthService(),
        _sessionManager = sessionManager ?? SessionManager(),
        _analytics = analytics ?? Analytics(),
        _errorReporter = errorReporter ?? ErrorReporter(),
        _storage = storage ?? LocalStorage(),
        super(AsyncState.initial());

  @override
  Future<AuthState> init() async {
    final savedSession = await _storage.getSession();
    if (savedSession != null && !savedSession.isExpired) {
      return AuthState.authenticated(savedSession.user);
    }
    return AuthState.unauthenticated();
  }

  @override
  void onAsyncStateChanged(
    AsyncState<AuthState> previous,
    AsyncState<AuthState> next,
  ) {
    // 1. Performance tracking
    _trackPerformance(previous, next);

    // 2. Analytics
    _trackAnalytics(previous, next);

    // 3. Error reporting
    _handleErrors(previous, next);

    // 4. Session management
    _manageSession(previous, next);

    // 5. Cross-service notifications
    _notifyOtherServices(previous, next);
  }

  void _trackPerformance(AsyncState<AuthState> previous, AsyncState<AuthState> next) {
    if (next.isLoading) {
      _operationStartTime = DateTime.now();
    }

    if (previous.isLoading && (next.isSuccess || next.isError)) {
      if (_operationStartTime != null) {
        final duration = DateTime.now().difference(_operationStartTime!);
        _analytics.track('Auth_OperationDuration', {
          'durationMs': duration.inMilliseconds,
          'result': next.isSuccess ? 'success' : 'error',
        });
        _operationStartTime = null;
      }
    }
  }

  void _trackAnalytics(AsyncState<AuthState> previous, AsyncState<AuthState> next) {
    // Login success
    if (next.isSuccess && next.data!.isAuthenticated) {
      if (!previous.isSuccess || !previous.data!.isAuthenticated) {
        _analytics.track('User_LoggedIn', {
          'userId': next.data!.user?.id,
          'method': next.data!.loginMethod?.name,
        });
        _analytics.setUserId(next.data!.user?.id);
      }
    }

    // Logout
    if (previous.isSuccess && previous.data!.isAuthenticated) {
      if (next.isSuccess && !next.data!.isAuthenticated) {
        _analytics.track('User_LoggedOut');
        _analytics.clearUserId();
      }
    }

    // Session expired
    if (next.isError && next.error is SessionExpiredException) {
      _analytics.track('Session_Expired');
    }
  }

  void _handleErrors(AsyncState<AuthState> previous, AsyncState<AuthState> next) {
    if (!next.isError) return;

    final error = next.error!;

    // Skip expected errors
    if (error is InvalidCredentialsException) {
      // User error, don't report
      return;
    }

    _errorReporter.report(
      error: error,
      stackTrace: next.stackTrace ?? StackTrace.current,
      context: {
        'viewModel': 'AuthViewModel',
        'previousState': previous.status.name,
        'previousAuthState': previous.data?.isAuthenticated.toString() ?? 'unknown',
      },
    );
  }

  void _manageSession(AsyncState<AuthState> previous, AsyncState<AuthState> next) {
    // Save session on successful login
    if (next.isSuccess && next.data!.isAuthenticated) {
      final session = Session(
        user: next.data!.user!,
        token: next.data!.token!,
        expiresAt: DateTime.now().add(Duration(hours: 24)),
      );
      _storage.saveSession(session);
      _sessionManager.startSession(session);
    }

    // Clear session on logout or error
    if (next.isSuccess && !next.data!.isAuthenticated) {
      _storage.clearSession();
      _sessionManager.endSession();
    }

    if (next.isError && next.error is SessionExpiredException) {
      _storage.clearSession();
      _sessionManager.endSession();
    }
  }

  void _notifyOtherServices(AsyncState<AuthState> previous, AsyncState<AuthState> next) {
    // Notify dependent services of auth changes
    if (previous.isSuccess && next.isSuccess) {
      final wasAuthenticated = previous.data!.isAuthenticated;
      final isAuthenticated = next.data!.isAuthenticated;

      if (wasAuthenticated != isAuthenticated) {
        // Trigger reload of user-dependent data
        if (isAuthenticated) {
          CartService.loadUserCart();
          NotificationService.registerForPush();
          PreferencesService.syncFromServer();
        } else {
          CartService.clearCart();
          NotificationService.unregister();
          PreferencesService.clearUserData();
        }
      }
    }
  }

  Future<void> login(String email, String password) async {
    loadingState();
    try {
      final result = await _authService.login(email, password);
      updateState(AuthState.authenticated(
        result.user,
        token: result.token,
        loginMethod: LoginMethod.email,
      ));
    } catch (e, stack) {
      errorState(e, stack);
    }
  }

  Future<void> logout() async {
    loadingState();
    try {
      await _authService.logout();
      updateState(AuthState.unauthenticated());
    } catch (e, stack) {
      // Still log out locally even if server fails
      updateState(AuthState.unauthenticated());
    }
  }
}
```

## Best Practices

### 1. Keep the Hook Fast

```dart
// GOOD - Quick, non-blocking operations
@override
void onAsyncStateChanged(AsyncState<T> previous, AsyncState<T> next) {
  log('State: ${next.status}');
  analytics.track('StateChange'); // Fire and forget
}

// AVOID - Blocking operations in hook
@override
void onAsyncStateChanged(AsyncState<T> previous, AsyncState<T> next) {
  await slowDatabaseOperation(); // Blocks state updates!
}
```

### 2. Use for Observation, Not Mutation

```dart
// GOOD - Observe and log
@override
void onAsyncStateChanged(AsyncState<T> previous, AsyncState<T> next) {
  if (next.isError) {
    errorLogger.log(next.error!);
  }
}

// AVOID - Mutating state in hook (can cause infinite loops)
@override
void onAsyncStateChanged(AsyncState<T> previous, AsyncState<T> next) {
  if (next.isError) {
    updateState(fallbackData); // May trigger another state change!
  }
}
```

### 3. Handle All Relevant Transitions

```dart
@override
void onAsyncStateChanged(AsyncState<Data> previous, AsyncState<Data> next) {
  // Handle all transitions you care about
  switch ((previous.status, next.status)) {
    case (AsyncStatus.initial, AsyncStatus.loading):
      onFirstLoad();
      break;
    case (AsyncStatus.loading, AsyncStatus.success):
      onLoadComplete(next.data!);
      break;
    case (AsyncStatus.loading, AsyncStatus.error):
      onLoadFailed(next.error!);
      break;
    case (AsyncStatus.success, AsyncStatus.success):
      onDataChanged(previous.data, next.data);
      break;
    default:
      // Other transitions
      break;
  }
}
```

### 4. Always Call Super If Extending Base Classes

```dart
class BaseAnalyticsViewModel<T> extends AsyncViewModelImpl<T> {
  @override
  void onAsyncStateChanged(AsyncState<T> previous, AsyncState<T> next) {
    // Base analytics
    analytics.track('StateChange', {'status': next.status.name});
  }
}

class MyViewModel extends BaseAnalyticsViewModel<MyData> {
  @override
  void onAsyncStateChanged(AsyncState<MyData> previous, AsyncState<MyData> next) {
    super.onAsyncStateChanged(previous, next); // Call base hook

    // Additional logic
    if (next.isSuccess) {
      // ...
    }
  }
}
```

### 5. Use Guards for Disposed State

```dart
@override
void onAsyncStateChanged(AsyncState<T> previous, AsyncState<T> next) {
  if (isDisposed) return; // Guard against post-dispose calls

  // Safe to proceed
  doSomething();
}
```

## Related Methods

- [`loadingState()`](./loading-state.md) - Triggers hook with loading state
- [`errorState()`](./error-state.md) - Triggers hook with error state
- [`updateState()`](../async-viewmodel.md#updatestate) - Triggers hook with success state
- [`transformDataStateSilently()`](./transform-data-state-silently.md) - Silent but triggers hook
