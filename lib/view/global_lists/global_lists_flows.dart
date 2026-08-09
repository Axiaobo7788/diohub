part of 'global_lists_screen.dart';

class _GlobalListsResolvingState extends StatelessWidget {
  const _GlobalListsResolvingState();

  @override
  Widget build(final BuildContext context) => const Center(
    child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator()),
  );
}

class _GlobalListsSignInState extends StatelessWidget {
  const _GlobalListsSignInState();

  @override
  Widget build(final BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.lock_outline, size: 44),
            const SizedBox(height: 16),
            Text(
              context.l10n.globalListsSignInTitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.globalListsSignInDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () =>
                  unawaited(context.router.push<void>(const AuthRoute())),
              icon: const Icon(Icons.login),
              label: Text(context.l10n.globalListsSignInAction),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _startCreateFlow({
  required final BuildContext context,
  required final WidgetRef ref,
  required final GlobalListDestination destination,
  required final String login,
  required final ResourceScope resourceScope,
}) async {
  final RepoRef? repoRef = await showDialog<RepoRef>(
    context: context,
    builder: (final BuildContext context) =>
        _RepositoryPickerDialog(login: login, resourceScope: resourceScope),
  );
  if (repoRef == null || !context.mounted) {
    return;
  }
  try {
    if (destination == GlobalListDestination.pullRequests) {
      await context.router.push<void>(NewPullRequestRoute(repoRef: repoRef));
      return;
    }
    final RepoInfoData repository = await ref.read(
      repositoryProvider(repoRef).future,
    );
    if (!context.mounted) {
      return;
    }
    final List<RepoIssueTemplate> templates =
        repository.repository?.issueTemplates?.toList(growable: false) ??
        const <RepoIssueTemplate>[];
    final _IssueTemplateChoice? choice = await showDialog<_IssueTemplateChoice>(
      context: context,
      builder: (final BuildContext context) =>
          _IssueTemplateDialog(templates: templates),
    );
    if (choice == null || !context.mounted) {
      return;
    }
    await context.router.push<void>(
      NewIssueRoute(repoRef: repoRef, template: choice.template),
    );
  } on Object catch (error, stackTrace) {
    AppLogger.warning(
      'Global work-list create flow failed',
      error: error,
      stackTrace: stackTrace,
      tag: 'GlobalLists',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.globalListsCreateFlowError)),
      );
    }
  }
}

class _RepositoryPickerDialog extends ConsumerStatefulWidget {
  const _RepositoryPickerDialog({
    required this.login,
    required this.resourceScope,
  });

  final String login;
  final ResourceScope resourceScope;

  @override
  ConsumerState<_RepositoryPickerDialog> createState() =>
      _RepositoryPickerDialogState();
}

class _RepositoryPickerDialogState
    extends ConsumerState<_RepositoryPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _queryText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final GlobalRepositoryBrowseQuery query = GlobalRepositoryBrowseQuery(
      login: widget.login,
      text: _queryText,
    );
    final PaginationController<UserRepoEdge, UserRepoEdge> controller = ref
        .watch(
          globalRepositoryControllerProvider((
            scope: widget.resourceScope,
            query: query,
          )),
        );
    final double availableHeight = math.max(
      320,
      MediaQuery.sizeOf(context).height - 64,
    );
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 640,
        height: math.min(620, availableHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      context.l10n.globalListsSelectRepository,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (final String value) =>
                    setState(() => _queryText = value),
                decoration: InputDecoration(
                  hintText: context.l10n.globalListsSearchRepositories,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _queryText.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _queryText = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                child: CustomScrollView(
                  key: PageStorageKey<String>(
                    'global-repository-picker-${query.identity}',
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[
                    PaginatedSliverList<UserRepoEdge>(
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
                          _GlobalListEmpty(
                            title: context.l10n.globalListsNoRepositories,
                          ),
                      itemBuilder:
                          (
                            final BuildContext context,
                            final UserRepoEdge edge,
                            final int index,
                          ) {
                            final Query$getUserRepositories$user$repositories$edges$node?
                            repository = edge.node;
                            if (repository == null) {
                              return const SizedBox.shrink();
                            }
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 4,
                              ),
                              leading: const Icon(Icons.book_outlined),
                              title: Text(repository.nameWithOwner),
                              subtitle:
                                  repository.description?.trim().isNotEmpty ??
                                      false
                                  ? Text(
                                      repository.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: repository.isPrivate
                                  ? const Icon(Icons.lock_outline, size: 18)
                                  : null,
                              onTap: () => Navigator.of(context).pop(
                                RepoRef(
                                  owner: repository.owner.login,
                                  name: repository.name,
                                  nodeId: repository.id,
                                ),
                              ),
                            );
                          },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _IssueTemplateChoice {
  const _IssueTemplateChoice(this.template);

  final RepoIssueTemplate? template;
}

class _IssueTemplateDialog extends StatelessWidget {
  const _IssueTemplateDialog({required this.templates});

  final List<RepoIssueTemplate> templates;

  @override
  Widget build(final BuildContext context) => SimpleDialog(
    title: Text(context.l10n.globalListsChooseIssueTemplate),
    children: <Widget>[
      for (final RepoIssueTemplate template in templates)
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(template.name),
          subtitle: template.about?.trim().isNotEmpty ?? false
              ? Text(template.about!)
              : null,
          onTap: () =>
              Navigator.of(context).pop(_IssueTemplateChoice(template)),
        ),
      ListTile(
        leading: const Icon(Icons.add),
        title: Text(context.l10n.globalListsBlankIssue),
        onTap: () =>
            Navigator.of(context).pop(const _IssueTemplateChoice(null)),
      ),
    ],
  );
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: ListTile(
      dense: true,
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(icon, size: 20),
      title: Text(
        label,
        style: selected ? const TextStyle(fontWeight: FontWeight.w700) : null,
      ),
      onTap: onTap,
    ),
  );
}
