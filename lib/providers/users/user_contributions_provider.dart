import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/providers/database_providers.dart' show apiClientProvider;
import 'package:diohub/services/users/user_contributions_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/future_provider.dart';

/// Provider for fetching user contributions with typed keys.
/// Returns a unified ContributionCollectionResult with both flattened data and per-year highlights.
/// Cache is maintained per unique ContributionQueryKey and kept alive for 5 minutes to prevent
/// redundant fetches when navigating away and back.
final userContributionsProvider = FutureProvider.autoDispose
    .family<ContributionCollectionResult, ContributionQueryKey>(
  (final Ref ref, final ContributionQueryKey key) async {
    keepAliveFor(ref);
    return UserContributionsService(
      ref.read(apiClientProvider),
      UserRef(login: key.userName),
    ).fetchContributions(key);
  },
  retry: (final int retryCount, final Object error) {
    if (retryCount < 3) {
      return const Duration(seconds: 1);
    }
    return null;
  },
);
