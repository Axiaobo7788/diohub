import 'dart:math' as math;
import 'package:diohub/common/cards/commit_card.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub/models/commits/commit_list_item_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/repository/commits/models/graph_layout.dart';
import 'package:flutter/material.dart';

class CommitGraphRow extends StatefulWidget {
  const CommitGraphRow({
    required this.commitRef,
    required this.commitWithLaneData,
    required this.branchTips,
    super.key,
  });

  final CommitRef commitRef;
  final CommitWithLaneData commitWithLaneData;
  final Map<String, List<String>>? branchTips;

  @override
  State<CommitGraphRow> createState() => _CommitGraphRowState();
}

class _CommitGraphRowState extends State<CommitGraphRow> {
  double? _contentHeight;

  @override
  void didUpdateWidget(final CommitGraphRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.commitWithLaneData.commit.oid !=
        widget.commitWithLaneData.commit.oid) {
      _contentHeight = null;
    }
  }

  void _onContentSize(Size size) {
    if (!mounted) return;
    const CommitGraphStyle style = CommitGraphStyle();
    final double effectiveRowHeight = math.max(size.height, style.rowHeight);
    if (_contentHeight != effectiveRowHeight) {
      setState(() => _contentHeight = effectiveRowHeight);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final CommitNode commit = widget.commitWithLaneData.commit;
    final LaneData laneData = widget.commitWithLaneData.laneData;
    const CommitGraphStyle style = CommitGraphStyle();
    final int lanes = laneData.row.effectiveLaneCount;
    final double railWidth = style.laneSpacing * lanes + style.railInset * 2;
    final List<String> branches =
        widget.branchTips?[commit.oid] ?? const <String>[];
    final double spacing = context.spacing.itemSpacing;
    final CommitListItemModel model = CommitListItemModel.fromGcommitListItem(
      commit,
      widget.commitRef.repo,
    );

    final double effectiveRowHeight =
        _contentHeight != null ? _contentHeight! : style.rowHeight;

    return Padding(
      key: ValueKey(commit.oid),
      padding: EdgeInsets.only(
        left: context.spacing.contentPadding.left,
        right: context.spacing.contentPadding.right,
        top: 0,
        bottom: 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: railWidth,
            height: effectiveRowHeight + style.rowOverlap + spacing,
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
          context.spacing.contentGap,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: BorderedContainer(
                ref: widget.commitRef,
                child: _MeasureContent(
                  onSize: _onContentSize,
                  child: CommitCard(
                    data: model,
                    branches: branches,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reports its child's layout size via [onSize] after each frame. Avoids
/// GlobalKey per list item so list items can be recycled.
class _MeasureContent extends StatefulWidget {
  const _MeasureContent({
    required this.onSize,
    required this.child,
  });
  final void Function(Size) onSize;
  final Widget child;

  @override
  State<_MeasureContent> createState() => _MeasureContentState();
}

class _MeasureContentState extends State<_MeasureContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_reportSize);
  }

  @override
  void didUpdateWidget(final _MeasureContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      WidgetsBinding.instance.addPostFrameCallback(_reportSize);
    }
  }

  void _reportSize(_) {
    if (!mounted) return;
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      widget.onSize(box.size);
    }
  }

  @override
  Widget build(final BuildContext context) => widget.child;
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
  void paint(final Canvas canvas, final Size size) {
    final LaneRowState row = laneData.row;

    final int laneCount = math.max(row.visualLaneCount, 1);
    final double centerY = rowHeight / 2;
    final double rowTopY = -style.rowOverlap / 2;
    final double rowBottomY = rowHeight + style.rowOverlap / 2;

    final double nodeX = row.before.containsKey(row.nodeLaneId)
        ? row.before[row.nodeLaneId]!.x
        : row.after[row.nodeLaneId]!.x;

    // Compute deterministic vertical offsets for merging lanes to avoid overlap
    final List<MapEntry<String, int>> mergingLanes = <MapEntry<String, int>>[];
    for (final String laneId in row.mergeIntoNodeLaneIds) {
      final LaneSnapshot? snapshot = row.before[laneId] ?? row.after[laneId];
      if (snapshot != null) {
        mergingLanes.add(MapEntry(laneId, snapshot.column));
      }
    }
    mergingLanes.sort(
        (final MapEntry<String, int> a, final MapEntry<String, int> b) =>
            a.value.compareTo(b.value));

    final Map<String, double> mergeOffsetMap = <String, double>{};
    if (mergingLanes.isNotEmpty) {
      final double maxOffset =
          (rowHeight / 2) * style.curveControlMultiplier * 0.5;
      final double step = mergingLanes.length > 1
          ? (maxOffset * 2) / (mergingLanes.length - 1)
          : 0.0;
      for (int i = 0; i < mergingLanes.length; i++) {
        final double offset = -maxOffset + (i * step);
        mergeOffsetMap[mergingLanes[i].key] = offset;
      }
    }

    final Path path = Path();

    // Vertical continuity or column transitions
    for (final String laneId in row.visibleLaneIds) {
      final bool hasBefore = row.before.containsKey(laneId);
      final bool hasAfter = row.after.containsKey(laneId);

      if (!hasBefore && !hasAfter) continue;

      final int? beforeColumn = hasBefore ? row.before[laneId]!.column : null;
      final int? afterColumn = hasAfter ? row.after[laneId]!.column : null;
      final LaneSnapshot? beforeLane = hasBefore ? row.before[laneId] : null;
      final LaneSnapshot? afterLane = hasAfter ? row.after[laneId] : null;

      if (hasBefore && hasAfter) {
        final double xBefore = beforeLane!.x;
        final double xAfter = afterLane!.x;

        if (beforeColumn == afterColumn) {
          final Paint paint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.strokeWidth
            ..color = beforeLane.color.withValues(alpha: style.railOpacity);
          canvas.drawLine(
            Offset(xBefore, rowTopY),
            Offset(xBefore, centerY),
            paint,
          );
          canvas.drawLine(
            Offset(xBefore, centerY),
            Offset(xBefore, rowBottomY),
            paint,
          );
        } else {
          final Paint afterPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.strokeWidth
            ..color = afterLane.color.withValues(alpha: style.railOpacity);

          // Lane-change curve (mirrored merge-style control points)
          final double dx = (xAfter - xBefore).abs();
          final double controlDY = math.min(
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
        final Paint paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.strokeWidth
          ..color = beforeLane!.color.withValues(alpha: style.railOpacity);
        if (row.mergeIntoNodeLaneIds.contains(laneId)) {
          // Terminating lane that merges into node: draw curve into node
          final double offset = mergeOffsetMap[laneId] ?? 0.0;
          final double dx = (nodeX - beforeLane.x).abs();
          final double controlDY = math.min(
            rowHeight * style.curveControlMultiplier,
            dx * 0.6,
          );
          final double controlY = centerY - controlDY;
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
          canvas.drawLine(
            Offset(beforeLane.x, rowTopY),
            Offset(beforeLane.x, centerY),
            paint,
          );
        }
      } else if (hasAfter) {
        if (laneId == row.nodeLaneId) {
          final Paint paint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.strokeWidth
            ..color = afterLane!.color.withValues(alpha: style.railOpacity);
          canvas.drawLine(
            Offset(afterLane.x, centerY),
            Offset(afterLane.x, rowBottomY),
            paint,
          );
        }
      }
    }

    // Secondary-parent merge curves
    for (final String targetLaneId in row.mergeFromNodeLaneIds) {
      if (!row.after.containsKey(targetLaneId)) continue;

      final LaneSnapshot targetLane = row.after[targetLaneId]!;
      final int targetColumn = targetLane.column;
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.strokeWidth
        ..color = targetLane.color.withValues(alpha: style.railOpacity);
      if (targetColumn >= laneCount) continue;
      final double targetX = targetLane.x;
      final double offset = mergeOffsetMap[targetLaneId] ?? 0.0;
      final double dx = (targetX - nodeX).abs();
      final double controlDY = math.min(
        rowHeight * style.curveControlMultiplier,
        dx * 0.6,
      );
      final double controlY = centerY + controlDY;
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
    final LaneSnapshot nodeLane = row.before.containsKey(row.nodeLaneId)
        ? row.before[row.nodeLaneId]!
        : row.after[row.nodeLaneId]!;
    final Paint nodePaint = Paint()
      ..color = nodeLane.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(nodeX, centerY), style.nodeRadius, nodePaint);

    final Paint stroke = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.nodeStrokeWidth;
    canvas.drawCircle(Offset(nodeX, centerY), style.nodeRadius, stroke);
  }

  @override
  bool shouldRepaint(covariant final _CommitRailPainter oldDelegate) =>
      oldDelegate.laneData != laneData ||
      oldDelegate.colorScheme != colorScheme ||
      oldDelegate.style != style ||
      oldDelegate.rowHeight != rowHeight;
}
