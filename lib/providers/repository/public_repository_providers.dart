import 'package:diohub/models/repositories/public_repository.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/services/repositories/public_repository_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<PublicRepositoryService> publicRepositoryServiceProvider =
    Provider<PublicRepositoryService>(
      (final Ref ref) =>
          PublicRepositoryService(ref.watch(apiClientProvider).rest),
    );

final publicRepositorySearchProvider = FutureProvider.autoDispose
    .family<List<PublicRepositorySummary>, String>((
      final Ref ref,
      final String query,
    ) async {
      return ref
          .watch(publicRepositoryServiceProvider)
          .searchRepositories(query);
    });

typedef PublicRepositoryContentsRequest = ({
  String fullName,
  String path,
  String ref,
});

final publicRepositoryContentsProvider = FutureProvider.autoDispose
    .family<List<PublicRepositoryEntry>, PublicRepositoryContentsRequest>((
      final Ref ref,
      final PublicRepositoryContentsRequest request,
    ) async {
      return ref
          .watch(publicRepositoryServiceProvider)
          .listContents(
            fullName: request.fullName,
            ref: request.ref,
            path: request.path,
          );
    });

typedef PublicRepositoryFileRequest = ({
  String fullName,
  String path,
  String ref,
});

final publicRepositoryFileProvider = FutureProvider.autoDispose
    .family<String, PublicRepositoryFileRequest>((
      final Ref ref,
      final PublicRepositoryFileRequest request,
    ) async {
      return ref
          .watch(publicRepositoryServiceProvider)
          .readTextFile(
            fullName: request.fullName,
            ref: request.ref,
            path: request.path,
          );
    });
