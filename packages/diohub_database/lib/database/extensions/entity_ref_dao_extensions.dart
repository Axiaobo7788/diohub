import 'package:drift/drift.dart';

import 'package:diohub_database/database/database.dart';
import 'package:diohub_models/models/entity_ref.dart';

/// Convenience for constructing Drift companions from [EntityRef].
extension EntityRefCompanionX on EntityRef {
  /// Build a [HistoryEntriesCompanion] (thin: accountKey, nodeId, visitedAt).
  /// Requires [nodeId] to be set.
  HistoryEntriesCompanion toHistoryCompanion({
    required String accountKey,
  }) {
    final nodeId = this.nodeId;
    if (nodeId == null || nodeId.isEmpty) {
      throw StateError(
        'EntityRef.nodeId is required for history; set it from GraphQL/REST before persisting.',
      );
    }
    return HistoryEntriesCompanion(
      accountKey: Value(accountKey),
      nodeId: Value(nodeId),
      visitedAt: Value(DateTime.now()),
    );
  }
}
