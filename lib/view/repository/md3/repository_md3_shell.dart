import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/view/app_chrome/app_chrome.dart';
import 'package:diohub/view/app_chrome/global_header.dart';
import 'package:diohub/view/repository/md3/repository_md3_layout.dart';
import 'package:diohub/view/repository/md3/repository_md3_theme.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared GitHub-style responsive shell for migrated Repository pages.
///
/// It owns the global app bar, repository navigation, and desktop aside. All
/// repository data and mutations remain in the existing providers/page widgets.
class RepositoryMd3Shell extends StatelessWidget {
  const RepositoryMd3Shell({
    required this.repositoryLabel,
    required this.repositoryNavigation,
    required this.body,
    required this.onRefresh,
    required this.onOpenLegacy,
    required this.onGlobalSearch,
    required this.onSearchRepositories,
    required this.account,
    required this.accountLoading,
    required this.topRepositories,
    this.header,
    this.aside,
    super.key,
  });

  final String repositoryLabel;
  final Widget? header;
  final Widget repositoryNavigation;
  final Widget body;
  final Widget? aside;
  final VoidCallback onRefresh;
  final VoidCallback? onOpenLegacy;
  final ValueChanged<String?> onGlobalSearch;
  final VoidCallback onSearchRepositories;
  final AccountModel? account;
  final bool accountLoading;
  final AsyncValue<List<HomeRepositoryItem>> topRepositories;

  @override
  Widget build(final BuildContext context) {
    final ThemeData repositoryTheme = repositoryMd3ThemeFor(Theme.of(context));
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final RepositoryWindowClass windowClass =
            RepositoryMd3Layout.windowClassFor(constraints.maxWidth);
        return _RepositoryScaffold(
          windowClass: windowClass,
          repositoryTheme: repositoryTheme,
          repositoryLabel: repositoryLabel,
          header: header,
          repositoryNavigation: repositoryNavigation,
          body: body,
          aside: aside,
          onRefresh: onRefresh,
          onOpenLegacy: onOpenLegacy,
          onGlobalSearch: onGlobalSearch,
          onSearchRepositories: onSearchRepositories,
          account: account,
          accountLoading: accountLoading,
          topRepositories: topRepositories,
        );
      },
    );
  }
}

class _RepositoryScaffold extends StatelessWidget {
  const _RepositoryScaffold({
    required this.windowClass,
    required this.repositoryTheme,
    required this.repositoryLabel,
    required this.repositoryNavigation,
    required this.body,
    required this.onRefresh,
    required this.onOpenLegacy,
    required this.onGlobalSearch,
    required this.onSearchRepositories,
    required this.account,
    required this.accountLoading,
    required this.topRepositories,
    this.header,
    this.aside,
  });

  final RepositoryWindowClass windowClass;
  final ThemeData repositoryTheme;
  final String repositoryLabel;
  final Widget? header;
  final Widget repositoryNavigation;
  final Widget body;
  final Widget? aside;
  final VoidCallback onRefresh;
  final VoidCallback? onOpenLegacy;
  final ValueChanged<String?> onGlobalSearch;
  final VoidCallback onSearchRepositories;
  final AccountModel? account;
  final bool accountLoading;
  final AsyncValue<List<HomeRepositoryItem>> topRepositories;

  bool get _isExpanded => windowClass == RepositoryWindowClass.expanded;
  List<String> get _repositoryParts => repositoryLabel.split('/');

  @override
  Widget build(final BuildContext context) {
    return AppChrome(
      account: account,
      accountLoading: accountLoading,
      topRepositories: topRepositories,
      onGlobalSearch: onGlobalSearch,
      onSearchRepositories: onSearchRepositories,
      title: GlobalHeaderTitle(
        owner: _repositoryParts.length > 1 ? _repositoryParts.first : null,
        title: _repositoryParts.last,
        compact: !_isExpanded,
        trailing: const Icon(Icons.arrow_drop_down, size: 20),
      ),
      pageActions: <Widget>[
        if (windowClass != RepositoryWindowClass.compact)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.l10n.repoRefreshRepository,
            onPressed: onRefresh,
          ),
        PopupMenuButton<_RepositoryMenuAction>(
          tooltip: context.l10n.repoOptions,
          onSelected: (final _RepositoryMenuAction value) {
            switch (value) {
              case _RepositoryMenuAction.refresh:
                onRefresh();
              case _RepositoryMenuAction.legacy:
                onOpenLegacy?.call();
            }
          },
          itemBuilder: (final BuildContext context) =>
              <PopupMenuEntry<_RepositoryMenuAction>>[
                if (windowClass == RepositoryWindowClass.compact)
                  PopupMenuItem<_RepositoryMenuAction>(
                    value: _RepositoryMenuAction.refresh,
                    child: Text(context.l10n.repoRefreshRepository),
                  ),
                if (onOpenLegacy != null)
                  PopupMenuItem<_RepositoryMenuAction>(
                    value: _RepositoryMenuAction.legacy,
                    child: Text(context.l10n.repoOpenLegacyLayout),
                  ),
              ],
        ),
      ],
      secondaryNavigation: Theme(
        data: repositoryTheme,
        child: repositoryNavigation,
      ),
      body: Theme(
        data: repositoryTheme,
        child: Center(
          child: ConstrainedBox(
            key: ValueKey<String>('repository-md3-${windowClass.name}'),
            constraints: const BoxConstraints(
              maxWidth: RepositoryMd3Layout.contentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (header != null) ...<Widget>[header!, const Divider()],
                Expanded(
                  child: _isExpanded && aside != null
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(child: body),
                            const VerticalDivider(),
                            SizedBox(
                              key: const ValueKey<String>(
                                'repository-md3-about-panel',
                              ),
                              width: RepositoryMd3Layout.asideWidth,
                              child: aside,
                            ),
                          ],
                        )
                      : body,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _RepositoryMenuAction { refresh, legacy }
