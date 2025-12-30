import 'package:diohub/app/global.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/services/users/user_contributions_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for fetching user contributions with typed keys.
/// Returns a unified ContributionCollectionResult with both flattened data and per-year highlights.
/// Cache is maintained per unique ContributionQueryKey and kept alive to prevent
/// redundant fetches when navigating away and back.
final userContributionsProvider =
    FutureProvider.family<ContributionCollectionResult, ContributionQueryKey>(
        (ref, key) async {
  // Keep provider alive to prevent refetch on navigation
  ref.keepAlive();
  final result = await UserContributionsService.fetchContributions(key);
  return result;
}, retry: (int retryCount, Object error) {
  if (retryCount < 3) {
    return Duration(seconds: 1);
  }
});
