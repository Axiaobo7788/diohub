import 'package:diohub/graphql/queries/repositories/__generated__/commits_list.data.gql.dart';

/// Constants for lane spacing and rail layout.
const double laneSpacing = 18;
const double railInset = 6;
double get startX => railInset + laneSpacing / 2;

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

/// Complete state of all lanes for a single commit row.
class LaneRowState {
  const LaneRowState({
    required this.nodeLaneId,
    required this.before,
    required this.after,
    required this.visibleLaneIds,
    required this.beforeX,
    required this.afterX,
    required this.collapsingLaneIds,
    required this.collapseInto,
    required this.mergeFromNodeLaneIds,
    required this.visualLaneCount,
  });

  /// Lane ID where the commit node is drawn.
  final String nodeLaneId;

  /// Active lanes entering this row: laneId → snapshot.
  final Map<String, LaneSnapshot> before;

  /// Active lanes exiting this row: laneId → snapshot.
  final Map<String, LaneSnapshot> after;

  /// Union of all lane IDs from both before and after.
  final Set<String> visibleLaneIds;

  /// X coordinates at row top: laneId → x coordinate.
  final Map<String, double> beforeX;

  /// X coordinates at row bottom: laneId → x coordinate.
  final Map<String, double> afterX;

  /// Lane IDs that terminate into another lane (for fast membership checks).
  final Set<String> collapsingLaneIds;

  /// Collapse relationships: fromLaneId → toLaneId.
  final Map<String, String> collapseInto;

  /// Secondary parents drawn from node (merge curves).
  final Set<String> mergeFromNodeLaneIds;

  /// Width driver (number of visual lanes).
  final int visualLaneCount;
}

/// Snapshot of lane state for a single commit row.
class LaneData {
  LaneData({
    required this.row,
  });

  /// Complete state of all lanes for this commit row.
  final LaneRowState row;

  // Legacy accessors for backward compatibility during migration
  @Deprecated('Use row.nodeLaneId instead')
  String get currentLaneId => row.nodeLaneId;

  @Deprecated('Use row.mergeFromNodeLaneIds instead')
  List<String> get mergeTargets => row.mergeFromNodeLaneIds.toList();

  @Deprecated('Use row.visualLaneCount instead')
  int get maxLanes => row.visualLaneCount;

  @Deprecated('Use row.collapseInto instead')
  Map<String, String> get collapsingLanes => row.collapseInto;

  @Deprecated('Use row.before instead')
  List<LaneSnapshot> get lanesBefore => row.before.values.toList();

  @Deprecated('Use row.after instead')
  List<LaneSnapshot> get lanesAfter => row.after.values.toList();
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
    LaneData? previousLaneData, {
    required double startX,
    required double laneSpacing,
  }) {
    // Convert previous snapshots back to Lane objects
    // Reconstruct lanes from previousLaneData.row.after
    var lanes = <Lane>[];
    if (previousLaneData != null) {
      for (final snapshot in previousLaneData.row.after.values) {
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
      for (final entry in previousLaneData.row.after.entries) {
        if (entry.key.isNotEmpty) {
          previousColumns[entry.key] = entry.value.column;
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

      // Compute visualLaneCount PER ROW (only active lanes)
      final visualLaneCount = activeLanesAfter.length;

      // Build before map (active lanes only)
      final beforeMap = <String, LaneSnapshot>{
        for (final snapshot in lanesBefore)
          if (snapshot.activeBefore && snapshot.laneId.isNotEmpty)
            snapshot.laneId: snapshot
      };

      // Build after map (active lanes only)
      final afterMap = <String, LaneSnapshot>{
        for (final snapshot in lanesAfter)
          if (snapshot.activeAfter && snapshot.laneId.isNotEmpty)
            snapshot.laneId: snapshot
      };

      // Build visibleLaneIds (union of before + after)
      final visibleLaneIds = <String>{
        ...beforeMap.keys,
        ...afterMap.keys,
      };

      // Build X coordinate maps
      final beforeX = <String, double>{
        for (final entry in beforeMap.entries)
          entry.key: startX + entry.value.column * laneSpacing
      };

      final afterX = <String, double>{
        for (final entry in afterMap.entries)
          entry.key: startX + entry.value.column * laneSpacing
      };

      // Build collapsingLaneIds and collapseInto
      final collapsingLaneIds = collapsingLanes.keys.toSet();
      final collapseInto = Map<String, String>.from(collapsingLanes);

      // Build mergeFromNodeLaneIds
      final mergeFromNodeLaneIds = mergeTargets.toSet();

      // Create LaneRowState
      final rowState = LaneRowState(
        nodeLaneId: currentLane.id,
        before: beforeMap,
        after: afterMap,
        visibleLaneIds: visibleLaneIds,
        beforeX: beforeX,
        afterX: afterX,
        collapsingLaneIds: collapsingLaneIds,
        collapseInto: collapseInto,
        mergeFromNodeLaneIds: mergeFromNodeLaneIds,
        visualLaneCount: visualLaneCount,
      );

      // Build snapshots ONLY from real lanes (no padding, no fake lanes)
      results.add(
        CommitWithLaneData(
          commit: commit,
          laneData: LaneData(row: rowState),
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
