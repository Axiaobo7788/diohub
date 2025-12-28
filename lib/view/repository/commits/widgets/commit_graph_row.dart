import 'dart:math' as math;
import 'dart:ui';

import 'package:diohub/graphql/queries/repositories/__generated__/commits_list.data.gql.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/repository/commits/models/graph_layout.dart';
import 'package:flutter/foundation.dart';
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

    // Merge curves from the current lane to secondary parent lanes (downward).
    final nodeX = startX + laneData.currentLane * _laneSpacing;

    final mergePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _laneColor(laneData.currentLane);

    for (final target in laneData.mergeTargets) {
      if (target >= laneCount) continue;
      final targetX = startX + target * _laneSpacing;

      final path = Path()..moveTo(nodeX, centerY);
      final midY = centerY + size.height * 0.25;
      final endY = size.height;
      path.cubicTo(
        nodeX,
        midY,
        targetX,
        centerY + size.height * 0.15,
        targetX,
        endY,
      );
      canvas.drawPath(path, mergePaint);
    }

    // Incoming curves for lanes that carry this commit into the node.
    final incomingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _laneColor(laneData.currentLane);

    for (var i = 0; i < laneData.lanesBefore.length; i++) {
      if (i == laneData.currentLane) {
        continue;
      }
      final upstreamOid = laneData.lanesBefore[i];
      if (upstreamOid == null || upstreamOid != commitOid) {
        continue;
      }
      // This lane was waiting for this commit - draw incoming curve
      final fromX = startX + i * _laneSpacing;
      final path = Path()..moveTo(fromX, 0);
      path.cubicTo(
        fromX,
        centerY * 0.4,
        nodeX,
        centerY * 0.6,
        nodeX,
        centerY,
      );
      canvas.drawPath(path, incomingPaint);
    }

    // Incoming curve-back lines: check all lanes for curve-back info pointing to this commit
    final isTargetCommit = commitOid.startsWith('02d1c20');
    final hasCurveBacks = laneData.curveBacksByLane.isNotEmpty;

    // Only log for commits with curve-backs or the target commit
    if (isTargetCommit || hasCurveBacks) {
      debugPrint(
          '[CommitRailPainter] ${commitOid.substring(0, 7)}: Checking for curve-backs');
      debugPrint(
          '[CommitRailPainter]   curveBacksByLane: ${laneData.curveBacksByLane.map((k, v) => MapEntry(k, '${v.parentOid.substring(0, 7)}@lane${v.parentLane}'))}');
      debugPrint(
          '[CommitRailPainter]   currentLane: ${laneData.currentLane}, laneCount: $laneCount');
    }

    // Check all lanes up to maxLanes to see if any have curve-back info pointing to this commit
    for (var laneIndex = 0; laneIndex < laneCount; laneIndex++) {
      final curveBackInfo = laneData.curveBacksByLane[laneIndex];
      if (curveBackInfo == null) {
        continue; // No curve-back for this lane
      }

      // Check if this curve-back points to the current commit
      final oidMatch = curveBackInfo.parentOid == commitOid;

      if (isTargetCommit || oidMatch) {
        debugPrint(
            '[CommitRailPainter]   Lane $laneIndex: curve-back to ${curveBackInfo.parentOid.substring(0, 7)}');
        debugPrint(
            '[CommitRailPainter]     OID match: $oidMatch (${curveBackInfo.parentOid.substring(0, 7)} == ${commitOid.substring(0, 7)})');
      }

      if (oidMatch) {
        // Use the stored parentLane from when the curve-back was detected
        // This is where the parent WAS when detected, which is what we want to draw to
        final targetLane = curveBackInfo.parentLane;
        final currentCommitLane = laneData.currentLane;

        debugPrint('[CommitRailPainter]     ✓ OID MATCH!');
        debugPrint(
            '[CommitRailPainter]       Source: lane $laneIndex, Target: lane $targetLane, Current: lane $currentCommitLane');

        // Only draw if source and target are different lanes
        if (laneIndex != targetLane) {
          debugPrint(
              '[CommitRailPainter]       ✓ DRAWING (source $laneIndex != target $targetLane)');

          final targetLaneX = startX + targetLane * _laneSpacing;

          final curveBackPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = _laneColor(laneIndex);

          // If source lane == current commit lane, start from commit node (lane mismatch case)
          // Otherwise, start from source lane top (normal case)
          final startXCoord = (laneIndex == currentCommitLane
                  ? startX + currentCommitLane * _laneSpacing
                  : startX + laneIndex * _laneSpacing)
              .toDouble();
          final startYCoord = (laneIndex == currentCommitLane ? centerY : 0.0);

          final path = Path()..moveTo(startXCoord, startYCoord);
          if (laneIndex == currentCommitLane) {
            // Start from commit node, curve upward to target lane
            path.cubicTo(
              startXCoord,
              centerY * 0.6, // Control point 1: start curving upward
              targetLaneX,
              centerY * 0.4, // Control point 2: move toward target lane
              targetLaneX,
              0, // End at top of target lane
            );
            debugPrint(
                '[CommitRailPainter]       ✓ Curve drawn from commit node ($startXCoord, $startYCoord) to ($targetLaneX, 0)');
          } else {
            // Start from source lane top, curve down to target lane
            path.cubicTo(
              startXCoord,
              centerY * 0.4, // Control point 1: stay near source lane
              targetLaneX,
              centerY * 0.6, // Control point 2: move toward target lane
              targetLaneX,
              centerY, // End at the target lane
            );
            debugPrint(
                '[CommitRailPainter]       ✓ Curve drawn from source lane ($startXCoord, $startYCoord) to ($targetLaneX, $centerY)');
          }
          canvas.drawPath(path, curveBackPaint);
        } else {
          debugPrint(
              '[CommitRailPainter]       ✗ SKIPPED: source ($laneIndex) == target ($targetLane)');
        }
      }
    }

    // Commit node
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
