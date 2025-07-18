import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'config/alchemist_config.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: ReactiveNotifierAlchemistConfig.standard,
    run: testMain,
  );
}
