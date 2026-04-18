/// License file content provider for a repository. Depends on
/// [repository_providers_core] and [branch_notifier].
library;

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/repository/branch_notifier.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/providers/repository/repository_providers_core.dart';
import 'package:diohub/services/git_database/git_database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/async_notifier.dart';
import 'package:diohub/providers/database_providers.dart';

final licenseContentProvider = AsyncNotifierProvider.autoDispose
    .family<LicenseContentNotifier, String?, RepoRef>(
  LicenseContentNotifier.new,
);

class LicenseContentNotifier extends AsyncNotifier<String?> {
  LicenseContentNotifier(this.arg);
  final RepoRef arg;

  static const List<String> _licensePaths = <String>[
    'LICENSE',
    'LICENSE.md',
    'LICENSE.txt',
    'LICENCE',
    'COPYING',
  ];

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
    final GitDatabaseService gitDb = arg.gitDb(ref.read(apiClientProvider));
    for (final String path in _licensePaths) {
      try {
        final blob = await gitDb.getFileByExpression(
          expression: '${resolved.currentSHA}:$path',
        );
        final String? text = blob.text;
        if (text != null && text.isNotEmpty) return text;
      } catch (e, st) {
        AppLogger.warning(
          'License file read failed for path: $path',
          error: e,
          stackTrace: st,
          tag: 'licenseProvider',
        );
        continue;
      }
    }
    return null;
  }
}
