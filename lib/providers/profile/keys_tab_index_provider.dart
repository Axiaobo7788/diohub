/// Current tab index for the viewer's Keys position: 0 = SSH, 1 = GPG, 2 = Signing.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _KeysTabIndexNotifier extends Notifier<int> {
  _KeysTabIndexNotifier(this._arg);
  final UserRef _arg;
  @override
  int build() => 0;
}

final keysTabIndexProvider =
    NotifierProvider.family<_KeysTabIndexNotifier, int, UserRef>(
  _KeysTabIndexNotifier.new,
);
