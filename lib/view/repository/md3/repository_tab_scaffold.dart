import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/view/repository/md3/repository_md3_layout.dart';
import 'package:flutter/material.dart';

/// Shared responsive structure for repository secondary tabs.
///
/// The global app/repository chrome remains owned by the repository MD3 shell.
/// This widget only models a page-local navigation pane such as the workflow
/// list used by Actions or the Insights report selector.
class RepositoryTabScaffold extends StatelessWidget {
  const RepositoryTabScaffold({
    required this.title,
    required this.slivers,
    this.navigation,
    this.compactNavigation,
    this.actions = const <Widget>[],
    this.refreshing = false,
    this.onRefresh,
    super.key,
  });

  final String title;
  final List<Widget> slivers;
  final Widget? navigation;
  final Widget? compactNavigation;
  final List<Widget> actions;
  final bool refreshing;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final bool showNavigation =
            navigation != null &&
            constraints.maxWidth >=
                RepositoryMd3Layout.inlineCodeToolbarBreakpoint;
        final Widget content = RefreshIndicator(
          onRefresh: onRefresh ?? () async {},
          notificationPredicate: (final ScrollNotification notification) =>
              notification.depth == 0,
          child: CustomScrollView(
            key: PageStorageKey<String>('repository-tab-$title'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverPadding(
                padding: RepositoryMd3Layout.pagePaddingFor(
                  RepositoryMd3Layout.windowClassFor(
                    showNavigation
                        ? constraints.maxWidth - _navigationWidth
                        : constraints.maxWidth,
                  ),
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (actions.isNotEmpty)
                            Wrap(
                              spacing: RepositoryMd3Layout.space8,
                              runSpacing: RepositoryMd3Layout.space8,
                              children: actions,
                            ),
                        ],
                      ),
                      if (compactNavigation != null && !showNavigation) ...[
                        const SizedBox(height: RepositoryMd3Layout.space16),
                        compactNavigation!,
                      ],
                    ],
                  ),
                ),
              ),
              if (refreshing)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              ...slivers,
            ],
          ),
        );
        if (!showNavigation) {
          return content;
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(width: _navigationWidth, child: navigation),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        );
      },
    );
  }

  static const double _navigationWidth = 264;
}

class RepositoryTabNavigation extends StatelessWidget {
  const RepositoryTabNavigation({
    required this.title,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final String title;
  final List<RepositoryTabNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(final BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(RepositoryMd3Layout.space12),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            RepositoryMd3Layout.space12,
            RepositoryMd3Layout.space8,
            RepositoryMd3Layout.space12,
            RepositoryMd3Layout.space12,
          ),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        for (int index = 0; index < destinations.length; index++)
          ListTile(
            selected: index == selectedIndex,
            leading: Icon(destinations[index].icon),
            title: Text(destinations[index].label),
            onTap: () => onSelected(index),
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                RepositoryMd3Layout.sectionRadius,
              ),
            ),
          ),
      ],
    );
  }
}

class RepositoryTabNavigationDestination {
  const RepositoryTabNavigationDestination({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class RepositoryTabStateCard extends StatelessWidget {
  const RepositoryTabStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(final BuildContext context) {
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 208),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(RepositoryMd3Layout.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: RepositoryMd3Layout.statusIconSize,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: RepositoryMd3Layout.space12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: RepositoryMd3Layout.space8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (action != null) ...<Widget>[
                  const SizedBox(height: RepositoryMd3Layout.space16),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RepositoryTabSignInState extends StatelessWidget {
  const RepositoryTabSignInState({required this.onSignIn, super.key});

  final VoidCallback onSignIn;

  @override
  Widget build(final BuildContext context) {
    return RepositoryTabStateCard(
      icon: Icons.lock_outline,
      title: context.l10n.repoSignInRequired,
      message: context.l10n.repoSecondaryTabSignInBody,
      action: FilledButton.icon(
        onPressed: onSignIn,
        icon: const Icon(Icons.login),
        label: Text(context.l10n.commonSignIn),
      ),
    );
  }
}
