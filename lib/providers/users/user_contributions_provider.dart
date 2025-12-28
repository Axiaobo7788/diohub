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
  if (kDebugMode) {
    final (from, to) = key.dateRange.dates;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    log.d(
        '[userContributionsProvider] ⚠️ PROVIDER FUNCTION EXECUTED at $timestamp for user: "${key.userName}", hashCode: ${key.hashCode}, dateRange: ${key.dateRange.runtimeType}, from: ${from.toIso8601String()}, to: ${to.toIso8601String()}');
    log.d(
        '[userContributionsProvider] Key equality check - userName: "${key.userName}", dateRange type: ${key.dateRange.runtimeType}, dateRange hashCode: ${key.dateRange.hashCode}');
    log.d(
        '[userContributionsProvider] ⚠️ This means Riverpod did NOT return cached Future - provider function is running');
  }
  // Keep provider alive to prevent refetch on navigation
  ref.keepAlive();
  if (kDebugMode) {
    log.d(
        '[userContributionsProvider] Calling fetchContributions for "${key.userName}"');
  }
  final result = await UserContributionsService.fetchContributions(key);
  if (kDebugMode) {
    log.d(
        '[userContributionsProvider] ✅ Completed fetchContributions for "${key.userName}", totalContributions: ${result.viewModel.totalContributions}');
  }
  return result;
}, retry: (int retryCount, Object error) {
  if (retryCount < 3) {
    return Duration(seconds: 1);
  }
});
