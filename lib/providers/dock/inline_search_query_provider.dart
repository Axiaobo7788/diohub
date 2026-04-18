import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-position inline search query for [InlineSearchDockPill].
///
/// Use a stable key per position (e.g. 'repo/owner/name/branches') so the pill
/// and the list body share the same notifier. The list body (e.g. [SliverListBody]
/// with [SliverListBody.queryNotifier]) should use this notifier when building
/// so filtering is driven by the dock pill.
/// Not autoDispose so the notifier survives tab switches; disposal is when the
/// screen (and its ref) is disposed.
final inlineSearchQueryNotifierProvider =
    Provider.family<ValueNotifier<String>, String>((ref, key) {
  final notifier = ValueNotifier<String>('');
  ref.onDispose(() => notifier.dispose());
  return notifier;
});
