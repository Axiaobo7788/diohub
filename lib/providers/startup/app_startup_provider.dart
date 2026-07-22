import 'package:diohub/app/app_logger.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:diohub_models/models/authentication/authenticated_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

sealed class AppStartupState {
  const AppStartupState();
}

class StartupLoading extends AppStartupState {
  const StartupLoading();
}

class StartupPublic extends AppStartupState {
  const StartupPublic();
}

class StartupError extends AppStartupState {
  const StartupError(this.message);
  final String message;
}

class StartupReady extends AppStartupState {
  const StartupReady({required this.session, required this.viewer});
  final AccountSession session;
  final ViewerInfo viewer;
}

class AppStartupNotifier extends AsyncNotifier<AppStartupState> {
  @override
  Future<AppStartupState> build() async {
    try {
      final AuthenticatedSession? authSession = await ref.watch(
        authenticatedSessionProvider.future,
      );
      if (authSession == null) {
        return const StartupPublic();
      }
      // accountProvider is already resolved (authenticatedSessionProvider depends on it)
      final AccountSession? session = await ref.watch(accountProvider.future);
      if (session == null || session.activeAccount == null) {
        return const StartupPublic();
      }
      try {
        final ViewerInfo? viewer = await ref.watch(currentUserProvider.future);
        if (viewer != null) {
          return StartupReady(session: session, viewer: viewer);
        }
      } on Object catch (e, st) {
        AppLogger.warning(
          'Viewer bootstrap failed; opening the shared home instead',
          error: e,
          stackTrace: st,
          tag: 'Startup',
        );
      }
      return const StartupPublic();
    } catch (e, st) {
      AppLogger.error(
        'App startup failed',
        error: e,
        stackTrace: st,
        tag: 'Startup',
      );
      return StartupError(e.toString());
    }
  }
}

final appStartupProvider =
    AsyncNotifierProvider<AppStartupNotifier, AppStartupState>(
      AppStartupNotifier.new,
    );
