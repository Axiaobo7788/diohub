import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/models/changelog/changelog_entry.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

enum ChangelogEntryStatus {
  newer,
  current,
  older,
}

class ChangelogEntryTile extends StatelessWidget {
  const ChangelogEntryTile({
    required this.entry,
    required this.status,
    super.key,
  });

  final ChangelogEntry entry;
  final ChangelogEntryStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    // Newer entries get tinted background
    final backgroundColor = status == ChangelogEntryStatus.newer
        ? cs.primaryContainer.withOpacity(0.3)
        : null;

    return BorderedContainer(
      backgroundColor: backgroundColor,
      child: Padding(
        padding: context.spacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row: version + date
            Row(
              children: [
                Text(
                  entry.tagName,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                context.spacing.tightGap,
                Text(
                  entry.publishedAt.toRelativeDate(shorten: false),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            context.spacing.tightGap,
            // Status badges
            Wrap(
              spacing: context.spacing.tightSpacing,
              children: [
                if (status == ChangelogEntryStatus.current)
                  TintedChip(
                    color: cs.primary,
                    icon: Icons.check_circle_outline,
                    label: 'Installed',
                    iconSize: 12,
                  ),
                if (status == ChangelogEntryStatus.newer)
                  TintedChip(
                    color: cs.secondary,
                    icon: Icons.update,
                    label: 'Update available',
                    iconSize: 12,
                  ),
                if (entry.isPrerelease)
                  TintedChip(
                    color: cs.tertiary,
                    icon: Octicons.tag,
                    label: 'Pre-release',
                    iconSize: 12,
                  ),
              ],
            ),
            context.spacing.itemGap,
            // Release notes body
            MarkdownBody(
              entry.bodyHtml,
              buildAsync: false,
            ),
          ],
        ),
      ),
    );
  }
}
