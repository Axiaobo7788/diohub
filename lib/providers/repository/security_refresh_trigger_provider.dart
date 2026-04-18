/// Stable [ValueNotifier<int>] per repo for the Security position. Increment to
/// trigger refresh of Dependabot and Code Scanning lists (e.g. after dismiss).
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final securityRefreshTriggerProvider =
    Provider.family<ValueNotifier<int>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) {
    final notifier = ValueNotifier<int>(0);
    ref.onDispose(notifier.dispose);
    return notifier;
  },
);
