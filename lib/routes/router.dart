import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/blocs/account_bloc/account_bloc.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// flutter packages pub run build_runner watch --delete-conflicting-outputs

StackRouter autoRoute(final BuildContext context) => AutoRouter.of(context);

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter(final BuildContext context) : authGuard = AuthGuard(context) {
    debugPrint('[AppRouter] Router created with context');
  }
  final AuthGuard authGuard;

  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => <AutoRoute>[
        AutoRoute(page: AuthRoute.page),
        AutoRoute(
          page: LandingLoadingRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
          initial: true,
        ),
        AutoRoute(
          page: HomeRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: PlaceHolderRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        CustomRoute(
          page: SearchOverlayRoute.page,
          transitionsBuilder: TransitionsBuilders.fadeIn,
          guards: <AutoRouteGuard>[authGuard],
        ),
        AutoRoute(
          page: IssuePullRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: RepositoryRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: FileViewerAPI.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: CommitInfoRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: WikiViewer.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: ChangesViewer.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: UserProfileRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: NewIssueRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: PRReviewRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: SearchRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        
      ];
}

// class $AppRouter {}

/// NavigatorObserver that reacts to AccountBloc state changes and redirects to AuthRoute
/// when accounts become empty. Handles reactive state changes (like logout)
/// that guards don't cover (guards only run on navigation attempts).
class AuthStateObserver extends NavigatorObserver {
  AuthStateObserver(this.context) {
    debugPrint('[AuthStateObserver] Observer created');
  }

  final BuildContext context;
  StreamSubscription<AccountState>? _subscription;
  bool _isInitialized = false;

  void _initialize() {
    if (_isInitialized) {
      debugPrint('[AuthStateObserver] Already initialized, skipping');
      return;
    }
    _isInitialized = true;
    debugPrint('[AuthStateObserver] Initializing observer');

    try {
      final accountBloc = BlocProvider.of<AccountBloc>(context);
      debugPrint(
          '[AuthStateObserver] Got AccountBloc, setting up stream subscription');
      _subscription = accountBloc.stream.listen((final AccountState state) {
        debugPrint('[AuthStateObserver] Received state: ${state.runtimeType}');

        // Use navigator.context which is guaranteed to be in the router tree
        final navigatorContext = navigator?.context;
        if (navigatorContext == null || !navigatorContext.mounted) {
          debugPrint(
              '[AuthStateObserver] Navigator context not available, skipping');
          return;
        }

        try {
          final router = AutoRouter.of(navigatorContext);
          final currentRouteName = router.current.name;
          debugPrint('[AuthStateObserver] Current route: $currentRouteName');

          if (state is AccountReady) {
            debugPrint(
                '[AuthStateObserver] AccountReady - accounts: ${state.accounts.length}, activeAccount: ${state.activeAccount ?? "null"}');
            if (state.accounts.isEmpty || state.activeAccount == null) {
              // Accounts became empty - redirect to auth immediately
              // This handles logout while already on a protected route
              debugPrint(
                  '[AuthStateObserver] Accounts empty or no active account');
              if (currentRouteName != AuthRoute.name) {
                debugPrint('[AuthStateObserver] Redirecting to AuthRoute');
                router.replaceAll(<PageRouteInfo>[AuthRoute()]);
                debugPrint('[AuthStateObserver] Redirected to AuthRoute');
              } else {
                debugPrint(
                    '[AuthStateObserver] Already on AuthRoute, skipping redirect');
              }
            } else if (state.activeAccount != null) {
              // Account ready with active account
              // If on AuthRoute, redirect to LandingLoadingRoute (post-login)
              debugPrint(
                  '[AuthStateObserver] Active account present: ${state.activeAccount}');
              if (currentRouteName == AuthRoute.name) {
                debugPrint(
                    '[AuthStateObserver] On AuthRoute with active account, redirecting to LandingLoadingRoute');
                router.replaceAll(<PageRouteInfo>[LandingLoadingRoute()]);
                debugPrint(
                    '[AuthStateObserver] Redirected to LandingLoadingRoute');
              } else {
                debugPrint(
                    '[AuthStateObserver] Not on AuthRoute (on $currentRouteName), skipping redirect');
              }
            }
          } else {
            debugPrint(
                '[AuthStateObserver] State is not AccountReady: ${state.runtimeType}');
          }
        } catch (e, stackTrace) {
          debugPrint('[AuthStateObserver] Error in state handler: $e');
          debugPrint('[AuthStateObserver] Stack trace: $stackTrace');
        }
      });
      debugPrint('[AuthStateObserver] Stream subscription set up successfully');
    } catch (e, stackTrace) {
      // Context might not be ready yet, will retry on next didPush
      debugPrint('[AuthStateObserver] Error initializing: $e');
      debugPrint('[AuthStateObserver] Stack trace: $stackTrace');
      _isInitialized = false;
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint(
        '[AuthStateObserver] didPush - route: ${route.settings.name}, previous: ${previousRoute?.settings.name ?? "null"}');
    // Initialize subscription on first route push
    if (!_isInitialized) {
      debugPrint('[AuthStateObserver] Not initialized, calling _initialize');
      _initialize();
    } else {
      debugPrint('[AuthStateObserver] Already initialized');
    }
  }

  void dispose() {
    debugPrint('[AuthStateObserver] Disposing observer');
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
  }
}

class AuthGuard extends AutoRouteGuard {
  AuthGuard(this.context) {
    debugPrint('[AuthGuard] Guard created');
  }

  final BuildContext context;

  @override
  void onNavigation(
    final NavigationResolver resolver,
    final StackRouter router,
  ) {
    final accountState = BlocProvider.of<AccountBloc>(context).state;
    final currentRouteName = router.current.name;
    final targetRouteName = resolver.route.name;

    debugPrint('[AuthGuard] onNavigation called');
    debugPrint('[AuthGuard] Current route: $currentRouteName');
    debugPrint('[AuthGuard] Target route: $targetRouteName');
    debugPrint('[AuthGuard] AccountState: ${accountState.runtimeType}');

    // Check AccountBloc state (source of truth)
    if (accountState is AccountReady) {
      debugPrint(
          '[AuthGuard] AccountReady - accounts: ${accountState.accounts.length}, activeAccount: ${accountState.activeAccount ?? "null"}');
      if (accountState.accounts.isEmpty || accountState.activeAccount == null) {
        // No accounts or no active account
        // Check if already on AuthRoute to prevent race condition with observer
        debugPrint('[AuthGuard] No accounts or no active account');
        if (currentRouteName != AuthRoute.name) {
          // Redirect to auth - observer will handle post-login redirect
          debugPrint('[AuthGuard] Not on AuthRoute, redirecting to AuthRoute');
          unawaited(router.replaceAll(<PageRouteInfo>[AuthRoute()]));
          debugPrint('[AuthGuard] Redirected to AuthRoute');
        } else {
          // Already on AuthRoute (observer redirected), just block navigation
          debugPrint('[AuthGuard] Already on AuthRoute, blocking navigation');
          resolver.next(false);
        }
      } else {
        // Account ready with active account - allow navigation
        debugPrint(
            '[AuthGuard] Account ready with active account, allowing navigation');
        resolver.next();
      }
    } else if (accountState is AccountLoading) {
      debugPrint(
          '[AuthGuard] AccountLoading - allowing through to LandingLoadingScreen');
      resolver.next();
    } else if (accountState is AccountAdding) {
      debugPrint(
          '[AuthGuard] AccountAdding - allowing through to LandingLoadingScreen');
      resolver.next();
    } else if (accountState is AccountSwitching) {
      debugPrint(
          '[AuthGuard] AccountSwitching - allowing through to LandingLoadingScreen');
      resolver.next();
    } else {
      // Uninitialized or error
      debugPrint(
          '[AuthGuard] Uninitialized or error state: ${accountState.runtimeType}');
      // Check if already on AuthRoute to prevent race condition with observer
      if (currentRouteName != AuthRoute.name) {
        // Redirect to auth - observer will handle post-login redirect
        debugPrint('[AuthGuard] Not on AuthRoute, redirecting to AuthRoute');
        unawaited(router.replaceAll(<PageRouteInfo>[AuthRoute()]));
        debugPrint('[AuthGuard] Redirected to AuthRoute');
      } else {
        // Already on AuthRoute (observer redirected), just block navigation
        debugPrint('[AuthGuard] Already on AuthRoute, blocking navigation');
        resolver.next(false);
      }
    }
  }
}

// Widget fadeThroughTransition(BuildContext context, Animation<double> animation,
//     Animation<double> secondaryAnimation, Widget child) {
//   return FadeThroughTransition(
//     animation: animation,
//     secondaryAnimation: secondaryAnimation,
//     fillColor: secondary(context),
//     child: child,
//   );
// }

T getRoute<T extends PageRouteInfo>(
  final PathData path, {
  required final T Function(PathData path) onDeepLink,
  final T Function(PathData path)? onAPILink,
}) {
  if (path.isAPIPath && onAPILink != null) {
    return onAPILink(path);
  }
  return onDeepLink(path);
}
