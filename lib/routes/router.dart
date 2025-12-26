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
  AppRouter(final BuildContext context) : authGuard = AuthGuard(context);
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
        AutoRoute(
          page: AccountManagementRoute.page,
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
  AuthStateObserver(this.context);

  final BuildContext context;
  StreamSubscription<AccountState>? _subscription;
  bool _isInitialized = false;

  void _initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final accountBloc = BlocProvider.of<AccountBloc>(context);
      _subscription = accountBloc.stream.listen((final AccountState state) {
        final routerContext = context;
        if (!routerContext.mounted) return;

        final router = AutoRouter.of(routerContext);

        if (state is AccountReady) {
          if (state.accounts.isEmpty || state.activeAccount == null) {
            // Accounts became empty - redirect to auth immediately
            // This handles logout while already on a protected route
            if (router.current.name != AuthRoute.name) {
              router.replaceAll(<PageRouteInfo>[AuthRoute()]);
            }
          } else if (state.activeAccount != null) {
            // Account ready with active account
            // If on AuthRoute, redirect to LandingLoadingRoute (post-login)
            if (router.current.name == AuthRoute.name) {
              router.replaceAll(<PageRouteInfo>[LandingLoadingRoute()]);
            }
          }
        }
      });
    } catch (e) {
      // Context might not be ready yet, will retry on next didPush
      _isInitialized = false;
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    // Initialize subscription on first route push
    if (!_isInitialized) {
      _initialize();
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

class AuthGuard extends AutoRouteGuard {
  AuthGuard(this.context);

  final BuildContext context;

  @override
  void onNavigation(
    final NavigationResolver resolver,
    final StackRouter router,
  ) {
    final accountState = BlocProvider.of<AccountBloc>(context).state;

    // Check AccountBloc state (source of truth)
    if (accountState is AccountReady) {
      if (accountState.accounts.isEmpty || accountState.activeAccount == null) {
        // No accounts or no active account
        // Check if already on AuthRoute to prevent race condition with observer
        if (router.current.name != AuthRoute.name) {
          // Redirect to auth - observer will handle post-login redirect
          unawaited(router.replaceAll(<PageRouteInfo>[AuthRoute()]));
        } else {
          // Already on AuthRoute (observer redirected), just block navigation
          resolver.next(false);
        }
      } else {
        // Account ready with active account - allow navigation
        resolver.next();
      }
    } else if (accountState is AccountLoading ||
        accountState is AccountAdding ||
        accountState is AccountSwitching) {
      // Still loading/adding/switching - allow through to LandingLoadingScreen
      resolver.next();
    } else {
      // Uninitialized or error
      // Check if already on AuthRoute to prevent race condition with observer
      if (router.current.name != AuthRoute.name) {
        // Redirect to auth - observer will handle post-login redirect
        unawaited(router.replaceAll(<PageRouteInfo>[AuthRoute()]));
      } else {
        // Already on AuthRoute (observer redirected), just block navigation
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
