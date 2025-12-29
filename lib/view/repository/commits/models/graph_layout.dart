import 'package:diohub/graphql/queries/repositories/__generated__/commits_list.data.gql.dart';

/// A lane with stable identity across rows.
class Lane {
  Lane({
    required this.id,
    this.expectedOid,
  });

  final String id; // stable identity
  String? expectedOid; // next commit this lane waits for

  @override
  String toString() => 'Lane(id: $id, oid: $expectedOid)';
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
          ));
        }
      }
    }

    // Track previous column assignments for stable sorting
    var previousColumns = <String, int>{};
    if (previousLaneData != null) {
      for (final snapshot in previousLaneData.lanesAfter) {
        if (snapshot.laneId.isNotEmpty && snapshot.activeAfter) {
          previousColumns[snapshot.laneId] = snapshot.column;
        }
      }
    }

    // Track pending merge-backs to be emitted on the next row
    var pendingCollapsingLanes = <String, String>{};

    final results = <CommitWithLaneData>[];

    for (final commit in commits) {
      final parents = _extractParents(commit);

      // Create snapshot of lanesBefore using PREVIOUS row's columns
      // Only include lanes that existed in the previous row (have a previous column)
      final activeLanesBefore = lanes
          .where((lane) =>
              lane.expectedOid != null && previousColumns.containsKey(lane.id))
          .toList();
      final lanesBefore = activeLanesBefore
          .map((lane) => LaneSnapshot(
                laneId: lane.id,
                column: previousColumns[lane.id]!,
                activeBefore: true,
                activeAfter: false, // not used for before
                expectedOid: lane.expectedOid,
              ))
          .toList();

      // Step A: Pick a lane for this commit
      // Exclude lanes in pendingCollapsingLanes (visual-only, don't participate in routing)
      Lane? currentLane;
      var currentLaneIndex = lanes.indexWhere(
        (lane) =>
            lane.expectedOid == commit.oid &&
            !pendingCollapsingLanes.containsKey(lane.id),
      );
      if (currentLaneIndex != -1) {
        currentLane = lanes[currentLaneIndex];
      } else {
        // Not waiting for this commit - find empty lane or create new
        // Exclude collapsing lanes from reuse
        currentLaneIndex = lanes.indexWhere(
          (lane) =>
              lane.expectedOid == null &&
              !pendingCollapsingLanes.containsKey(lane.id),
        );
        if (currentLaneIndex != -1) {
          currentLane = lanes[currentLaneIndex];
        } else {
          // Create new lane (no column assignment yet)
          currentLane = Lane(
            id: _generateLaneId(),
            expectedOid: null,
          );
          lanes.add(currentLane);
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
        // Exclude collapsing lanes from reuse
        var mergeLaneIndex = lanes.indexWhere(
          (lane) =>
              lane.expectedOid == parent &&
              !pendingCollapsingLanes.containsKey(lane.id),
        );
        Lane mergeLane;
        if (mergeLaneIndex != -1) {
          mergeLane = lanes[mergeLaneIndex];
        } else {
          // Find empty lane or create new
          // Exclude collapsing lanes from reuse
          mergeLaneIndex = lanes.indexWhere(
            (lane) =>
                lane.expectedOid == null &&
                !pendingCollapsingLanes.containsKey(lane.id),
          );
          if (mergeLaneIndex != -1) {
            mergeLane = lanes[mergeLaneIndex];
          } else {
            // Create new lane (no column assignment yet)
            mergeLane = Lane(
              id: _generateLaneId(),
              expectedOid: null,
            );
            lanes.add(mergeLane);
            mergeLaneIndex = lanes.length - 1;
          }
        }
        mergeLane.expectedOid = parent;

        // Only draw node-merge if this parent is NOT already
        // connected to the node via lane continuity
        // Check if parent was in lanesBefore at the same column as currentLane
        final currentLaneColumn = previousColumns[currentLane.id];
        final parentLaneBeforeSnapshot = lanesBefore.firstWhere(
          (snapshot) => snapshot.expectedOid == parent && snapshot.activeBefore,
          orElse: () => const LaneSnapshot(
            laneId: '',
            column: -1,
            activeBefore: false,
            activeAfter: false,
            expectedOid: null,
          ),
        );
        final isVerticallyConnected =
            parentLaneBeforeSnapshot.laneId.isNotEmpty &&
                currentLaneColumn != null &&
                parentLaneBeforeSnapshot.column == currentLaneColumn;

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

      // STEP 1 & 2: Defer merge-back by one row - keep collapsing lane active
      // Store merge-back intent to be emitted on NEXT row (parent commit row)
      final newPendingCollapsingLanes = <String, String>{};

      for (final entry in lanesByOid.entries) {
        final oidLanes = entry.value;
        if (oidLanes.length <= 1) continue; // No duplicates

        // Sort by previous column to find leftmost
        oidLanes.sort((a, b) {
          final aCol = previousColumns[a.id];
          final bCol = previousColumns[b.id];
          if (aCol != null && bCol != null) {
            return aCol.compareTo(bCol);
          }
          if (aCol != null) return -1;
          if (bCol != null) return 1;
          return a.id.compareTo(b.id);
        });
        final survivorLane = oidLanes.first;

        // Store merge-back intent for NEXT row (don't mark as dying yet)
        // Keep collapsing lane active for one more row
        for (var i = 1; i < oidLanes.length; i++) {
          final collapsingLane = oidLanes[i];
          newPendingCollapsingLanes[collapsingLane.id] = survivorLane.id;
          // DO NOT set expectedOid = null here - keep lane active for merge-back curve
        }
      }

      // Use pending merge-backs from previous row (emitted on THIS row)
      final collapsingLanes = Map<String, String>.from(pendingCollapsingLanes);

      // Update pending merge-backs for next row
      pendingCollapsingLanes = newPendingCollapsingLanes;

      // Assign columns PER ROW AFTER processing commit (only active lanes)
      // Exclude collapsing lanes from activeLanesAfter (visual-only, don't affect columns)
      final activeLanesAfter = lanes
          .where(
            (lane) =>
                lane.expectedOid != null &&
                !collapsingLanes.containsKey(lane.id),
          )
          .toList();

      // Sort active lanes by previous column (if existed), then by stable laneId
      activeLanesAfter.sort((a, b) {
        final aCol = previousColumns[a.id];
        final bCol = previousColumns[b.id];
        if (aCol != null && bCol != null) {
          return aCol.compareTo(bCol);
        }
        if (aCol != null) return -1;
        if (bCol != null) return 1;
        return a.id.compareTo(b.id);
      });

      // Assign columns sequentially to active lanes
      final laneToColumnAfter = <String, int>{};
      for (var i = 0; i < activeLanesAfter.length; i++) {
        laneToColumnAfter[activeLanesAfter[i].id] = i;
      }

      // Create snapshot of lanesAfter (only active lanes)
      final lanesAfter = activeLanesAfter
          .map((lane) => LaneSnapshot(
                laneId: lane.id,
                column: laneToColumnAfter[lane.id]!,
                activeBefore: false, // not used for after
                activeAfter: true,
                expectedOid: lane.expectedOid,
              ))
          .toList();

      // Update previousColumns for next row
      previousColumns = laneToColumnAfter;

      // Compute maxLanes PER ROW (only active lanes)
      final maxLanes = activeLanesAfter.length;

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

      // Remove collapsing lanes from lanes list AFTER emitting the row
      // (they were visual-only for this row, don't participate in routing)
      lanes.removeWhere((lane) => collapsingLanes.containsKey(lane.id));
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
