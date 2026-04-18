import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/search/client_text_matcher.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef _Edge = UserRepoEdge;

final _matcher = ClientTextMatcher<_Edge>(
  fields: [(_Edge e) => e.node?.nameWithOwner],
);

/// Shared controller for paginated repo lists with client-side text filtering.
///
/// Used by [TransferIssueSheet] and [RepoPickerBottomSheet].
class RepoListFilterController {
  RepoListFilterController({
    required this.userRef,
    required this.queryNotifier,
    required this.ref,
    this.pageSize = 20,
  }) {
    _query = queryNotifier.value;
    queryNotifier.addListener(_onQueryChanged);
  }

  final UserRef userRef;
  final ValueNotifier<String> queryNotifier;
  final WidgetRef ref;
  final int pageSize;

  String _query = '';
  PaginationController<_Edge, _Edge>? _controller;

  PaginationController<_Edge, _Edge> get controller {
    _controller ??= PaginationController<_Edge, _Edge>(
      source: CursorForwardSource<_Edge>(
        fetch: ({required int first, String? after}) async {
          final conn =
              await ref.read(userInfoServiceProvider).getUserRepositories(
                    userRef.login,
                    first,
                    refresh: false,
                    after: after,
                  );
          final edges = conn.edges?.whereType<_Edge>().toList() ?? <_Edge>[];
          final pageInfo = conn.pageInfo;
          return CursorPage<_Edge>(
            items: edges,
            hasNextPage: pageInfo.hasNextPage,
            endCursor: pageInfo.endCursor,
          );
        },
      ),
      idOf: (_Edge e) => e.cursor,
      filter: (List<_Edge> items) => _matcher.filter(items, _query),
      pageSize: pageSize,
    );
    return _controller!;
  }

  void _onQueryChanged() {
    final String q = queryNotifier.value;
    if (_query != q) {
      _query = q;
      _controller?.refilter();
    }
  }

  void dispose() {
    queryNotifier.removeListener(_onQueryChanged);
    _controller?.dispose();
  }
}
