import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot.dart';
import 'package:diohub/models/repositories/repository_initial_state.dart';
import 'package:diohub/providers/entity_store_notifier.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/repository/md3/repository_code_md3.dart';
import 'package:diohub/view/repository/md3/repository_md3_layout.dart';
import 'package:diohub/view/repository/md3/repository_md3_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class RepositoryMd3Screen extends ConsumerStatefulWidget {
  const RepositoryMd3Screen({
    required this.repoRef,
    required this.repo,
    required this.initialState,
    required this.onOpenLegacy,
    super.key,
  });

  final RepoRef repoRef;
  final RepoInfo repo;
  final RepositoryInitialState initialState;
  final VoidCallback onOpenLegacy;

  @override
  ConsumerState<RepositoryMd3Screen> createState() =>
      _RepositoryMd3ScreenState();
}

class _RepositoryMd3ScreenState extends ConsumerState<RepositoryMd3Screen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _visitRecorded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _repositoryTabs.length,
      initialIndex: _initialTabIndex(widget.initialState.tabKind),
      vsync: this,
    )..addListener(_handleTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_visitRecorded) {
      _visitRecorded = true;
      ref
          .read(entityStoreMutatorProvider)
          .recordVisit(
            widget.repoRef,
            snapshot: EntitySnapshot(title: widget.repo.name),
          );
    }
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      setState(() {});
    }
  }

  Future<void> _refresh() async {
    await ref.read(repositoryProvider(widget.repoRef).notifier).refresh();
    if (!mounted) {
      return;
    }
    await refreshRepositoryCode(ref, widget.repoRef);
  }

  void _openSearch() {
    context.router.push(
      SearchRoute(initialQuery: 'repo:${widget.repo.nameWithOwner} '),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final RepoInfo repo = ref.watch(
      repositoryProvider(widget.repoRef).select(
        (final AsyncValue<RepoInfoData> value) =>
            value.value?.repository ?? widget.repo,
      ),
    );
    final String? ownerAvatarUrl = repo.owner.maybeWhen(
      user: (final user) => user.avatarUrl.toString(),
      organization: (final organization) => organization.avatarUrl.toString(),
      orElse: () => null,
    );
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final RepositoryWindowClass windowClass =
            RepositoryMd3Layout.windowClassFor(constraints.maxWidth);
        final bool showInlineAbout =
            windowClass != RepositoryWindowClass.expanded;
        return RepositoryMd3Shell(
          repositoryLabel: repo.nameWithOwner,
          onBack: () => context.router.maybePop(),
          onSearch: _openSearch,
          onRefresh: _refresh,
          onOpenLegacy: widget.onOpenLegacy,
          header: _RepositoryIdentityHeader(
            repoRef: widget.repoRef,
            repo: repo,
            ownerAvatarUrl: ownerAvatarUrl,
          ),
          repositoryNavigation: _RepositoryNavigation(
            controller: _tabController,
            repo: repo,
          ),
          body: _buildSelectedBody(
            repo,
            inlineAbout: showInlineAbout
                ? _RepositoryAboutPanel(repo: repo, embedded: true)
                : null,
          ),
          aside: _RepositoryAboutPanel(repo: repo),
        );
      },
    );
  }

  Widget _buildSelectedBody(
    final RepoInfo repo, {
    required final Widget? inlineAbout,
  }) {
    if (_tabController.index == 0) {
      return RepositoryCodeMd3(
        repoRef: widget.repoRef,
        repo: repo,
        inlineAbout: inlineAbout,
      );
    }
    return _RepositoryPhasePlaceholder(
      tabLabel: _repositoryTabs[_tabController.index].label,
      onOpenLegacy: widget.onOpenLegacy,
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
    required this.ownerAvatarUrl,
  });

  final RepoRef repoRef;
  final RepoInfo repo;
  final String? ownerAvatarUrl;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final bool compact =
            constraints.maxWidth < RepositoryMd3Layout.compactBreakpoint;
        final Widget identity = Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UserAvatar(
              avatarUrl: ownerAvatarUrl,
              size: RepositoryMd3Layout.avatarSize,
            ),
            const SizedBox(width: RepositoryMd3Layout.space12),
            Flexible(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: RepositoryMd3Layout.space4,
                runSpacing: RepositoryMd3Layout.space4,
                children: <Widget>[
                  Text(
                    repoRef.owner,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('/', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    repoRef.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Chip(
                    label: Text(repo.isPrivate ? 'Private' : 'Public'),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (repo.isArchived)
                    const Chip(
                      label: Text('Archived'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ],
        );
        final Widget actions = _RepositoryActions(repoRef: repoRef, repo: repo);
        return Padding(
          padding: RepositoryMd3Layout.pagePaddingFor(
            compact
                ? RepositoryWindowClass.compact
                : RepositoryWindowClass.medium,
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    identity,
                    const SizedBox(height: RepositoryMd3Layout.space12),
                    actions,
                  ],
                )
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

class _RepositoryActions extends ConsumerWidget {
  const _RepositoryActions({required this.repoRef, required this.repo});

  final RepoRef repoRef;
  final RepoInfo repo;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final RepositoryNotifier notifier = ref.read(
      repositoryProvider(repoRef).notifier,
    );
    final bool isWatching =
        repo.viewerSubscription == SubscriptionState.SUBSCRIBED;
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: RepositoryMd3Layout.space8,
      runSpacing: RepositoryMd3Layout.space8,
      children: <Widget>[
        MenuAnchor(
          menuChildren: <Widget>[
            MenuItemButton(
              leadingIcon: const Icon(Icons.notifications_active_outlined),
              onPressed: () =>
                  notifier.toggleWatch(SubscriptionState.SUBSCRIBED),
              child: const Text('All activity'),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.notifications_none),
              onPressed: () =>
                  notifier.toggleWatch(SubscriptionState.UNSUBSCRIBED),
              child: const Text('Not watching'),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.notifications_off_outlined),
              onPressed: () => notifier.toggleWatch(SubscriptionState.IGNORED),
              child: const Text('Ignore'),
            ),
          ],
          builder:
              (
                final BuildContext context,
                final MenuController controller,
                final Widget? child,
              ) => OutlinedButton.icon(
                onPressed: repo.viewerCanSubscribe
                    ? () => controller.isOpen
                          ? controller.close()
                          : controller.open()
                    : null,
                icon: Icon(
                  isWatching
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                ),
                label: Text('Watch ${_formatCount(repo.watchers.totalCount)}'),
              ),
        ),
        OutlinedButton.icon(
          onPressed: repo.forkingAllowed ? notifier.fork : null,
          icon: const Icon(Icons.call_split),
          label: Text('Fork ${_formatCount(repo.forkCount)}'),
        ),
        repo.viewerHasStarred
            ? FilledButton.tonalIcon(
                onPressed: notifier.toggleStar,
                icon: const Icon(Icons.star),
                label: Text('Star ${_formatCount(repo.stargazerCount)}'),
              )
            : OutlinedButton.icon(
                onPressed: notifier.toggleStar,
                icon: const Icon(Icons.star_border),
                label: Text('Star ${_formatCount(repo.stargazerCount)}'),
              ),
      ],
    );
  }
}

class _RepositoryNavigation extends StatelessWidget {
  const _RepositoryNavigation({required this.controller, required this.repo});

  final TabController controller;
  final RepoInfo repo;

  @override
  Widget build(final BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: <Widget>[
        _RepositoryTabLabel(tab: _repositoryTabs[0]),
        _RepositoryTabLabel(
          tab: _repositoryTabs[1],
          count: repo.issues.totalCount,
        ),
        _RepositoryTabLabel(
          tab: _repositoryTabs[2],
          count: repo.pullRequests.totalCount,
        ),
        ..._repositoryTabs
            .skip(3)
            .map(
              (final _RepositoryTabData tab) => _RepositoryTabLabel(tab: tab),
            ),
      ],
    );
  }
}

class _RepositoryTabLabel extends StatelessWidget {
  const _RepositoryTabLabel({required this.tab, this.count});

  final _RepositoryTabData tab;
  final int? count;

  @override
  Widget build(final BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(tab.icon),
          const SizedBox(width: RepositoryMd3Layout.space8),
          Text(tab.label),
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
  const _RepositoryAboutPanel({required this.repo, this.embedded = false});

  final RepoInfo repo;
  final bool embedded;

  @override
  Widget build(final BuildContext context) {
    final Iterable<String> topics =
        repo.repositoryTopics.edges
            ?.map((final RepoTopicEdge? edge) => edge?.node?.topic.name)
            .whereType<String>() ??
        const <String>[];
    return ListView(
      primary: false,
      shrinkWrap: embedded,
      physics: embedded ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(RepositoryMd3Layout.space16),
      children: <Widget>[
        Text('About', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: RepositoryMd3Layout.space12),
        Text(
          repo.description?.trim().isNotEmpty == true
              ? repo.description!
              : 'No description provided.',
        ),
        if (repo.homepageUrl != null) ...<Widget>[
          const SizedBox(height: RepositoryMd3Layout.space8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => launchUrl(repo.homepageUrl!),
              icon: const Icon(Icons.link),
              label: Text(
                repo.homepageUrl.toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
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
        const SizedBox(height: RepositoryMd3Layout.space16),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.star_border),
          title: Text('${_formatCount(repo.stargazerCount)} stars'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.remove_red_eye_outlined),
          title: Text('${_formatCount(repo.watchers.totalCount)} watching'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.call_split),
          title: Text('${_formatCount(repo.forkCount)} forks'),
        ),
        if (repo.licenseInfo != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.balance_outlined),
            title: Text(repo.licenseInfo!.name),
          ),
        if (repo.primaryLanguage != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.code),
            title: Text(repo.primaryLanguage!.name),
          ),
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
  final VoidCallback onOpenLegacy;

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
              '$tabLabel is not migrated yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RepositoryMd3Layout.space8),
            const Text(
              'This phase only rewrites the Repository Code page. '
              'Use the legacy layout for the existing implementation.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RepositoryMd3Layout.space24),
            FilledButton.icon(
              onPressed: onOpenLegacy,
              icon: const Icon(Icons.history),
              label: const Text('Open legacy layout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepositoryTabData {
  const _RepositoryTabData(this.label, this.icon);

  final String label;
  final IconData icon;
}

const List<_RepositoryTabData> _repositoryTabs = <_RepositoryTabData>[
  _RepositoryTabData('Code', Icons.code),
  _RepositoryTabData('Issues', Icons.adjust),
  _RepositoryTabData('Pull requests', Icons.call_merge),
  _RepositoryTabData('Actions', Icons.play_circle_outline),
  _RepositoryTabData('Projects', Icons.table_chart_outlined),
  _RepositoryTabData('Security', Icons.shield_outlined),
  _RepositoryTabData('Insights', Icons.insights_outlined),
];

String _formatCount(final int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}m';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k';
  }
  return '$value';
}
