/// Holds client-side patches for the repo milestones list so mutations can
/// update the UI without ref.invalidate. The milestones position fetcher
/// applies these when loading the first page.
library;

import 'package:flutter/foundation.dart';

import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/milestone_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MilestoneListPatchesNotifier extends Notifier<MilestoneListPatchesState> {
  MilestoneListPatchesNotifier(this._repoRef);

  /// Family key for [milestoneListPatchesProvider]; kept for constructor signature.
  // ignore: unused_field
  final RepoRef _repoRef;

  @override
  MilestoneListPatchesState build() => const MilestoneListPatchesState();

  void prepend(MilestoneEdge edge) {
    state = MilestoneListPatchesState(
      prepended: [edge, ...state.prepended],
      updated: state.updated,
      removed: state.removed,
    );
  }

  void update(int milestoneNumber,
      MilestoneEdge edge) {
    final updated =
        Map<int, MilestoneEdge>.from(
            state.updated)
          ..[milestoneNumber] = edge;
    state = MilestoneListPatchesState(
      prepended: state.prepended,
      updated: updated,
      removed: state.removed,
    );
  }

  void remove(int milestoneNumber) {
    final updated =
        Map<int, MilestoneEdge>.from(
            state.updated)
          ..remove(milestoneNumber);
    state = MilestoneListPatchesState(
      prepended: state.prepended
          .where((e) => e.node?.number != milestoneNumber)
          .toList(),
      updated: updated,
      removed: {...state.removed, milestoneNumber},
    );
  }
}

@immutable
class MilestoneListPatchesState {
  const MilestoneListPatchesState({
    this.prepended = const [],
    this.updated = const {},
    this.removed = const {},
  });

  final List<MilestoneEdge> prepended;
  final Map<int, MilestoneEdge> updated;
  final Set<int> removed;
}

/// Milestone list patches per repo (create/update/delete optimistic state). Auto-disposes when no longer watched.
final milestoneListPatchesProvider = NotifierProvider.autoDispose.family<
    MilestoneListPatchesNotifier,
    MilestoneListPatchesState,
    RepoRef>(MilestoneListPatchesNotifier.new);

/// Builds a GQL edge from REST API response (create/update milestone).
MilestoneEdge?
    buildMilestoneEdgeFromRest(MilestoneResult rest) {
  final number = rest.number;
  final state =
      rest.state.toUpperCase() == 'CLOSED'
          ? MilestoneState.CLOSED
          : MilestoneState.OPEN;
  final nodeJson = <String, dynamic>{
    '__typename': 'Milestone',
    'id': rest.nodeId ?? 'MI_rest_$number',
    'number': number,
    'title': rest.title,
    'description': rest.description,
    'dueOn': rest.dueOn?.toUtc().toIso8601String(),
    'state': state.name,
  };
  final node =
      MilestoneNode.fromJson(
          nodeJson);
  if (node == null) return null;
  final edgeJson = <String, dynamic>{
    '__typename': 'MilestoneEdge',
    'cursor': 'rest_$number',
    'node': node.toJson(),
  };
  return MilestoneEdge.fromJson(
      edgeJson);
}
