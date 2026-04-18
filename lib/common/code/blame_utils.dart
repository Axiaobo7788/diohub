import 'dart:async';

import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub_models/models/repositories/tree_typedefs.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns a background color for a blame range by age (1 = newest, 10 = oldest).
/// Uses a gradient from almost transparent to a deeper tint of [scheme].primary.
Color blameAgeColor(final int age, final ColorScheme scheme) {
  final int clamped = age.clamp(1, 10);
  final double t = (clamped - 1) / 9;
  final Color base = scheme.primary.withValues(alpha: 0.06 + t * 0.12);
  return base;
}

/// Finds the blame range that contains the given 1-based line number.
BlameRange? blameRangeForLine(
    final int oneBasedLine, final List<BlameRange> ranges) {
  for (final BlameRange r in ranges) {
    if (oneBasedLine >= r.startingLine && oneBasedLine <= r.endingLine) {
      return r;
    }
  }
  return null;
}

/// Shows the standard blame commit bottom sheet.
/// Used by both re_editor blame gutter and diff view blame gutter.
void showBlameSheet(
  final BuildContext context,
  final WidgetRef ref,
  final BlameRange range,
  final RepoRef? repoRef,
) {
  final bool canViewCommit = repoRef != null;
  unawaited(
    AppSheet.simple<void>(
      context,
      bodyBuilder: (final BuildContext sheetContext, StateSetter setState) {
        final ThemeData theme = Theme.of(sheetContext);
        return Padding(
          padding: sheetContext.spacing.cardContentPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                range.commit.message,
                style: theme.textTheme.bodyMedium,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              context.spacing.itemGap,
              Text(
                '${range.commit.author?.name ?? 'Unknown'} · '
                '${range.commit.abbreviatedOid}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (canViewCommit) ...[
                context.spacing.sectionGap,
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    CommitRef(
                      repo: repoRef!,
                      oid: range.commit.oid,
                    ).navigate(context, ref);
                  },
                  icon: const Icon(Icons.commit),
                  label: const Text('View Commit'),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
