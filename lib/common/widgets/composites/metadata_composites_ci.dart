import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/utils/duration_format.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class CICheckRunRow extends StatelessWidget {
  const CICheckRunRow({
    required this.name,
    required this.conclusion,
    this.status,
    this.detailsUrl,
    this.startedAt,
    this.completedAt,
    this.appName,
    this.appLogoUrl,
    super.key,
  });

  final String name;
  final String? conclusion;
  final String? status;
  final String? detailsUrl;
  final String? startedAt;
  final String? completedAt;
  final String? appName;
  final String? appLogoUrl;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final (Color color, IconData icon, String? conclusionLabel) =
        _conclusionIconAndColor(context);
    final Widget row = Padding(
      padding: spacing.metadataRowPadding,
      child: Row(
        children: <Widget>[
          if (appLogoUrl != null && appLogoUrl!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: spacing.tightSpacing),
              child: CircleAvatar(
                radius: 8,
                backgroundImage: NetworkImage(appLogoUrl!),
                backgroundColor: context.colorScheme.surfaceContainerHighest,
              ),
            ),
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          spacing.itemGap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (conclusionLabel != null)
                      Padding(
                        padding: EdgeInsets.only(left: spacing.tightSpacing),
                        child: Text(
                          conclusionLabel,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: color,
                                  ),
                        ),
                      ),
                  ],
                ),
                if (appName != null && appName!.isNotEmpty)
                  Text(
                    appName!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (_durationText != null)
                  Text(
                    _durationText!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                  ),
                if (status != null &&
                    conclusion == null &&
                    _statusLabel != null)
                  Text(
                    _statusLabel!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),
          if (detailsUrl != null && detailsUrl!.isNotEmpty)
            Icon(
              Icons.open_in_new_rounded,
              size: 14,
              color: context.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
    if (detailsUrl != null && detailsUrl!.isNotEmpty) {
      return InkWell(
        onTap: () => launchUrl(Uri.parse(detailsUrl!)),
        child: row,
      );
    }
    return row;
  }

  String? get _durationText {
    if (startedAt == null || completedAt == null) return null;
    try {
      final start = DateTime.parse(startedAt!);
      final end = DateTime.parse(completedAt!);
      final d = end.difference(start);
      return formatDuration(d, granularity: DurationGranularity.secondsUp);
    } catch (e, st) {
      AppLogger.warning(
        'Failed to parse run duration dates',
        error: e,
        stackTrace: st,
        tag: 'metadata_composites',
      );
      return null;
    }
  }

  /// Icon, color, and optional label for conclusion; when conclusion is null
  /// uses status (IN_PROGRESS, PENDING, etc.).
  (Color, IconData, String?) _conclusionIconAndColor(BuildContext context) {
    final ColorScheme cs = context.colorScheme;
    if (conclusion != null) {
      switch (conclusion!) {
        case 'SUCCESS':
          return (cs.primary, Icons.check_circle_rounded, null);
        case 'FAILURE':
          return (cs.error, Icons.cancel_rounded, null);
        case 'CANCELLED':
          return (cs.onSurfaceVariant, Icons.stop_circle_rounded, 'Cancelled');
        case 'TIMED_OUT':
          return (
            const Color(0xFFE65100),
            Icons.schedule_rounded,
            'Timed out',
          );
        case 'ACTION_REQUIRED':
          return (
            const Color(0xFFF9A825),
            Icons.info_outline_rounded,
            'Action required',
          );
        case 'NEUTRAL':
          return (
            cs.onSurfaceVariant,
            Icons.remove_circle_outline_rounded,
            null
          );
        case 'SKIPPED':
          return (
            cs.onSurfaceVariant.withValues(alpha: 0.8),
            Icons.skip_next_rounded,
            null,
          );
        case 'STALE':
          return (cs.onSurfaceVariant, Icons.archive_rounded, null);
        case 'STARTUP_FAILURE':
          return (
            const Color(0xFFD84315),
            Icons.warning_amber_rounded,
            'Startup failed',
          );
        default:
          return (cs.onSurfaceVariant, Icons.schedule_rounded, null);
      }
    }
    if (status != null) {
      switch (status!) {
        case 'COMPLETED':
          return (cs.onSurfaceVariant, Icons.schedule_rounded, null);
        case 'IN_PROGRESS':
          return (cs.primary, Icons.hourglass_empty_rounded, 'In progress');
        case 'PENDING':
          return (const Color(0xFFF9A825), Icons.schedule_rounded, 'Pending');
        case 'QUEUED':
          return (cs.onSurfaceVariant, Icons.queue_rounded, 'Queued');
        case 'REQUESTED':
          return (cs.onSurfaceVariant, Icons.schedule_rounded, 'Requested');
        case 'WAITING':
          return (
            const Color(0xFFF9A825),
            Icons.hourglass_empty_rounded,
            'Waiting'
          );
        default:
          return (cs.onSurfaceVariant, Icons.schedule_rounded, status);
      }
    }
    return (cs.onSurfaceVariant, Icons.schedule_rounded, null);
  }

  /// Display label for status when conclusion is null (e.g. in progress, queued).
  String? get _statusLabel {
    if (status == null) return null;
    switch (status!) {
      case 'IN_PROGRESS':
        return 'In progress';
      case 'QUEUED':
        return 'Queued';
      case 'PENDING':
        return 'Pending';
      case 'REQUESTED':
        return 'Requested';
      case 'WAITING':
        return 'Waiting';
      case 'COMPLETED':
        return 'Completed';
      default:
        return status!.replaceAll('_', ' ').toLowerCase();
    }
  }
}

/// List of CI check runs for ChecksStatusChip popup/bottom sheet.
class CIChecksList extends StatelessWidget {
  const CIChecksList({
    required this.runs,
    super.key,
  });

  final List<CICheckRunRowData> runs;

  @override
  Widget build(final BuildContext context) {
    if (runs.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: runs
          .map(
            (final CICheckRunRowData r) => CICheckRunRow(
              name: r.name,
              conclusion: r.conclusion,
              status: r.status,
              detailsUrl: r.detailsUrl,
              startedAt: r.startedAt,
              completedAt: r.completedAt,
              appName: r.appName,
              appLogoUrl: r.appLogoUrl,
            ),
          )
          .toList(),
    );
  }
}

/// Data for a single CI check run row.
class CICheckRunRowData {
  const CICheckRunRowData({
    required this.name,
    this.conclusion,
    this.status,
    this.detailsUrl,
    this.startedAt,
    this.completedAt,
    this.appName,
    this.appLogoUrl,
    this.checkSuiteDatabaseId,
  });

  final String name;
  final String? conclusion;
  final String? status;
  final String? detailsUrl;
  final String? startedAt;
  final String? completedAt;
  final String? appName;
  final String? appLogoUrl;

  /// Check suite database ID for re-request API.
  final int? checkSuiteDatabaseId;
}

/// Per-reviewer row: avatar + login + state icon (approved / changes requested / commented / pending).
