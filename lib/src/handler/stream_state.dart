sealed class StreamState<T> {
  const StreamState();

  const factory StreamState.initial() = _StreamStateInitial;
  const factory StreamState.loading() = _StreamStateLoading;
  const factory StreamState.data(T data) = _StreamStateData;
  const factory StreamState.error(Object error) = _StreamStateError;
  const factory StreamState.done() = _StreamStateDone;

  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) data,
    required R Function(Object error) error,
    required R Function() done,
  });
}

class _StreamStateInitial<T> extends StreamState<T> {
  const _StreamStateInitial();

  @override
  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) data,
    required R Function(Object error) error,
    required R Function() done,
  }) =>
      initial();
}

class _StreamStateLoading<T> extends StreamState<T> {
  const _StreamStateLoading();

  @override
  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) data,
    required R Function(Object error) error,
    required R Function() done,
  }) =>
      loading();
}

class _StreamStateData<T> extends StreamState<T> {
  final T data;
  const _StreamStateData(this.data);

  @override
  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) data,
    required R Function(Object error) error,
    required R Function() done,
  }) =>
      data(this.data);
}

class _StreamStateError<T> extends StreamState<T> {
  final Object error;
  const _StreamStateError(this.error);

  @override
  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) data,
    required R Function(Object error) error,
    required R Function() done,
  }) =>
      error(this.error);
}

class _StreamStateDone<T> extends StreamState<T> {
  const _StreamStateDone();

  @override
  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) data,
    required R Function(Object error) error,
    required R Function() done,
  }) =>
      done();
}
