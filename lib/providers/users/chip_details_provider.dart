import 'package:diohub/models/contributions/chip_detail_models.dart';
import 'package:diohub/models/contributions/contribution_chip_type.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/services/users/chip_details_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key for chip details provider requests
class ChipDetailsKey {
  const ChipDetailsKey({
    required this.chipType,
    required this.queryKey,
    this.cursor,
  });

  final ContributionChipType chipType;
  final ContributionQueryKey queryKey;
  final String? cursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChipDetailsKey &&
          runtimeType == other.runtimeType &&
          chipType == other.chipType &&
          queryKey == other.queryKey &&
          cursor == other.cursor;

  @override
  int get hashCode => chipType.hashCode ^ queryKey.hashCode ^ cursor.hashCode;
}

/// Provider for fetching issue chip details with pagination
final issueChipDetailsProvider =
    FutureProvider.family<IssueChipDetails, ChipDetailsKey>(
  (ref, key) async {
    final (from, to) = key.queryKey.dateRange.dates;
    return ChipDetailsService.fetchIssueContributions(
      userName: key.queryKey.userName,
      from: from,
      to: to,
      after: key.cursor,
    );
  },
);

/// Provider for fetching pull request chip details with pagination
final pullRequestChipDetailsProvider =
    FutureProvider.family<PullRequestChipDetails, ChipDetailsKey>(
  (ref, key) async {
    final (from, to) = key.queryKey.dateRange.dates;
    return ChipDetailsService.fetchPullRequestContributions(
      userName: key.queryKey.userName,
      from: from,
      to: to,
      after: key.cursor,
    );
  },
);

/// Provider for fetching review chip details with pagination
final reviewChipDetailsProvider =
    FutureProvider.family<ReviewChipDetails, ChipDetailsKey>(
  (ref, key) async {
    final (from, to) = key.queryKey.dateRange.dates;
    return ChipDetailsService.fetchReviewContributions(
      userName: key.queryKey.userName,
      from: from,
      to: to,
      after: key.cursor,
    );
  },
);

/// Provider for fetching created repo chip details with pagination
final createdRepoChipDetailsProvider =
    FutureProvider.family<CreatedRepoChipDetails, ChipDetailsKey>(
  (ref, key) async {
    final (from, to) = key.queryKey.dateRange.dates;
    return ChipDetailsService.fetchCreatedRepoContributions(
      userName: key.queryKey.userName,
      from: from,
      to: to,
      after: key.cursor,
    );
  },
);









