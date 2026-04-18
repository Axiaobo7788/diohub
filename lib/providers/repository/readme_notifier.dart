/// README HTML provider for a repository. Depends on [repository_providers_core]
/// and [branch_notifier].
library;

import 'package:dio/dio.dart';
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/repository/branch_notifier.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/providers/repository/repository_providers_core.dart';
import 'package:diohub/services/repositories/repo_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/async_notifier.dart';
import 'package:diohub/providers/database_providers.dart';

final readmeProvider =
    AsyncNotifierProvider.autoDispose.family<ReadmeNotifier, String?, RepoRef>(
  ReadmeNotifier.new,
);

class ReadmeNotifier extends AsyncNotifier<String?> {
  ReadmeNotifier(this.arg);
  final RepoRef arg;

  @override
  Future<String?> build() async {
    keepAliveFor(ref);

    BranchState branch = ref.watch(branchProvider(arg));
    if (branch is BranchStateLoading) {
      await ref.read<Future<RepoInfoData>>(
        repositoryProvider(arg).future,
      );
      branch = ref.read<BranchState>(branchProvider(arg));
      if (branch case BranchStateLoading()) return null;
    }
    final BranchStateResolved resolved = branch as BranchStateResolved;

    final RepositoryServices services = arg.services(ref.read(apiClientProvider));
    try {
      return await services.fetchReadmeHtml(branch: resolved.currentSHA);
    } on DioException catch (e) {
      // 404 means no README exists — treat as absence, not error.
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
