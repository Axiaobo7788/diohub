import 'package:diohub/providers/database_providers.dart' show apiClientProvider;
import 'package:diohub/services/node_mutations/comment_node_resolver_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final commentNodeResolverServiceProvider =
    Provider<CommentNodeResolverService>(
  (ref) => CommentNodeResolverService(ref.read(apiClientProvider)),
);

/// Resolves the createdAt timestamp for a comment node by ID.
/// Used by discussion anchor callback for scroll-to-comment.
final commentCreatedAtProvider =
    FutureProvider.autoDispose.family<DateTime?, String>(
  (final Ref ref, final String nodeId) =>
      ref.read(commentNodeResolverServiceProvider).resolveNodeCreatedAt(nodeId),
);

/// Comment draft data for issue/PR compose. Replaces legacy [ChangeNotifier].
/// Use [commentDataProvider.notifier] to update or clear.
class CommentDataNotifier extends Notifier<String> {
  @override
  String build() => '';
}

final commentDataProvider =
    NotifierProvider.autoDispose<CommentDataNotifier, String>(
  CommentDataNotifier.new,
);
