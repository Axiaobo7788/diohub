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
    this.collapsingLanes = const {},
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

  /// Lanes that collapse into other lanes: Map<fromLane, toLane>
  /// When duplicate OIDs are detected, the rightmost lane collapses into the leftmost.
  final Map<int, int> collapsingLanes;
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

/// Lane router - treats commits as a DAG routing problem, not a tree.
class GraphLayoutCalculator {
  List<CommitWithLaneData> processCommitsIncremental(
    List<GcommitListItem> commits,
    LaneData? previousLaneData,
  ) {
    // Lane table: lane index → expected next commit OID (or null if free)
    var lanes = List<String?>.from(previousLaneData?.lanesAfter ?? const []);
    var maxLanes = previousLaneData?.maxLanes ?? lanes.length;

    final results = <CommitWithLaneData>[];

    for (final commit in commits) {
      final parents = _extractParents(commit);
      final lanesBefore = List<String?>.from(lanes);

      // Step A: Pick a lane for this commit
      var currentLane = lanes.indexOf(commit.oid);
      if (currentLane == -1) {
        // Not waiting for this commit - find empty lane or create new
        currentLane = lanes.indexWhere((oid) => oid == null);
        if (currentLane == -1) {
          currentLane = lanes.length;
          lanes.add(null);
        }
      }

      // Step B: Update lane table
      final lanesAfter = List<String?>.from(lanes);

      // Primary parent continues in same lane
      final primaryParent = parents.isNotEmpty ? parents.first : null;
      lanesAfter[currentLane] = primaryParent;

      // Secondary parents reserve other lanes
      final mergeTargets = <int>[];
      for (final parent in parents.skip(1)) {
        var mergeLane = lanesAfter.indexOf(parent);
        if (mergeLane == -1) {
          // Reserve empty lane for this parent
          mergeLane = lanesAfter.indexWhere((oid) => oid == null);
          if (mergeLane == -1) {
            mergeLane = lanesAfter.length;
            lanesAfter.add(null);
          }
        }
        lanesAfter[mergeLane] = parent;

        // Only draw node-merge if this parent is NOT already
        // connected to the node via lane continuity
        final parentLaneBefore = lanesBefore.indexOf(parent);
        final isVerticallyConnected =
            parentLaneBefore != -1 && parentLaneBefore == currentLane;

        if (!isVerticallyConnected) {
          mergeTargets.add(mergeLane);
        }
      }

      // Step C: Deferred lane collapse - keep leftmost, free duplicates
      // Capture merge-back intent explicitly: fromLane → toLane
      final seen = <String, int>{};
      final collapsingLanes = <int, int>{};
      for (var i = 0; i < lanesAfter.length; i++) {
        final oid = lanesAfter[i];
        if (oid == null) continue;

        if (!seen.containsKey(oid)) {
          seen[oid] = i; // survivor lane (leftmost)
        } else {
          final targetLane = seen[oid]!;
          collapsingLanes[i] = targetLane; // lane i collapses into targetLane
          lanesAfter[i] = null;
        }
      }

      // Trim trailing empty lanes
      while (lanesAfter.isNotEmpty && lanesAfter.last == null) {
        lanesAfter.removeLast();
      }

      // Update maxLanes (monotonic width)
      maxLanes = math.max(
        maxLanes,
        math.max(lanesAfter.length, currentLane + 1),
      );

      // Pad to maxLanes for consistent width
      final paddedBefore = _padTo(lanesBefore, maxLanes);
      final paddedAfter = _padTo(lanesAfter, maxLanes);

      lanes = paddedAfter;

      results.add(
        CommitWithLaneData(
          commit: commit,
          laneData: LaneData(
            lanesBefore: paddedBefore,
            lanesAfter: paddedAfter,
            currentLane: currentLane,
            mergeTargets: mergeTargets,
            collapsingLanes: collapsingLanes,
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

  List<String?> _padTo(final List<String?> value, final int targetLength) {
    final padded = List<String?>.from(value);
    while (padded.length < targetLength) {
      padded.add(null);
    }
    return padded;
  }
}
