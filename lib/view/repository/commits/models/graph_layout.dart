import 'dart:math' as math;

import 'package:diohub/graphql/queries/repositories/__generated__/commits_list.data.gql.dart';
import 'package:flutter/foundation.dart';

/// Information about a curve-back from a lane to a parent commit.
class CurveBackInfo {
  const CurveBackInfo({
    required this.parentOid,
    required this.parentLane,
  });

  final String parentOid;
  final int parentLane;
}

/// Snapshot of lane state for a single commit row.
class LaneData {
  const LaneData({
    required this.lanesBefore,
    required this.lanesAfter,
    required this.currentLane,
    required this.mergeTargets,
    required this.maxLanes,
    this.curveBacksByLane = const {},
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

  /// Curve-back info stored on lanes themselves.
  /// Map<laneIndex, CurveBackInfo> where:
  /// - laneIndex: the lane that curves back
  /// - CurveBackInfo: contains the parent commit OID and the lane it was on when detected
  /// This map is carried forward across pages so curve-backs can be drawn
  /// when the parent commit is eventually processed.
  final Map<int, CurveBackInfo> curveBacksByLane;
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
    // Track curve-backs by lane: Map<laneIndex, CurveBackInfo>
    // Start with curve-backs from previous page
    final curveBacksByLane = <int, CurveBackInfo>{
      ...previousLaneData?.curveBacksByLane ?? {}
    };

    // Map to track commit OID -> lane number for stable lookups
    // This avoids issues when intermediate commits cause lanes to shift
    final commitToLane = <String, int>{};
    // Initialize from activeLanes
    for (var i = 0; i < activeLanes.length; i++) {
      if (activeLanes[i] != null) {
        commitToLane[activeLanes[i]!] = i;
      }
    }

    for (final commit in commits) {
      final parents = _extractParents(commit);
      final lanesBefore = List<String?>.from(activeLanes);

      // Place commit on an existing lane if we were already waiting for it.
      // Use map for stable lookup instead of indexOf
      var currentLane = commitToLane[commit.oid];
      if (currentLane == null) {
        currentLane = _firstEmptyIndex(activeLanes);
        if (currentLane == -1) {
          currentLane = activeLanes.length;
          activeLanes.add(null);
        }
        // Update map
        commitToLane[commit.oid] = currentLane;
      }

      // Check if this commit has incoming curve-backs and log the mismatch
      final incomingCurveBacks = curveBacksByLane.entries
          .where((e) => e.value.parentOid == commit.oid)
          .toList();
      if (incomingCurveBacks.isNotEmpty) {
        for (final entry in incomingCurveBacks) {
          final detectedLane = entry.value.parentLane;
          debugPrint(
              '[GraphLayout] Processing ${commit.oid.substring(0, 7)}: Has incoming curve-back from lane ${entry.key}');
          debugPrint(
              '[GraphLayout]   Curve-back detected parent on lane: $detectedLane');
          debugPrint(
              '[GraphLayout]   Commit actually assigned to lane: $currentLane');
          if (detectedLane != currentLane) {
            debugPrint(
                '[GraphLayout]   ⚠⚠⚠ LANE MISMATCH: Parent was detected on lane $detectedLane but commit is on lane $currentLane');
            debugPrint(
                '[GraphLayout]   activeLanes before processing: ${activeLanes.map((oid) => oid?.substring(0, 7) ?? "null").toList()}');
          }
        }
      }

      // Prepare lanesAfter starting from current active snapshot.
      final lanesAfter = List<String?>.from(activeLanes);

      // Primary parent continues down the current lane.
      final primaryParent = parents.isNotEmpty ? parents.first : null;

      // DETECT CURVE-BACK: Check if primary parent is already on a different lane
      // BEFORE we assign it to the current lane
      if (primaryParent != null) {
        // Use map for stable lookup - this gives us the parent's current lane
        final parentLane = commitToLane[primaryParent];

        if (parentLane != null && parentLane != currentLane) {
          // Primary parent is already on a different lane - this is a curve-back!
          curveBacksByLane[currentLane] = CurveBackInfo(
            parentOid: primaryParent,
            parentLane: parentLane,
          );
          debugPrint(
              '[GraphLayout] CURVE-BACK DETECTED: Commit ${commit.oid.substring(0, 7)} on lane $currentLane → parent ${primaryParent.substring(0, 7)} detected on lane $parentLane');
        }
      }

      lanesAfter[currentLane] = primaryParent;

      // Secondary parents get their own lanes (merge curves).
      final mergeTargets = <int>[];
      for (final parent in parents.skip(1)) {
        // Use map for stable lookup
        var mergeLane = commitToLane[parent];
        if (mergeLane == null) {
          mergeLane = _firstEmptyIndex(lanesAfter);
          if (mergeLane == -1) {
            mergeLane = lanesAfter.length;
            lanesAfter.add(null);
          }
          // Update map
          commitToLane[parent] = mergeLane;
        }
        lanesAfter[mergeLane] = parent;
        mergeTargets.add(mergeLane);
      }

      // Collapse lanes that now converge to the same downstream commit.
      // Keep the first lane per OID and free duplicates for reuse.
      final seenParentLane = <String, int>{};
      for (var i = 0; i < lanesAfter.length; i++) {
        final oid = lanesAfter[i];
        if (oid == null) continue;
        if (seenParentLane.containsKey(oid)) {
          lanesAfter[i] = null;
          // Remove from map when lane becomes null
          if (commitToLane[oid] == i) {
            commitToLane.remove(oid);
          }
        } else {
          seenParentLane[oid] = i;
          // DON'T update commitToLane here - it's already correct from explicit assignments above
          // The map is updated when we assign commits to lanes (lines 105, 167), not here
        }
      }

      // Also check for curve-back after collapse (in case lane collapsed)
      // This handles cases where the lane collapses AND the parent is on a different lane
      if (primaryParent != null) {
        final currentLaneAfter = lanesAfter[currentLane];
        if (currentLaneAfter == null) {
          // Current lane collapsed - check if primary parent is on different lane
          // Use map for stable lookup
          final parentLane = commitToLane[primaryParent];
          if (parentLane != null && parentLane != currentLane) {
            // Curve-back detected! Store on the lane itself
            // (Only if we haven't already stored it above)
            if (!curveBacksByLane.containsKey(currentLane)) {
              curveBacksByLane[currentLane] = CurveBackInfo(
                parentOid: primaryParent,
                parentLane: parentLane,
              );
              debugPrint(
                  '[GraphLayout] CURVE-BACK DETECTED (after collapse): Commit ${commit.oid.substring(0, 7)} on lane $currentLane → parent ${primaryParent.substring(0, 7)} on lane $parentLane');
            }
          }
        }
        // Note: We don't update stored parentLane after collapse - it should remain
        // as it was when detected. The painter will use the current commit's lane as the target.
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

      // Sync commitToLane map with final activeLanes state
      // Remove entries for commits that are no longer in activeLanes
      commitToLane.removeWhere((oid, lane) =>
          lane >= activeLanes.length || activeLanes[lane] != oid);
      // Add/update entries for commits in activeLanes
      // IMPORTANT: Only update for commits we're currently processing or explicitly assigned
      // Don't update for unprocessed primary parents - they'll be updated when they're processed
      for (var i = 0; i < activeLanes.length; i++) {
        final oid = activeLanes[i];
        if (oid != null) {
          // Only update if:
          // 1. This is the current commit (we're processing it now)
          // 2. This is a secondary parent we just assigned (already updated at line 167)
          // 3. This commit is not yet in the map (newly added)
          // DON'T update for primary parents that are already in the map (they haven't been processed yet)
          if (oid == commit.oid ||
              (parents.length > 1 && parents.skip(1).contains(oid)) ||
              !commitToLane.containsKey(oid)) {
            commitToLane[oid] = i;
          }
        }
      }

      // First, create LaneData with current curveBacksByLane (includes curve-backs for this commit)
      // This allows the painter to draw curve-backs when processing the parent commit

      // Debug log for 02d1c20
      if (commit.oid.startsWith('02d1c20')) {
        debugPrint('[GraphLayout] ═══ Creating LaneData for 02d1c20 ═══');
        debugPrint(
            '[GraphLayout] curveBacksByLane: ${curveBacksByLane.map((k, v) => MapEntry(k, '${v.parentOid.substring(0, 7)}@lane${v.parentLane}'))}');
        debugPrint('[GraphLayout] currentLane: $currentLane');
        debugPrint(
            '[GraphLayout] lanesAfter: ${lanesAfter.map((oid) => oid?.substring(0, 7) ?? "null")}');
      }

      results.add(
        CommitWithLaneData(
          commit: commit,
          laneData: LaneData(
            lanesBefore: paddedBefore,
            lanesAfter: paddedAfter,
            currentLane: currentLane,
            mergeTargets: mergeTargets,
            maxLanes: maxLanes,
            curveBacksByLane:
                Map.from(curveBacksByLane), // Every commit gets the full map
          ),
        ),
      );

      // Now remove curve-backs for lanes that no longer exist (were trimmed)
      // Also remove curve-backs whose parent was just processed (this commit)
      final remainingCurveBacksByLane = <int, CurveBackInfo>{};
      for (final entry in curveBacksByLane.entries) {
        final laneIndex = entry.key;
        final curveBackInfo = entry.value;

        // Keep curve-back if:
        // 1. The lane index is within maxLanes (even if trimmed, painter checks up to maxLanes)
        // 2. The parent hasn't been processed yet (not this commit)
        if (laneIndex < maxLanes && curveBackInfo.parentOid != commit.oid) {
          remainingCurveBacksByLane[laneIndex] = curveBackInfo;
        }
      }
      curveBacksByLane.clear();
      curveBacksByLane.addAll(remainingCurveBacksByLane);
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
