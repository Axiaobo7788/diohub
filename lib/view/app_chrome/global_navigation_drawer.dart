import 'dart:async';

import 'package:diohub/common/const/app_info.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/view/app_chrome/app_chrome_layout.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GlobalNavigationDestination { home, issues, pullRequests, repositories }

/// GitHub-style global navigation shared by Home and Repository pages.
class GlobalNavigationDrawer extends StatelessWidget {
  const GlobalNavigationDrawer({
    required this.account,
    required this.topRepositories,
    required this.onDestination,
    required this.onSearchRepositories,
    required this.onSignIn,
    required this.onOpenTopRepository,
    required this.onStagedAction,
    this.selectedDestination,
    super.key,
  });

  final AccountModel? account;
  final AsyncValue<List<HomeRepositoryItem>> topRepositories;
  final GlobalNavigationDestination? selectedDestination;
  final ValueChanged<GlobalNavigationDestination> onDestination;
  final VoidCallback onSearchRepositories;
  final Future<void> Function() onSignIn;
  final ValueChanged<HomeRepositoryItem> onOpenTopRepository;
  final ValueChanged<String> onStagedAction;

  void _close(final BuildContext context) => Navigator.of(context).pop();

  void _closeThen(final BuildContext context, final VoidCallback action) {
    _close(context);
    action();
  }

  @override
  Widget build(final BuildContext context) {
    final double width = AppChromeLayout.drawerWidthFor(
      MediaQuery.sizeOf(context).width,
    );
    return SizedBox(
      width: width,
      child: NavigationDrawer(
        key: const ValueKey<String>('global-navigation-drawer'),
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              child: Row(
                children: <Widget>[
                  const AppLogoWidget(size: 32),
                  const SizedBox(width: 12),
                  Text(
                    context.l10n.appName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _close(context),
                    tooltip: context.l10n.navClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          _DrawerNavigationTile(
            key: const ValueKey<String>('global-nav-home'),
            icon: Icons.home_outlined,
            label: context.l10n.homeTitle,
            selected: selectedDestination == GlobalNavigationDestination.home,
            onTap: () => _closeThen(
              context,
              () => onDestination(GlobalNavigationDestination.home),
            ),
          ),
          _DrawerNavigationTile(
            key: const ValueKey<String>('global-nav-issues'),
            icon: Icons.adjust_outlined,
            label: context.l10n.navAllIssues,
            selected: selectedDestination == GlobalNavigationDestination.issues,
            onTap: () => _closeThen(
              context,
              () => onDestination(GlobalNavigationDestination.issues),
            ),
          ),
          _DrawerNavigationTile(
            key: const ValueKey<String>('global-nav-pull-requests'),
            icon: Icons.call_merge_outlined,
            label: context.l10n.navAllPullRequests,
            selected:
                selectedDestination == GlobalNavigationDestination.pullRequests,
            onTap: () => _closeThen(
              context,
              () => onDestination(GlobalNavigationDestination.pullRequests),
            ),
          ),
          _DrawerNavigationTile(
            key: const ValueKey<String>('global-nav-repositories'),
            icon: Icons.book_outlined,
            label: context.l10n.navAllRepositories,
            selected:
                selectedDestination == GlobalNavigationDestination.repositories,
            onTap: () => _closeThen(
              context,
              () => onDestination(GlobalNavigationDestination.repositories),
            ),
          ),
          for (final (IconData, String) destination in <(IconData, String)>[
            (Icons.grid_view_outlined, context.l10n.navProjects),
            (Icons.forum_outlined, context.l10n.navDiscussions),
            (Icons.computer_outlined, context.l10n.navCodespaces),
            (Icons.smart_toy_outlined, context.l10n.navCopilot),
          ])
            _DrawerNavigationTile(
              icon: destination.$1,
              label: destination.$2,
              onTap: () =>
                  _closeThen(context, () => onStagedAction(destination.$2)),
            ),
          const Divider(),
          for (final (IconData, String) destination in <(IconData, String)>[
            (Icons.explore_outlined, context.l10n.navExplore),
            (Icons.storefront_outlined, context.l10n.navMarketplace),
            (Icons.hub_outlined, context.l10n.navMcpRegistry),
          ])
            _DrawerNavigationTile(
              icon: destination.$1,
              label: destination.$2,
              onTap: () =>
                  _closeThen(context, () => onStagedAction(destination.$2)),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.l10n.homeTopRepositories,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _closeThen(context, onSearchRepositories),
                  tooltip: context.l10n.homeFindRepositoryTooltip,
                  icon: const Icon(Icons.search, size: 20),
                ),
              ],
            ),
          ),
          if (account == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: OutlinedButton.icon(
                onPressed: () {
                  _close(context);
                  unawaited(onSignIn());
                },
                icon: const Icon(Icons.login),
                label: Text(context.l10n.homeSignInToPersonalize),
              ),
            )
          else
            topRepositories.when(
              loading: () => const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: LinearProgressIndicator(),
              ),
              error: (final Object error, final StackTrace stackTrace) =>
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Text(context.l10n.homeTopRepositoriesUnavailable),
                  ),
              data: (final List<HomeRepositoryItem> repositories) => Column(
                children: <Widget>[
                  for (final HomeRepositoryItem repository in repositories.take(
                    6,
                  ))
                    ListTile(
                      dense: true,
                      minTileHeight: 48,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      leading: UserAvatar(
                        avatarUrl: repository.ownerAvatarUrl,
                        fallbackText: repository.owner,
                        size: 20,
                      ),
                      title: Text(
                        repository.fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: repository.isPrivate
                          ? const Icon(Icons.lock_outline, size: 15)
                          : null,
                      onTap: () => _closeThen(
                        context,
                        () => onOpenTopRepository(repository),
                      ),
                    ),
                  if (repositories.length > 6)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        child: TextButton(
                          onPressed: () =>
                              _closeThen(context, onSearchRepositories),
                          child: Text(context.l10n.commonShowMore),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DrawerNavigationTile extends StatelessWidget {
  const _DrawerNavigationTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
    child: ListTile(
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
      selectedColor: Theme.of(context).colorScheme.onSecondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(icon, size: 21),
      title: Text(label),
      onTap: onTap,
    ),
  );
}
