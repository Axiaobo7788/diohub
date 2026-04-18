/// Providers for pull request files, merge status, and review threads.
library;

import 'package:diohub/common/pagination/page_size.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_graphql/queries/issues_pulls/review_typedefs.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/database_providers.dart' show apiClientProvider;
import 'package:diohub/providers/issue_pulls/issue_providers.dart' show pullDetailProvider;
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/services/pulls/pull_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches PR review threads (timeline comments with review context).
final pullReviewThreadsProvider =
    FutureProvider.autoDispose.family<ReviewThreadsData?, PullRequestRef>(
  (final Ref ref, final PullRequestRef pullRef) async =>
      pullRef.services(ref.read(apiClientProvider)).getPullRequestReviewThreads(refresh: true),
);

/// For merge status, use: ref.watch(pullDetailProvider(pr).select((v) => v.whenData((d) => (d.mergeable, d.mergeStateStatus))))

/// Fetches a single PR file's patch (diff) via REST on demand.
final pullFilePatchProvider = FutureProvider.autoDispose
    .family<DiffEntry?, ({PullRequestRef pr, String path})>(
  (final Ref ref, final ({PullRequestRef pr, String path}) args) =>
      args.pr.services(ref.read(apiClientProvider)).getPullFilePatch(args.path),
);

/// Sort order for the "Files Changed" position list.
enum FilesChangedSortOrder {
  byPath,
  byChangeType,
  byDelta,
}

class _PullFilesSortOrderNotifier extends Notifier<FilesChangedSortOrder> {
  _PullFilesSortOrderNotifier(this._arg);
  final PullRequestRef _arg;
  @override
  FilesChangedSortOrder build() => FilesChangedSortOrder.byPath;
}

/// Sort order for PR files changed list (by path, change type, or delta size).
final pullFilesSortOrderProvider = NotifierProvider.family<
    _PullFilesSortOrderNotifier,
    FilesChangedSortOrder,
    PullRequestRef>(_PullFilesSortOrderNotifier.new);

/// Controller for PR changed files via GQL (cursor pagination). Used by Files Changed position and viewed-state seeding.
final pullFilesFullListControllerProvider = Provider.autoDispose
    .family<PaginationController<PullFileEdge?, PullFileEdge?>, PullRequestRef>(
        (ref, pullRef) {
  final PullService service = pullRef.services(ref.read(apiClientProvider));
  final controller = PaginationController<PullFileEdge?, PullFileEdge?>(
    source: CursorForwardSource<PullFileEdge?>(
      fetch: ({required int first, String? after}) async {
        final result = await service.getPullFilesGQLPage(
          first: first,
          after: after,
          refresh: after == null,
        );
        return CursorPage<PullFileEdge?>(
          items: result.items,
          hasNextPage: result.hasNextPage,
          endCursor: result.endCursor,
        );
      },
    ),
    idOf: (e) => e?.node?.path ?? '',
    pageSize: kDefaultPageSize,
  );
  ref.onDispose(controller.dispose);
  return controller;
});
