/// Stable [ValueNotifier<int>] per [CommitRef]. Increment to trigger
/// the commit comments list to refresh (e.g. after create).
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

final ProviderFamily<ValueNotifier<int>, CommitRef>
    commitCommentsRefreshTriggerProvider =
    Provider.family<ValueNotifier<int>, CommitRef>(
  (final Ref ref, final CommitRef commitRef) {
    final notifier = ValueNotifier<int>(0);
    ref.onDispose(notifier.dispose);
    return notifier;
  },
);
