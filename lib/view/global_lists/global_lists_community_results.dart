part of 'global_lists_screen.dart';

class _ProjectResults extends ConsumerWidget {
  const _ProjectResults({required this.resourceScope, required this.query});

  final ResourceScope resourceScope;
  final GlobalProjectBrowseQuery query;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final PaginationController<UserProjectV2Edge, UserProjectV2Edge>
    controller = ref.watch(
      globalProjectControllerProvider((scope: resourceScope, query: query)),
    );
    return _GlobalPaginatedList<UserProjectV2Edge>(
      storageKey: 'global-projects-${query.identity}',
      controller: controller,
      emptyTitle: context.l10n.globalProjectsEmpty,
      pendingCountLabel: context.l10n.navProjects,
      itemBuilder:
          (
            final BuildContext context,
            final UserProjectV2Edge edge,
            final int index,
          ) {
            final UserProjectV2Node? project = edge.node;
            if (project == null) {
              return const SizedBox.shrink();
            }
            return _GlobalProjectRow(
              project: project,
              onTap: () => unawaited(
                _openCommunityUrl(
                  context: context,
                  url: project.url,
                  errorMessage: context.l10n.globalProjectsOpenError,
                  logTag: 'GlobalProjects',
                ),
              ),
            );
          },
    );
  }
}

class _DiscussionResults extends ConsumerWidget {
  const _DiscussionResults({required this.resourceScope, required this.query});

  final ResourceScope resourceScope;
  final GlobalDiscussionBrowseQuery query;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final PaginationController<DiscussionCardData, DiscussionCardData>
    controller = ref.watch(
      globalDiscussionControllerProvider((
        scope: resourceScope,
        query: query.apiQuery,
      )),
    );
    return _GlobalPaginatedList<DiscussionCardData>(
      storageKey: 'global-discussions-${query.identity}',
      controller: controller,
      emptyTitle: context.l10n.globalDiscussionsEmpty,
      pendingCountLabel: context.l10n.navDiscussions,
      itemBuilder:
          (
            final BuildContext context,
            final DiscussionCardData discussion,
            final int index,
          ) => _GlobalDiscussionRow(
            discussion: discussion,
            onTap: () => unawaited(
              _openCommunityUrl(
                context: context,
                url: discussion.url,
                errorMessage: context.l10n.globalDiscussionsOpenError,
                logTag: 'GlobalDiscussions',
              ),
            ),
          ),
    );
  }
}

class _GlobalProjectRow extends StatelessWidget {
  const _GlobalProjectRow({required this.project, required this.onTap});

  final UserProjectV2Node project;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String state = project.closed
        ? context.l10n.globalProjectsClosed
        : context.l10n.globalProjectsOpen;
    final String updated = context.l10n.globalListsUpdated(
      formatRelativeTime(context, project.updatedAt),
    );
    final String metadata = context.l10n.globalProjectsMetadata(
      project.number,
      state,
      updated,
    );
    return Semantics(
      container: true,
      link: true,
      label: '${project.title}, $metadata',
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    project.closed
                        ? Icons.check_circle_outline
                        : Icons.grid_view_outlined,
                    color: project.closed
                        ? colors.onSurfaceVariant
                        : colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          project.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
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
                  const SizedBox(width: 12),
                  Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: colors.onSurfaceVariant,
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

class _GlobalDiscussionRow extends StatelessWidget {
  const _GlobalDiscussionRow({required this.discussion, required this.onTap});

  final DiscussionCardData discussion;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String author =
        discussion.author?.login ?? context.l10n.repoUnknownAuthor;
    final String metadata = context.l10n.globalDiscussionsMetadata(
      discussion.repository.nameWithOwner,
      author,
      formatRelativeTime(context, discussion.updatedAt),
    );
    final bool answered = discussion.answer != null;
    final String semanticLabel = <String>[
      discussion.title,
      metadata,
      discussion.category.name,
      if (answered) context.l10n.globalDiscussionsAnswered,
      context.l10n.repoCommentsCount(discussion.comments.totalCount),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  Text(
                    discussion.category.emoji,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          discussion.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          metadata,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            _CommunityBadge(label: discussion.category.name),
                            if (answered)
                              _CommunityBadge(
                                label: context.l10n.globalDiscussionsAnswered,
                                icon: Icons.check_circle_outline,
                              ),
                            if (discussion.closed)
                              _CommunityBadge(
                                label: context.l10n.repoClosed,
                                icon: Icons.lock_outline,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (discussion.comments.totalCount > 0) ...<Widget>[
                    const SizedBox(width: 12),
                    Tooltip(
                      message: context.l10n.repoCommentsCount(
                        discussion.comments.totalCount,
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
                            '${discussion.comments.totalCount}',
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

class _CommunityBadge extends StatelessWidget {
  const _CommunityBadge({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(final BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: ShapeDecoration(
      shape: StadiumBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 13),
          const SizedBox(width: 4),
        ],
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

Future<void> _openCommunityUrl({
  required final BuildContext context,
  required final Uri url,
  required final String errorMessage,
  required final String logTag,
}) async {
  try {
    await openInAppBrowser(url);
  } on Object catch (error, stackTrace) {
    AppLogger.warning(
      'Could not open account-wide community item',
      error: error,
      stackTrace: stackTrace,
      tag: logTag,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }
}
