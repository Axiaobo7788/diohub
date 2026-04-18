import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub_models/models/issues/issue_pull_mutation_result.dart';
import 'package:diohub/services/capabilities/capabilities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

/// Cursor source for comment edit history (userContentEdits) by node ID.
/// Used by [showCommentEditHistorySheet].
final commentEditHistorySourceProvider =
    Provider.family<CursorForwardSource<CommentEditHistoryItem>, String>(
        (ref, commentNodeId) {
  return CursorForwardSource<CommentEditHistoryItem>(
    fetch: ({required int first, String? after}) =>
        CommentNodeService(ref.read(apiClientProvider), commentNodeId).getEditHistoryPage(
      first: first,
      after: after,
    ),
  );
});
