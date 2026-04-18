/// Stable [ValueNotifier<int>] per [UserRef] for the viewer's Keys position.
/// Increment to trigger list refresh after add/delete SSH (or GPG/signing) key.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

final ProviderFamily<ValueNotifier<int>, UserRef> keysRefreshTriggerProvider =
    Provider.family<ValueNotifier<int>, UserRef>(
  (final Ref ref, final UserRef userRef) {
    final notifier = ValueNotifier<int>(0);
    ref.onDispose(notifier.dispose);
    return notifier;
  },
);
