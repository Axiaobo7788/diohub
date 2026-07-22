import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/events/events.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/router_provider.dart';
import 'package:diohub/providers/watchers/watcher_manager_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/services/watchers/background_watcher_service.dart';
import 'package:diohub/utils/fire_and_forget.dart';
import 'package:diohub/view/home/unified_home_screen.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
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
  bool _watchersStarted = false;

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
    if (!mounted || _watchersStarted) return;
    final AccountModel? account = ref
        .read(accountProvider)
        .value
        ?.activeAccountModel;
    if (account == null) return;

    _watchersStarted = true;
    fireAndForget(() async {
      await BackgroundWatcherService.instance.initialize((final Uri uri) {
        if (mounted) {
          ref.read(pendingDeepLinkProvider.notifier).set(uri);
        }
      });
    }, label: 'Background watcher initialization');
    fireAndForget(
      () async => ref.read(watcherServiceProvider).start(),
      label: 'Watcher startup',
    );
  }

  void _stopAuthenticatedServices() {
    if (!_watchersStarted) return;
    ref.read(watcherServiceProvider).stop();
    _watchersStarted = false;
  }

  Future<void> _refreshActivity() async {
    await _feedRefreshRegistrar.value?.call();
  }

  Future<void> _openSignIn() async {
    if (!mounted) return;
    await context.router.push<void>(const AuthRoute());
  }

  Future<void> _signOut() async {
    await ref.read(accountProvider.notifier).logOutAll();
  }

  @override
  void dispose() {
    _feedRefreshRegistrar.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    ref.listen<AsyncValue<AccountSession?>>(accountProvider, (
      final AsyncValue<AccountSession?>? previous,
      final AsyncValue<AccountSession?> next,
    ) {
      final bool wasAuthenticated = previous?.value?.activeAccountModel != null;
      final bool isAuthenticated = next.value?.activeAccountModel != null;
      if (!wasAuthenticated && isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((final _) {
          _startAuthenticatedServices();
        });
      } else if (wasAuthenticated && !isAuthenticated) {
        _stopAuthenticatedServices();
      }
    });

    final AsyncValue<AccountSession?> accountState = ref.watch(accountProvider);
    return UnifiedHomeScreen(
      account: accountState.value?.activeAccountModel,
      accountLoading: accountState.isLoading,
      activityFeedSliver: Events(refreshRegistrar: _feedRefreshRegistrar),
      onRefreshActivity: _refreshActivity,
      onSignIn: _openSignIn,
      onSignOut: _signOut,
    );
  }
}
