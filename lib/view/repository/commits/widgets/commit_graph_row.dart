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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                padding: const EdgeInsets.symmetric(vertical: 4),
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
    final nodeX = startX + laneData.currentLane * _laneSpacing;

    // Draw merge-back curves (lanes collapsing into other lanes)
    for (final entry in laneData.collapsingLanes.entries) {
      final fromLane = entry.key;
      final toLane = entry.value;

      final fromX = startX + fromLane * _laneSpacing;
      final toX = startX + toLane * _laneSpacing;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _laneColor(fromLane);

      final path = Path()..moveTo(fromX, centerY);
      path.cubicTo(
        fromX,
        centerY + size.height * 0.25,
        toX,
        centerY + size.height * 0.35,
        toX,
        size.height,
      );
      canvas.drawPath(path, paint);
    }

    // Draw vertical lane lines
    for (var i = 0; i < laneCount; i++) {
      final x = startX + i * _laneSpacing;
      final beforeActive =
          i < laneData.lanesBefore.length && laneData.lanesBefore[i] != null;
      final afterActive =
          i < laneData.lanesAfter.length && laneData.lanesAfter[i] != null;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _laneColor(i);

      if (beforeActive) {
        canvas.drawLine(Offset(x, 0), Offset(x, centerY), paint);
      }
      if (afterActive) {
        canvas.drawLine(Offset(x, centerY), Offset(x, size.height), paint);
      }
    }

    // Draw merge curves (downward) - secondary parents
    final mergePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _laneColor(laneData.currentLane);

    for (final target in laneData.mergeTargets) {
      if (target >= laneCount) continue;
      final targetX = startX + target * _laneSpacing;
      final path = Path()..moveTo(nodeX, centerY);
      path.cubicTo(
        nodeX,
        centerY + size.height * 0.25,
        targetX,
        centerY + size.height * 0.15,
        targetX,
        size.height,
      );
      canvas.drawPath(path, mergePaint);
    }

    // Draw commit node
    final nodePaint = Paint()
      ..color = _laneColor(laneData.currentLane)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(nodeX, centerY), _nodeRadius, nodePaint);

    final stroke = Paint()
      ..color = colorScheme.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(Offset(nodeX, centerY), _nodeRadius, stroke);
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
