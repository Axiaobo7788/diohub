part of 'global_lists_screen.dart';

SearchScope _searchScope(
  final GlobalListDestination destination,
  final AccountModel account,
) => switch (destination) {
  GlobalListDestination.issues => SearchScope.homeIssues(
    viewerLogin: account.username,
  ),
  GlobalListDestination.pullRequests => SearchScope.homePulls(
    viewerLogin: account.username,
  ),
  GlobalListDestination.repositories => SearchScope.userRepos(
    user: UserRef(login: account.username, nodeId: account.nodeId),
  ),
  GlobalListDestination.projects || GlobalListDestination.discussions =>
    throw StateError('$destination does not use SearchStateNotifier'),
};

GlobalNavigationDestination _navigationDestination(
  final GlobalListDestination destination,
) => switch (destination) {
  GlobalListDestination.issues => GlobalNavigationDestination.issues,
  GlobalListDestination.pullRequests =>
    GlobalNavigationDestination.pullRequests,
  GlobalListDestination.repositories =>
    GlobalNavigationDestination.repositories,
  GlobalListDestination.projects => GlobalNavigationDestination.projects,
  GlobalListDestination.discussions => GlobalNavigationDestination.discussions,
};

String _title(
  final BuildContext context,
  final GlobalListDestination destination,
) => switch (destination) {
  GlobalListDestination.issues => context.l10n.navAllIssues,
  GlobalListDestination.pullRequests => context.l10n.navAllPullRequests,
  GlobalListDestination.repositories => context.l10n.navAllRepositories,
  GlobalListDestination.projects => context.l10n.navProjects,
  GlobalListDestination.discussions => context.l10n.navDiscussions,
};

String _searchHint(
  final BuildContext context,
  final GlobalListDestination destination,
) => switch (destination) {
  GlobalListDestination.issues => context.l10n.globalListsSearchIssues,
  GlobalListDestination.pullRequests =>
    context.l10n.globalListsSearchPullRequests,
  GlobalListDestination.repositories =>
    context.l10n.globalListsSearchRepositories,
  GlobalListDestination.projects => context.l10n.globalListsSearchProjects,
  GlobalListDestination.discussions =>
    context.l10n.globalListsSearchDiscussions,
};

IconData _destinationIcon(final GlobalListDestination destination) =>
    switch (destination) {
      GlobalListDestination.issues => Icons.adjust_outlined,
      GlobalListDestination.pullRequests => Icons.call_merge_outlined,
      GlobalListDestination.repositories => Icons.book_outlined,
      GlobalListDestination.projects => Icons.grid_view_outlined,
      GlobalListDestination.discussions => Icons.forum_outlined,
    };

IconData _quickFilterIcon(final QuickFilter filter) {
  final String qualifier = filter.qualifier.qualifier.toQueryString();
  if (qualifier.startsWith('assignee:')) {
    return Icons.gps_fixed;
  }
  if (qualifier.startsWith('author:')) {
    return Icons.add_circle_outline;
  }
  if (qualifier.startsWith('mentions:')) {
    return Icons.alternate_email;
  }
  if (qualifier == 'is:public') {
    return Icons.public;
  }
  if (qualifier == 'is:private') {
    return Icons.lock_outline;
  }
  if (qualifier.startsWith('archived:')) {
    return Icons.archive_outlined;
  }
  if (qualifier.startsWith('mirror:')) {
    return Icons.sync_outlined;
  }
  if (qualifier.startsWith('fork:')) {
    return Icons.fork_right_outlined;
  }
  return Icons.filter_alt_outlined;
}

String _quickFilterLabel(final BuildContext context, final QuickFilter filter) {
  final String qualifier = filter.qualifier.qualifier.toQueryString();
  if (qualifier.startsWith('assignee:')) {
    return context.l10n.repoAssignedToMe;
  }
  if (qualifier.startsWith('author:')) {
    return context.l10n.repoCreatedByMe;
  }
  if (qualifier.startsWith('mentions:')) {
    return context.l10n.repoMentioned;
  }
  if (qualifier == 'is:public') {
    return context.l10n.repoPublic;
  }
  if (qualifier == 'is:private') {
    return context.l10n.repoPrivate;
  }
  if (qualifier.startsWith('archived:')) {
    return context.l10n.repoArchived;
  }
  if (qualifier.startsWith('mirror:')) {
    return context.l10n.globalListsMirrors;
  }
  if (qualifier.startsWith('fork:')) {
    return context.l10n.globalListsForks;
  }
  return filter.displayLabel;
}

String? _selectedQuickFilter(
  final SearchState state,
  final List<QuickFilter> filters,
) {
  final Set<String> active = state.activeQualifiers
      .map(
        (final QualifierExpression expression) =>
            expression.qualifier.toQueryString(),
      )
      .toSet();
  for (final QuickFilter filter in filters) {
    final String query = filter.qualifier.qualifier.toQueryString();
    if (active.contains(query)) {
      return query;
    }
  }
  return null;
}

List<QuickFilter> _quickFilters(
  final GlobalListDestination destination,
  final SearchScope scope,
) {
  if (destination != GlobalListDestination.repositories) {
    return scope.quickFilters;
  }
  return scope.quickFilters
      .where((final QuickFilter filter) {
        final String qualifier = filter.qualifier.qualifier.toQueryString();
        return qualifier == 'is:public' ||
            qualifier == 'is:private' ||
            qualifier.startsWith('fork:');
      })
      .toList(growable: false);
}

GlobalRepositoryBrowseQuery _repositoryBrowseQuery(
  final String login,
  final SearchState state,
) {
  final Set<String> active = state.activeQualifiers
      .map(
        (final QualifierExpression expression) =>
            expression.qualifier.toQueryString(),
      )
      .toSet();
  final GlobalRepositoryVisibility visibility = active.contains('is:private')
      ? GlobalRepositoryVisibility.private
      : active.contains('is:public')
      ? GlobalRepositoryVisibility.public
      : GlobalRepositoryVisibility.all;
  final GlobalRepositorySort sort = switch (state.sort?.key) {
    'updated-desc' => GlobalRepositorySort.recentlyUpdated,
    'stars-desc' => GlobalRepositorySort.stars,
    'name-asc' => GlobalRepositorySort.name,
    _ => GlobalRepositorySort.recentlyPushed,
  };
  return GlobalRepositoryBrowseQuery(
    login: login,
    text: state.freeText,
    visibility: visibility,
    forksOnly: active.any((final String query) => query.startsWith('fork:')),
    sort: sort,
  );
}

String _sortLabel(final BuildContext context, final String key) =>
    switch (key) {
      'best' => context.l10n.globalListsBestMatch,
      'created-desc' => context.l10n.globalListsNewest,
      'created-asc' => context.l10n.globalListsOldest,
      'comments-desc' => context.l10n.globalListsMostComments,
      'pushed-desc' => context.l10n.globalListsRecentlyPushed,
      'updated-desc' => context.l10n.globalListsRecentlyUpdated,
      'name-asc' => context.l10n.globalListsName,
      'stars-desc' => context.l10n.globalListsMostStars,
      'forks-desc' => context.l10n.globalListsMostForks,
      _ => key,
    };

Color _languageColor(final String? value, final ColorScheme colors) {
  if (value == null || value.isEmpty) {
    return colors.outline;
  }
  try {
    return Color(
      int.parse(value.replaceFirst('#', ''), radix: 16) | 0xFF000000,
    );
  } on FormatException {
    return colors.outline;
  }
}

void _openRepositoryDashboardItem({
  required final BuildContext context,
  required final WidgetRef ref,
  required final Query$getUserRepositories$user$repositories$edges$node
  repository,
  required final RepoRef repoRef,
}) {
  ref
      .read(repositoryPreviewProvider(repoRef).notifier)
      .seed(
        RepositoryPreview(
          fullName: repository.nameWithOwner,
          name: repository.name,
          owner: repository.owner.login,
          ownerAvatarUrl: repository.owner.avatarUrl.toString(),
          isPrivate: repository.isPrivate,
          nodeId: repository.id,
        ),
      );
  ref.read(repositoryProvider(repoRef));
  unawaited(repoRef.navigate(context, ref));
}
