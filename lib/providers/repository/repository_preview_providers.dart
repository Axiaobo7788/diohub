import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub/models/repository_contributor_preview.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// First contributors for the Code sidebar, fetched independently from the
/// repository's full GraphQL payload so it can never block the page shell.
final repositoryContributorPreviewProvider = FutureProvider.autoDispose
    .family<List<RepositoryContributorPreview>, RepoRef>((
      final Ref ref,
      final RepoRef repoRef,
    ) async {
      keepAliveFor(ref);
      return repoRef
          .services(ref.read(apiClientProvider))
          .fetchContributorPreview();
    });
