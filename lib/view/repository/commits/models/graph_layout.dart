import 'package:diohub/graphql/queries/repositories/__generated__/commits_list.data.gql.dart';
import 'package:flutter/material.dart';

/// Constants for lane spacing and rail layout.
const double laneSpacing = 18;
const double railInset = 6;
double get startX => railInset + laneSpacing / 2;

/// Stable categorical palette for commit graph lanes in dark mode (12 colors, no orange/yellow).
const List<Color> commitLanePaletteDark = [
  Color(0xFF4E79A7), // blue
  Color(0xFF59A14F), // green
  Color(0xFFAF7AA1), // purple
  Color(0xFF76B7B2), // teal
  Color(0xFFE15759), // red
  Color(0xFF9C755F), // brown
  Color(0xFFB07AA1), // lavender
  Color(0xFF86BCB6), // cyan-muted
  Color(0xFF8CD17D), // mint
  Color(0xFF79706E), // neutral gray
  Color(0xFF5F6CAF), // indigo
  Color(0xFF6B8E23), // olive (non-yellow)
];

/// Stable categorical palette for commit graph lanes in light mode (12 colors, no orange/yellow).
const List<Color> commitLanePaletteLight = [
  Color(0xFF4E79A7), // blue
  Color(0xFF59A14F), // green
  Color(0xFFAF7AA1), // purple
  Color(0xFF76B7B2), // teal
  Color(0xFFE15759), // red
  Color(0xFF9C755F), // brown
  Color(0xFFB07AA1), // lavender
  Color(0xFF86BCB6), // cyan-muted
  Color(0xFF8CD17D), // mint
  Color(0xFF79706E), // neutral gray
  Color(0xFF5F6CAF), // indigo
  Color(0xFF6B8E23), // olive (non-yellow)
];

/// Returns the appropriate palette for the given brightness.
List<Color> commitLanePaletteForBrightness(Brightness brightness) {
  return brightness == Brightness.dark
      ? commitLanePaletteDark
      : commitLanePaletteLight;
}

/// A lane with stable identity across rows.
class Lane {
  Lane({
    required this.id,
    required this.color,
    this.expectedOid,
  });

  final String id; // stable identity
  final Color color; // stable color assigned at creation
  String? expectedOid; // next commit this lane waits for

  @override
  String toString() => 'Lane(id: $id, oid: $expectedOid)';
}

/// Snapshot of a lane's state at a commit row.
class LaneSnapshot {
  const LaneSnapshot({
    required this.laneId,
    required this.column,
    required this.color,
    this.expectedOid,
  });

  final String laneId;
  final int column;
  final Color color; // stable color from the lane
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

/// Internal routing state that flows forward row-by-row.
/// Separates routing concerns from rendering concerns.
class _RoutingState {
  _RoutingState({
    required this.routingLanes,
    required this.previousLaneColumns,
    required this.deferredMergeBacks,
  });

  final List<Lane> routingLanes;
  final Map<String, int> previousLaneColumns;
  final Map<String, String> deferredMergeBacks;

  /// Create initial routing state from previous row's rendering data.
  factory _RoutingState.fromPreviousRow(LaneData? previousLaneData) {
    // Convert previous snapshots back to Lane objects
    // Reconstruct routingLanes from previousLaneData.row.after
    final routingLanes = <Lane>[];
    if (previousLaneData != null) {
      for (final snapshot in previousLaneData.row.after.values) {
        if (snapshot.laneId.isNotEmpty) {
          routingLanes.add(Lane(
            id: snapshot.laneId,
            expectedOid: snapshot.expectedOid,
            color: snapshot.color, // Preserve color from snapshot
          ));
        }
      }
    }

    // Track previous column assignments for stable sorting
    final previousLaneColumns = <String, int>{};
    if (previousLaneData != null) {
      for (final entry in previousLaneData.row.after.entries) {
        if (entry.key.isNotEmpty) {
          previousLaneColumns[entry.key] = entry.value.column;
        }
      }
    }

    // Track pending merge-backs to be emitted on the next row
    final deferredMergeBacks = <String, String>{};

    return _RoutingState(
      routingLanes: routingLanes,
      previousLaneColumns: previousLaneColumns,
      deferredMergeBacks: deferredMergeBacks,
    );
  }
}

/// Lane router - treats commits as a DAG routing problem, not a tree.
class GraphLayoutCalculator {
  GraphLayoutCalculator({
    required Brightness brightness,
  }) : _palette = commitLanePaletteForBrightness(brightness);

  final List<Color> _palette;
  // Counter for generating unique lane IDs
  int _nextLaneId = 0;

  String _generateLaneId() => 'lane_${_nextLaneId++}';

  List<CommitWithLaneData> processCommitsIncremental(
    List<GcommitListItem> commits,
    LaneData? previousLaneData, {
    required double startX,
    required double laneSpacing,
  }) {
    // Initialize routing state from previous row
    var routingState = _RoutingState.fromPreviousRow(previousLaneData);

    final results = <CommitWithLaneData>[];

    for (final commit in commits) {
      final parents = _extractParents(commit);

      // Create snapshot of lanesBefore using PREVIOUS row's columns
      // Only include routingLanes that existed in the previous row (have a previous column)
      final activeLanesBefore = routingState.routingLanes
          .where((lane) =>
              lane.expectedOid != null &&
              routingState.previousLaneColumns.containsKey(lane.id))
          .toList();
      final lanesBefore = activeLanesBefore
          .map((lane) => LaneSnapshot(
                laneId: lane.id,
                column: routingState.previousLaneColumns[lane.id]!,
                color: lane.color,
                expectedOid: lane.expectedOid,
              ))
          .toList();

      // Step A: Pick a lane for this commit
      // Exclude routingLanes in deferredMergeBacks (visual-only, don't participate in routing)
      final currentLaneIndex = routingState.routingLanes.indexWhere(
        (lane) =>
            lane.expectedOid == commit.oid &&
            !routingState.deferredMergeBacks.containsKey(lane.id),
      );
      final Lane currentLane;
      if (currentLaneIndex != -1) {
        currentLane = routingState.routingLanes[currentLaneIndex];
      } else {
        // Not waiting for this commit - find empty lane or create new
        // Exclude collapsing lanes from reuse
        final emptyLaneIndex = routingState.routingLanes.indexWhere(
          (lane) =>
              lane.expectedOid == null &&
              !routingState.deferredMergeBacks.containsKey(lane.id),
        );
        if (emptyLaneIndex != -1) {
          currentLane = routingState.routingLanes[emptyLaneIndex];
        } else {
          // Create new lane (no column assignment yet)
          // Assign color sequentially based on lane creation order
          final color = _palette[_nextLaneId % _palette.length];
          currentLane = Lane(
            id: _generateLaneId(),
            color: color,
            expectedOid: null,
          );
          routingState.routingLanes.add(currentLane);
        }
      }

      // Step B: Update lane table
      // Primary parent continues in same lane
      final primaryParent = parents.isNotEmpty ? parents.first : null;
      currentLane.expectedOid = primaryParent;

      // Secondary parents reserve other lanes
      final nodeMergeTargets = <String>[];
      for (final parent in parents.skip(1)) {
        // Find existing lane waiting for this parent
        // Exclude collapsing lanes from reuse
        var mergeLaneIndex = routingState.routingLanes.indexWhere(
          (lane) =>
              lane.expectedOid == parent &&
              !routingState.deferredMergeBacks.containsKey(lane.id),
        );
        Lane mergeLane;
        if (mergeLaneIndex != -1) {
          mergeLane = routingState.routingLanes[mergeLaneIndex];
        } else {
          // Find empty lane or create new
          // Exclude collapsing lanes from reuse
          mergeLaneIndex = routingState.routingLanes.indexWhere(
            (lane) =>
                lane.expectedOid == null &&
                !routingState.deferredMergeBacks.containsKey(lane.id),
          );
          if (mergeLaneIndex != -1) {
            mergeLane = routingState.routingLanes[mergeLaneIndex];
          } else {
            // Create new lane (no column assignment yet)
            // Assign color sequentially based on lane creation order
            final color = _palette[_nextLaneId % _palette.length];
            mergeLane = Lane(
              id: _generateLaneId(),
              color: color,
              expectedOid: null,
            );
            routingState.routingLanes.add(mergeLane);
            mergeLaneIndex = routingState.routingLanes.length - 1;
          }
        }
        mergeLane.expectedOid = parent;

        // Only draw node-merge if this parent is NOT already
        // connected to the node via lane continuity
        // Check if parent was in lanesBefore at the same column as currentLane
        final currentLaneColumn =
            routingState.previousLaneColumns[currentLane.id];
        final parentLaneBeforeSnapshot = lanesBefore.firstWhere(
          (snapshot) => snapshot.expectedOid == parent,
          orElse: () => LaneSnapshot(
            laneId: '',
            column: -1,
            color: _palette[0], // Default color for empty snapshot
            expectedOid: null,
          ),
        );
        final isVerticallyConnected =
            parentLaneBeforeSnapshot.laneId.isNotEmpty &&
                currentLaneColumn != null &&
                parentLaneBeforeSnapshot.column == currentLaneColumn;

        if (!isVerticallyConnected) {
          nodeMergeTargets.add(mergeLane.id);
        }
      }

      // Step C: Deferred lane collapse - keep leftmost, free duplicates
      // Capture merge-back intent explicitly: fromLaneId → toLaneId
      // Group routingLanes by expectedOid, then find leftmost (lowest column) for each
      final lanesByOid = <String, List<Lane>>{};
      for (final lane in routingState.routingLanes) {
        final oid = lane.expectedOid;
        if (oid == null) continue;
        lanesByOid.putIfAbsent(oid, () => []).add(lane);
      }

      // DEFERRED MERGE-BACK TIMING EXPLANATION:
      //
      // When duplicate OIDs are detected (multiple lanes waiting for the same commit),
      // we defer the merge-back visualization by one row. This is critical for correct
      // visual representation:
      //
      // 1. DELAY REASON: Merge-back curves must be drawn on the PARENT commit's row,
      //    not the current commit's row. The curve connects the collapsing lane's
      //    top position to the survivor lane's node position. Drawing it on the current
      //    row would be incorrect because the parent commit hasn't been processed yet.
      //
      // 2. VISUAL ACTIVITY: Collapsing lanes remain active (expectedOid not set to null)
      //    for one more row so they appear in row.before/row.after maps. This allows
      //    the painter to draw the merge-back curve from the collapsing lane's position
      //    to the survivor lane's node on the parent commit row.
      //
      // 3. ROUTING EXCLUSION: While visually active, collapsing lanes are excluded from
      //    column assignment and routing decisions (see activeRoutingLanes filter below).
      //    They are visual-only participants for their final row.
      //
      // Flow: Detect duplicates → Store intent for NEXT row → NEXT row draws curves → Remove lanes

      // STEP 1 & 2: Defer merge-back by one row - keep collapsing lane active
      // Store merge-back intent to be emitted on NEXT row (parent commit row)
      final newDeferredMergeBacks = <String, String>{};

      for (final entry in lanesByOid.entries) {
        final oidLanes = entry.value;
        if (oidLanes.length <= 1) continue; // No duplicates

        // Sort by previous column to find leftmost
        oidLanes.sort((a, b) {
          final aCol = routingState.previousLaneColumns[a.id];
          final bCol = routingState.previousLaneColumns[b.id];
          if (aCol != null && bCol != null) {
            return aCol.compareTo(bCol);
          }
          if (aCol != null) return -1;
          if (bCol != null) return 1;
          return a.id.compareTo(b.id);
        });
        final survivorLane = oidLanes.first;

        // Store merge-back intent for NEXT row (don't mark as dying yet)
        // Keep collapsing lane active for one more row so it appears in row.before/row.after
        // This allows the painter to draw the merge-back curve on the parent commit row
        for (var i = 1; i < oidLanes.length; i++) {
          final collapsingLane = oidLanes[i];
          newDeferredMergeBacks[collapsingLane.id] = survivorLane.id;
          // DO NOT set expectedOid = null here - keep lane active for merge-back curve
        }
      }

      // Use pending merge-backs from previous row (emitted on THIS row)
      // These were detected on the previous commit and are now ready to be visualized
      final mergeBacksThisRow =
          Map<String, String>.from(routingState.deferredMergeBacks);

      // Update routing state for next row
      routingState = _RoutingState(
        routingLanes: routingState.routingLanes,
        previousLaneColumns: routingState.previousLaneColumns,
        deferredMergeBacks: newDeferredMergeBacks,
      );

      // Assign columns PER ROW AFTER processing commit (only active lanes)
      // Exclude collapsing lanes from activeRoutingLanes (visual-only, don't affect columns)
      final activeRoutingLanes = routingState.routingLanes
          .where(
            (lane) =>
                lane.expectedOid != null &&
                !mergeBacksThisRow.containsKey(lane.id),
          )
          .toList();

      // Sort active lanes by previous column (if existed), then by stable laneId
      activeRoutingLanes.sort((a, b) {
        final aCol = routingState.previousLaneColumns[a.id];
        final bCol = routingState.previousLaneColumns[b.id];
        if (aCol != null && bCol != null) {
          return aCol.compareTo(bCol);
        }
        if (aCol != null) return -1;
        if (bCol != null) return 1;
        return a.id.compareTo(b.id);
      });

      // Assign columns sequentially to active lanes
      final laneToColumnAfter = <String, int>{};
      for (var i = 0; i < activeRoutingLanes.length; i++) {
        laneToColumnAfter[activeRoutingLanes[i].id] = i;
      }

      // Create snapshot of lanesAfter (only active lanes)
      final lanesAfter = activeRoutingLanes
          .map((lane) => LaneSnapshot(
                laneId: lane.id,
                column: laneToColumnAfter[lane.id]!,
                color: lane.color,
                expectedOid: lane.expectedOid,
              ))
          .toList();

      // Update routing state with new column assignments for next row
      routingState = _RoutingState(
        routingLanes: routingState.routingLanes,
        previousLaneColumns: laneToColumnAfter,
        deferredMergeBacks: routingState.deferredMergeBacks,
      );

      // Compute visualLaneCount PER ROW (only active lanes)
      final visualLaneCount = activeRoutingLanes.length;

      // Build before map (active lanes only)
      final beforeMap = <String, LaneSnapshot>{
        for (final snapshot in lanesBefore)
          if (snapshot.laneId.isNotEmpty) snapshot.laneId: snapshot
      };

      // Build after map (active lanes only)
      final afterMap = <String, LaneSnapshot>{
        for (final snapshot in lanesAfter)
          if (snapshot.laneId.isNotEmpty) snapshot.laneId: snapshot
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
      final collapsingLaneIds = mergeBacksThisRow.keys.toSet();
      final collapseInto = Map<String, String>.from(mergeBacksThisRow);

      // Build mergeFromNodeLaneIds
      final mergeFromNodeLaneIds = nodeMergeTargets.toSet();

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

      // Remove collapsing lanes from routingLanes list AFTER emitting the row
      //
      // POST-PAINT REMOVAL EXPLANATION:
      // Collapsing lanes are removed here, AFTER the row has been emitted, because:
      //
      // 1. VISUALIZATION COMPLETE: The merge-back curves have been drawn on this row
      //    (see _CommitRailPainter.paint()). The collapsing lanes served their visual
      //    purpose and are no longer needed for rendering.
      //
      // 2. ROUTING CLEANUP: These lanes were excluded from routing decisions (column
      //    assignment) but remained in routingLanes for visual access. Now that the
      //    row is complete, we remove them to prevent them from affecting future rows.
      //
      // 3. TIMING CRITICAL: Removal MUST happen after row emission. If removed earlier,
      //    the painter wouldn't have access to their positions in row.before/row.after,
      //    and the merge-back curves couldn't be drawn correctly.
      //
      // Lifecycle: Detect duplicates → Defer to next row → Draw curves → Remove lanes
      final updatedRoutingLanes = routingState.routingLanes
          .where((lane) => !mergeBacksThisRow.containsKey(lane.id))
          .toList();

      // Update routing state for next iteration
      routingState = _RoutingState(
        routingLanes: updatedRoutingLanes,
        previousLaneColumns: routingState.previousLaneColumns,
        deferredMergeBacks: routingState.deferredMergeBacks,
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
