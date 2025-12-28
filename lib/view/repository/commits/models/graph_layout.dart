import 'dart:math' as math;

import 'package:diohub/graphql/queries/repositories/__generated__/commits_list.data.gql.dart';

/// Snapshot of lane state for a single commit row.
class LaneData {
  const LaneData({
    required this.lanesBefore,
    required this.lanesAfter,
    required this.currentLane,
    required this.mergeTargets,
    required this.maxLanes,
  });

  /// Lanes coming into this row (top half of the painter).
  final List<String?> lanesBefore;

  /// Lanes leaving this row (bottom half of the painter).
  final List<String?> lanesAfter;

  /// Lane index where the current commit node is drawn.
  final int currentLane;

  /// Lane indices for secondary parents (merges) that should be drawn
  /// as curves from this node into the target lane.
  final List<int> mergeTargets;

  /// Running maximum of lanes seen so far (keeps rail width from shrinking).
  final int maxLanes;
}

/// Convenience bundle pairing a commit with its calculated lane data.
class CommitWithLaneData {
  const CommitWithLaneData({
    required this.commit,
    required this.laneData,
  });

  final GcommitListItem commit;
  final LaneData laneData;
}

/// Stateless lane layout calculator – no hidden mutation between pages.
class GraphLayoutCalculator {
  List<CommitWithLaneData> processCommitsIncremental(
    List<GcommitListItem> commits,
    LaneData? previousLaneData,
  ) {
    var activeLanes =
        List<String?>.from(previousLaneData?.lanesAfter ?? const []);
    var maxLanes = previousLaneData?.maxLanes ?? activeLanes.length;

    final results = <CommitWithLaneData>[];

    for (final commit in commits) {
      final parents = _extractParents(commit);
      final lanesBefore = List<String?>.from(activeLanes);

      // Place commit on an existing lane if we were already waiting for it.
      var currentLane = activeLanes.indexOf(commit.oid);
      if (currentLane == -1) {
        currentLane = _firstEmptyIndex(activeLanes);
        if (currentLane == -1) {
          currentLane = activeLanes.length;
          activeLanes.add(null);
        }
      }

      // Prepare lanesAfter starting from current active snapshot.
      final lanesAfter = List<String?>.from(activeLanes);

      // Primary parent continues down the current lane.
      final primaryParent = parents.isNotEmpty ? parents.first : null;
      lanesAfter[currentLane] = primaryParent;

      // Secondary parents get their own lanes (merge curves).
      final mergeTargets = <int>[];
      for (final parent in parents.skip(1)) {
        var mergeLane = lanesAfter.indexOf(parent);
        if (mergeLane == -1) {
          mergeLane = _firstEmptyIndex(lanesAfter);
          if (mergeLane == -1) {
            mergeLane = lanesAfter.length;
            lanesAfter.add(null);
          }
        }
        lanesAfter[mergeLane] = parent;
        mergeTargets.add(mergeLane);
      }

      // Trim trailing empty lanes while keeping width monotonic via maxLanes.
      while (lanesAfter.isNotEmpty && lanesAfter.last == null) {
        lanesAfter.removeLast();
      }

      maxLanes = math.max(
        maxLanes,
        math.max(
          lanesAfter.length,
          currentLane + 1,
        ),
      );

      final paddedBefore = _padTo(lanesBefore, maxLanes);
      final paddedAfter = _padTo(lanesAfter, maxLanes);

      activeLanes = paddedAfter;

      results.add(
        CommitWithLaneData(
          commit: commit,
          laneData: LaneData(
            lanesBefore: paddedBefore,
            lanesAfter: paddedAfter,
            currentLane: currentLane,
            mergeTargets: mergeTargets,
            maxLanes: maxLanes,
          ),
        ),
      );
    }

    return results;
  }

  List<String> _extractParents(final GcommitListItem commit) =>
      commit.parents.edges
          ?.map((edge) => edge?.node?.oid)
          .whereType<String>()
          .toList() ??
      const [];

  int _firstEmptyIndex(final List<String?> lanes) =>
      lanes.indexWhere((lane) => lane == null);

  List<String?> _padTo(final List<String?> value, final int targetLength) {
    final padded = List<String?>.from(value);
    while (padded.length < targetLength) {
      padded.add(null);
    }
    return padded;
  }
}
