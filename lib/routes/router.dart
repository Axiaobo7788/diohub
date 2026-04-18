import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub/providers/router_provider.dart';
import 'package:diohub/providers/startup/app_startup_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';

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
      duration: const Duration(milliseconds: 400),
      transitionsBuilder:
          (
            final BuildContext context,
            final Animation<double> animation,
            final Animation<double> secondaryAnimation,
            final Widget child,
          ) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          ),
    ),
    AutoRoute(page: IssueDetailRoute.page),
    AutoRoute(page: PullRequestDetailRoute.page),
    AutoRoute(page: RepositoryRoute.page),
    AutoRoute(page: FileViewerRoute.page),
    AutoRoute(page: CommitInfoRoute.page),
    AutoRoute(page: WikiViewer.page),
    AutoRoute(page: ChangesViewer.page),
    AutoRoute(page: FileDiffRoute.page),
    AutoRoute(page: UserProfileRoute.page),
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
/// No splash-complete gate: on [StartupReady], navigate to [HomeRoute] immediately
/// when on [LandingLoadingRoute] or [AuthRoute]. Framework handles route transition.
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
            case StartupUnauthenticated():
              // Stay on LandingLoadingRoute - auth UI rendered in-place
              if (currentRoute != LandingLoadingRoute.name) {
                router.replaceAll(<PageRouteInfo>[LandingLoadingRoute()]);
              }
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
    if (state is! StartupReady) return;

    final String currentRoute = router.current.name;
    if (currentRoute != LandingLoadingRoute.name &&
        currentRoute != AuthRoute.name) {
      return;
    }

    Uri? pendingLink;
    if (!_deepLinkConsumed) {
      _deepLinkConsumed = true;
      pendingLink = _container.read(pendingDeepLinkProvider);
      if (pendingLink != null) {
        _container.read(pendingDeepLinkProvider.notifier).state = null;
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
