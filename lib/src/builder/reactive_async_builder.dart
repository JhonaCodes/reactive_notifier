import 'package:flutter/material.dart';
import 'package:reactive_notifier/src/viewmodel/async_viewmodel_impl.dart';

class ReactiveAsyncBuilder<T> extends StatelessWidget {
  final AsyncViewModelImpl<T> viewModel;
  final Widget Function(T data) buildSuccess;
  final Widget Function()? buildLoading;
  final Widget Function(Object? error, StackTrace? stackTrace)? buildError;
  final Widget Function()? buildInitial;

  const ReactiveAsyncBuilder({
    super.key,
    required this.viewModel,
    required this.buildSuccess,
    this.buildLoading,
    this.buildError,
    this.buildInitial,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        return viewModel.value.when(
          initial: () => buildInitial?.call() ?? const SizedBox.shrink(),
          loading: () =>
              buildLoading?.call() ??
              const Center(child: CircularProgressIndicator.adaptive()),
          success: (data) => buildSuccess(data),
          error: (error, stackTrace) =>
              buildError?.call(error, stackTrace) ??
              Center(child: Text('Error: $error')),
        );
      },
    );
  }
}
