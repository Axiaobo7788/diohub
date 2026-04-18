import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Single file row in a changed-files list: status icon, filename, stats row, mini diff bar.
/// Expands to "View Changes" that opens [ChangesViewer] (or [onViewChanges] when provided).
class ChangedFilesListCard extends StatelessWidget {
  const ChangedFilesListCard(
    this.file, {
    super.key,
    this.onViewChanges,
  });

  final FileElement file;

  /// When set, called instead of navigating to [ChangesViewer] (e.g. for PR [FileDiffScreen]).
  final void Function(BuildContext context, FileElement file)? onViewChanges;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final Color statusColor = DiffColors.forDiffStatus(file.diffStatus);
    final int additions = file.additions;
    final int deletions = file.deletions;
    final int total = additions + deletions;
    final bool hasStats = total > 0;

    return BorderedContainer(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(
          horizontal: spacing.cardContentPadding.horizontal,
          vertical: spacing.compactSpacing,
        ),
        title: Row(
          children: <Widget>[
            Icon(
              Octicons.file_diff,
              size: 18,
              color: statusColor,
            ),
            spacing.tightGap,
            Expanded(
              child: Text(
                file.filename,
                style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: spacing.tightSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Stats row: +X / -Y (and optionally · N changes)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (file.isAdded && additions > 0)
                    Text(
                      '+$additions',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: DiffColors.addition,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (file.isRemoved && deletions > 0)
                    Text(
                      '-$deletions',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: DiffColors.deletion,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (hasStats) ...<Widget>[
                    Text(
                      '+$additions',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: DiffColors.addition,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' / ',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant.secondary,
                      ),
                    ),
                    Text(
                      '-$deletions',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: DiffColors.deletion,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (file.changes > 0) ...<Widget>[
                      Text(
                        ' · ${file.changes} changes',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant.secondary,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
              if (hasStats) ...<Widget>[
                SizedBox(height: spacing.tightSpacing),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 4,
                    child: Row(
                      children: <Widget>[
                        if (additions > 0)
                          Expanded(
                            flex: additions,
                            child: ColoredBox(
                              color:
                                  DiffColors.addition.withValues(alpha: 0.75),
                            ),
                          ),
                        if (deletions > 0)
                          Expanded(
                            flex: deletions,
                            child: ColoredBox(
                              color:
                                  DiffColors.deletion.withValues(alpha: 0.75),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        children: <Widget>[
          Divider(height: 0, color: context.colorScheme.outlineVariant),
          InkWell(
            borderRadius: context.radius(RadiusSize.medium),
            onTap: (file.patch != null || onViewChanges != null)
                ? () {
                    if (onViewChanges != null) {
                      onViewChanges!(context, file);
                    } else {
                      AutoRouter.of(context).push(
                        ChangesViewer(
                          patch: file.patch,
                          contentURL: file.contentsUrl,
                          fileType: file.filename.split('.').last,
                        ),
                      );
                    }
                  }
                : null,
            child: Padding(
              padding: spacing.cardContentPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'View Changes',
                    style: context.textTheme.labelLarge?.copyWith(
                      color: (file.patch != null || onViewChanges != null)
                          ? context.colorScheme.primary
                          : context.colorScheme.onSurfaceVariant.muted,
                    ),
                  ),
                  spacing.tightGap,
                  Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: (file.patch != null || onViewChanges != null)
                        ? context.colorScheme.primary
                        : context.colorScheme.onSurfaceVariant.muted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
