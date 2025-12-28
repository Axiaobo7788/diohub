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
                height: _rowMinHeight,
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
    final laneCount = math.max(laneData.maxLanes, 1);
    final centerY = size.height / 2;
    final startX = _railInset + _laneSpacing / 2;

    // Find current lane column
    final currentLaneSnapshot = laneData.lanesAfter.firstWhere(
      (snapshot) => snapshot.laneId == laneData.currentLaneId,
      orElse: () => laneData.lanesAfter.first,
    );
    final nodeX = startX + currentLaneSnapshot.column * _laneSpacing;

    // Draw merge-back curves (lanes collapsing into other lanes)
    for (final entry in laneData.collapsingLanes.entries) {
      final fromLaneId = entry.key;
      final toLaneId = entry.value;

      // Find columns for these lanes (merge-back uses lanesBefore for both)
      final fromSnapshot = laneData.lanesBefore.firstWhere(
        (snapshot) => snapshot.laneId == fromLaneId,
      );
      final toSnapshot = laneData.lanesBefore.firstWhere(
        (snapshot) => snapshot.laneId == toLaneId,
      );

      final fromX = startX + fromSnapshot.column * _laneSpacing;
      final toX = startX + toSnapshot.column * _laneSpacing;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _laneColorById(fromLaneId);

      final path = Path()..moveTo(fromX, centerY);
      path.cubicTo(
        fromX,
        centerY + _halfRow * 0.6,
        toX,
        centerY + _halfRow * 0.6,
        toX,
        size.height,
      );
      canvas.drawPath(path, paint);
    }

    // Draw vertical lane lines
    // Iterate by COLUMN, not index (padded arrays mean index != column)
    for (var col = 0; col < laneCount; col++) {
      final snapshotBefore = laneData.lanesBefore.firstWhere(
        (s) => s.column == col,
        orElse: () => const LaneSnapshot(
          laneId: '',
          column: -1,
          activeBefore: false,
          activeAfter: false,
          expectedOid: null,
        ),
      );

      final snapshotAfter = laneData.lanesAfter.firstWhere(
        (s) => s.column == col,
        orElse: () => const LaneSnapshot(
          laneId: '',
          column: -1,
          activeBefore: false,
          activeAfter: false,
          expectedOid: null,
        ),
      );

      final x = startX + col * _laneSpacing;

      // Resolve laneId ONCE per column (before any drawing)
      String? resolvedLaneId;
      if (snapshotBefore.laneId.isNotEmpty) {
        resolvedLaneId = snapshotBefore.laneId;
      } else if (snapshotAfter.laneId.isNotEmpty) {
        resolvedLaneId = snapshotAfter.laneId;
      }

      if (resolvedLaneId == null) continue;

      final beforeActive = snapshotBefore.activeBefore;
      final afterActive = snapshotAfter.activeAfter &&
          (snapshotBefore.activeBefore ||
              resolvedLaneId == laneData.currentLaneId);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _laneColorById(resolvedLaneId);

      if (beforeActive) {
        canvas.drawLine(Offset(x, 0), Offset(x, centerY), paint);
      }
      if (afterActive) {
        canvas.drawLine(Offset(x, centerY), Offset(x, size.height), paint);
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
        size.height,
      );
      canvas.drawPath(path, paint);
    }

    // Draw commit node
    // Node color must match the lane that was active before at the node's column
    final nodeLaneId = () {
      final col = currentLaneSnapshot.column;
      for (final snapshot in laneData.lanesBefore) {
        if (snapshot.column == col && snapshot.activeBefore) {
          return snapshot.laneId;
        }
      }
      return laneData.currentLaneId;
    }();

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
