import 'dart:math' as math;
import 'dart:ui';

import 'package:diohub/graphql/queries/repositories/__generated__/commits_list.data.gql.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/repository/commits/models/graph_layout.dart';
import 'package:flutter/material.dart';

class CommitGraphRow extends StatelessWidget {
  const CommitGraphRow({
    required this.commitWithLaneData,
    required this.branchTips,
    super.key,
  });

  final CommitWithLaneData commitWithLaneData;
  final Map<String, List<String>>? branchTips;

  @override
  Widget build(BuildContext context) {
    final commit = commitWithLaneData.commit;
    final laneData = commitWithLaneData.laneData;
    final lanes = math.max(laneData.maxLanes, 1);
    final railWidth = _laneSpacing * lanes + _railInset * 2;
    final branches = branchTips?[commit.oid] ?? const <String>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _rowMinHeight),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: railWidth,
              child: SizedBox(
                height: _rowMinHeight + _rowOverlap,
                child: CustomPaint(
                  painter: _CommitRailPainter(
                    laneData: laneData,
                    colorScheme: Theme.of(context).colorScheme,
                    commitOid: commit.oid,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.zero,
                child: _CommitContent(
                  commit: commit,
                  branches: branches,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommitContent extends StatelessWidget {
  const _CommitContent({
    required this.commit,
    required this.branches,
  });

  final GcommitListItem commit;
  final List<String> branches;

  @override
  Widget build(BuildContext context) {
    final authorUser = commit.author?.user;
    // Avoid union casts; base user has login too.
    final authorLogin =
        authorUser?.login ?? commit.author?.name ?? commit.author?.email;
    final message = commit.messageHeadline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (branches.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: branches
                .map(
                  (branch) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          context.colorScheme.primaryContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      branch,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            if (authorLogin != null) ...[
              Icon(
                Icons.person_outline,
                size: 14,
                color: context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                authorLogin,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Icon(
              Icons.access_time,
              size: 14,
              color: context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              getDate(commit.committedDate.toIso8601String(), shorten: false),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.commit,
              size: 14,
              color: context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              commit.abbreviatedOid,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommitRailPainter extends CustomPainter {
  _CommitRailPainter({
    required this.laneData,
    required this.colorScheme,
    required this.commitOid,
  });

  final LaneData laneData;
  final ColorScheme colorScheme;
  final String commitOid;

  @override
  void paint(Canvas canvas, Size size) {
    // PART 1 — LOG ROW CONTEXT
    debugPrint('--- PAINT ROW ---');
    debugPrint('commitOid=$commitOid');
    debugPrint('currentLaneId=${laneData.currentLaneId}');

    final laneCount = math.max(laneData.maxLanes, 1);
    final centerY = _rowMinHeight / 2;
    final topY = -_rowOverlap / 2;
    final bottomY = _rowMinHeight + _rowOverlap / 2;
    final startX = _railInset + _laneSpacing / 2;

    // Find node column from lanesBefore (where commit occurred)
    LaneSnapshot? nodeBeforeSnapshot;
    for (final snapshot in laneData.lanesBefore) {
      if (snapshot.laneId == laneData.currentLaneId && snapshot.activeBefore) {
        nodeBeforeSnapshot = snapshot;
        break;
      }
    }

    // Fallback ONLY if this is a brand new lane (no lanesBefore entry)
    final nodeColumn = nodeBeforeSnapshot != null
        ? nodeBeforeSnapshot.column
        : laneData.lanesAfter
            .firstWhere(
              (s) => s.laneId == laneData.currentLaneId,
            )
            .column;

    final nodeX = startX + nodeColumn * _laneSpacing;

    // PART 5 — LOG NODE POSITION
    debugPrint(
      'NODE: laneId=${laneData.currentLaneId} '
      'column=$nodeColumn centerY=$centerY',
    );

    // PART 2 — LOG LANES BEFORE / AFTER
    debugPrint('lanesBefore:');
    for (final s in laneData.lanesBefore) {
      debugPrint(
        '  BEFORE laneId=${s.laneId} col=${s.column} activeBefore=${s.activeBefore} expectedOid=${s.expectedOid}',
      );
    }

    debugPrint('lanesAfter:');
    for (final s in laneData.lanesAfter) {
      debugPrint(
        '  AFTER  laneId=${s.laneId} col=${s.column} activeAfter=${s.activeAfter} expectedOid=${s.expectedOid}',
      );
    }

    // PART 3 — LOG COLLAPSING LANES (MERGE-BACK INTENT)
    debugPrint('collapsingLanes:');
    laneData.collapsingLanes.forEach((from, to) {
      debugPrint('  from=$from → to=$to');
    });

    // Draw merge-back curves (lanes collapsing into other lanes)
    for (final entry in laneData.collapsingLanes.entries) {
      final fromLaneId = entry.key;
      final toLaneId = entry.value;

      // PART 4 — LOG MERGE-BACK DRAW ATTEMPTS
      debugPrint(
        'MERGE-BACK TRY: fromLaneId=$fromLaneId toLaneId=$toLaneId '
        'currentLaneId=${laneData.currentLaneId}',
      );

      // Find columns for these lanes (merge-back uses lanesBefore for both)
      final fromSnapshot = laneData.lanesBefore.firstWhere(
        (snapshot) => snapshot.laneId == fromLaneId,
        orElse: () {
          debugPrint(
            '  SKIP: fromLaneId=$fromLaneId not present in lanesBefore',
          );
          return const LaneSnapshot(
            laneId: '',
            column: -1,
            activeBefore: false,
            activeAfter: false,
            expectedOid: null,
          );
        },
      );

      if (fromSnapshot.laneId.isEmpty) continue;

      // Check if survivor lane (toLaneId) exists in lanesBefore and is active
      final toLaneBefore = laneData.lanesBefore.any(
        (s) => s.laneId == toLaneId && s.activeBefore,
      );

      if (!toLaneBefore) {
        debugPrint(
          '  SKIP: toLaneId ($toLaneId) not active in lanesBefore',
        );
        continue;
      }

      // Find survivor lane's column from lanesBefore (preferred) or lanesAfter (fallback)
      LaneSnapshot? toSnapshot;
      for (final snapshot in laneData.lanesBefore) {
        if (snapshot.laneId == toLaneId && snapshot.activeBefore) {
          toSnapshot = snapshot;
          break;
        }
      }

      // Fallback to lanesAfter if not found in lanesBefore
      if (toSnapshot == null) {
        try {
          toSnapshot = laneData.lanesAfter.firstWhere(
            (s) => s.laneId == toLaneId && s.activeAfter,
          );
        } catch (e) {
          debugPrint(
            '  SKIP: toLaneId ($toLaneId) not found in lanesAfter either',
          );
          continue;
        }
      }

      final fromX = startX + fromSnapshot.column * _laneSpacing;
      final toLaneNodeX = startX + toSnapshot.column * _laneSpacing;

      debugPrint(
        '  DRAW MERGE-BACK: fromLaneId=$fromLaneId '
        'fromCol=${fromSnapshot.column} '
        'toLaneId=$toLaneId '
        'toCol=${toSnapshot.column} '
        'centerY=$centerY',
      );

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _laneColorById(fromLaneId);

      // Merge-back curve starts at TOP of row, ends at CENTER of survivor lane's node
      final path = Path()..moveTo(fromX, topY);
      path.cubicTo(
        fromX,
        centerY - _halfRow * 0.6,
        toLaneNodeX,
        centerY,
        toLaneNodeX,
        centerY,
      );
      canvas.drawPath(path, paint);
    }

    // Draw vertical lane lines
    // Iterate by LANE IDENTITY, not column (columns can change between rows)

    // Collect all unique laneIds from both snapshots
    final allLaneIds = <String>{};
    for (final snapshot in laneData.lanesBefore) {
      if (snapshot.laneId.isNotEmpty) {
        allLaneIds.add(snapshot.laneId);
      }
    }
    for (final snapshot in laneData.lanesAfter) {
      if (snapshot.laneId.isNotEmpty) {
        allLaneIds.add(snapshot.laneId);
      }
    }

    // For each laneId, find its column in before and after snapshots
    for (final laneId in allLaneIds) {
      // Skip collapsing lanes - they are fully represented by merge-back curves
      if (laneData.collapsingLanes.containsKey(laneId)) continue;

      // Find snapshot in lanesBefore
      LaneSnapshot? snapshotBefore;
      for (final snapshot in laneData.lanesBefore) {
        if (snapshot.laneId == laneId && snapshot.activeBefore) {
          snapshotBefore = snapshot;
          break;
        }
      }

      // Find snapshot in lanesAfter
      LaneSnapshot? snapshotAfter;
      for (final snapshot in laneData.lanesAfter) {
        if (snapshot.laneId == laneId && snapshot.activeAfter) {
          snapshotAfter = snapshot;
          break;
        }
      }

      // Skip if lane doesn't exist in either snapshot
      if (snapshotBefore == null && snapshotAfter == null) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _laneColorById(laneId);

      final beforeColumn = snapshotBefore?.column;
      final afterColumn = snapshotAfter?.column;
      final xBefore =
          beforeColumn != null ? startX + beforeColumn * _laneSpacing : null;
      final xAfter =
          afterColumn != null ? startX + afterColumn * _laneSpacing : null;

      // Drawing rules:
      // - If lane exists before AND after with same column → draw vertical line
      // - If lane exists before AND after with different columns → draw curve
      // - If lane exists only before → draw top vertical segment
      // - If lane exists only after → draw bottom vertical segment

      if (beforeColumn != null && afterColumn != null) {
        // Both columns exist - we know xBefore and xAfter are non-null here
        final xB = xBefore!;
        final xA = xAfter!;

        if (beforeColumn == afterColumn) {
          // Same column: draw continuous vertical line
          canvas.drawLine(Offset(xB, topY), Offset(xB, centerY), paint);
          canvas.drawLine(Offset(xB, centerY), Offset(xB, bottomY), paint);
        } else {
          // Different columns: draw vertical-first transition
          // Top segment: old column (vertical line)
          canvas.drawLine(Offset(xB, topY), Offset(xB, centerY), paint);

          // Curve from old column centerY to new column bottomY (downward, never horizontal at centerY)
          final path = Path()..moveTo(xB, centerY);
          path.cubicTo(
            xB,
            centerY + _halfRow * 0.6,
            xA,
            centerY + _halfRow * 0.6,
            xA,
            bottomY,
          );
          canvas.drawPath(path, paint);
        }
      } else if (beforeColumn != null) {
        // Lane exists only before: draw top vertical segment
        canvas.drawLine(
            Offset(xBefore!, topY), Offset(xBefore!, centerY), paint);
      } else if (afterColumn != null) {
        // Lane exists only after: draw bottom vertical segment
        // Also check if this is the current commit's lane (should be visible)
        final afterActive = snapshotAfter?.activeAfter == true &&
            (laneId == laneData.currentLaneId);
        if (afterActive) {
          canvas.drawLine(
              Offset(xAfter!, centerY), Offset(xAfter!, bottomY), paint);
        }
      }
    }

    // Draw merge curves (downward) - secondary parents
    for (final targetLaneId in laneData.mergeTargets) {
      final targetSnapshot = laneData.lanesAfter.firstWhere(
        (snapshot) => snapshot.laneId == targetLaneId,
      );

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _laneColorById(targetLaneId);

      final targetColumn = targetSnapshot.column;
      if (targetColumn >= laneCount) continue;
      final targetX = startX + targetColumn * _laneSpacing;
      final path = Path()..moveTo(nodeX, centerY);
      path.cubicTo(
        nodeX,
        centerY + _halfRow * 0.6,
        targetX,
        centerY + _halfRow * 0.6,
        targetX,
        bottomY,
      );
      canvas.drawPath(path, paint);
    }

    // Draw commit node
    // Node color matches the current lane
    final nodeLaneId = laneData.currentLaneId;

    final nodePaint = Paint()
      ..color = _laneColorById(nodeLaneId)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(nodeX, centerY), _nodeRadius, nodePaint);

    final stroke = Paint()
      ..color = colorScheme.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(Offset(nodeX, centerY), _nodeRadius, stroke);
  }

  Color _laneColorById(String laneId) {
    // Stable color mapping based on lane ID
    // Use hash of laneId to get consistent color
    final hash = laneId.hashCode;
    return _laneColor(hash.abs() % 6);
  }

  Color _laneColor(int lane) {
    const palette = [
      Color(0xFFFBBC05),
      Color(0xFF7C4DFF),
      Color(0xFF00C49A),
      Color(0xFF42A5F5),
      Color(0xFFFF7043),
      Color(0xFF9CCC65),
    ];
    if (lane < palette.length) return palette[lane];
    final base = palette[lane % palette.length];
    return base.withOpacity(0.8);
  }

  @override
  bool shouldRepaint(covariant _CommitRailPainter oldDelegate) {
    return oldDelegate.laneData != laneData ||
        oldDelegate.colorScheme != colorScheme;
  }
}

const double _laneSpacing = 18;
const double _nodeRadius = 5;
const double _railInset = 6;
const double _rowMinHeight = 68;
const double _halfRow = _rowMinHeight / 2;
const double _rowOverlap = 16;
