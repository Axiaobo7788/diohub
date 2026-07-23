import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/events/events.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/dashboard/home_top_repositories_provider.dart';
import 'package:diohub/providers/database_providers.dart'
    show authenticatedSessionProvider;
import 'package:diohub/providers/router_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/providers/watchers/watcher_manager_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/services/watchers/background_watcher_service.dart';
import 'package:diohub/utils/fire_and_forget.dart';
import 'package:diohub/view/app_chrome/global_account_actions.dart';
import 'package:diohub/view/home/unified_home_screen.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:diohub_models/models/authentication/authenticated_session.dart';
import 'package:diohub_models/models/home_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.initialTabPath, this.filter});

  /// Retained for route compatibility while legacy home tabs are migrated.
  final String? initialTabPath;
  final HomeFilter? filter;

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final ValueNotifier<Future<void> Function()?> _feedRefreshRegistrar =
      ValueNotifier<Future<void> Function()?>(null);
  final ValueNotifier<ActivityLoadMoreCallback?> _feedLoadMoreRegistrar =
      ValueNotifier<ActivityLoadMoreCallback?>(null);
  String? _watcherAccountKey;
  bool _watcherServiceStarted = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _startAuthenticatedServices();
    });
  }

  void _startAuthenticatedServices() {
    if (!mounted) {
      return;
    }
    final AccountModel? account = ref
        .read(accountProvider)
        .value
        ?.activeAccountModel;
    if (account == null) {
      return;
    }
    final String accountKey = account.accountKey;
    if (_watcherAccountKey == accountKey) {
      return;
    }

    _watcherAccountKey = accountKey;
    fireAndForget(() async {
      await BackgroundWatcherService.instance.initialize((final Uri uri) {
        if (mounted) {
          ref.read(pendingDeepLinkProvider.notifier).set(uri);
        }
      });
    }, label: 'Background watcher initialization');
    fireAndForget(() async {
      final AuthenticatedSession? authenticatedSession = await ref.read(
        authenticatedSessionProvider.future,
      );
      if (!mounted ||
          authenticatedSession == null ||
          _watcherAccountKey != accountKey ||
          ref.read(accountProvider).value?.activeAccountModel?.accountKey !=
              accountKey) {
        return;
      }
      ref.invalidate(watcherServiceProvider);
      ref.read(watcherServiceProvider).start();
      _watcherServiceStarted = true;
    }, label: 'Watcher startup');
  }

  void _stopAuthenticatedServices() {
    _watcherAccountKey = null;
    if (_watcherServiceStarted) {
      ref.read(watcherServiceProvider).stop();
    }
    ref.invalidate(watcherServiceProvider);
    _watcherServiceStarted = false;
  }

  Future<void> _refreshActivity() async {
    await _feedRefreshRegistrar.value?.call();
  }

  Future<bool> _loadMoreActivity() async {
    return await _feedLoadMoreRegistrar.value?.call() ?? false;
  }

  void _refreshTopRepositories() {
    final AccountModel? account = ref
        .read(accountProvider)
        .value
        ?.activeAccountModel;
    if (account != null) {
      ref.invalidate(
        homeTopRepositoriesProvider((
          accountKey: account.accountKey,
          login: account.username,
        )),
      );
    }
  }

  Future<void> _openSignIn() async {
    if (!mounted) {
      return;
    }
    await context.router.push<void>(const AuthRoute());
  }

  Future<void> _signOut() async {
    if (!mounted) {
      return;
    }
    final bool confirmed = await confirmSignOutAllAccounts(context);
    if (!confirmed) {
      return;
    }
    await ref.read(accountProvider.notifier).logOutAll();
  }

  @override
  void dispose() {
    _feedRefreshRegistrar.dispose();
    _feedLoadMoreRegistrar.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    ref.listen<AsyncValue<AccountSession?>>(accountProvider, (
      final AsyncValue<AccountSession?>? previous,
      final AsyncValue<AccountSession?> next,
    ) {
      final String? previousAccountKey =
          previous?.value?.activeAccountModel?.accountKey;
      final String? nextAccountKey = next.value?.activeAccountModel?.accountKey;
      if (previousAccountKey == nextAccountKey) {
        return;
      }
      if (previousAccountKey != null) {
        _stopAuthenticatedServices();
      }
      if (nextAccountKey != null) {
        WidgetsBinding.instance.addPostFrameCallback((final _) {
          _startAuthenticatedServices();
        });
      }
    });

    final AsyncValue<AccountSession?> accountState = ref.watch(accountProvider);
    final AccountModel? account = accountState.value?.activeAccountModel;
    final ViewerInfo? viewerCandidate = account == null
        ? null
        : ref.watch(currentUserProvider).value;
    final ViewerInfo? viewer = viewerCandidate?.id == account?.nodeId
        ? viewerCandidate
        : null;
    final AsyncValue<List<HomeRepositoryItem>> topRepositories = account == null
        ? const AsyncData<List<HomeRepositoryItem>>(<HomeRepositoryItem>[])
        : ref.watch(
            homeTopRepositoriesProvider((
              accountKey: account.accountKey,
              login: account.username,
            )),
          );
    return UnifiedHomeScreen(
      account: account,
      accountLoading: accountState.isLoading,
      statusEmoji: viewer?.status?.emoji,
      statusMessage: viewer?.status?.message,
      topRepositories: topRepositories,
      onRefreshTopRepositories: _refreshTopRepositories,
      activityFeedSliver: Events(
        refreshRegistrar: _feedRefreshRegistrar,
        loadMoreRegistrar: _feedLoadMoreRegistrar,
      ),
      onRefreshActivity: _refreshActivity,
      onLoadMoreActivity: _loadMoreActivity,
      onSignIn: _openSignIn,
      onSignOut: _signOut,
    );
  }
}
