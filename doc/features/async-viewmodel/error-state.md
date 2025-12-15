# errorState()

## Method Signature

```dart
void errorState(Object error, [StackTrace? stackTrace])
```

## Purpose

Sets the current async state to `AsyncState.error()` with the provided error object and optional stack trace, then notifies all listeners. This method signals that an asynchronous operation has failed, allowing the UI to display appropriate error messages and recovery options.

## Parameters

### error (required)

**Type:** `Object`

The error object representing what went wrong. Can be any object type - typically an `Exception`, `Error`, or custom error class.

### stackTrace (optional)

**Type:** `StackTrace?`
**Default:** `null`

The stack trace associated with the error. Useful for debugging and error logging services.

## Return Type

`void`

## Behavior

1. Stores the previous state for the hook
2. Sets the internal state to `AsyncState.error(error, stackTrace)`
3. Calls `notifyListeners()` to trigger UI updates
4. Triggers `onAsyncStateChanged(previous, newState)` hook

## Usage Example

### Basic Error Handling

```dart
class UserViewModel extends AsyncViewModelImpl<User> {
  UserViewModel() : super(AsyncState.initial());

  @override
  Future<User> init() async {
    return await userRepository.getCurrentUser();
  }

  Future<void> updateEmail(String newEmail) async {
    loadingState();

    try {
      final updated = await userRepository.updateEmail(newEmail);
      updateState(updated);
    } catch (e, stack) {
      errorState(e, stack); // Set error with stack trace
    }
  }
}
```

### Custom Error Types

```dart
// Define custom errors
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  NetworkException(this.message, {this.statusCode});

  @override
  String toString() => 'NetworkException: $message (code: $statusCode)';
}

class ValidationException implements Exception {
  final Map<String, String> fieldErrors;
  ValidationException(this.fieldErrors);

  @override
  String toString() => 'Validation failed: ${fieldErrors.keys.join(', ')}';
}

class OrderViewModel extends AsyncViewModelImpl<Order> {
  Future<void> submitOrder(OrderRequest request) async {
    loadingState();

    try {
      // Validate first
      final errors = _validateRequest(request);
      if (errors.isNotEmpty) {
        errorState(ValidationException(errors));
        return;
      }

      final order = await orderRepository.submit(request);
      updateState(order);
    } on NetworkException catch (e, stack) {
      errorState(e, stack);
    } catch (e, stack) {
      errorState(Exception('Unexpected error: $e'), stack);
    }
  }

  Map<String, String> _validateRequest(OrderRequest request) {
    final errors = <String, String>{};
    if (request.items.isEmpty) {
      errors['items'] = 'Order must contain at least one item';
    }
    if (request.shippingAddress == null) {
      errors['address'] = 'Shipping address is required';
    }
    return errors;
  }
}
```

### Error Without Stack Trace

```dart
class FormViewModel extends AsyncViewModelImpl<FormResult> {
  void setValidationError(String message) {
    // Business logic error - no stack trace needed
    errorState(ValidationException({'form': message}));
  }

  void setNetworkError() {
    errorState(
      NetworkException('Unable to connect to server'),
    );
  }
}
```

### Error Recovery Pattern

```dart
class DataViewModel extends AsyncViewModelImpl<List<Item>> {
  int _retryCount = 0;
  static const maxRetries = 3;

  Future<void> fetchWithRetry() async {
    loadingState();

    try {
      final data = await repository.fetch();
      _retryCount = 0; // Reset on success
      updateState(data);
    } catch (e, stack) {
      _retryCount++;

      if (_retryCount < maxRetries) {
        // Retry after delay
        await Future.delayed(Duration(seconds: _retryCount * 2));
        return fetchWithRetry();
      }

      // Max retries exceeded
      errorState(
        MaxRetriesException('Failed after $maxRetries attempts', original: e),
        stack,
      );
    }
  }
}
```

## Complete Example

```dart
class PaymentViewModel extends AsyncViewModelImpl<PaymentResult> {
  final PaymentService _paymentService;
  final ErrorReporter _errorReporter;

  PaymentViewModel({
    PaymentService? paymentService,
    ErrorReporter? errorReporter,
  })  : _paymentService = paymentService ?? PaymentService(),
        _errorReporter = errorReporter ?? ErrorReporter(),
        super(AsyncState.initial());

  @override
  Future<PaymentResult> init() async {
    return PaymentResult.initial();
  }

  @override
  void onAsyncStateChanged(
    AsyncState<PaymentResult> previous,
    AsyncState<PaymentResult> next,
  ) {
    // Automatic error logging
    if (next.isError) {
      _errorReporter.report(
        error: next.error!,
        stackTrace: next.stackTrace,
        context: {
          'viewModel': 'PaymentViewModel',
          'previousState': previous.status.name,
        },
      );

      // Analytics tracking
      analytics.track('PaymentError', {
        'errorType': next.error.runtimeType.toString(),
        'message': next.error.toString(),
      });
    }
  }

  Future<void> processPayment(PaymentRequest request) async {
    loadingState();

    try {
      // Validate card
      if (!_isValidCard(request.cardNumber)) {
        errorState(PaymentException(
          code: 'INVALID_CARD',
          message: 'Invalid card number',
          isRetryable: false,
        ));
        return;
      }

      // Process payment
      final result = await _paymentService.process(request);

      if (result.isDeclined) {
        errorState(PaymentException(
          code: result.declineCode!,
          message: result.declineReason!,
          isRetryable: result.canRetry,
        ));
        return;
      }

      updateState(result);
    } on NetworkException catch (e, stack) {
      errorState(PaymentException(
        code: 'NETWORK_ERROR',
        message: 'Connection failed. Please check your internet.',
        isRetryable: true,
        originalError: e,
      ), stack);
    } on TimeoutException catch (e, stack) {
      errorState(PaymentException(
        code: 'TIMEOUT',
        message: 'Payment timed out. Please try again.',
        isRetryable: true,
        originalError: e,
      ), stack);
    } catch (e, stack) {
      errorState(PaymentException(
        code: 'UNKNOWN',
        message: 'An unexpected error occurred',
        isRetryable: false,
        originalError: e,
      ), stack);
    }
  }

  bool _isValidCard(String cardNumber) {
    // Luhn algorithm validation
    return cardNumber.length >= 13 && cardNumber.length <= 19;
  }
}

// Custom exception with additional context
class PaymentException implements Exception {
  final String code;
  final String message;
  final bool isRetryable;
  final Object? originalError;

  PaymentException({
    required this.code,
    required this.message,
    required this.isRetryable,
    this.originalError,
  });

  @override
  String toString() => 'PaymentException[$code]: $message';
}
```

## UI Integration

```dart
class PaymentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveAsyncBuilder<PaymentViewModel, PaymentResult>(
      notifier: PaymentService.payment.notifier,
      onData: (result, viewModel, keep) {
        return PaymentSuccessView(result: result);
      },
      onLoading: () {
        return PaymentProcessingView();
      },
      onError: (error, stackTrace) {
        // Type-specific error handling
        if (error is PaymentException) {
          return PaymentErrorView(
            message: error.message,
            canRetry: error.isRetryable,
            onRetry: error.isRetryable
                ? () => PaymentService.payment.notifier.reload()
                : null,
          );
        }

        // Generic error fallback
        return GenericErrorView(
          message: error.toString(),
          onRetry: () => PaymentService.payment.notifier.reload(),
        );
      },
    );
  }
}

class PaymentErrorView extends StatelessWidget {
  final String message;
  final bool canRetry;
  final VoidCallback? onRetry;

  const PaymentErrorView({
    required this.message,
    required this.canRetry,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red),
        SizedBox(height: 16),
        Text(
          message,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        if (canRetry && onRetry != null)
          ElevatedButton(
            onPressed: onRetry,
            child: Text('Try Again'),
          ),
      ],
    );
  }
}
```

## Best Practices

### 1. Always Include Stack Trace When Available

```dart
// GOOD - Preserve stack trace for debugging
try {
  await riskyOperation();
} catch (e, stack) {
  errorState(e, stack);
}

// AVOID - Losing stack trace information
try {
  await riskyOperation();
} catch (e) {
  errorState(e); // Stack trace lost!
}
```

### 2. Use Typed Exceptions

```dart
// GOOD - Specific exception types enable better error handling
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
}

errorState(ApiException(404, 'Resource not found'), stack);

// AVOID - Generic exceptions are hard to handle
errorState(Exception('Something went wrong'), stack);
```

### 3. Include Recovery Information

```dart
class RetryableException implements Exception {
  final String message;
  final Duration? retryAfter;
  final bool canRetry;

  RetryableException(this.message, {this.retryAfter, this.canRetry = true});
}

// In UI
if (error is RetryableException && error.canRetry) {
  showRetryButton(delay: error.retryAfter);
}
```

### 4. Log Errors in onAsyncStateChanged

```dart
@override
void onAsyncStateChanged(AsyncState<T> previous, AsyncState<T> next) {
  if (next.isError) {
    // Centralized error logging
    errorLogger.log(
      error: next.error!,
      stackTrace: next.stackTrace ?? StackTrace.current,
      metadata: {'viewModel': runtimeType.toString()},
    );
  }
}
```

### 5. Provide User-Friendly Messages

```dart
String getUserMessage(Object error) {
  if (error is NetworkException) {
    return 'Please check your internet connection';
  }
  if (error is AuthException) {
    return 'Please sign in again';
  }
  if (error is ValidationException) {
    return error.fieldErrors.values.first;
  }
  return 'Something went wrong. Please try again.';
}

// In catch block
errorState(
  UserFriendlyException(
    technical: e,
    userMessage: getUserMessage(e),
  ),
  stack,
);
```

### 6. Clear Error State Before Retry

```dart
Future<void> retryOperation() async {
  // loadingState() automatically clears error
  loadingState();

  try {
    final result = await operation();
    updateState(result);
  } catch (e, stack) {
    errorState(e, stack);
  }
}
```

## Related Methods

- [`loadingState()`](./loading-state.md) - Set loading state with notification
- [`updateState()`](../async-viewmodel.md#updatestate) - Set success state with notification
- [`onAsyncStateChanged()`](./on-async-state-changed.md) - Hook for error logging
- [`error`](./async-properties.md#error) - Property to access current error
- [`stackTrace`](./async-properties.md#stacktrace) - Property to access current stack trace
