import 'package:flutter/material.dart';
import 'package:diohub/style/app_spacing.dart';

/// Shared mock list content: two [MiniIssueCard]s with a gap.
/// Used by Surface & Glass and App Bar previews so they show realistic
/// issue-style cards instead of generic rectangles.
class MockListContent extends StatelessWidget {
  const MockListContent({super.key, this.topPadding = 48});

  /// Space above the first card (for overlay height).
  final double topPadding;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MiniIssueCard(
            title: 'Add dark mode support',
            number: '128',
            stateColor: Colors.green,
            repoName: 'octocat/Hello-World',
            bodySnippet: 'Implements dark mode theming across all screens…',
            chips: <Widget>[
              _LabelChip(label: 'enhancement'),
              Text(
                '👍 12',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          context.spacing.compactGap,
          MiniIssueCard(
            title: 'Fix notification badge count',
            number: '127',
            stateColor: Colors.red,
            repoName: 'octocat/Hello-World',
          ),
        ],
      ),
    );
  }
}

/// Single mock issue/PR card for previews.
class MiniIssueCard extends StatelessWidget {
  const MiniIssueCard({
    required this.title,
    required this.number,
    required this.stateColor,
    required this.repoName,
    super.key,
    this.bodySnippet,
    this.chips,
    this.padding,
  });

  final String title;
  final String number;
  final Color stateColor;
  final String repoName;
  final String? bodySnippet;
  final List<Widget>? chips;
  final EdgeInsets? padding;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final EdgeInsets cardPadding = padding ?? const EdgeInsets.all(10);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: cardPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: stateColor,
                  shape: BoxShape.circle,
                ),
              ),
              context.spacing.tightGap,
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '#$number',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          context.spacing.tightGap,
          Text(
            repoName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (bodySnippet != null) ...<Widget>[
            context.spacing.tightGap,
            Text(
              bodySnippet!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (chips != null && chips!.isNotEmpty) ...<Widget>[
            context.spacing.compactGap,
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: chips!,
            ),
          ],
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label});

  final String label;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
