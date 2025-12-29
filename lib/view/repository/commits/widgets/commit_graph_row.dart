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
    final row = laneData.row;

    final laneCount = math.max(row.visualLaneCount, 1);
    final centerY = _rowMinHeight / 2;
    final rowTopY = -_rowOverlap / 2;
    final rowBottomY = _rowMinHeight + _rowOverlap / 2;
    final startX = _railInset + _laneSpacing / 2;

    // Find node column from before (where commit occurred)
    // Fallback ONLY if this is a brand new lane (no before entry)
    final nodeColumn = row.before.containsKey(row.nodeLaneId)
        ? row.before[row.nodeLaneId]!.column
        : row.after[row.nodeLaneId]!.column;

    final nodeX = startX + nodeColumn * _laneSpacing;

    // Reusable path instance to minimize allocations
    final path = Path();

    // Draw merge-back curves (lanes collapsing into other lanes)
    //
    // DEFERRED MERGE-BACK VISUALIZATION:
    // These curves are drawn on THIS row, but represent merge-backs that were detected
    // on the PREVIOUS commit row. The deferral ensures:
    //
    // 1. CORRECT TIMING: The curve connects the collapsing lane's position (from row.before)
    //    to the survivor lane's node position (on this row). Drawing on the previous row
    //    would be incorrect because the survivor lane's node doesn't exist there yet.
    //
    // 2. VISUAL CONTINUITY: The collapsing lane remains in row.before/row.after maps for
    //    one extra row, allowing us to draw the curve from its actual position. Without
    //    this deferral, the lane would disappear before we could draw the merge-back.
    //
    // 3. ROUTING SEPARATION: Collapsing lanes are excluded from routing (column assignment)
    //    but remain visually active so the painter can access their positions.
    //
    // The collapsing lanes will be removed from routingLanes AFTER this row is emitted,
    // completing their lifecycle: detect → defer → visualize → remove.
    for (final fromLaneId in row.collapsingLaneIds) {
      final toLaneId = row.collapseInto[fromLaneId]!;

      // Find columns for these lanes (merge-back uses before for both)
      if (!row.before.containsKey(fromLaneId)) {
        continue;
      }

      // Find survivor lane's column from before (preferred) or after (fallback)
      final hasToLaneBefore = row.before.containsKey(toLaneId);
      final hasToLaneAfter = row.after.containsKey(toLaneId);

      if (!hasToLaneBefore && !hasToLaneAfter) {
        continue;
      }

      final fromX = row.beforeX[fromLaneId]!;
      final toLaneNodeX =
          hasToLaneBefore ? row.beforeX[toLaneId]! : row.afterX[toLaneId]!;

      final fromSnapshot = row.before[fromLaneId]!;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = fromSnapshot.color;

      // Merge-back curve starts at TOP of row, ends at CENTER of survivor lane's node
      path.reset();
      path.moveTo(fromX, rowTopY);
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

    // For each laneId, find its column in before and after snapshots
    for (final laneId in row.visibleLaneIds) {
      // Skip collapsing lanes - they are fully represented by merge-back curves
      if (row.collapsingLaneIds.contains(laneId)) continue;

      // Check lane existence using maps
      final existsBefore = row.before.containsKey(laneId);
      final existsAfter = row.after.containsKey(laneId);

      // Skip if lane doesn't exist in either snapshot
      if (!existsBefore && !existsAfter) continue;

      // Get columns and X coordinates only when lanes exist
      final beforeColumn = existsBefore ? row.before[laneId]!.column : null;
      final afterColumn = existsAfter ? row.after[laneId]!.column : null;
      final xBefore = row.beforeX[laneId];
      final xAfter = row.afterX[laneId];

      // Drawing rules:
      // - If lane exists before AND after with same column → draw vertical line
      // - If lane exists before AND after with different columns → draw curve
      // - If lane exists only before → draw top vertical segment
      // - If lane exists only after → draw bottom vertical segment

      if (existsBefore && existsAfter) {
        // Both exist - we know xBefore and xAfter are non-null here
        final xBeforeNonNull = xBefore!;
        final xAfterNonNull = xAfter!;

        if (beforeColumn == afterColumn) {
          // Same column: draw continuous vertical line with single color
          final snapshot = row.before[laneId]!;
          final paint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = snapshot.color;
          canvas.drawLine(Offset(xBeforeNonNull, rowTopY),
              Offset(xBeforeNonNull, centerY), paint);
          canvas.drawLine(Offset(xBeforeNonNull, centerY),
              Offset(xBeforeNonNull, rowBottomY), paint);
        } else {
          // Different columns: draw vertical-first transition with lane-specific colors
          // Top segment: before snapshot color (vertical line)
          final beforeSnapshot = row.before[laneId]!;
          final beforePaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = beforeSnapshot.color;
          canvas.drawLine(Offset(xBeforeNonNull, rowTopY),
              Offset(xBeforeNonNull, centerY), beforePaint);

          // Curve from old column centerY to new column bottomY (downward, never horizontal at centerY)
          final afterSnapshot = row.after[laneId]!;
          final afterPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = afterSnapshot.color;
          path.reset();
          path.moveTo(xBeforeNonNull, centerY);
          path.cubicTo(
            xBeforeNonNull,
            centerY + _halfRow * 0.6,
            xAfterNonNull,
            centerY + _halfRow * 0.6,
            xAfterNonNull,
            rowBottomY,
          );
          canvas.drawPath(path, afterPaint);
        }
      } else if (existsBefore) {
        // Lane exists only before: draw top vertical segment
        final xBeforeNonNull = xBefore!;
        final snapshot = row.before[laneId]!;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = snapshot.color;
        canvas.drawLine(Offset(xBeforeNonNull, rowTopY),
            Offset(xBeforeNonNull, centerY), paint);
      } else if (existsAfter) {
        // Lane exists only after: draw bottom vertical segment
        // Also check if this is the current commit's lane (should be visible)
        if (laneId == row.nodeLaneId) {
          final xAfterNonNull = xAfter!;
          final snapshot = row.after[laneId]!;
          final paint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = snapshot.color;
          canvas.drawLine(Offset(xAfterNonNull, centerY),
              Offset(xAfterNonNull, rowBottomY), paint);
        }
      }
    }

    // Draw merge curves (downward) - secondary parents
    for (final targetLaneId in row.mergeFromNodeLaneIds) {
      if (!row.after.containsKey(targetLaneId)) continue;

      final targetSnapshot = row.after[targetLaneId]!;
      final targetColumn = targetSnapshot.column;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = targetSnapshot.color;
      if (targetColumn >= laneCount) continue;
      final targetX = row.afterX[targetLaneId]!;
      path.reset();
      path.moveTo(nodeX, centerY);
      path.cubicTo(
        nodeX,
        centerY + _halfRow * 0.6,
        targetX,
        centerY + _halfRow * 0.6,
        targetX,
        rowBottomY,
      );
      canvas.drawPath(path, paint);
    }

    // Draw commit node
    // Node color matches the lane color
    final nodeSnapshot = row.before.containsKey(row.nodeLaneId)
        ? row.before[row.nodeLaneId]!
        : row.after[row.nodeLaneId]!;
    final nodePaint = Paint()
      ..color = nodeSnapshot.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(nodeX, centerY), _nodeRadius, nodePaint);

    final stroke = Paint()
      ..color = colorScheme.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(Offset(nodeX, centerY), _nodeRadius, stroke);
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
