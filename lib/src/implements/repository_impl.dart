/// Use for Repository
@Deprecated(
    "If your VM class uses ViewModel, [RepositoryImpl] is not required. However, if you are using ViewModelImpl, you must continue using [RepositoryImpl]. It is recommended to migrate to ViewModel, as [RepositoryImpl] will be removed in version 2.7.0.")
interface class RepositoryImpl<T> {}
