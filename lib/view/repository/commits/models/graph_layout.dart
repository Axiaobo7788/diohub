import 'dart:math' as math;

import 'package:diohub/graphql/queries/repositories/__generated__/commits_list.data.gql.dart';
import 'package:flutter/material.dart';

/// Commit Graph Lane Lifecycle
///
/// Lanes terminate immediately when they reach their expected commit:
/// - A lane terminates when lane.expectedOid == commit.oid
/// - Terminated lanes are removed from liveLanes immediately
/// - No deferred termination or merge-back visualization
/// - Lanes that terminate simply stop drawing at the commit node

/// Visual styling constants for commit graph rendering.
class CommitGraphStyle {
  const CommitGraphStyle({
    this.laneSpacing = 12,
    this.railInset = 6,
    this.nodeRadius = 6,
    this.strokeWidth = 2,
    this.nodeStrokeWidth = 2.0,
    this.rowHeight = 68,
    this.rowOverlap = 16,
    this.railOpacity = 0.8,
    this.curveControlMultiplier = 0.7,
  });

  final double laneSpacing;
  final double railInset;
  final double nodeRadius;
  final double strokeWidth;
  final double nodeStrokeWidth;
  final double rowHeight;
  final double rowOverlap;
  final double railOpacity;
  final double curveControlMultiplier;

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
    required this.mergeFromNodeLaneIds,
    required this.mergeIntoNodeLaneIds,
    required this.visualLaneCount,
    required this.effectiveLaneCount,
  });

  /// Lane ID where the commit node is drawn.
  final String nodeLaneId;

  /// Active lanes entering this row: laneId → snapshot.
  final Map<String, LaneSnapshot> before;

  /// Active lanes exiting this row: laneId → snapshot.
  final Map<String, LaneSnapshot> after;

  /// Union of all lane IDs from both before and after.
  final Set<String> visibleLaneIds;

  /// Secondary parents drawn from node (merge curves).
  final Set<String> mergeFromNodeLaneIds;

  /// All lanes that merge into the node (arriving lanes + secondary parents).
  final Set<String> mergeIntoNodeLaneIds;

  /// Width driver (number of visual lanes).
  final int visualLaneCount;

  /// Effective lane count accounting for all visually-present lanes (max column + 1).
  final int effectiveLaneCount;
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
  });

  final List<Lane> liveLanes;
  final Map<String, int> laneColumnsPrevRow;

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

    return _RoutingState(
      liveLanes: liveLanes,
      laneColumnsPrevRow: laneColumnsPrevRow,
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

      // Snapshot lanes arriving at this commit BEFORE any mutations
      final arrivingLaneIds = state.liveLanes
          .where((lane) => lane.expectedOid == commit.oid)
          .map((lane) => lane.id)
          .toSet();

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
        (lane) => lane.expectedOid == commit.oid,
      );
      final Lane currentLane;
      if (matchedLaneIndex != -1) {
        currentLane = state.liveLanes[matchedLaneIndex];
      } else {
        final reusableLaneIndex = state.liveLanes.indexWhere(
          (lane) => lane.expectedOid == null,
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
          (lane) => lane.expectedOid == parent,
        );
        Lane mergeLane;
        if (mergeLaneIndex != -1) {
          mergeLane = state.liveLanes[mergeLaneIndex];
        } else {
          mergeLaneIndex = state.liveLanes.indexWhere(
            (lane) => lane.expectedOid == null,
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

      final routableLanes = state.liveLanes
          .where((lane) =>
              lane.expectedOid != null &&
              (!arrivingLaneIds.contains(lane.id) || lane.id == currentLane.id))
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

      final mergeFromNodeLaneIds = nodeMergeTargets.toSet();
      final mergeIntoNodeLaneIds = <String>{
        ...arrivingLaneIds,
        ...mergeFromNodeLaneIds,
      };

      // Compute effectiveLaneCount from max column index in both before and after
      int maxColumn = -1;
      for (final snapshot in lanesBefore) {
        maxColumn = math.max(maxColumn, snapshot.column);
      }
      for (final snapshot in lanesAfter) {
        maxColumn = math.max(maxColumn, snapshot.column);
      }
      final effectiveLaneCount = math.max(1, maxColumn + 1);

      final rowState = LaneRowState(
        nodeLaneId: currentLane.id,
        before: beforeMap,
        after: afterMap,
        visibleLaneIds: visibleLaneIds,
        mergeFromNodeLaneIds: mergeFromNodeLaneIds,
        mergeIntoNodeLaneIds: mergeIntoNodeLaneIds,
        visualLaneCount: visualLaneCount,
        effectiveLaneCount: effectiveLaneCount,
      );

      results.add(
        CommitWithLaneData(
          commit: commit,
          laneData: LaneData(row: rowState),
        ),
      );

      final updatedLiveLanes = state.liveLanes
          .where((lane) =>
              !arrivingLaneIds.contains(lane.id) || lane.id == currentLane.id)
          .toList();

      state = _RoutingState(
        liveLanes: updatedLiveLanes,
        laneColumnsPrevRow: state.laneColumnsPrevRow,
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
