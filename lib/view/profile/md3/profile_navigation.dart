import 'package:diohub/l10n/l10n.dart';
import 'package:flutter/material.dart';

enum ProfileNavigationDestination {
  overview,
  repositories,
  projects,
  packages,
  stars;

  static bool supportsPath(final String? path) =>
      path == null ||
      path.isEmpty ||
      path == 'overview' ||
      path == 'readme' ||
      path == 'activity' ||
      path == 'repositories' ||
      path == 'projects' ||
      path == 'packages' ||
      path == 'stars';

  static ProfileNavigationDestination fromPath(final String? path) =>
      switch (path) {
        'repositories' => repositories,
        'projects' => projects,
        'packages' => packages,
        'stars' => stars,
        _ => overview,
      };

  String? get path => switch (this) {
    overview => null,
    repositories => 'repositories',
    projects => 'projects',
    packages => 'packages',
    stars => 'stars',
  };
}

class ProfileNavigation extends StatelessWidget {
  const ProfileNavigation({
    required this.controller,
    required this.repositoryCount,
    required this.projectCount,
    required this.packageCount,
    required this.starCount,
    super.key,
  });

  final TabController controller;
  final int? repositoryCount;
  final int? projectCount;
  final int? packageCount;
  final int? starCount;

  @override
  Widget build(final BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: TabBar(
          key: const ValueKey<String>('profile-navigation'),
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerHeight: 0,
          tabs: <Widget>[
            _ProfileNavigationTab(
              icon: Icons.book_outlined,
              label: context.l10n.profileOverview,
            ),
            _ProfileNavigationTab(
              icon: Icons.bookmarks_outlined,
              label: context.l10n.profileRepositories,
              count: repositoryCount,
            ),
            _ProfileNavigationTab(
              icon: Icons.table_chart_outlined,
              label: context.l10n.profileProjects,
              count: projectCount,
            ),
            _ProfileNavigationTab(
              icon: Icons.inventory_2_outlined,
              label: context.l10n.profilePackages,
              count: packageCount,
            ),
            _ProfileNavigationTab(
              icon: Icons.star_outline,
              label: context.l10n.profileStars,
              count: starCount,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileNavigationTab extends StatelessWidget {
  const _ProfileNavigationTab({
    required this.icon,
    required this.label,
    this.count,
  });

  final IconData icon;
  final String label;
  final int? count;

  @override
  Widget build(final BuildContext context) => Tab(
    height: 48,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
        if (count != null) ...<Widget>[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ],
    ),
  );
}
