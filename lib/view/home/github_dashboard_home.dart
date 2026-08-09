import 'dart:async';

import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/models/github_changelog_item.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/models/repositories/public_repository.dart';
import 'package:diohub/providers/repository/public_repository_providers.dart';
import 'package:diohub/services/repositories/public_repository_service.dart';
import 'package:diohub/style/app_typography.dart';
import 'package:diohub/view/home/home_layout.dart';
import 'package:diohub/view/home/widgets/github_changelog_aside.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GitHubDashboardHome extends StatelessWidget {
  const GitHubDashboardHome({
    required this.account,
    required this.activityFeedSliver,
    required this.topRepositories,
    required this.changelog,
    required this.query,
    required this.desktop,
    required this.showAside,
    required this.onClearSearch,
    required this.onSelectSearchResult,
    required this.onOpenTopRepository,
    required this.onCreateRepository,
    required this.onRefreshTopRepositories,
    required this.onRefreshChangelog,
    required this.onOpenChangelogItem,
    required this.onOpenChangelog,
    required this.onRefreshActivity,
    required this.onLoadMoreActivity,
    required this.onSignIn,
    required this.onSwitchAccount,
    required this.onStagedAction,
    super.key,
  });

  final AccountModel? account;
  final Widget? activityFeedSliver;
  final AsyncValue<List<HomeRepositoryItem>> topRepositories;
  final AsyncValue<List<GitHubChangelogItem>> changelog;
  final String query;
  final bool desktop;
  final bool showAside;
  final VoidCallback onClearSearch;
  final ValueChanged<PublicRepositorySummary> onSelectSearchResult;
  final ValueChanged<HomeRepositoryItem> onOpenTopRepository;
  final Future<void> Function() onCreateRepository;
  final VoidCallback? onRefreshTopRepositories;
  final VoidCallback onRefreshChangelog;
  final ValueChanged<GitHubChangelogItem> onOpenChangelogItem;
  final VoidCallback onOpenChangelog;
  final Future<void> Function()? onRefreshActivity;
  final Future<bool> Function()? onLoadMoreActivity;
  final Future<void> Function() onSignIn;
  final VoidCallback onSwitchAccount;
  final ValueChanged<String> onStagedAction;

  @override
  Widget build(final BuildContext context) {
    final bool searching = query.isNotEmpty;
    final List<Widget> centerHeader = searching
        ? <Widget>[_SearchResultsHeader(query: query, onClose: onClearSearch)]
        : <Widget>[
            if (!desktop)
              _MobileAccountStrip(
                account: account,
                onSignIn: onSignIn,
                onSwitchAccount: onSwitchAccount,
              ),
            _HomeCenterIntro(
              account: account,
              onSignIn: onSignIn,
              onStagedAction: onStagedAction,
            ),
            if (!desktop)
              KeyedSubtree(
                key: const ValueKey<String>('home-mobile-top-repositories'),
                child: _TopRepositoriesPanel(
                  account: account,
                  repositories: topRepositories,
                  mobile: true,
                  onOpen: onOpenTopRepository,
                  onCreate: onCreateRepository,
                  onRefresh: onRefreshTopRepositories,
                  onSignIn: onSignIn,
                ),
              ),
          ];

    final Widget center = _HomeActivityPane(
      headerChildren: centerHeader,
      feedSliver: searching
          ? _RepositorySearchResultsSliver(
              query: query,
              account: account,
              onSelect: onSelectSearchResult,
              onSignIn: onSignIn,
            )
          : account == null
          ? _SignedOutFeed(onSignIn: onSignIn)
          : activityFeedSliver,
      showFeedHeader: !searching,
      onRefresh: searching ? null : onRefreshActivity,
      onLoadMore: searching || account == null ? null : onLoadMoreActivity,
    );

    if (!desktop) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: HomeLayout.compactContentMaxWidth,
          ),
          child: center,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: SizedBox(
            key: const ValueKey<String>('home-desktop-sidebar'),
            width: HomeLayout.persistentSidebarWidth,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: _TopRepositoriesPanel(
                account: account,
                repositories: topRepositories,
                showAccount: true,
                onOpen: onOpenTopRepository,
                onCreate: onCreateRepository,
                onRefresh: onRefreshTopRepositories,
                onSignIn: onSignIn,
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: center),
              if (showAside)
                SizedBox(
                  key: const ValueKey<String>('home-desktop-aside'),
                  width: HomeLayout.rightAsideWidth + 40,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                    child: GitHubChangelogAside(
                      items: changelog,
                      onRetry: onRefreshChangelog,
                      onOpenItem: onOpenChangelogItem,
                      onViewAll: onOpenChangelog,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileAccountStrip extends StatelessWidget {
  const _MobileAccountStrip({
    required this.account,
    required this.onSignIn,
    required this.onSwitchAccount,
  });

  final AccountModel? account;
  final Future<void> Function() onSignIn;
  final VoidCallback onSwitchAccount;

  @override
  Widget build(final BuildContext context) {
    final AccountModel? activeAccount = account;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: activeAccount == null
          ? Row(
              children: <Widget>[
                const CircleAvatar(
                  radius: 14,
                  child: Icon(Icons.public, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(context.l10n.homeBrowsingGitHubPublicly)),
                TextButton(
                  onPressed: () => unawaited(onSignIn()),
                  child: Text(context.l10n.commonSignIn),
                ),
              ],
            )
          : Semantics(
              key: const ValueKey<String>('home-mobile-account-switch'),
              container: true,
              button: true,
              label: context.l10n.accountSwitch,
              onTap: onSwitchAccount,
              child: ExcludeSemantics(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onSwitchAccount,
                    borderRadius: BorderRadius.circular(6),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
                        children: <Widget>[
                          UserAvatar(
                            avatarUrl: activeAccount.avatarUrl,
                            fallbackText: activeAccount.username,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              activeAccount.username,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _HomeCenterIntro extends StatelessWidget {
  const _HomeCenterIntro({
    required this.account,
    required this.onSignIn,
    required this.onStagedAction,
  });

  final AccountModel? account;
  final Future<void> Function() onSignIn;
  final ValueChanged<String> onStagedAction;

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(context.l10n.homeTitle, style: context.appTypography.pageTitle),
        const SizedBox(height: 20),
        _HomeCommandPanel(
          account: account,
          onSignIn: onSignIn,
          onStagedAction: onStagedAction,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _HomeCommandPanel extends StatelessWidget {
  const _HomeCommandPanel({
    required this.account,
    required this.onSignIn,
    required this.onStagedAction,
  });

  final AccountModel? account;
  final Future<void> Function() onSignIn;
  final ValueChanged<String> onStagedAction;

  void _activate(final String label) {
    if (account == null) {
      unawaited(onSignIn());
    } else {
      onStagedAction(label);
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Column(
      children: <Widget>[
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                InkWell(
                  onTap: () => _activate(context.l10n.homeAskAnything),
                  borderRadius: BorderRadius.circular(6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 72),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        context.l10n.homeAskAnything,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    IconButton(
                      key: const ValueKey<String>('home-command-ask'),
                      onPressed: () => _activate(context.l10n.homeAskAnything),
                      tooltip: context.l10n.homeAskAnything,
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    ),
                    IconButton(
                      key: const ValueKey<String>('home-command-add-context'),
                      onPressed: () => _activate(context.l10n.homeAddContext),
                      tooltip: context.l10n.homeAddContext,
                      icon: const Icon(Icons.add_box_outlined, size: 20),
                    ),
                    const Spacer(),
                    ConstrainedBox(
                      key: const ValueKey<String>('home-command-model'),
                      constraints: const BoxConstraints(minHeight: 48),
                      child: TextButton.icon(
                        onPressed: () =>
                            _activate(context.l10n.homeSelectModel),
                        icon: const Icon(Icons.smart_toy_outlined, size: 20),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(context.l10n.commonAuto),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey<String>('home-command-send'),
                      onPressed: () => _activate(context.l10n.homeSendPrompt),
                      tooltip: context.l10n.homeSendPrompt,
                      icon: const Icon(Icons.send_outlined, size: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: <Widget>[
            _DashboardActionButton(
              icon: Icons.support_agent_outlined,
              label: context.l10n.homeAgent,
              onPressed: () => _activate(context.l10n.homeAgent),
            ),
            _DashboardActionButton(
              icon: Icons.add_circle_outline,
              label: context.l10n.homeCreateIssue,
              onPressed: () => _activate(context.l10n.homeCreateIssue),
            ),
            _DashboardActionButton(
              icon: Icons.description_outlined,
              label: context.l10n.homeWriteCode,
              trailing: true,
              onPressed: () => _activate(context.l10n.homeWriteCode),
            ),
            _DashboardActionButton(
              icon: Icons.account_tree_outlined,
              label: 'Git',
              trailing: true,
              onPressed: () => _activate('Git'),
            ),
            _DashboardActionButton(
              icon: Icons.call_merge_outlined,
              label: context.l10n.homePullRequests,
              trailing: true,
              onPressed: () => _activate(context.l10n.homePullRequests),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardActionButton extends StatelessWidget {
  const _DashboardActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.trailing = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool trailing;

  @override
  Widget build(final BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 19),
          const SizedBox(width: 8),
          Flexible(child: Text(label, textAlign: TextAlign.center)),
          if (trailing) ...<Widget>[
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ],
      ),
    );
  }
}

class _TopRepositoriesPanel extends StatefulWidget {
  const _TopRepositoriesPanel({
    required this.account,
    required this.repositories,
    required this.onOpen,
    required this.onCreate,
    required this.onRefresh,
    required this.onSignIn,
    this.mobile = false,
    this.showAccount = false,
  });

  final AccountModel? account;
  final AsyncValue<List<HomeRepositoryItem>> repositories;
  final ValueChanged<HomeRepositoryItem> onOpen;
  final Future<void> Function() onCreate;
  final VoidCallback? onRefresh;
  final Future<void> Function() onSignIn;
  final bool mobile;
  final bool showAccount;

  @override
  State<_TopRepositoriesPanel> createState() => _TopRepositoriesPanelState();
}

class _TopRepositoriesPanelState extends State<_TopRepositoriesPanel> {
  String _filter = '';
  bool _showAll = false;

  @override
  Widget build(final BuildContext context) {
    final AccountModel? activeAccount = widget.account;
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.showAccount) ...<Widget>[
          if (activeAccount == null)
            Row(
              children: <Widget>[
                const CircleAvatar(
                  radius: 13,
                  child: Icon(Icons.public, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(context.l10n.homePublicBrowsing)),
              ],
            )
          else
            Row(
              children: <Widget>[
                UserAvatar(
                  avatarUrl: activeAccount.avatarUrl,
                  fallbackText: activeAccount.username,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    activeAccount.username,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          const SizedBox(height: 28),
        ],
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                context.l10n.homeTopRepositories,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (activeAccount != null)
              FilledButton.icon(
                onPressed: () => unawaited(widget.onCreate()),
                icon: const Icon(Icons.book_outlined, size: 17),
                label: Text(context.l10n.commonNew),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (activeAccount == null)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  Text(context.l10n.homeTopRepositoriesSignInBody),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => unawaited(widget.onSignIn()),
                    icon: const Icon(Icons.login),
                    label: Text(context.l10n.commonSignIn),
                  ),
                ],
              ),
            ),
          )
        else ...<Widget>[
          TextField(
            onChanged: (final String value) {
              setState(() {
                _filter = value.trim().toLowerCase();
                _showAll = false;
              });
            },
            decoration: InputDecoration(
              hintText: context.l10n.homeFindRepository,
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 19),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          widget.repositories.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: LinearProgressIndicator(),
            ),
            error: (final Object error, final StackTrace stack) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: <Widget>[
                  Text(context.l10n.homeRepositoriesLoadError),
                  if (widget.onRefresh != null)
                    TextButton(
                      onPressed: widget.onRefresh,
                      child: Text(context.l10n.commonRetry),
                    ),
                ],
              ),
            ),
            data: (final List<HomeRepositoryItem> repositories) {
              final List<HomeRepositoryItem> filtered = repositories
                  .where(
                    (final HomeRepositoryItem repository) =>
                        _filter.isEmpty ||
                        repository.fullName.toLowerCase().contains(_filter),
                  )
                  .toList();
              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(context.l10n.homeNoRepositoriesFound),
                );
              }
              final List<HomeRepositoryItem> visible = _showAll
                  ? filtered
                  : filtered.take(widget.mobile ? 6 : 8).toList();
              return Column(
                children: <Widget>[
                  for (final HomeRepositoryItem repository in visible)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      leading: UserAvatar(
                        avatarUrl: repository.ownerAvatarUrl,
                        fallbackText: repository.owner,
                        size: 20,
                      ),
                      title: Text(
                        repository.fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: repository.isPrivate
                          ? const Icon(Icons.lock_outline, size: 16)
                          : null,
                      onTap: () => widget.onOpen(repository),
                    ),
                  if (filtered.length > visible.length)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _showAll = true;
                          });
                        },
                        child: Text(context.l10n.commonShowMore),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );

    if (!widget.mobile) {
      return content;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(padding: const EdgeInsets.all(16), child: content),
      ),
    );
  }
}

class _SearchResultsHeader extends StatelessWidget {
  const _SearchResultsHeader({required this.query, required this.onClose});

  final String query;
  final VoidCallback onClose;

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.l10n.homeRepositorySearch,
                style: context.appTypography.pageTitle,
              ),
              Text(
                query,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          tooltip: context.l10n.homeCloseSearch,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class _RepositorySearchResultsSliver extends ConsumerWidget {
  const _RepositorySearchResultsSliver({
    required this.query,
    required this.account,
    required this.onSelect,
    required this.onSignIn,
  });

  final String query;
  final AccountModel? account;
  final ValueChanged<PublicRepositorySummary> onSelect;
  final Future<void> Function() onSignIn;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return ref
        .watch(publicRepositorySearchProvider(query))
        .when(
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (final Object error, final StackTrace stack) =>
              SliverFillRemaining(
                hasScrollBody: false,
                child: _DashboardSearchError(
                  message: publicGitHubErrorMessage(
                    error,
                    rateLimitMessage: context.l10n.publicGitHubRateLimitReached,
                  ),
                  onRetry: () =>
                      ref.invalidate(publicRepositorySearchProvider(query)),
                  onSignIn: account == null ? onSignIn : null,
                ),
              ),
          data: (final List<PublicRepositorySummary> repositories) {
            if (repositories.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(context.l10n.homeNoRepositoriesFound),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList.separated(
                itemCount: repositories.length,
                separatorBuilder:
                    (final BuildContext context, final int index) =>
                        const SizedBox(height: 8),
                itemBuilder: (final BuildContext context, final int index) {
                  final PublicRepositorySummary repository =
                      repositories[index];
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      onTap: () => onSelect(repository),
                      title: Text(repository.fullName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (repository.description != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                repository.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: <Widget>[
                              _DashboardRepositoryMetric(
                                icon: Icons.star_outline,
                                label: _dashboardCompactNumber(
                                  repository.stargazerCount,
                                ),
                              ),
                              _DashboardRepositoryMetric(
                                icon: Icons.call_split,
                                label: _dashboardCompactNumber(
                                  repository.forkCount,
                                ),
                              ),
                              if (repository.language != null)
                                _DashboardRepositoryMetric(
                                  icon: Icons.code,
                                  label: repository.language!,
                                ),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            );
          },
        );
  }
}

class _DashboardSearchError extends StatelessWidget {
  const _DashboardSearchError({
    required this.message,
    required this.onRetry,
    this.onSignIn,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<void> Function()? onSignIn;

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.commonRetry),
                ),
                if (onSignIn != null)
                  TextButton(
                    onPressed: () => unawaited(onSignIn!()),
                    child: Text(context.l10n.commonSignIn),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardRepositoryMetric extends StatelessWidget {
  const _DashboardRepositoryMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

String _dashboardCompactNumber(final int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}m';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
}

class _SignedOutFeed extends StatelessWidget {
  const _SignedOutFeed({required this.onSignIn});

  final Future<void> Function() onSignIn;

  @override
  Widget build(final BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                const Icon(Icons.dynamic_feed_outlined, size: 36),
                const SizedBox(height: 12),
                Text(
                  context.l10n.homeSignInToPersonalizeFeed,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.homePublicSearchAvailable,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => unawaited(onSignIn()),
                  icon: const Icon(Icons.login),
                  label: Text(context.l10n.commonSignIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeActivityPane extends StatefulWidget {
  const _HomeActivityPane({
    required this.headerChildren,
    required this.showFeedHeader,
    this.feedSliver,
    this.onRefresh,
    this.onLoadMore,
  });

  final List<Widget> headerChildren;
  final bool showFeedHeader;
  final Widget? feedSliver;
  final Future<void> Function()? onRefresh;
  final Future<bool> Function()? onLoadMore;

  @override
  State<_HomeActivityPane> createState() => _HomeActivityPaneState();
}

class _HomeActivityPaneState extends State<_HomeActivityPane> {
  static const double _prefetchExtent = 800;

  final ScrollController _scrollController = ScrollController();
  bool _loadMoreInFlight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybePrefetch);
    _schedulePrefetchCheck();
  }

  @override
  void didUpdateWidget(covariant final _HomeActivityPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onLoadMore != widget.onLoadMore ||
        oldWidget.feedSliver != widget.feedSliver) {
      _schedulePrefetchCheck();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_maybePrefetch)
      ..dispose();
    super.dispose();
  }

  void _schedulePrefetchCheck() {
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) {
        _maybePrefetch();
      }
    });
  }

  void _maybePrefetch() {
    final Future<bool> Function()? loadMore = widget.onLoadMore;
    if (loadMore == null ||
        _loadMoreInFlight ||
        !_scrollController.hasClients) {
      return;
    }
    final ScrollPosition position = _scrollController.position;
    if (!position.hasContentDimensions ||
        position.extentAfter > _prefetchExtent) {
      return;
    }

    _loadMoreInFlight = true;
    unawaited(_loadNextPage(loadMore));
  }

  Future<void> _loadNextPage(final Future<bool> Function() loadMore) async {
    bool hasMore = false;
    try {
      hasMore = await loadMore();
    } finally {
      _loadMoreInFlight = false;
    }
    if (mounted && hasMore) {
      _schedulePrefetchCheck();
    }
  }

  @override
  Widget build(final BuildContext context) {
    final double horizontalPadding =
        MediaQuery.sizeOf(context).width < HomeLayout.compactPaddingBreakpoint
        ? HomeLayout.mobileHorizontalPadding
        : HomeLayout.regularHorizontalPadding;
    final Widget scrollView = CustomScrollView(
      key: const ValueKey<String>('home-activity-feed'),
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        if (widget.headerChildren.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                28,
                horizontalPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.headerChildren,
              ),
            ),
          ),
        if (widget.showFeedHeader)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding - 8,
                8,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      context.l10n.homeFeed,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const _FeedFilterMenu(),
                  if (widget.onRefresh != null)
                    IconButton(
                      onPressed: () => unawaited(widget.onRefresh!()),
                      tooltip: context.l10n.homeRefreshActivity,
                      icon: const Icon(Icons.refresh),
                    ),
                ],
              ),
            ),
          ),
        widget.feedSliver ??
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(context.l10n.homeActivityNotConnected)),
            ),
      ],
    );
    final Future<void> Function()? refresh = widget.onRefresh;
    final Widget refreshable = refresh == null
        ? scrollView
        : RefreshIndicator(onRefresh: refresh, child: scrollView);
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (final ScrollMetricsNotification notification) {
        _schedulePrefetchCheck();
        return false;
      },
      child: refreshable,
    );
  }
}

class _FeedFilterMenu extends StatelessWidget {
  const _FeedFilterMenu();

  @override
  Widget build(final BuildContext context) {
    return MenuAnchor(
      menuChildren: <Widget>[
        MenuItemButton(
          leadingIcon: const Icon(Icons.check),
          child: Text(context.l10n.homeFollowingAndWatched),
        ),
      ],
      builder:
          (
            final BuildContext context,
            final MenuController controller,
            final Widget? child,
          ) => OutlinedButton.icon(
            onPressed: () {
              controller.isOpen ? controller.close() : controller.open();
            },
            icon: const Icon(Icons.filter_list, size: 18),
            label: Text(context.l10n.commonFilter),
          ),
    );
  }
}
