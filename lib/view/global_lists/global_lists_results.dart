part of 'global_lists_screen.dart';

class _IssuePullResults extends ConsumerWidget {
  const _IssuePullResults({
    required this.destination,
    required this.resourceScope,
    required this.query,
  });

  final GlobalListDestination destination;
  final ResourceScope resourceScope;
  final String query;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final PaginationController<IssueOrPull, IssueOrPull> controller = ref.watch(
      globalIssuePullControllerProvider((
        scope: resourceScope,
        destination: destination,
        query: query,
      )),
    );
    return _GlobalPaginatedList<IssueOrPull>(
      storageKey: 'global-${destination.name}-$query',
      controller: controller,
      emptyTitle: destination == GlobalListDestination.issues
          ? context.l10n.globalListsNoIssues
          : context.l10n.globalListsNoPullRequests,
      pendingCountLabel: _title(context, destination),
      itemBuilder:
          (
            final BuildContext context,
            final IssueOrPull item,
            final int index,
          ) {
            final RepositoryIssuePullRowData row =
                RepositoryIssuePullRowData.fromSearchResult(item);
            return _GlobalIssuePullRow(
              data: row,
              onTap: () => unawaited(row.ref.navigate(context, ref)),
            );
          },
    );
  }
}

class _RepositoryResults extends ConsumerWidget {
  const _RepositoryResults({required this.resourceScope, required this.query});

  final ResourceScope resourceScope;
  final GlobalRepositoryBrowseQuery query;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final PaginationController<UserRepoEdge, UserRepoEdge> controller = ref
        .watch(
          globalRepositoryControllerProvider((
            scope: resourceScope,
            query: query,
          )),
        );
    return _GlobalPaginatedList<UserRepoEdge>(
      storageKey: 'global-repositories-${query.identity}',
      controller: controller,
      emptyTitle: context.l10n.globalListsNoRepositories,
      pendingCountLabel: context.l10n.navAllRepositories,
      itemBuilder:
          (
            final BuildContext context,
            final UserRepoEdge item,
            final int index,
          ) {
            final Query$getUserRepositories$user$repositories$edges$node?
            repository = item.node;
            if (repository == null) {
              return const SizedBox.shrink();
            }
            final RepoRef refData = RepoRef(
              owner: repository.owner.login,
              name: repository.name,
              nodeId: repository.id,
            );
            return _GlobalRepositoryRow(
              repository: repository,
              onTap: () => _openRepositoryDashboardItem(
                context: context,
                ref: ref,
                repository: repository,
                repoRef: refData,
              ),
            );
          },
    );
  }
}

class _GlobalPaginatedList<T> extends StatelessWidget {
  const _GlobalPaginatedList({
    required this.storageKey,
    required this.controller,
    required this.emptyTitle,
    required this.itemBuilder,
    this.pendingCountLabel,
  });

  final String storageKey;
  final PaginationController<T, T> controller;
  final String emptyTitle;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final String? pendingCountLabel;

  @override
  Widget build(final BuildContext context) => RefreshIndicator(
    onRefresh: controller.refresh,
    child: CustomScrollView(
      key: PageStorageKey<String>(storageKey),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          sliver: SliverMainAxisGroup(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _ResultsHeader<T>(
                  controller: controller,
                  pendingCountLabel: pendingCountLabel,
                ),
              ),
              PaginatedSliverList<T>(
                controller: controller,
                loadingBuilder: (final BuildContext context) =>
                    const _GlobalListLoadingRows(),
                errorBuilder:
                    (
                      final BuildContext context,
                      final Object error,
                      final VoidCallback retry,
                    ) => _GlobalListError(error: error, onRetry: retry),
                emptyBuilder: (final BuildContext context) =>
                    _GlobalListEmpty(title: emptyTitle),
                itemBuilder: itemBuilder,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ResultsHeader<T> extends StatelessWidget {
  const _ResultsHeader({
    required this.controller,
    required this.pendingCountLabel,
  });

  final PaginationController<T, T> controller;
  final String? pendingCountLabel;

  @override
  Widget build(final BuildContext context) =>
      ValueListenableBuilder<PaginationState<T>>(
        valueListenable: controller.state,
        builder:
            (
              final BuildContext context,
              final PaginationState<T> state,
              final Widget? child,
            ) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.list_alt_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.totalCount != null || !state.hasMoreForward
                          ? context.l10n.globalListsResultsCount(
                              state.totalCount ?? state.items.length,
                            )
                          : pendingCountLabel ??
                                context.l10n.globalListsResultsCount(
                                  state.items.length,
                                ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: context.l10n.globalListsRefresh,
                    onPressed: controller.refresh,
                    icon: const Icon(Icons.refresh, size: 19),
                  ),
                ],
              ),
            ),
      );
}

class _GlobalIssuePullRow extends StatelessWidget {
  const _GlobalIssuePullRow({required this.data, required this.onTap});

  final RepositoryIssuePullRowData data;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final GitHubActionVisual visual = GitHubVisualStyles.fromVisualState(
      data.visualState,
    );
    final String action = switch (data.visualState) {
      IssueVisualState.open ||
      PrVisualState.open => context.l10n.repoListOpened,
      IssueVisualState.closed ||
      IssueVisualState.closedNotPlanned ||
      IssueVisualState.closedDuplicate ||
      PrVisualState.closed => context.l10n.repoListClosed,
      PrVisualState.draft => context.l10n.repoListDraft,
      PrVisualState.merged => context.l10n.repoListMerged,
    };
    final String author = (data.author?.trim().isNotEmpty ?? false)
        ? data.author!
        : context.l10n.repoUnknownAuthor;
    final RepoRef repo = switch (data.ref) {
      final IssueRef issue => issue.repo,
      final PullRequestRef pull => pull.repo,
      _ => throw StateError('Expected a repository-scoped work item'),
    };
    final String metadata = context.l10n.globalListsIssueMetadata(
      repo.fullName,
      data.number,
      action,
      author,
      formatRelativeTime(context, data.timestamp),
    );
    final String semanticLabel = <String>[
      data.title,
      metadata,
      if (data.commentsCount > 0)
        context.l10n.repoCommentsCount(data.commentsCount),
    ].join(', ');

    return Semantics(
      container: true,
      link: true,
      label: semanticLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colors.outlineVariant),
                  right: BorderSide(color: colors.outlineVariant),
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(visual.icon, size: 20, color: visual.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            Text(
                              data.title,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            for (final RepositoryIssuePullLabelData label
                                in data.labels.take(5))
                              IssueLabel.fromNameColor(label.name, label.color),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          metadata,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (data.commentsCount > 0) ...<Widget>[
                    const SizedBox(width: 12),
                    Tooltip(
                      message: context.l10n.repoCommentsCount(
                        data.commentsCount,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.mode_comment_outlined,
                            size: 17,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${data.commentsCount}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlobalRepositoryRow extends StatelessWidget {
  const _GlobalRepositoryRow({required this.repository, required this.onTap});

  final Query$getUserRepositories$user$repositories$edges$node repository;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Query$getUserRepositories$user$repositories$edges$node$primaryLanguage?
    language = repository.primaryLanguage;
    final String? languageColor = language?.color;
    final DateTime updatedAt = repository.pushedAt ?? repository.createdAt;
    final String updatedLabel = context.l10n.globalListsUpdated(
      formatRelativeTime(context, updatedAt),
    );
    final String semanticLabel = <String>[
      repository.nameWithOwner,
      if (repository.description?.trim().isNotEmpty ?? false)
        repository.description!,
      if (language != null) language.name,
      context.l10n.repoStarsCount(repository.stargazerCount.toShortenedStr()),
      updatedLabel,
    ].join(', ');
    return Semantics(
      container: true,
      link: true,
      label: semanticLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colors.outlineVariant),
                  right: BorderSide(color: colors.outlineVariant),
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        repository.nameWithOwner,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      _RepositoryBadge(
                        label: repository.isPrivate
                            ? context.l10n.repoPrivate
                            : context.l10n.repoPublic,
                      ),
                      if (repository.isFork)
                        _RepositoryBadge(label: context.l10n.globalListsForks),
                    ],
                  ),
                  if (repository.description?.trim().isNotEmpty ??
                      false) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      repository.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      if (language != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: _languageColor(languageColor, colors),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              language.name,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      _RepositoryMetric(
                        icon: Icons.star_outline,
                        value: repository.stargazerCount.toShortenedStr(),
                      ),
                      Text(
                        updatedLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RepositoryBadge extends StatelessWidget {
  const _RepositoryBadge({required this.label});

  final String label;

  @override
  Widget build(final BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
  );
}

class _RepositoryMetric extends StatelessWidget {
  const _RepositoryMetric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(final BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, size: 16),
      const SizedBox(width: 4),
      Text(value, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _GlobalListLoadingRows extends StatelessWidget {
  const _GlobalListLoadingRows();

  @override
  Widget build(final BuildContext context) => ShimmerScope(
    child: Column(
      children: <Widget>[
        for (int index = 0; index < 5; index++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const ShimmerBone.icon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ShimmerBone.title(width: index.isEven ? 280 : 220),
                      const SizedBox(height: 8),
                      ShimmerBone.label(width: index.isEven ? 180 : 240),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _GlobalListEmpty extends StatelessWidget {
  const _GlobalListEmpty({required this.title});

  final String title;

  @override
  Widget build(final BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.search_off_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.globalListsNoResultsDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _GlobalListError extends StatelessWidget {
  const _GlobalListError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.error_outline, size: 36),
        const SizedBox(height: 12),
        Text(
          context.l10n.globalListsLoadError,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          error.toString(),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(context.l10n.commonRetry),
        ),
      ],
    ),
  );
}
