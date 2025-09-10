// Stub for ReactiveNotifier - DevTools extension uses service protocol
// This stub provides the basic interface needed for the extension

class ReactiveNotifier<T> {
  final String keyNotifier;
  final bool autoDispose;
  final List<ReactiveNotifier>? related;
  
  late final T notifier;
  bool get hasListeners => false; // Will be populated by service protocol

  ReactiveNotifier(T Function() factory, {this.autoDispose = false, this.related}) 
    : keyNotifier = factory.runtimeType.toString(),
      notifier = factory();

  static List<ReactiveNotifier> get getInstances => [];
  static void cleanup() {}
}