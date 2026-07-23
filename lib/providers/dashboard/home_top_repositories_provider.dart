import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/base/base_service.dart' show ApiClient;
import 'package:diohub/services/dashboard/home_top_repositories_service.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

typedef HomeTopRepositoriesKey = ({String accountKey, String login});

final Provider<HomeTopRepositoriesService> homeTopRepositoriesServiceProvider =
    Provider<HomeTopRepositoriesService>((final Ref ref) {
      final ApiClient apiClient = ref.watch(apiClientProvider);
      return HomeTopRepositoriesService(
        graphql: apiClient.gql,
        userInfoService: UserInfoService(apiClient),
      );
    });

final FutureProviderFamily<List<HomeRepositoryItem>, HomeTopRepositoriesKey>
homeTopRepositoriesProvider = FutureProvider.autoDispose
    .family<List<HomeRepositoryItem>, HomeTopRepositoriesKey>((
      final Ref ref,
      final HomeTopRepositoriesKey key,
    ) async {
      keepAliveFor(ref);
      return ref
          .watch(homeTopRepositoriesServiceProvider)
          .fetch(login: key.login, refreshCache: true);
    });
