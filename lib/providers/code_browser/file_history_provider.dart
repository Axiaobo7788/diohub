import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub/models/commits/commit_list_item_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

/// Key for [fileHistoryProvider].
typedef FileHistoryKey = ({RepoRef repo, String branch, String path});

final fileHistoryProvider = NotifierProvider.autoDispose.family<
    FileHistoryNotifier,
    PaginationController<CommitEdge?, CommitListItemModel>,
    FileHistoryKey>(FileHistoryNotifier.new);

class FileHistoryNotifier extends Notifier<
    PaginationController<CommitEdge?, CommitListItemModel>> {
  FileHistoryNotifier(this._key);
  final FileHistoryKey _key;

  @override
  PaginationController<CommitEdge?, CommitListItemModel> build() {
    final controller =
        PaginationController<CommitEdge?, CommitListItemModel>(
      source: CursorForwardSource<CommitEdge?>(
        fetch: ({required int first, String? after}) async {
          final String? refArg = _key.branch.length == 40
              ? null
              : _key.branch.startsWith('refs/')
                  ? _key.branch
                  : 'refs/heads/${_key.branch}';
          final connection = await _key.repo.services(ref.read(apiClientProvider)).getCommitsListGQL(
            first: first,
            after: after,
            path: _key.path.isEmpty ? null : _key.path,
            ref: refArg,
            oid: _key.branch.length == 40 ? _key.branch : null,
          );
          final edges = connection.edges?.toList() ?? [];
          return CursorPage<CommitEdge?>(
            items: edges,
            hasNextPage: connection.pageInfo.hasNextPage,
            endCursor: connection.pageInfo.endCursor,
          );
        },
      ),
      idOf: (m) => m.sha,
      transform: (raw) {
        return raw
            .where((e) => e?.node != null)
            .map((e) => CommitListItemModel.fromGcommitListItem(
                  e!.node! as CommitNode,
                  _key.repo,
                ))
            .toList();
      },
      pageSize: 20,
    );
    ref.onDispose(controller.dispose);
    return controller;
  }
}
