import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/l10n/relative_time.dart';
import 'package:diohub/models/github_changelog_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The official GitHub product changelog shown beside the desktop feed.
class GitHubChangelogAside extends StatelessWidget {
  const GitHubChangelogAside({
    required this.items,
    required this.onRetry,
    required this.onOpenItem,
    required this.onViewAll,
    super.key,
  });

  final AsyncValue<List<GitHubChangelogItem>> items;
  final VoidCallback onRetry;
  final ValueChanged<GitHubChangelogItem> onOpenItem;
  final VoidCallback onViewAll;

  @override
  Widget build(final BuildContext context) {
    return Card(
      key: const ValueKey<String>('github-changelog-aside'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.changelogLatest,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            items.when(
              loading: () => const _ChangelogLoading(),
              error: (final Object error, final StackTrace stackTrace) =>
                  _ChangelogError(onRetry: onRetry),
              data: (final List<GitHubChangelogItem> entries) {
                if (entries.isEmpty) {
                  return _ChangelogError(
                    message: context.l10n.changelogEmpty,
                    onRetry: onRetry,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final (int, GitHubChangelogItem) indexed
                        in entries.take(4).indexed)
                      _ChangelogTimelineItem(
                        item: indexed.$2,
                        last: indexed.$1 == entries.take(4).length - 1,
                        onTap: () => onOpenItem(indexed.$2),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: TextButton(
                        onPressed: onViewAll,
                        child: Text(context.l10n.changelogViewAll),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangelogTimelineItem extends StatelessWidget {
  const _ChangelogTimelineItem({
    required this.item,
    required this.last,
    required this.onTap,
  });

  final GitHubChangelogItem item;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final Color lineColor = Theme.of(context).colorScheme.outlineVariant;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 16,
            child: Column(
              children: <Widget>[
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: lineColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!last)
                  Expanded(child: VerticalDivider(width: 1, color: lineColor)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        formatRelativeTime(context, item.publishedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _ChangelogLoading extends StatelessWidget {
  const _ChangelogLoading();

  @override
  Widget build(final BuildContext context) {
    final Color color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      children: <Widget>[
        for (int index = 0; index < 4; index += 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(width: 72, height: 10, color: color),
                      const SizedBox(height: 8),
                      Container(height: 14, color: color),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChangelogError extends StatelessWidget {
  const _ChangelogError({required this.onRetry, this.message});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          message ?? context.l10n.changelogLoadError,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(context.l10n.commonRetry),
        ),
      ],
    );
  }
}
