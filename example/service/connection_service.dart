import 'package:reactive_notifier/reactive_notifier.dart';

import '../viewmodel/connection_state_viewmodel.dart';

mixin ConnectionService {
  static final ReactiveNotifier<ConnectionManagerVM> instance =
      ReactiveNotifier<ConnectionManagerVM>(() => ConnectionManagerVM());
}
