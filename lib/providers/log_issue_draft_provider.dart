import 'package:flutter_riverpod/flutter_riverpod.dart';

class _PendingLogIssueDraftNotifier
    extends Notifier<({String title, String body})?> {
  @override
  ({String title, String body})? build() => null;
}

/// Pending issue title/body when navigating from "Report issue" in the log viewer.
/// [NewIssueScreen] reads this and pre-fills the form, then clears it.
final pendingLogIssueDraftProvider =
    NotifierProvider<_PendingLogIssueDraftNotifier,
        ({String title, String body})?>(_PendingLogIssueDraftNotifier.new);
