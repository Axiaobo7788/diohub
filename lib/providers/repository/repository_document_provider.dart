import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub/models/repository_document.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/repository/license_content_notifier.dart';
import 'package:diohub/providers/repository/readme_notifier.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

/// Cache identity for a repository document tab.
///
/// Including the branch prevents document content from leaking between branch
/// selections even though README and license retain their existing providers.
typedef RepositoryDocumentKey = ({
  RepoRef repoRef,
  String branch,
  RepositoryDocumentKind kind,
});

/// Loads repository document tabs only after a caller watches the selected tab.
///
/// README and license reuse the established providers. CONTRIBUTING and
/// SECURITY use rendered HTML from the Contents API through RepoContentService.
final FutureProviderFamily<RepositoryDocument?, RepositoryDocumentKey>
repositoryDocumentProvider = FutureProvider.autoDispose
    .family<RepositoryDocument?, RepositoryDocumentKey>((
      final Ref ref,
      final RepositoryDocumentKey key,
    ) async {
      keepAliveFor(ref);

      switch (key.kind) {
        case RepositoryDocumentKind.readme:
          final String? content = await ref.watch(
            readmeProvider(key.repoRef).future,
          );
          return content == null
              ? null
              : RepositoryDocument(
                  kind: key.kind,
                  branch: key.branch,
                  content: content,
                  format: RepositoryDocumentFormat.html,
                );
        case RepositoryDocumentKind.license:
          final String? content = await ref.watch(
            licenseContentProvider(key.repoRef).future,
          );
          return content == null
              ? null
              : RepositoryDocument(
                  kind: key.kind,
                  branch: key.branch,
                  content: content,
                  format: RepositoryDocumentFormat.markdown,
                );
        case RepositoryDocumentKind.contributing:
        case RepositoryDocumentKind.security:
          return key.repoRef
              .services(ref.read(apiClientProvider))
              .fetchRepositoryDocumentHtml(kind: key.kind, branch: key.branch);
      }
    });
