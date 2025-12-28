import 'dart:math' as math;

import 'package:diohub/graphql/queries/repositories/__generated__/commits_list.data.gql.dart';

/// A lane with stable identity across rows.
class Lane {
  Lane({
    required this.id,
    this.expectedOid,
    required this.column,
  });

  final String id; // stable identity
  String? expectedOid; // next commit this lane waits for
  int column; // visual column (x position)

  @override
  String toString() => 'Lane(id: $id, oid: $expectedOid, col: $column)';
}

/// Snapshot of a lane's state at a commit row.
class LaneSnapshot {
  const LaneSnapshot({
    required this.laneId,
    required this.column,
    required this.activeBefore,
    required this.activeAfter,
    this.expectedOid,
  });

  final String laneId;
  final int column;
  final bool activeBefore;
  final bool activeAfter;
  final String?
      expectedOid; // OID this lane is waiting for (for reconstruction)
}

/// Snapshot of lane state for a single commit row.
class LaneData {
  const LaneData({
    required this.lanesBefore,
    required this.lanesAfter,
    required this.currentLaneId,
    required this.mergeTargets,
    required this.maxLanes,
    this.collapsingLanes = const {},
  });

  /// Lane snapshots coming into this row (top half of the painter).
  final List<LaneSnapshot> lanesBefore;

  /// Lane snapshots leaving this row (bottom half of the painter).
  final List<LaneSnapshot> lanesAfter;

  /// Lane ID where the current commit node is drawn.
  final String currentLaneId;

  /// Lane IDs for secondary parents (merges) that should be drawn
  /// as curves from this node into the target lane.
  final List<String> mergeTargets;

  /// Running maximum of lanes seen so far (keeps rail width from shrinking).
  final int maxLanes;

  /// Lanes that collapse into other lanes: Map<fromLaneId, toLaneId>
  /// When duplicate OIDs are detected, the rightmost lane collapses into the leftmost.
  final Map<String, String> collapsingLanes;
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
  // Counter for generating unique lane IDs
  int _nextLaneId = 0;

  String _generateLaneId() => 'lane_${_nextLaneId++}';

  List<CommitWithLaneData> processCommitsIncremental(
    List<GcommitListItem> commits,
    LaneData? previousLaneData,
  ) {
    // Convert previous snapshots back to Lane objects
    // Reconstruct lanes from previousLaneData.lanesAfter
    var lanes = <Lane>[];
    if (previousLaneData != null) {
      for (final snapshot in previousLaneData.lanesAfter) {
        if (snapshot.laneId.isNotEmpty) {
          lanes.add(Lane(
            id: snapshot.laneId,
            expectedOid: snapshot.expectedOid,
            column: snapshot.column,
          ));
        }
      }
    }

    var maxLanes = previousLaneData?.maxLanes ?? lanes.length;

    final results = <CommitWithLaneData>[];

    for (final commit in commits) {
      final parents = _extractParents(commit);

      // Create snapshot of lanesBefore
      final lanesBefore = lanes
          .map((lane) => LaneSnapshot(
                laneId: lane.id,
                column: lane.column,
                activeBefore: lane.expectedOid != null,
                activeAfter: false, // not used for before
                expectedOid: lane.expectedOid,
              ))
          .toList();

      // Step A: Pick a lane for this commit
      Lane? currentLane;
      var currentLaneIndex =
          lanes.indexWhere((lane) => lane.expectedOid == commit.oid);
      if (currentLaneIndex != -1) {
        currentLane = lanes[currentLaneIndex];
      } else {
        // Not waiting for this commit - find empty lane or create new
        currentLaneIndex = lanes.indexWhere((lane) => lane.expectedOid == null);
        if (currentLaneIndex != -1) {
          currentLane = lanes[currentLaneIndex];
        } else {
          // Create new lane with permanent column assignment
          currentLane = Lane(
            id: _generateLaneId(),
            expectedOid: null,
            column: maxLanes, // permanent column
          );
          lanes.add(currentLane);
          maxLanes = maxLanes + 1; // increment after creation
          currentLaneIndex = lanes.length - 1;
        }
      }

      // Step B: Update lane table
      // Primary parent continues in same lane
      final primaryParent = parents.isNotEmpty ? parents.first : null;
      currentLane.expectedOid = primaryParent;

      // Secondary parents reserve other lanes
      final mergeTargets = <String>[];
      for (final parent in parents.skip(1)) {
        // Find existing lane waiting for this parent
        var mergeLaneIndex =
            lanes.indexWhere((lane) => lane.expectedOid == parent);
        Lane mergeLane;
        if (mergeLaneIndex != -1) {
          mergeLane = lanes[mergeLaneIndex];
        } else {
          // Find empty lane or create new
          mergeLaneIndex = lanes.indexWhere((lane) => lane.expectedOid == null);
          if (mergeLaneIndex != -1) {
            mergeLane = lanes[mergeLaneIndex];
          } else {
            // Create new lane with permanent column assignment
            mergeLane = Lane(
              id: _generateLaneId(),
              expectedOid: null,
              column: maxLanes, // permanent column
            );
            lanes.add(mergeLane);
            maxLanes = maxLanes + 1; // increment after creation
            mergeLaneIndex = lanes.length - 1;
          }
        }
        mergeLane.expectedOid = parent;

        // Only draw node-merge if this parent is NOT already
        // connected to the node via lane continuity
        // Check if parent was in lanesBefore at the same column as currentLane
        final parentLaneBeforeIndex = lanesBefore.indexWhere(
          (snapshot) => snapshot.expectedOid == parent && snapshot.activeBefore,
        );
        final isVerticallyConnected = parentLaneBeforeIndex != -1 &&
            lanesBefore[parentLaneBeforeIndex].column == currentLane.column;

        if (!isVerticallyConnected) {
          mergeTargets.add(mergeLane.id);
        }
      }

      // Step C: Deferred lane collapse - keep leftmost, free duplicates
      // Capture merge-back intent explicitly: fromLaneId → toLaneId
      // Group lanes by expectedOid, then find leftmost (lowest column) for each
      final lanesByOid = <String, List<Lane>>{};
      for (final lane in lanes) {
        final oid = lane.expectedOid;
        if (oid == null) continue;
        lanesByOid.putIfAbsent(oid, () => []).add(lane);
      }

      final collapsingLanes = <String, String>{};
      final dyingLanes = <Lane>[];

      for (final entry in lanesByOid.entries) {
        final oidLanes = entry.value;
        if (oidLanes.length <= 1) continue; // No duplicates

        // Sort by column to find leftmost
        oidLanes.sort((a, b) => a.column.compareTo(b.column));
        final survivorLane = oidLanes.first;

        // Mark all others as collapsing
        for (var i = 1; i < oidLanes.length; i++) {
          final collapsingLane = oidLanes[i];
          collapsingLanes[collapsingLane.id] = survivorLane.id;
          dyingLanes.add(collapsingLane);
          collapsingLane.expectedOid = null; // mark as dying
        }
      }

      // Lanes are NEVER removed - they just become inactive (expectedOid = null)
      // Columns are NEVER reassigned - they remain permanent once assigned

      // Create snapshot of lanesAfter
      final lanesAfter = lanes
          .map((lane) => LaneSnapshot(
                laneId: lane.id,
                column: lane.column,
                activeBefore: false, // not used for after
                activeAfter: lane.expectedOid != null,
                expectedOid: lane.expectedOid,
              ))
          .toList();

      // Update maxLanes (monotonic width) - based on actual lane columns
      for (final lane in lanes) {
        maxLanes = math.max(maxLanes, lane.column + 1);
      }

      // Build snapshots ONLY from real lanes (no padding, no fake lanes)
      results.add(
        CommitWithLaneData(
          commit: commit,
          laneData: LaneData(
            lanesBefore: lanesBefore,
            lanesAfter: lanesAfter,
            currentLaneId: currentLane.id,
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
}
