import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/view/repository/md3/repository_md3_layout.dart';
import 'package:flutter/material.dart';

enum RepositoryNavigationDestination {
  code(Icons.code),
  issues(Icons.adjust),
  pullRequests(Icons.call_merge),
  actions(Icons.play_circle_outline),
  projects(Icons.table_chart_outlined),
  wiki(Icons.menu_book_outlined),
  security(Icons.shield_outlined),
  insights(Icons.insights_outlined);

  const RepositoryNavigationDestination(this.icon);

  final IconData icon;

  String label(final BuildContext context) => switch (this) {
    RepositoryNavigationDestination.code => context.l10n.repoCode,
    RepositoryNavigationDestination.issues => context.l10n.repoIssues,
    RepositoryNavigationDestination.pullRequests =>
      context.l10n.repoPullRequests,
    RepositoryNavigationDestination.actions => context.l10n.repoActions,
    RepositoryNavigationDestination.projects => context.l10n.repoProjects,
    RepositoryNavigationDestination.wiki => context.l10n.repoWiki,
    RepositoryNavigationDestination.security => context.l10n.repoSecurity,
    RepositoryNavigationDestination.insights => context.l10n.repoInsights,
  };
}

/// Shared repository-level navigation used by Code, list, and detail routes.
class RepositoryNavigationBar extends StatelessWidget {
  const RepositoryNavigationBar({
    this.controller,
    this.issueCount,
    this.pullRequestCount,
    this.onSelected,
    super.key,
  });

  final TabController? controller;
  final int? issueCount;
  final int? pullRequestCount;
  final ValueChanged<RepositoryNavigationDestination>? onSelected;

  @override
  Widget build(final BuildContext context) {
    return TabBar(
      key: const ValueKey<String>('repository-primary-navigation'),
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      onTap: (final int index) =>
          onSelected?.call(RepositoryNavigationDestination.values[index]),
      tabs: <Widget>[
        for (final RepositoryNavigationDestination destination
            in RepositoryNavigationDestination.values)
          _RepositoryNavigationLabel(
            destination: destination,
            count: switch (destination) {
              RepositoryNavigationDestination.issues => issueCount,
              RepositoryNavigationDestination.pullRequests => pullRequestCount,
              _ => null,
            },
          ),
      ],
    );
  }
}

class _RepositoryNavigationLabel extends StatelessWidget {
  const _RepositoryNavigationLabel({
    required this.destination,
    required this.count,
  });

  final RepositoryNavigationDestination destination;
  final int? count;

  @override
  Widget build(final BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(destination.icon),
          const SizedBox(width: RepositoryMd3Layout.space8),
          Text(destination.label(context)),
          if (count != null) ...<Widget>[
            const SizedBox(width: RepositoryMd3Layout.space8),
            Badge(
              label: Text(_formatCount(count!)),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              textColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}

String _formatCount(final int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}m';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k';
  }
  return '$value';
}
