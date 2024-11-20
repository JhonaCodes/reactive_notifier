/// State of asynd ata, example, success, error, etc
/// this async state shouldbe inside of asynNotifier for value of type AsyncState.
enum AsyncStatus { initial, loading, success, error }

class AsyncState<T> {
  final AsyncStatus status;
  final T? data;
  final Object? error;
  final StackTrace? stackTrace;
  AsyncState._({required this.status, this.data, this.error, this.stackTrace});

  factory AsyncState.initial() => AsyncState._(status: AsyncStatus.initial);
  factory AsyncState.loading() => AsyncState._(status: AsyncStatus.loading);
  factory AsyncState.success(T data) =>
      AsyncState._(status: AsyncStatus.success, data: data);
  factory AsyncState.error(Object error, [StackTrace? stackTrace]) =>
      AsyncState._(
          status: AsyncStatus.error, error: error, stackTrace: stackTrace);

  bool get isInitial => status == AsyncStatus.initial;
  bool get isLoading => status == AsyncStatus.loading;
  bool get isSuccess => status == AsyncStatus.success;
  bool get isError => status == AsyncStatus.error;

  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(Object? error, StackTrace? stackTrace) error,
  }) {
    switch (status) {
      case AsyncStatus.initial:
        return initial();
      case AsyncStatus.loading:
        return loading();
      case AsyncStatus.success:
        return success(data as T);
      case AsyncStatus.error:
        return error(this.error, this.stackTrace);
    }
  }
}
