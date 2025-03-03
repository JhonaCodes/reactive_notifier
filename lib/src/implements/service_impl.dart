import 'package:reactive_notifier/reactive_notifier.dart';

/// Use for Services
@Deprecated(
    "If your VM class uses ViewModel, [ServiceImpl] is not required. However, if you are using ViewModelImpl, you must continue using [ServiceImpl]. It is recommended to migrate to ViewModel, as [ServiceImpl] will be removed in version 2.7.0.")
interface class ServiceImpl<T> implements RepositoryImpl<T> {}
