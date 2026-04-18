/// Riverpod providers for repository data and mutations.
///
/// [repositoryProvider] is the primary data provider keyed by [RepoRef].
/// [branchProvider] is the current branch/SHA keyed by [RepoRef].
/// [readmeProvider], [licenseContentProvider], [commitGraphProvider] are
/// in separate files and re-exported here.
library;

import 'package:dio/dio.dart';
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/services/repositories/repo_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/future_provider.dart';
import 'package:diohub/providers/database_providers.dart';

export 'package:diohub/providers/repository/branch_notifier.dart'
    show
        applyInitialRef,
        branchInitialOverride,
        branchProvider,
        BranchNotifier,
        BranchState,
        BranchStateLoading,
        BranchStateResolved,
        RefKind,
        RepoRevision,
        RepositoryInitialRef;
export 'package:diohub/providers/repository/commit_graph_notifier.dart'
    show commitGraphProvider, CommitGraphData, CommitGraphNotifier;
export 'package:diohub/providers/repository/license_content_notifier.dart'
    show licenseContentProvider, LicenseContentNotifier;
export 'package:diohub/providers/repository/readme_notifier.dart'
    show readmeProvider, ReadmeNotifier;
export 'package:diohub/providers/repository/repository_providers_core.dart'
    show
        compareResultProvider,
        repoCardProvider,
        repositoryProvider,
        RepositoryNotifier;

/// Fetches the profile README HTML for a **user** (from the `{login}/{login}`
/// repo) without depending on [branchProvider] or [repositoryProvider].
///
/// This avoids a full repository GraphQL fetch just to discover the default
/// branch, since the REST API returns the default branch README when no `ref`
/// is specified.
final profileReadmeHtmlProvider = FutureProvider.autoDispose
    .family<String?, UserRef>((final Ref ref, final UserRef userRef) async {
  keepAliveFor(ref);
  final RepoRef repoRef = RepoRef(owner: userRef.login, name: userRef.login);
  final RepositoryServices services = repoRef.services(ref.read(apiClientProvider));
  try {
    return await services.fetchReadmeHtml();
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});

/// Fetches the profile README HTML for an **organization** (from the
/// `{login}/.github` repo, sub-directory `profile/README.md`).
///
/// GitHub's org profile README convention differs from users:
///   - Users  → `{login}/{login}` repo, root `README.md`
///   - Orgs   → `{login}/.github` repo, `profile/README.md`
///
/// Uses the REST "get a repository README for a directory" endpoint:
/// `GET /repos/{owner}/{repo}/readme/{dir}`
final orgProfileReadmeHtmlProvider = FutureProvider.autoDispose
    .family<String?, UserRef>((final Ref ref, final UserRef userRef) async {
  keepAliveFor(ref);
  final RepoRef repoRef = RepoRef(owner: userRef.login, name: '.github');
  final RepositoryServices services = repoRef.services(ref.read(apiClientProvider));
  try {
    return await services.fetchReadmeHtml(dir: 'profile');
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});
