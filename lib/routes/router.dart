import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/animations/app_page_transition.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/providers/router_provider.dart';
import 'package:diohub/providers/startup/app_startup_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

StackRouter autoRoute(final BuildContext context) => AutoRouter.of(context);

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter();

  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => <AutoRoute>[
    AutoRoute(page: AuthRoute.page),
    AutoRoute(page: LandingLoadingRoute.page, initial: true),
    CustomRoute<dynamic>(
      page: HomeRoute.page,
      duration: kPageTransitionDuration,
      reverseDuration: kPageTransitionReverseDuration,
      transitionsBuilder: buildAppPageTransition,
    ),
    CustomRoute<dynamic>(
      page: NotificationsRoute.page,
      duration: kPageTransitionDuration,
      reverseDuration: kPageTransitionReverseDuration,
      transitionsBuilder: buildAppPageTransition,
    ),
    CustomRoute<dynamic>(
      page: GlobalListsRoute.page,
      duration: kPageTransitionDuration,
      reverseDuration: kPageTransitionReverseDuration,
      transitionsBuilder: buildAppPageTransition,
    ),
    CustomRoute<dynamic>(
      page: SettingsRoute.page,
      duration: kPageTransitionDuration,
      reverseDuration: kPageTransitionReverseDuration,
      transitionsBuilder: buildAppPageTransition,
    ),
    CustomRoute<dynamic>(
      page: IssueDetailRoute.page,
      duration: kPageTransitionDuration,
      reverseDuration: kPageTransitionReverseDuration,
      transitionsBuilder: buildAppPageTransition,
    ),
    CustomRoute<dynamic>(
      page: PullRequestDetailRoute.page,
      duration: kPageTransitionDuration,
      reverseDuration: kPageTransitionReverseDuration,
      transitionsBuilder: buildAppPageTransition,
    ),
    CustomRoute<dynamic>(
      page: RepositoryRoute.page,
      duration: kPageTransitionDuration,
      reverseDuration: kPageTransitionReverseDuration,
      transitionsBuilder: buildAppPageTransition,
    ),
    CustomRoute<dynamic>(
      page: WikiViewer.page,
      duration: kPageTransitionDuration,
      reverseDuration: kPageTransitionReverseDuration,
      transitionsBuilder: buildAppPageTransition,
    ),
    AutoRoute(page: FileViewerRoute.page),
    AutoRoute(page: CommitInfoRoute.page),
    AutoRoute(page: ChangesViewer.page),
    AutoRoute(page: FileDiffRoute.page),
    CustomRoute<dynamic>(
      page: UserProfileRoute.page,
      duration: kPageTransitionDuration,
      reverseDuration: kPageTransitionReverseDuration,
      transitionsBuilder: buildAppPageTransition,
    ),
    AutoRoute(page: NewIssueRoute.page),
    AutoRoute(page: CommentRoute.page),
    AutoRoute(page: NewPullRequestRoute.page),
    AutoRoute(page: EditIssueRoute.page),
    AutoRoute(page: EditPullRequestRoute.page),
    AutoRoute(page: SearchRoute.page),
    AutoRoute(page: SSHConnectionsRoute.page),
    AutoRoute(page: SSHTerminalRoute.page),
    AutoRoute(page: ChangelogRoute.page),
    // Merge premium routes (empty in OSS, populated when premium is loaded)
    ...premiumRoutes,
  ];
}

/// The single navigation authority for the entire app.
///
/// Listens to [appStartupProvider] to drive all route-stack transitions.
/// No splash-complete gate: public and authenticated startup both navigate to
/// [HomeRoute]. [AuthRoute] is replaced only after an explicit sign-in succeeds.
class AppNavigationObserver extends NavigatorObserver {
  AppNavigationObserver(this._container) {
    _startupSub = _container.listen<AsyncValue<AppStartupState>>(
      appStartupProvider,
      _handleStartupChange,
      fireImmediately: true,
    );
  }

  final ProviderContainer _container;
  ProviderSubscription<AsyncValue<AppStartupState>>? _startupSub;

  AsyncValue<AppStartupState>? _lastStartup;
  bool _deepLinkConsumed = false;

  void _handleStartupChange(
    final AsyncValue<AppStartupState>? prev,
    final AsyncValue<AppStartupState> next,
  ) {
    _lastStartup = next;
    final nav = navigator;
    if (nav == null) return;

    try {
      final StackRouter router = AutoRouter.of(nav.context);
      final String currentRoute = router.current.name;

      next.when(
        loading: () {
          if (currentRoute != LandingLoadingRoute.name) {
            _deepLinkConsumed = false;
            router.replaceAll(<PageRouteInfo>[LandingLoadingRoute()]);
          }
        },
        error: (final Object e, final StackTrace st) {
          if (currentRoute != LandingLoadingRoute.name) {
            router.replaceAll(<PageRouteInfo>[LandingLoadingRoute()]);
          }
        },
        data: (final AppStartupState state) {
          switch (state) {
            case StartupLoading():
              if (currentRoute != LandingLoadingRoute.name) {
                _deepLinkConsumed = false;
                router.replaceAll(<PageRouteInfo>[LandingLoadingRoute()]);
              }
            case StartupPublic():
              _maybeNavigateToHome(router);
            case StartupError():
              if (currentRoute != LandingLoadingRoute.name) {
                router.replaceAll(<PageRouteInfo>[LandingLoadingRoute()]);
              }
            case StartupReady():
              _maybeNavigateToHome(router);
          }
        },
      );
    } catch (e, stackTrace) {
      AppLogger.warning(
        'AppNavigationObserver startup handler failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'AppNavigationObserver',
      );
    }
  }

  void _maybeNavigateToHome(final StackRouter router) {
    final AsyncValue<AppStartupState>? startup = _lastStartup;
    if (startup == null || startup is! AsyncData<AppStartupState>) return;
    final AppStartupState state = startup.value;
    if (state is! StartupReady && state is! StartupPublic) return;

    final String currentRoute = router.current.name;
    if (currentRoute != LandingLoadingRoute.name &&
        (state is! StartupReady || currentRoute != AuthRoute.name)) {
      return;
    }

    Uri? pendingLink;
    if (state is StartupReady && !_deepLinkConsumed) {
      _deepLinkConsumed = true;
      pendingLink = _container.read(pendingDeepLinkProvider);
      if (pendingLink != null) {
        _container.read(pendingDeepLinkProvider.notifier).clear();
      }
    }

    router.replaceAll(<PageRouteInfo>[HomeRoute()]);

    if (pendingLink != null) {
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        final ctx = navigator?.context;
        if (ctx != null && ctx.mounted) {
          deepLinkNavigate(pendingLink!, ctx);
        }
      });
    }
  }

  void dispose() {
    _startupSub?.close();
  }
}
