/// Riverpod provider for commit data.
///
/// [commitDataProvider] fetches commit info (GraphQL) and changed files (REST)
/// keyed by [CommitRef].
library;

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/async_notifier.dart';
import 'package:diohub/providers/database_providers.dart';

class _CommitAuthorFilterNotifier extends Notifier<String?> {
  _CommitAuthorFilterNotifier(this._arg);
  final RepoRef _arg;
  @override
  String? build() => null;
}

class _CommitPathFilterNotifier extends Notifier<String?> {
  _CommitPathFilterNotifier(this._arg);
  final RepoRef _arg;
  @override
  String? build() => null;
}

/// Current commit list author filter (e.g. login or email) per repo.
final commitAuthorFilterProvider =
    NotifierProvider.family<_CommitAuthorFilterNotifier, String?, RepoRef>(
  _CommitAuthorFilterNotifier.new,
);

/// Current commit list path filter (file path prefix) per repo.
final commitPathFilterProvider =
    NotifierProvider.family<_CommitPathFilterNotifier, String?, RepoRef>(
  _CommitPathFilterNotifier.new,
);

/// Bundles GraphQL commit info with the REST file list.
class CommitData {
  const CommitData({required this.info, this.files});

  final CommitInfo info;
  final List<FileElement>? files;
}

final commitDataProvider = AsyncNotifierProvider.autoDispose
    .family<CommitDataNotifier, CommitData, CommitRef>(
  CommitDataNotifier.new,
);

class CommitDataNotifier extends AsyncNotifier<CommitData> {
  CommitDataNotifier(this.arg);
  final CommitRef arg;

  @override
  Future<CommitData> build() async {
    keepAliveFor(ref);
    final services = arg.repo.services(ref.read(apiClientProvider));

    final CommitInfo info = await services.getCommitInfo(oid: arg.oid);

    List<FileElement>? files;
    try {
      final CommitModel commitModel = await services.getCommit(arg);
      files = commitModel.files;
    } catch (e, st) {
      AppLogger.warning(
        'Failed to fetch commit files via REST',
        error: e,
        stackTrace: st,
        tag: 'CommitDataNotifier',
      );
    }

    return CommitData(info: info, files: files);
  }
}
