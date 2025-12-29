import 'dart:math' as math;
import 'dart:ui';

import 'package:diohub/graphql/queries/repositories/__generated__/commits_list.data.gql.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/repository/commits/models/graph_layout.dart';
import 'package:flutter/material.dart';

class CommitGraphRow extends StatefulWidget {
  const CommitGraphRow({
    required this.commitWithLaneData,
    required this.branchTips,
    super.key,
  });

  final CommitWithLaneData commitWithLaneData;
  final Map<String, List<String>>? branchTips;

  @override
  State<CommitGraphRow> createState() => _CommitGraphRowState();
}

class _CommitGraphRowState extends State<CommitGraphRow> {
  final _contentKey = GlobalKey();
  double? _contentHeight;

  @override
  Widget build(BuildContext context) {
    final commit = widget.commitWithLaneData.commit;
    final laneData = widget.commitWithLaneData.laneData;
    final style = CommitGraphStyle();
    final lanes = laneData.row.effectiveLaneCount;
    final railWidth = style.laneSpacing * lanes + style.railInset * 2;
    final branches = widget.branchTips?[commit.oid] ?? const <String>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _contentKey.currentContext != null) {
              final renderBox =
                  _contentKey.currentContext!.findRenderObject() as RenderBox?;
              if (renderBox != null && renderBox.hasSize) {
                final measuredHeight = renderBox.size.height;
                final effectiveRowHeight =
                    math.max(measuredHeight, style.rowHeight);
                if (_contentHeight != effectiveRowHeight) {
                  setState(() {
                    _contentHeight = effectiveRowHeight;
                  });
                }
              }
            }
          });

          final effectiveRowHeight =
              _contentHeight != null ? _contentHeight! : style.rowHeight;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: railWidth,
                  height: effectiveRowHeight + style.rowOverlap,
                  child: CustomPaint(
                    painter: _CommitRailPainter(
                      laneData: laneData,
                      colorScheme: Theme.of(context).colorScheme,
                      commitOid: commit.oid,
                      style: style,
                      rowHeight: effectiveRowHeight,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: _CommitContent(
                      key: _contentKey,
                      commit: commit,
                      branches: branches,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CommitContent extends StatelessWidget {
  const _CommitContent({
    super.key,
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
          softWrap: true,
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
    required this.style,
    required this.rowHeight,
  });

  final LaneData laneData;
  final ColorScheme colorScheme;
  final String commitOid;
  final CommitGraphStyle style;
  final double rowHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final row = laneData.row;

    final laneCount = math.max(row.visualLaneCount, 1);
    final centerY = rowHeight / 2;
    final rowTopY = -style.rowOverlap / 2;
    final rowBottomY = rowHeight + style.rowOverlap / 2;

    final nodeX = row.before.containsKey(row.nodeLaneId)
        ? row.before[row.nodeLaneId]!.x
        : row.after[row.nodeLaneId]!.x;

    // Compute deterministic vertical offsets for merging lanes to avoid overlap
    final mergingLanes = <MapEntry<String, int>>[];
    for (final laneId in row.mergeIntoNodeLaneIds) {
      final snapshot = row.before[laneId] ?? row.after[laneId];
      if (snapshot != null) {
        mergingLanes.add(MapEntry(laneId, snapshot.column));
      }
    }
    mergingLanes.sort((a, b) => a.value.compareTo(b.value));

    final mergeOffsetMap = <String, double>{};
    if (mergingLanes.isNotEmpty) {
      final maxOffset = (rowHeight / 2) * style.curveControlMultiplier * 0.5;
      final step = mergingLanes.length > 1
          ? (maxOffset * 2) / (mergingLanes.length - 1)
          : 0.0;
      for (var i = 0; i < mergingLanes.length; i++) {
        final offset = -maxOffset + (i * step);
        mergeOffsetMap[mergingLanes[i].key] = offset;
      }
    }

    final path = Path();

    // Vertical continuity or column transitions
    for (final laneId in row.visibleLaneIds) {
      final hasBefore = row.before.containsKey(laneId);
      final hasAfter = row.after.containsKey(laneId);

      if (!hasBefore && !hasAfter) continue;

      final beforeColumn = hasBefore ? row.before[laneId]!.column : null;
      final afterColumn = hasAfter ? row.after[laneId]!.column : null;
      final beforeLane = hasBefore ? row.before[laneId] : null;
      final afterLane = hasAfter ? row.after[laneId] : null;

      if (hasBefore && hasAfter) {
        final xBefore = beforeLane!.x;
        final xAfter = afterLane!.x;

        if (beforeColumn == afterColumn) {
          final paint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.strokeWidth
            ..color = beforeLane.color.withOpacity(style.railOpacity);
          canvas.drawLine(
              Offset(xBefore, rowTopY), Offset(xBefore, centerY), paint);
          canvas.drawLine(
              Offset(xBefore, centerY), Offset(xBefore, rowBottomY), paint);
        } else {
          final afterPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.strokeWidth
            ..color = afterLane.color.withOpacity(style.railOpacity);

          // Lane-change curve (mirrored merge-style control points)
          final dx = (xAfter - xBefore).abs();
          final controlDY = math.min(
            rowHeight * style.curveControlMultiplier,
            dx * 0.6,
          );

          path.reset();
          path.moveTo(xBefore, rowTopY);
          path.cubicTo(
            xBefore,
            centerY - controlDY,
            xAfter,
            centerY - controlDY,
            xAfter,
            centerY,
          );
          canvas.drawPath(path, afterPaint);

          // Vertical after node
          canvas.drawLine(
            Offset(xAfter, centerY),
            Offset(xAfter, rowBottomY),
            afterPaint,
          );
        }
      } else if (hasBefore) {
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.strokeWidth
          ..color = beforeLane!.color.withOpacity(style.railOpacity);
        if (row.mergeIntoNodeLaneIds.contains(laneId)) {
          // Terminating lane that merges into node: draw curve into node
          final offset = mergeOffsetMap[laneId] ?? 0.0;
          final dx = (nodeX - beforeLane.x).abs();
          final controlDY = math.min(
            rowHeight * style.curveControlMultiplier,
            dx * 0.6,
          );
          final controlY = centerY - controlDY;
          path.reset();
          path.moveTo(beforeLane.x, rowTopY);
          path.cubicTo(
            beforeLane.x,
            controlY + offset,
            nodeX,
            controlY + offset,
            nodeX,
            centerY,
          );
          canvas.drawPath(path, paint);
        } else {
          // Terminating lane that doesn't merge: draw only vertical line
          canvas.drawLine(Offset(beforeLane.x, rowTopY),
              Offset(beforeLane.x, centerY), paint);
        }
      } else if (hasAfter) {
        if (laneId == row.nodeLaneId) {
          final paint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.strokeWidth
            ..color = afterLane!.color.withOpacity(style.railOpacity);
          canvas.drawLine(Offset(afterLane.x, centerY),
              Offset(afterLane.x, rowBottomY), paint);
        }
      }
    }

    // Secondary-parent merge curves
    for (final targetLaneId in row.mergeFromNodeLaneIds) {
      if (!row.after.containsKey(targetLaneId)) continue;

      final targetLane = row.after[targetLaneId]!;
      final targetColumn = targetLane.column;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.strokeWidth
        ..color = targetLane.color.withOpacity(style.railOpacity);
      if (targetColumn >= laneCount) continue;
      final targetX = targetLane.x;
      final offset = mergeOffsetMap[targetLaneId] ?? 0.0;
      final dx = (targetX - nodeX).abs();
      final controlDY = math.min(
        rowHeight * style.curveControlMultiplier,
        dx * 0.6,
      );
      final controlY = centerY + controlDY;
      path.reset();
      path.moveTo(nodeX, centerY);
      path.cubicTo(
        nodeX,
        controlY + offset,
        targetX,
        controlY + offset,
        targetX,
        rowBottomY,
      );
      canvas.drawPath(path, paint);
    }

    // Commit node
    final nodeLane = row.before.containsKey(row.nodeLaneId)
        ? row.before[row.nodeLaneId]!
        : row.after[row.nodeLaneId]!;
    final nodePaint = Paint()
      ..color = nodeLane.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(nodeX, centerY), style.nodeRadius, nodePaint);

    final stroke = Paint()
      ..color = colorScheme.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.nodeStrokeWidth;
    canvas.drawCircle(Offset(nodeX, centerY), style.nodeRadius, stroke);
  }

  @override
  bool shouldRepaint(covariant _CommitRailPainter oldDelegate) {
    return oldDelegate.laneData != laneData ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.style != style ||
        oldDelegate.rowHeight != rowHeight;
  }
}
