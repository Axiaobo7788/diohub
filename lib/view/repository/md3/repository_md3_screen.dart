import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/widgets/metadata_language_bar.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/fragments/repo_card_fields.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_graphql/schema.graphql.dart' show Enum$FundingPlatform;
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/models/repositories/repository_initial_state.dart';
import 'package:diohub/models/repository_contributor_preview.dart';
import 'package:diohub/models/repository_preview.dart';
import 'package:diohub/l10n/relative_time.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/dashboard/home_top_repositories_provider.dart';
import 'package:diohub/providers/entity_store_notifier.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/providers/repository/repository_preview_provider.dart';
import 'package:diohub/providers/repository/repository_preview_providers.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/repository/md3/repository_code_md3.dart';
import 'package:diohub/view/repository/md3/repository_issue_pull_md3.dart';
import 'package:diohub/view/repository/md3/repository_md3_layout.dart';
import 'package:diohub/view/repository/md3/repository_md3_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class RepositoryMd3Screen extends ConsumerStatefulWidget {
  const RepositoryMd3Screen({
    required this.repoRef,
    required this.initialState,
    required this.onOpenLegacy,
    super.key,
  });

  final RepoRef repoRef;
  final RepositoryInitialState initialState;
  final VoidCallback? onOpenLegacy;

  @override
  ConsumerState<RepositoryMd3Screen> createState() =>
      _RepositoryMd3ScreenState();
}

class _RepositoryMd3ScreenState extends ConsumerState<RepositoryMd3Screen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late int _selectedTabIndex;
  bool _visitRecorded = false;
  Future<void> Function()? _issuesRefresh;
  Future<void> Function()? _pullRequestsRefresh;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = _initialTabIndex(widget.initialState.tabKind);
    _tabController = TabController(
      length: _repositoryTabs.length,
      initialIndex: _selectedTabIndex,
      vsync: this,
    )..addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    final int nextIndex = _tabController.index;
    if (mounted && nextIndex != _selectedTabIndex) {
      setState(() => _selectedTabIndex = nextIndex);
    }
  }

  Future<void> _refresh() async {
    final accountState = ref.read(accountProvider);
    final bool signedIn =
        accountState.hasValue &&
        !accountState.hasError &&
        accountState.value?.activeAccountModel != null;
    if (signedIn) {
      ref.invalidate(repoCardProvider(widget.repoRef));
      await ref.read(repositoryProvider(widget.repoRef).notifier).refresh();
    }
    if (!mounted) {
      return;
    }
    switch (_selectedTabIndex) {
      case 0:
        if (signedIn) {
          await refreshRepositoryCode(ref, widget.repoRef);
        }
      case 1:
        await _issuesRefresh?.call();
      case 2:
        await _pullRequestsRefresh?.call();
    }
  }

  void _openRepositorySearch(final String? query) {
    final String normalized = query?.trim() ?? '';
    final String repositoryQualifier = 'repo:${widget.repoRef.fullName}';
    unawaited(
      context.router.push<void>(
        SearchRoute(
          initialQuery: normalized.isEmpty
              ? '$repositoryQualifier '
              : '$repositoryQualifier $normalized',
        ),
      ),
    );
  }

  void _openRepositoryBrowserSearch() {
    unawaited(
      context.router.push<void>(SearchRoute(initialQuery: 'type:repository ')),
    );
  }

  void _openPublicHome() {
    unawaited(context.router.replaceAll(<PageRouteInfo>[HomeRoute()]));
  }

  @override
  Widget build(final BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final bool accountResolved =
        accountState.hasValue && !accountState.hasError;
    final account = accountResolved
        ? accountState.value?.activeAccountModel
        : null;
    final bool signedIn = accountResolved && account != null;
    final AsyncValue<List<HomeRepositoryItem>> topRepositories = account == null
        ? const AsyncData<List<HomeRepositoryItem>>(<HomeRepositoryItem>[])
        : ref.watch(
            homeTopRepositoriesProvider((
              accountKey: account.accountKey,
              login: account.username,
            )),
          );
    final AsyncValue<RepoInfoData>? repositoryAsync = signedIn
        ? ref.watch(repositoryProvider(widget.repoRef))
        : null;
    final RepoInfo? details = repositoryAsync?.value?.repository;
    final RepositoryPreview? preview = ref.watch(
      repositoryPreviewProvider(widget.repoRef),
    );
    final AsyncValue<RepoCardData>? cardAsync =
        signedIn && details == null && preview?.defaultBranch == null
        ? ref.watch(repoCardProvider(widget.repoRef))
        : null;
    final RepoCardData? repo = details ?? cardAsync?.value;
    final Object? loadError = repositoryAsync?.error ?? cardAsync?.error;
    final String? ownerAvatarUrl = repo == null
        ? preview?.ownerAvatarUrl
        : switch (repo.owner) {
            Fragment$repoCardFields$owner$$User(:final avatarUrl) =>
              avatarUrl.toString(),
            Fragment$repoCardFields$owner$$Organization(:final avatarUrl) =>
              avatarUrl.toString(),
            _ => preview?.ownerAvatarUrl,
          };
    if (!_visitRecorded && details != null) {
      _visitRecorded = true;
      unawaited(
        ref
            .read(entityStoreMutatorProvider)
            .recordVisit(
              RepoRef.fromRepoCardFields(details),
              snapshot: EntitySnapshot(
                title: details.name,
                authorLogin: widget.repoRef.owner,
                authorAvatarUrl: ownerAvatarUrl,
                stars: details.stargazerCount,
                language: details.primaryLanguage?.name,
                languageColor: details.primaryLanguage?.color,
                isPrivate: details.isPrivate,
                isFork: details.isFork,
                isArchived: details.isArchived,
              ),
            ),
      );
    }
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final RepositoryWindowClass windowClass =
            RepositoryMd3Layout.windowClassFor(constraints.maxWidth);
        final bool expanded = windowClass == RepositoryWindowClass.expanded;
        final Widget identityHeader = _RepositoryIdentityHeader(
          repoRef: widget.repoRef,
          repo: repo,
          preview: preview,
          ownerAvatarUrl: ownerAvatarUrl,
          detailsReady: details != null,
        );
        final Widget about = _RepositoryAboutPanel(
          repoRef: widget.repoRef,
          repo: repo,
          details: details,
          scrollable: !expanded,
        );
        return RepositoryMd3Shell(
          repositoryLabel: repo?.nameWithOwner ?? widget.repoRef.fullName,
          onRefresh: _refresh,
          onOpenLegacy: signedIn ? widget.onOpenLegacy : null,
          onGlobalSearch: signedIn
              ? _openRepositorySearch
              : (final String? _) => _openPublicHome(),
          onSearchRepositories: signedIn
              ? _openRepositoryBrowserSearch
              : _openPublicHome,
          account: account,
          accountLoading: !accountResolved,
          topRepositories: topRepositories,
          repositoryNavigation: _RepositoryNavigation(
            controller: _tabController,
            repo: repo,
          ),
          body: _buildSelectedBody(
            repo,
            details: details,
            signedIn: signedIn,
            accountResolved: accountResolved,
            accountError: accountState.hasError ? accountState.error : null,
            loading: !accountResolved || (repositoryAsync?.isLoading ?? false),
            error: loadError,
            header: identityHeader,
            inlineAbout: expanded
                ? null
                : _RepositoryAboutPanel(
                    repoRef: widget.repoRef,
                    repo: repo,
                    details: details,
                    embedded: true,
                  ),
            aside: expanded ? about : null,
          ),
        );
      },
    );
  }

  Widget _buildSelectedBody(
    final RepoCardData? repo, {
    required final RepoInfo? details,
    required final bool signedIn,
    required final bool accountResolved,
    required final Object? accountError,
    required final bool loading,
    required final Object? error,
    required final Widget header,
    required final Widget? inlineAbout,
    required final Widget? aside,
  }) {
    if (!accountResolved) {
      return _RepositoryAccountStateBody(
        header: header,
        error: accountError,
        onRetry: () => ref.invalidate(accountProvider),
      );
    }
    if (_selectedTabIndex == 0) {
      if (!signedIn) {
        return _RepositoryGuestCodeBody(
          header: header,
          onSignIn: () =>
              unawaited(context.router.push<void>(const AuthRoute())),
          onBrowsePublic: _openPublicHome,
        );
      }
      return RepositoryCodeMd3(
        repoRef: widget.repoRef,
        repo: repo,
        details: details,
        detailsLoading: loading,
        detailsError: error,
        onRetryDetails: _refresh,
        header: header,
        inlineAbout: inlineAbout,
        aside: aside,
      );
    }
    if (_selectedTabIndex == 1) {
      return RepositoryIssuesMd3Page(
        repoRef: widget.repoRef,
        repo: repo,
        details: details,
        signedIn: signedIn,
        onRefreshReady: (final Future<void> Function()? callback) {
          _issuesRefresh = callback;
        },
        onOpenProjects: () => _tabController.animateTo(4),
      );
    }
    if (_selectedTabIndex == 2) {
      return RepositoryPullRequestsMd3Page(
        repoRef: widget.repoRef,
        repo: repo,
        details: details,
        signedIn: signedIn,
        onRefreshReady: (final Future<void> Function()? callback) {
          _pullRequestsRefresh = callback;
        },
      );
    }
    return _RepositoryPhasePlaceholder(
      tabLabel: _repositoryTabLabel(context, _selectedTabIndex),
      onOpenLegacy: widget.onOpenLegacy,
    );
  }
}

class _RepositoryAccountStateBody extends StatelessWidget {
  const _RepositoryAccountStateBody({
    required this.header,
    required this.error,
    required this.onRetry,
  });

  final Widget header;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) {
    return CustomScrollView(
      key: ValueKey<String>(
        error == null
            ? 'repository-account-loading'
            : 'repository-account-error',
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverToBoxAdapter(child: header),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        if (error == null)
          const SliverToBoxAdapter(
            child: LinearProgressIndicator(minHeight: 2),
          ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: error == null
                ? Text(context.l10n.repoLoading)
                : Padding(
                    padding: const EdgeInsets.all(RepositoryMd3Layout.space24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.error_outline, size: 40),
                        const SizedBox(height: RepositoryMd3Layout.space12),
                        Text(
                          context.l10n.repoAccountStateLoadError,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: RepositoryMd3Layout.space8),
                        Text(
                          '$error',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: RepositoryMd3Layout.space16),
                        OutlinedButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh),
                          label: Text(context.l10n.commonRetry),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _RepositoryGuestCodeBody extends StatelessWidget {
  const _RepositoryGuestCodeBody({
    required this.header,
    required this.onSignIn,
    required this.onBrowsePublic,
  });

  final Widget header;
  final VoidCallback onSignIn;
  final VoidCallback onBrowsePublic;

  @override
  Widget build(final BuildContext context) {
    return CustomScrollView(
      key: const ValueKey<String>('repository-code-sign-in'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverToBoxAdapter(child: header),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(RepositoryMd3Layout.space24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.lock_outline, size: 40),
                    const SizedBox(height: RepositoryMd3Layout.space12),
                    Text(
                      context.l10n.repoSignInRequired,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: RepositoryMd3Layout.space8),
                    Text(
                      context.l10n.homePublicSearchAvailable,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: RepositoryMd3Layout.space16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: RepositoryMd3Layout.space8,
                      runSpacing: RepositoryMd3Layout.space8,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: onSignIn,
                          icon: const Icon(Icons.login),
                          label: Text(context.l10n.commonSignIn),
                        ),
                        OutlinedButton.icon(
                          onPressed: onBrowsePublic,
                          icon: const Icon(Icons.search),
                          label: Text(context.l10n.homeSearchRepositories),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

int _initialTabIndex(final RepositoryTabKind? kind) {
  return switch (kind) {
    RepositoryTabKind.issues => 1,
    RepositoryTabKind.pulls => 2,
    RepositoryTabKind.projects => 4,
    _ => 0,
  };
}

class _RepositoryIdentityHeader extends ConsumerWidget {
  const _RepositoryIdentityHeader({
    required this.repoRef,
    required this.repo,
    required this.preview,
    required this.ownerAvatarUrl,
    required this.detailsReady,
  });

  final RepoRef repoRef;
  final RepoCardData? repo;
  final RepositoryPreview? preview;
  final String? ownerAvatarUrl;
  final bool detailsReady;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final bool compact =
            constraints.maxWidth < RepositoryMd3Layout.compactBreakpoint;
        final Widget identity = Row(
          children: <Widget>[
            UserAvatar(
              avatarUrl: ownerAvatarUrl,
              fallbackText: repoRef.owner,
              size: RepositoryMd3Layout.avatarSize,
            ),
            const SizedBox(width: RepositoryMd3Layout.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: RepositoryMd3Layout.space8,
                    runSpacing: RepositoryMd3Layout.space4,
                    children: <Widget>[
                      Text(
                        repo?.name ?? preview?.name ?? repoRef.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Chip(
                        label: Text(
                          (repo?.isPrivate ?? preview?.isPrivate ?? false)
                              ? context.l10n.repoPrivate
                              : context.l10n.repoPublic,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (repo?.isArchived == true)
                        Chip(
                          label: Text(context.l10n.repoArchived),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  if (repo?.isFork == true && repo?.parent != null)
                    Text(
                      context.l10n.repoForkedFrom(repo!.parent!.nameWithOwner),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ],
        );
        final Widget actions = repo == null
            ? const _RepositoryActionsPlaceholder()
            : _RepositoryActions(
                repoRef: repoRef,
                repo: repo!,
                compact: compact,
                detailsReady: detailsReady,
              );
        return Padding(
          padding: RepositoryMd3Layout.pagePaddingFor(
            compact
                ? RepositoryWindowClass.compact
                : RepositoryWindowClass.medium,
          ),
          child: compact
              ? Align(alignment: Alignment.centerLeft, child: actions)
              : Row(
                  children: <Widget>[
                    Expanded(child: identity),
                    const SizedBox(width: RepositoryMd3Layout.space16),
                    actions,
                  ],
                ),
        );
      },
    );
  }
}

class _RepositoryActionsPlaceholder extends StatelessWidget {
  const _RepositoryActionsPlaceholder();

  @override
  Widget build(final BuildContext context) {
    final Color color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Wrap(
      spacing: RepositoryMd3Layout.space8,
      runSpacing: RepositoryMd3Layout.space8,
      children: <Widget>[
        for (final double width in <double>[116, 88, 96])
          Container(
            width: width,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
      ],
    );
  }
}

class _RepositoryActions extends ConsumerWidget {
  const _RepositoryActions({
    required this.repoRef,
    required this.repo,
    required this.compact,
    required this.detailsReady,
  });

  final RepoRef repoRef;
  final RepoCardData repo;
  final bool compact;
  final bool detailsReady;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final RepositoryNotifier notifier = ref.read(
      repositoryProvider(repoRef).notifier,
    );
    final bool isWatching =
        repo.viewerSubscription == SubscriptionState.SUBSCRIBED;
    return Wrap(
      alignment: compact ? WrapAlignment.start : WrapAlignment.end,
      spacing: RepositoryMd3Layout.space8,
      runSpacing: RepositoryMd3Layout.space8,
      children: <Widget>[
        MenuAnchor(
          menuChildren: <Widget>[
            MenuItemButton(
              leadingIcon: const Icon(Icons.notifications_active_outlined),
              onPressed: detailsReady
                  ? () => notifier.toggleWatch(SubscriptionState.SUBSCRIBED)
                  : null,
              child: Text(context.l10n.repoAllActivity),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.notifications_none),
              onPressed: detailsReady
                  ? () => notifier.toggleWatch(SubscriptionState.UNSUBSCRIBED)
                  : null,
              child: Text(context.l10n.repoNotWatching),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.notifications_off_outlined),
              onPressed: detailsReady
                  ? () => notifier.toggleWatch(SubscriptionState.IGNORED)
                  : null,
              child: Text(context.l10n.repoIgnore),
            ),
          ],
          builder:
              (
                final BuildContext context,
                final MenuController controller,
                final Widget? child,
              ) => OutlinedButton.icon(
                onPressed: detailsReady && repo.viewerCanSubscribe
                    ? () => controller.isOpen
                          ? controller.close()
                          : controller.open()
                    : null,
                icon: Icon(
                  isWatching
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                ),
                label: Text(
                  context.l10n.repoWatchCount(
                    _formatCount(repo.watchers.totalCount),
                  ),
                ),
              ),
        ),
        OutlinedButton.icon(
          onPressed: detailsReady && repo.forkingAllowed ? notifier.fork : null,
          icon: const Icon(Icons.call_split),
          label: Text(context.l10n.repoForkCount(_formatCount(repo.forkCount))),
        ),
        repo.viewerHasStarred
            ? FilledButton.tonalIcon(
                onPressed: detailsReady ? notifier.toggleStar : null,
                icon: const Icon(Icons.star),
                label: Text(
                  context.l10n.repoStarCount(_formatCount(repo.stargazerCount)),
                ),
              )
            : OutlinedButton.icon(
                onPressed: detailsReady ? notifier.toggleStar : null,
                icon: const Icon(Icons.star_border),
                label: Text(
                  context.l10n.repoStarCount(_formatCount(repo.stargazerCount)),
                ),
              ),
      ],
    );
  }
}

class _RepositoryNavigation extends StatelessWidget {
  const _RepositoryNavigation({required this.controller, required this.repo});

  final TabController controller;
  final RepoCardData? repo;

  @override
  Widget build(final BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: <Widget>[
        _RepositoryTabLabel(
          tab: _repositoryTabs[0],
          label: _repositoryTabLabel(context, 0),
        ),
        _RepositoryTabLabel(
          tab: _repositoryTabs[1],
          label: _repositoryTabLabel(context, 1),
          count: repo?.issues.totalCount,
        ),
        _RepositoryTabLabel(
          tab: _repositoryTabs[2],
          label: _repositoryTabLabel(context, 2),
          count: repo?.pullRequests.totalCount,
        ),
        for (int index = 3; index < _repositoryTabs.length; index++)
          _RepositoryTabLabel(
            tab: _repositoryTabs[index],
            label: _repositoryTabLabel(context, index),
          ),
      ],
    );
  }
}

class _RepositoryTabLabel extends StatelessWidget {
  const _RepositoryTabLabel({
    required this.tab,
    required this.label,
    this.count,
  });

  final _RepositoryTabData tab;
  final String label;
  final int? count;

  @override
  Widget build(final BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(tab.icon),
          const SizedBox(width: RepositoryMd3Layout.space8),
          Text(label),
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

class _RepositoryAboutPanel extends StatelessWidget {
  const _RepositoryAboutPanel({
    required this.repoRef,
    required this.repo,
    required this.details,
    this.embedded = false,
    this.scrollable = true,
  });

  final RepoRef repoRef;
  final RepoCardData? repo;
  final RepoInfo? details;
  final bool embedded;
  final bool scrollable;

  @override
  Widget build(final BuildContext context) {
    final RepoCardData? summary = repo;
    final RepoInfo? full = details;
    if (summary == null) {
      return _RepositoryAboutPlaceholder(embedded: embedded);
    }
    final Iterable<String> topics =
        summary.repositoryTopics.edges
            ?.map((final edge) => edge?.node?.topic.name)
            .whereType<String>() ??
        const <String>[];
    final List<LanguageBarEntry> languages = <LanguageBarEntry>[
      for (final Fragment$repoCardFields$languages$edges? edge
          in summary.languages?.edges ??
              const <Fragment$repoCardFields$languages$edges?>[])
        if (edge != null)
          LanguageBarEntry(
            name: edge.node.name,
            color: edge.node.color ?? '#6e7681',
            size: edge.size,
          ),
    ];
    final bool hasRepositoryActivity =
        full?.latestRelease != null ||
        (full?.releases.totalCount ?? 0) > 0 ||
        (full?.fundingLinks.isNotEmpty ?? false) ||
        languages.isNotEmpty;
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!embedded) ...<Widget>[
          Text(
            context.l10n.repoAbout,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: RepositoryMd3Layout.space16),
        ],
        Text(
          summary.description?.trim().isNotEmpty == true
              ? summary.description!
              : context.l10n.repoNoDescription,
          style: embedded ? Theme.of(context).textTheme.titleMedium : null,
        ),
        if (summary.homepageUrl != null)
          _AboutLink(
            icon: Icons.link,
            label: summary.homepageUrl.toString(),
            onTap: () => unawaited(launchUrl(summary.homepageUrl!)),
          ),
        if (summary.licenseInfo != null)
          _AboutLink(
            icon: Icons.balance_outlined,
            label: summary.licenseInfo!.name,
          ),
        if (full?.contributingGuidelines?.url != null)
          _AboutLink(
            icon: Icons.group_outlined,
            label: context.l10n.repoContributing,
            onTap: () =>
                unawaited(launchUrl(full!.contributingGuidelines!.url!)),
          ),
        if (full?.isSecurityPolicyEnabled == true)
          _AboutLink(
            icon: Icons.security_outlined,
            label: context.l10n.repoSecurityPolicy,
            onTap: () => unawaited(
              launchUrl(
                summary.url.replace(
                  path: '${summary.url.path}/security/policy',
                ),
              ),
            ),
          ),
        if (topics.isNotEmpty) ...<Widget>[
          const SizedBox(height: RepositoryMd3Layout.space12),
          Wrap(
            spacing: RepositoryMd3Layout.space8,
            runSpacing: RepositoryMd3Layout.space8,
            children: topics
                .map((final String topic) => Chip(label: Text(topic)))
                .toList(),
          ),
        ],
        const SizedBox(height: RepositoryMd3Layout.space12),
        Wrap(
          spacing: RepositoryMd3Layout.space16,
          runSpacing: RepositoryMd3Layout.space8,
          children: <Widget>[
            _AboutMetric(
              icon: Icons.star_border,
              label: context.l10n.repoStarsCount(
                _formatCount(summary.stargazerCount),
              ),
            ),
            _AboutMetric(
              icon: Icons.call_split,
              label: context.l10n.repoForksCount(
                _formatCount(summary.forkCount),
              ),
            ),
            _AboutMetric(
              icon: Icons.remove_red_eye_outlined,
              label: context.l10n.repoWatchingCount(
                _formatCount(summary.watchers.totalCount),
              ),
            ),
            if (full?.branchCount != null)
              _AboutMetric(
                icon: Icons.account_tree_outlined,
                label: context.l10n.repoBranchesCount(
                  _formatCount(full!.branchCount!.totalCount),
                ),
              ),
            if (full?.tagCount != null)
              _AboutMetric(
                icon: Icons.sell_outlined,
                label: context.l10n.repoTagsCount(
                  _formatCount(full!.tagCount!.totalCount),
                ),
              ),
          ],
        ),
        if (summary.primaryLanguage != null)
          _AboutLink(icon: Icons.code, label: summary.primaryLanguage!.name),
        if (summary.isFork && summary.parent != null)
          _AboutLink(
            icon: Icons.public,
            label:
                '${summary.isPrivate ? context.l10n.repoPrivate : context.l10n.repoPublic}'
                ' · ${context.l10n.repoForkedFrom(summary.parent!.nameWithOwner)}',
            onTap: () => unawaited(launchUrl(summary.parent!.url)),
          ),
        if (hasRepositoryActivity) const Divider(height: 32),
        if (full?.latestRelease != null ||
            (full?.releases.totalCount ?? 0) > 0) ...<Widget>[
          _AboutSectionHeading(
            title: context.l10n.repoReleases,
            count: full!.releases.totalCount,
          ),
          if (full.latestRelease case final release?)
            _AboutLink(
              icon: Icons.sell_outlined,
              label: release.name?.trim().isNotEmpty == true
                  ? release.name!
                  : release.tagName,
              supportingText: <String>[
                release.tagName,
                if (release.isLatest) context.l10n.repoLatest,
                if (release.publishedAt != null)
                  formatRelativeTime(context, release.publishedAt!),
              ].join(' · '),
              onTap: () => unawaited(launchUrl(release.url)),
            ),
        ],
        if (full?.fundingLinks.isNotEmpty ?? false) ...<Widget>[
          if (full!.latestRelease != null || full.releases.totalCount > 0)
            const Divider(height: 32),
          _AboutSectionHeading(title: context.l10n.repoSponsorProject),
          for (final fundingLink in full.fundingLinks)
            _AboutLink(
              icon: Icons.favorite_outline,
              label: _fundingPlatformLabel(context, fundingLink.platform),
              supportingText: fundingLink.url.host,
              onTap: () => unawaited(launchUrl(fundingLink.url)),
            ),
        ],
        _RepositoryContributorsSection(repoRef: repoRef),
        if (languages.isNotEmpty) ...<Widget>[
          const Divider(height: 32),
          _AboutSectionHeading(title: context.l10n.repoLanguages),
          const SizedBox(height: RepositoryMd3Layout.space8),
          MetadataLanguageBar(entries: languages),
        ],
      ],
    );
    if (embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          RepositoryMd3Layout.space16,
          RepositoryMd3Layout.space8,
          RepositoryMd3Layout.space16,
          RepositoryMd3Layout.space16,
        ),
        child: content,
      );
    }
    if (!scrollable) {
      return Padding(
        padding: const EdgeInsets.all(RepositoryMd3Layout.space16),
        child: content,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(RepositoryMd3Layout.space16),
      child: content,
    );
  }
}

class _RepositoryContributorsSection extends ConsumerWidget {
  const _RepositoryContributorsSection({required this.repoRef});

  final RepoRef repoRef;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<List<RepositoryContributorPreview>> contributors = ref
        .watch(repositoryContributorPreviewProvider(repoRef));
    return contributors.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Divider(height: 32),
          _AboutSectionHeading(title: context.l10n.repoContributors),
          const SizedBox(height: RepositoryMd3Layout.space12),
          const Wrap(
            spacing: RepositoryMd3Layout.space8,
            runSpacing: RepositoryMd3Layout.space8,
            children: <Widget>[
              _ContributorAvatarPlaceholder(),
              _ContributorAvatarPlaceholder(),
              _ContributorAvatarPlaceholder(),
              _ContributorAvatarPlaceholder(),
            ],
          ),
        ],
      ),
      error: (final Object error, final StackTrace stack) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Divider(height: 32),
          Row(
            children: <Widget>[
              Expanded(
                child: _AboutSectionHeading(
                  title: context.l10n.repoContributors,
                ),
              ),
              IconButton(
                tooltip: context.l10n.commonRetry,
                onPressed: () => ref.invalidate(
                  repositoryContributorPreviewProvider(repoRef),
                ),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ],
      ),
      data: (final List<RepositoryContributorPreview> items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Divider(height: 32),
            _AboutSectionHeading(title: context.l10n.repoContributors),
            const SizedBox(height: RepositoryMd3Layout.space12),
            Wrap(
              spacing: RepositoryMd3Layout.space8,
              runSpacing: RepositoryMd3Layout.space8,
              children: <Widget>[
                for (final RepositoryContributorPreview contributor in items)
                  Tooltip(
                    message:
                        '${contributor.login} · ${contributor.contributions}',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => UserRef(
                        login: contributor.login,
                      ).navigate(context, ref),
                      child: UserAvatar(
                        avatarUrl: contributor.avatarUrl,
                        fallbackText: contributor.login,
                        size: 36,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ContributorAvatarPlaceholder extends StatelessWidget {
  const _ContributorAvatarPlaceholder();

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

class _RepositoryAboutPlaceholder extends StatelessWidget {
  const _RepositoryAboutPlaceholder({required this.embedded});

  final bool embedded;

  @override
  Widget build(final BuildContext context) {
    final Color color = Theme.of(context).colorScheme.surfaceContainerHighest;
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!embedded) ...<Widget>[
          Text(
            context.l10n.repoAbout,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: RepositoryMd3Layout.space16),
        ],
        for (final double width in <double>[224, 252, 184, 216]) ...<Widget>[
          Container(
            width: width,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: RepositoryMd3Layout.space12),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.all(RepositoryMd3Layout.space16),
      child: content,
    );
  }
}

class _AboutSectionHeading extends StatelessWidget {
  const _AboutSectionHeading({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (count != null)
          Badge(
            label: Text(_formatCount(count!)),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            textColor: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      ],
    );
  }
}

class _AboutLink extends StatelessWidget {
  const _AboutLink({
    required this.icon,
    required this.label,
    this.supportingText,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? supportingText;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: RepositoryMd3Layout.space8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: RepositoryMd3Layout.space4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 20),
              const SizedBox(width: RepositoryMd3Layout.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: onTap == null
                          ? null
                          : TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                    if (supportingText != null)
                      Text(
                        supportingText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fundingPlatformLabel(
  final BuildContext context,
  final Enum$FundingPlatform platform,
) {
  return switch (platform) {
    Enum$FundingPlatform.BUY_ME_A_COFFEE => 'Buy Me a Coffee',
    Enum$FundingPlatform.COMMUNITY_BRIDGE => 'Community Bridge',
    Enum$FundingPlatform.GITHUB => 'GitHub Sponsors',
    Enum$FundingPlatform.ISSUEHUNT => 'IssueHunt',
    Enum$FundingPlatform.KO_FI => 'Ko-fi',
    Enum$FundingPlatform.LFX_CROWDFUNDING => 'LFX Crowdfunding',
    Enum$FundingPlatform.LIBERAPAY => 'Liberapay',
    Enum$FundingPlatform.OPEN_COLLECTIVE => 'Open Collective',
    Enum$FundingPlatform.PATREON => 'Patreon',
    Enum$FundingPlatform.POLAR => 'Polar',
    Enum$FundingPlatform.THANKS_DEV => 'thanks.dev',
    Enum$FundingPlatform.TIDELIFT => 'Tidelift',
    Enum$FundingPlatform.CUSTOM ||
    Enum$FundingPlatform.$unknown => context.l10n.repoFunding,
  };
}

class _AboutMetric extends StatelessWidget {
  const _AboutMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18),
        const SizedBox(width: RepositoryMd3Layout.space4),
        Text(label),
      ],
    );
  }
}

class _RepositoryPhasePlaceholder extends StatelessWidget {
  const _RepositoryPhasePlaceholder({
    required this.tabLabel,
    required this.onOpenLegacy,
  });

  final String tabLabel;
  final VoidCallback? onOpenLegacy;

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RepositoryMd3Layout.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.construction,
              size: RepositoryMd3Layout.statusIconSize,
            ),
            const SizedBox(height: RepositoryMd3Layout.space16),
            Text(
              context.l10n.repoNotMigrated(tabLabel),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RepositoryMd3Layout.space8),
            Text(context.l10n.repoPhaseCodeOnly, textAlign: TextAlign.center),
            if (onOpenLegacy != null) ...<Widget>[
              const SizedBox(height: RepositoryMd3Layout.space24),
              FilledButton.icon(
                onPressed: onOpenLegacy,
                icon: const Icon(Icons.history),
                label: Text(context.l10n.repoOpenLegacyLayout),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RepositoryTabData {
  const _RepositoryTabData(this.icon);

  final IconData icon;
}

const List<_RepositoryTabData> _repositoryTabs = <_RepositoryTabData>[
  _RepositoryTabData(Icons.code),
  _RepositoryTabData(Icons.adjust),
  _RepositoryTabData(Icons.call_merge),
  _RepositoryTabData(Icons.play_circle_outline),
  _RepositoryTabData(Icons.table_chart_outlined),
  _RepositoryTabData(Icons.shield_outlined),
  _RepositoryTabData(Icons.insights_outlined),
];

String _repositoryTabLabel(final BuildContext context, final int index) {
  return switch (index) {
    0 => context.l10n.repoCode,
    1 => context.l10n.repoIssues,
    2 => context.l10n.repoPullRequests,
    3 => context.l10n.repoActions,
    4 => context.l10n.repoProjects,
    5 => context.l10n.repoSecurity,
    6 => context.l10n.repoInsights,
    _ => '',
  };
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
