import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/models/contributions/chip_detail_models.dart';
import 'package:diohub_models/models/contributions/contribution_chip_type.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/services/users/chip_details_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chip_details_provider.freezed.dart';

/// Key for chip details (no cursor; pagination is handled by controller).
@freezed
abstract class ChipDetailsKey with _$ChipDetailsKey {
  const ChipDetailsKey._();

  const factory ChipDetailsKey({
    required ContributionChipType chipType,
    required ContributionQueryKey queryKey,
  }) = _ChipDetailsKey;
}

final chipDetailsServiceProvider = Provider<ChipDetailsService>(
  (ref) => ChipDetailsService(ref.read(apiClientProvider)),
);

/// Creates a new [PaginationController] for issue chip details (cursor pagination).
/// The sheet body owns and disposes the controller.
final issueChipDetailsControllerProvider = Provider.autoDispose
    .family<
      PaginationController<IssueChipItem, IssueChipItem> Function(),
      ChipDetailsKey
    >((final Ref ref, final ChipDetailsKey key) {
      final (DateTime from, DateTime to) = key.queryKey.dateRange.dates;
      final service = ref.read(chipDetailsServiceProvider);
      return () => PaginationController<IssueChipItem, IssueChipItem>(
        source: CursorForwardSource<IssueChipItem>(
          fetch: ({required int first, String? after}) async {
            final page = await service.fetchIssueContributions(
              userName: key.queryKey.userName,
              from: from,
              to: to,
              after: after,
              first: first,
            );
            return CursorPage<IssueChipItem>(
              items: page.issues,
              hasNextPage: page.hasNextPage,
              endCursor: page.endCursor,
              totalCount: page.totalCount,
            );
          },
        ),
        idOf: (final IssueChipItem e) => e.issue?.id?.toString() ?? '',
        pageSize: 20,
      );
    });

/// Creates a new [PaginationController] for pull request chip details.
final pullRequestChipDetailsControllerProvider = Provider.autoDispose
    .family<
      PaginationController<PullRequestChipItem, PullRequestChipItem> Function(),
      ChipDetailsKey
    >((final Ref ref, final ChipDetailsKey key) {
      final (DateTime from, DateTime to) = key.queryKey.dateRange.dates;
      final service = ref.read(chipDetailsServiceProvider);
      return () =>
          PaginationController<PullRequestChipItem, PullRequestChipItem>(
            source: CursorForwardSource<PullRequestChipItem>(
              fetch: ({required int first, String? after}) async {
                final page = await service.fetchPullRequestContributions(
                  userName: key.queryKey.userName,
                  from: from,
                  to: to,
                  after: after,
                  first: first,
                );
                return CursorPage<PullRequestChipItem>(
                  items: page.pullRequests,
                  hasNextPage: page.hasNextPage,
                  endCursor: page.endCursor,
                  totalCount: page.totalCount,
                );
              },
            ),
            idOf: (final PullRequestChipItem e) =>
                e.pullRequest?.id?.toString() ?? '',
            pageSize: 20,
          );
    });

/// Creates a new [PaginationController] for review chip details.
final reviewChipDetailsControllerProvider = Provider.autoDispose
    .family<
      PaginationController<ReviewChipItem, ReviewChipItem> Function(),
      ChipDetailsKey
    >((final Ref ref, final ChipDetailsKey key) {
      final (DateTime from, DateTime to) = key.queryKey.dateRange.dates;
      final service = ref.read(chipDetailsServiceProvider);
      return () => PaginationController<ReviewChipItem, ReviewChipItem>(
        source: CursorForwardSource<ReviewChipItem>(
          fetch: ({required int first, String? after}) async {
            final page = await service.fetchReviewContributions(
              userName: key.queryKey.userName,
              from: from,
              to: to,
              after: after,
              first: first,
            );
            return CursorPage<ReviewChipItem>(
              items: page.reviews,
              hasNextPage: page.hasNextPage,
              endCursor: page.endCursor,
              totalCount: page.totalCount,
            );
          },
        ),
        idOf: (final ReviewChipItem e) => e.pullRequest?.id?.toString() ?? '',
        pageSize: 20,
      );
    });

/// Creates a new [PaginationController] for created repo chip details.
final createdRepoChipDetailsControllerProvider = Provider.autoDispose
    .family<
      PaginationController<CreatedRepoChipItem, CreatedRepoChipItem> Function(),
      ChipDetailsKey
    >((final Ref ref, final ChipDetailsKey key) {
      final (DateTime from, DateTime to) = key.queryKey.dateRange.dates;
      final service = ref.read(chipDetailsServiceProvider);
      return () =>
          PaginationController<CreatedRepoChipItem, CreatedRepoChipItem>(
            source: CursorForwardSource<CreatedRepoChipItem>(
              fetch: ({required int first, String? after}) async {
                final page = await service.fetchCreatedRepoContributions(
                  userName: key.queryKey.userName,
                  from: from,
                  to: to,
                  after: after,
                  first: first,
                );
                return CursorPage<CreatedRepoChipItem>(
                  items: page.repositories,
                  hasNextPage: page.hasNextPage,
                  endCursor: page.endCursor,
                  totalCount: page.totalCount,
                );
              },
            ),
            idOf: (final CreatedRepoChipItem e) => e.repository.id,
            pageSize: 20,
          );
    });

/// Injected by [ChipDetailBottomSheet] when showing commits content.
/// Used by [commitChipDetailsProvider].
final Provider<ContributionCollectionResult?>
contributionResultForCommitDetailsProvider =
    Provider<ContributionCollectionResult?>((ref) => null);

/// Commit chip details. Requires [contributionResultForCommitDetailsProvider] override.
final FutureProvider<CommitChipDetails> commitChipDetailsProvider =
    FutureProvider.autoDispose<CommitChipDetails>((ref) async {
      final result = ref.watch(contributionResultForCommitDetailsProvider);
      if (result == null)
        throw StateError('contributionResultForCommitDetailsProvider not set');
      return ref
          .read(chipDetailsServiceProvider)
          .fetchCommitContributions(contributionResult: result);
    });
