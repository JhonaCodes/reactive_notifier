import 'package:flutter/material.dart';
import 'package:reactive_notifier/src/viewmodel/async_viewmodel_impl.dart';

class ReactiveAsyncBuilder<T> extends StatelessWidget {
  final AsyncViewModelImpl<T> notifier;
  final Widget Function(T data) onSuccess;
  final Widget Function()? onLoading;
  final Widget Function(Object? error, StackTrace? stackTrace)? onError;
  final Widget Function()? onInitial;

  const ReactiveAsyncBuilder({
    super.key,
    required this.notifier,
    required this.onSuccess,
    this.onLoading,
    this.onError,
    this.onInitial,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: notifier,
      builder: (context, _) {
        return notifier.when(
          initial: () => onInitial?.call() ?? const SizedBox.shrink(),
          loading: () =>
              onLoading?.call() ??
              const Center(child: CircularProgressIndicator.adaptive()),
          success: (data) => onSuccess(data),
          error: (error, stackTrace) => onError != null
              ? onError!(error, stackTrace)
              : Center(child: Text('Error: $error')),
        );
      },
    );
  }
}