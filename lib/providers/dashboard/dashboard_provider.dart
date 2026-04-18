import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardDataProvider =
    AsyncNotifierProvider<DashboardDataNotifier, DashboardData>(
  DashboardDataNotifier.new,
);

class DashboardDataNotifier extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    final login = ref.watch(currentUserProvider).value?.login;
    if (login == null) throw StateError('No active account');
    return ref.watch(userInfoServiceProvider).getDashboardData(
          viewerLogin: login,
        );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final login = ref.read(currentUserProvider).value?.login;
      if (login == null) throw StateError('No active account');
      return ref.read(userInfoServiceProvider).getDashboardData(
        viewerLogin: login,
        refresh: true,
      );
    });
  }
}
