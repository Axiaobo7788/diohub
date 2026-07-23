import 'dart:async';

import 'package:diohub/models/repository_preview.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/repository/branch_notifier.dart';
import 'package:diohub/providers/repository/repository_preview_provider.dart';
import 'package:diohub/providers/repository/repository_providers_core.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('repositoryPreviewProvider', () {
    test('stores a seed under its exact repository route key', () {
      final RepoRef routeKey = RepoRef(
        owner: 'refetch-project',
        name: 'concept',
        nodeId: 'R_concept',
      );
      final RepoRef equivalentKey = RepoRef(
        owner: 'refetch-project',
        name: 'concept',
        nodeId: 'R_concept',
      );
      final RepoRef differentKey = RepoRef(
        owner: 'refetch-project',
        name: 'core-rust',
        nodeId: 'R_core',
      );
      const RepositoryPreview preview = RepositoryPreview(
        fullName: 'refetch-project/concept',
        name: 'concept',
        owner: 'refetch-project',
        ownerAvatarUrl: 'https://avatars.example/refetch-project.png',
        isPrivate: false,
        nodeId: 'R_concept',
        defaultBranch: 'develop',
      );
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(repositoryPreviewProvider(routeKey).notifier)
          .seed(preview);

      expect(container.read(repositoryPreviewProvider(equivalentKey)), preview);
      expect(container.read(repositoryPreviewProvider(differentKey)), isNull);
    });

    test('ignores a seed whose full name does not match the route key', () {
      const RepoRef routeKey = RepoRef(owner: 'octocat', name: 'hello-world');
      const RepositoryPreview wrongRepository = RepositoryPreview(
        fullName: 'octocat/a-different-repository',
        name: 'a-different-repository',
        owner: 'octocat',
        ownerAvatarUrl: null,
        isPrivate: false,
        defaultBranch: 'main',
      );
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(repositoryPreviewProvider(routeKey).notifier)
          .seed(wrongRepository);

      expect(container.read(repositoryPreviewProvider(routeKey)), isNull);
    });
  });

  test(
    'branchProvider resolves the preview branch while full repository loads',
    () async {
      const RepoRef repoRef = RepoRef(
        owner: 'refetch-project',
        name: 'concept',
        nodeId: 'R_concept',
      );
      const RepositoryPreview preview = RepositoryPreview(
        fullName: 'refetch-project/concept',
        name: 'concept',
        owner: 'refetch-project',
        ownerAvatarUrl: null,
        isPrivate: false,
        nodeId: 'R_concept',
        defaultBranch: 'develop',
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          accountProvider.overrideWith(_SignedInAccountNotifier.new),
          repositoryProvider.overrideWith2(_PendingRepositoryNotifier.new),
        ],
      );
      addTearDown(container.dispose);
      await container.read(accountProvider.future);
      container.read(repositoryPreviewProvider(repoRef).notifier).seed(preview);

      final BranchState branch = container.read(branchProvider(repoRef));

      expect(
        container.read(repositoryProvider(repoRef)),
        isA<AsyncLoading<RepoInfoData>>(),
      );
      expect(branch, isA<BranchStateResolved>());
      final BranchStateResolved resolved = branch as BranchStateResolved;
      expect(resolved.refValue, 'develop');
      expect(resolved.refKind, RefKind.branch);
      expect(resolved.oid, isNull);
      expect(resolved.treeOid, isEmpty);
    },
  );
}

final class _SignedInAccountNotifier extends AccountNotifier {
  @override
  Future<AccountSession?> build() async {
    final AccountModel account = AccountModel(
      nodeId: 'U_octocat',
      username: 'octocat',
      addedAt: DateTime.utc(2026),
    );
    return AccountSession(
      accounts: <AccountModel>[account],
      activeAccount: account.username,
    );
  }
}

final class _PendingRepositoryNotifier extends RepositoryNotifier {
  _PendingRepositoryNotifier(super.arg);

  @override
  Future<RepoInfoData> build() => Completer<RepoInfoData>().future;
}
