import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/dashboard/home_top_repositories_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/repository/md3/repository_md3_shell.dart';
import 'package:diohub/view/repository/md3/repository_navigation.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stable global/repository chrome for standalone repository-scoped routes.
///
/// Issue, pull request, and wiki details keep their existing domain providers
/// and content widgets. This wrapper only owns shared app chrome and
/// repository-level navigation.
class RepositoryContextChrome extends ConsumerWidget {
  const RepositoryContextChrome({
    required this.repoRef,
    required this.selectedDestination,
    required this.body,
    required this.onRefresh,
    super.key,
  });

  final RepoRef repoRef;
  final RepositoryNavigationDestination selectedDestination;
  final Widget body;
  final VoidCallback onRefresh;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final accountState = ref.watch(accountProvider);
    final bool accountResolved =
        accountState.hasValue && !accountState.hasError;
    final account = accountResolved
        ? accountState.value?.activeAccountModel
        : null;
    final AsyncValue<List<HomeRepositoryItem>> topRepositories = account == null
        ? const AsyncData<List<HomeRepositoryItem>>(<HomeRepositoryItem>[])
        : ref.watch(
            homeTopRepositoriesProvider((
              accountKey: account.accountKey,
              login: account.username,
            )),
          );

    return DefaultTabController(
      length: RepositoryNavigationDestination.values.length,
      initialIndex: selectedDestination.index,
      child: RepositoryMd3Shell(
        repositoryLabel: repoRef.fullName,
        account: account,
        accountLoading: !accountResolved,
        topRepositories: topRepositories,
        repositoryNavigation: Builder(
          builder: (final BuildContext navigationContext) =>
              RepositoryNavigationBar(
                onSelected:
                    (final RepositoryNavigationDestination destination) =>
                        _openDestination(navigationContext, destination),
              ),
        ),
        body: body,
        onGlobalSearch: (final String? query) {
          final String normalized = query?.trim() ?? '';
          final String qualifier = 'repo:${repoRef.fullName}';
          unawaited(
            context.router.push<void>(
              SearchRoute(
                initialQuery: normalized.isEmpty
                    ? '$qualifier '
                    : '$qualifier $normalized',
              ),
            ),
          );
        },
        onSearchRepositories: () => unawaited(
          context.router.push<void>(
            SearchRoute(initialQuery: 'type:repository '),
          ),
        ),
        onRefresh: onRefresh,
        onOpenLegacy: null,
      ),
    );
  }

  void _openDestination(
    final BuildContext context,
    final RepositoryNavigationDestination destination,
  ) {
    final RepoLocation? location = switch (destination) {
      RepositoryNavigationDestination.code => const RepoLocation.root(),
      RepositoryNavigationDestination.issues => const RepoLocation.issues(),
      RepositoryNavigationDestination.pullRequests =>
        const RepoLocation.pulls(),
      RepositoryNavigationDestination.actions => const RepoLocation.actions(),
      RepositoryNavigationDestination.projects => const RepoLocation.projects(),
      RepositoryNavigationDestination.wiki => const RepoLocation.wiki(),
      RepositoryNavigationDestination.security => const RepoLocation.security(),
      RepositoryNavigationDestination.insights => const RepoLocation.insights(),
    };
    unawaited(
      context.router.replace<void>(
        RepositoryRoute(repo: repoRef.copyWith(location: location)),
      ),
    );
  }
}
