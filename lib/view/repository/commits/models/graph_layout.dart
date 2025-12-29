import 'package:diohub/graphql/queries/repositories/__generated__/commits_list.data.gql.dart';
import 'package:flutter/material.dart';

/// Deferred Merge-Back Visualization
///
/// When multiple lanes wait for the same commit (duplicate OIDs), we defer
/// merge-back visualization by one row. This ensures correct visual representation:
///
/// 1. Timing: Merge-back curves connect the collapsing lane's top position to the
///    survivor lane's node position. The curve must be drawn on the PARENT commit's
///    row, not the current commit's row, because the parent commit hasn't been
///    processed yet.
///
/// 2. Lane Lifecycle: Collapsing lanes remain active (expectedOid not set to null)
///    for one extra row so they appear in row.before/row.after maps. This allows
///    the painter to access their positions for drawing the merge-back curve.
///
/// 3. Routing Exclusion: While visually active, collapsing lanes are excluded from
///    column assignment and routing decisions. They are visual-only participants
///    for their final row.
///
/// Flow: Detect duplicates → Store intent for NEXT row → NEXT row draws curves → Remove lanes

/// Visual styling constants for commit graph rendering.
class CommitGraphStyle {
  const CommitGraphStyle({
    this.laneSpacing = 18,
    this.railInset = 6,
    this.nodeRadius = 5,
    this.strokeWidth = 2,
    this.nodeStrokeWidth = 1.4,
    this.rowHeight = 68,
    this.rowOverlap = 16,
  });

  final double laneSpacing;
  final double railInset;
  final double nodeRadius;
  final double strokeWidth;
  final double nodeStrokeWidth;
  final double rowHeight;
  final double rowOverlap;

  /// X coordinate where the first lane starts.
  double get startX => railInset + laneSpacing / 2;

  /// Half of row height for calculations.
  double get halfRowHeight => rowHeight / 2;
}

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
    required this.x,
    this.expectedOid,
  });

  final String laneId;
  final int column;
  final Color color; // stable color from the lane
  final double x; // X coordinate: startX + column * laneSpacing
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
    required this.liveLanes,
    required this.laneColumnsPrevRow,
    required this.pendingMergeBacks,
  });

  final List<Lane> liveLanes;
  final Map<String, int> laneColumnsPrevRow;
  final Map<String, String> pendingMergeBacks;

  factory _RoutingState.fromPreviousRow(LaneData? previousLaneData) {
    final liveLanes = <Lane>[];
    if (previousLaneData != null) {
      for (final snapshot in previousLaneData.row.after.values) {
        if (snapshot.laneId.isNotEmpty) {
          liveLanes.add(Lane(
              id: snapshot.laneId,
              expectedOid: snapshot.expectedOid,
              color: snapshot.color));
        }
      }
    }

    final laneColumnsPrevRow = <String, int>{};
    if (previousLaneData != null) {
      for (final entry in previousLaneData.row.after.entries) {
        if (entry.key.isNotEmpty) {
          laneColumnsPrevRow[entry.key] = entry.value.column;
        }
      }
    }

    final pendingMergeBacks = <String, String>{};

    return _RoutingState(
      liveLanes: liveLanes,
      laneColumnsPrevRow: laneColumnsPrevRow,
      pendingMergeBacks: pendingMergeBacks,
    );
  }
}

/// Lane router - treats commits as a DAG routing problem, not a tree.
class GraphLayoutCalculator {
  GraphLayoutCalculator({
    required Brightness brightness,
    required this.style,
  }) : _palette = commitLanePaletteForBrightness(brightness);

  final List<Color> _palette;
  final CommitGraphStyle style;
  // Counter for generating unique lane IDs
  int _nextLaneId = 0;

  String _generateLaneId() => 'lane_${_nextLaneId++}';

  List<CommitWithLaneData> processCommitsIncremental(
    List<GcommitListItem> commits,
    LaneData? previousLaneData,
  ) {
    var state = _RoutingState.fromPreviousRow(previousLaneData);

    final results = <CommitWithLaneData>[];

    for (final commit in commits) {
      final parents = _extractParents(commit);

      final activeLanesBefore = state.liveLanes
          .where((lane) =>
              lane.expectedOid != null &&
              state.laneColumnsPrevRow.containsKey(lane.id))
          .toList();
      final lanesBefore = activeLanesBefore.map((lane) {
        final column = state.laneColumnsPrevRow[lane.id]!;
        return LaneSnapshot(
          laneId: lane.id,
          column: column,
          color: lane.color,
          x: style.startX + column * style.laneSpacing,
          expectedOid: lane.expectedOid,
        );
      }).toList();

      final matchedLaneIndex = state.liveLanes.indexWhere(
        (lane) =>
            lane.expectedOid == commit.oid &&
            !state.pendingMergeBacks.containsKey(lane.id),
      );
      final Lane currentLane;
      if (matchedLaneIndex != -1) {
        currentLane = state.liveLanes[matchedLaneIndex];
      } else {
        final reusableLaneIndex = state.liveLanes.indexWhere(
          (lane) =>
              lane.expectedOid == null &&
              !state.pendingMergeBacks.containsKey(lane.id),
        );
        if (reusableLaneIndex != -1) {
          currentLane = state.liveLanes[reusableLaneIndex];
        } else {
          final color = _palette[_nextLaneId % _palette.length];
          currentLane = Lane(
            id: _generateLaneId(),
            color: color,
            expectedOid: null,
          );
          state.liveLanes.add(currentLane);
        }
      }

      final primaryParent = parents.isNotEmpty ? parents.first : null;
      currentLane.expectedOid = primaryParent;

      final nodeMergeTargets = <String>[];
      for (final parent in parents.skip(1)) {
        var mergeLaneIndex = state.liveLanes.indexWhere(
          (lane) =>
              lane.expectedOid == parent &&
              !state.pendingMergeBacks.containsKey(lane.id),
        );
        Lane mergeLane;
        if (mergeLaneIndex != -1) {
          mergeLane = state.liveLanes[mergeLaneIndex];
        } else {
          mergeLaneIndex = state.liveLanes.indexWhere(
            (lane) =>
                lane.expectedOid == null &&
                !state.pendingMergeBacks.containsKey(lane.id),
          );
          if (mergeLaneIndex != -1) {
            mergeLane = state.liveLanes[mergeLaneIndex];
          } else {
            final color = _palette[_nextLaneId % _palette.length];
            mergeLane = Lane(
              id: _generateLaneId(),
              color: color,
              expectedOid: null,
            );
            state.liveLanes.add(mergeLane);
            mergeLaneIndex = state.liveLanes.length - 1;
          }
        }
        mergeLane.expectedOid = parent;

        final currentLaneColumn = state.laneColumnsPrevRow[currentLane.id];
        final parentLaneBeforeSnapshot = lanesBefore.firstWhere(
          (snapshot) => snapshot.expectedOid == parent,
          orElse: () => LaneSnapshot(
            laneId: '',
            column: -1,
            color: _palette[0],
            x: style.startX,
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

      // Deferred merge-back (see file-level documentation)
      final lanesGroupedByExpectedOid = <String, List<Lane>>{};
      for (final lane in state.liveLanes) {
        final oid = lane.expectedOid;
        if (oid == null) continue;
        lanesGroupedByExpectedOid.putIfAbsent(oid, () => []).add(lane);
      }

      final deferredMergeBacksNextRow = <String, String>{};

      for (final entry in lanesGroupedByExpectedOid.entries) {
        final oidLanes = entry.value;
        if (oidLanes.length <= 1) continue;

        oidLanes.sort((a, b) {
          final aCol = state.laneColumnsPrevRow[a.id];
          final bCol = state.laneColumnsPrevRow[b.id];
          if (aCol != null && bCol != null) {
            return aCol.compareTo(bCol);
          }
          if (aCol != null) return -1;
          if (bCol != null) return 1;
          return a.id.compareTo(b.id);
        });
        final survivorLane = oidLanes.first;

        for (var i = 1; i < oidLanes.length; i++) {
          final collapsingLane = oidLanes[i];
          deferredMergeBacksNextRow[collapsingLane.id] = survivorLane.id;
        }
      }

      final mergeBacks = Map<String, String>.from(state.pendingMergeBacks);

      state = _RoutingState(
        liveLanes: state.liveLanes,
        laneColumnsPrevRow: state.laneColumnsPrevRow,
        pendingMergeBacks: deferredMergeBacksNextRow,
      );

      final routableLanes = state.liveLanes
          .where(
            (lane) =>
                lane.expectedOid != null && !mergeBacks.containsKey(lane.id),
          )
          .toList();

      routableLanes.sort((a, b) {
        final aCol = state.laneColumnsPrevRow[a.id];
        final bCol = state.laneColumnsPrevRow[b.id];
        if (aCol != null && bCol != null) {
          return aCol.compareTo(bCol);
        }
        if (aCol != null) return -1;
        if (bCol != null) return 1;
        return a.id.compareTo(b.id);
      });

      final laneToColumnAfter = <String, int>{};
      for (var i = 0; i < routableLanes.length; i++) {
        laneToColumnAfter[routableLanes[i].id] = i;
      }

      final lanesAfter = routableLanes.map((lane) {
        final column = laneToColumnAfter[lane.id]!;
        return LaneSnapshot(
          laneId: lane.id,
          column: column,
          color: lane.color,
          x: style.startX + column * style.laneSpacing,
          expectedOid: lane.expectedOid,
        );
      }).toList();

      state = _RoutingState(
        liveLanes: state.liveLanes,
        laneColumnsPrevRow: laneToColumnAfter,
        pendingMergeBacks: state.pendingMergeBacks,
      );

      final visualLaneCount = routableLanes.length;

      final beforeMap = <String, LaneSnapshot>{
        for (final snapshot in lanesBefore)
          if (snapshot.laneId.isNotEmpty) snapshot.laneId: snapshot
      };

      final afterMap = <String, LaneSnapshot>{
        for (final snapshot in lanesAfter)
          if (snapshot.laneId.isNotEmpty) snapshot.laneId: snapshot
      };

      final visibleLaneIds = <String>{
        ...beforeMap.keys,
        ...afterMap.keys,
      };

      final collapsingLaneIds = mergeBacks.keys.toSet();
      final collapseInto = Map<String, String>.from(mergeBacks);
      final mergeFromNodeLaneIds = nodeMergeTargets.toSet();

      final rowState = LaneRowState(
        nodeLaneId: currentLane.id,
        before: beforeMap,
        after: afterMap,
        visibleLaneIds: visibleLaneIds,
        collapsingLaneIds: collapsingLaneIds,
        collapseInto: collapseInto,
        mergeFromNodeLaneIds: mergeFromNodeLaneIds,
        visualLaneCount: visualLaneCount,
      );

      results.add(
        CommitWithLaneData(
          commit: commit,
          laneData: LaneData(row: rowState),
        ),
      );

      final updatedLiveLanes = state.liveLanes
          .where((lane) => !mergeBacks.containsKey(lane.id))
          .toList();

      state = _RoutingState(
        liveLanes: updatedLiveLanes,
        laneColumnsPrevRow: state.laneColumnsPrevRow,
        pendingMergeBacks: state.pendingMergeBacks,
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
