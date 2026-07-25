import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/providers/repository/repository_issue_pull_page_resource.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef RepositoryIssuePullRuntimePageSourceFactory =
    RuntimeForwardPageSource<Object, RepositoryIssuePullPageKey> Function({
      required RepoRef repo,
      required String query,
      required bool signedIn,
      required ResourceScope scope,
    });

/// Binds the generic Runtime pagination bridge to Repository Issues/PR.
///
/// Query-session ownership stays in the page's PaginationController. This
/// provider captures the current Runtime and an immutable page spec factory.
/// The page keys sessions by [ResourceScope], disposes them when that scope
/// changes, and the replacement source then resolves only its selected
/// authenticated or public transport.
final repositoryIssuePullRuntimePageSourceFactoryProvider =
    Provider<RepositoryIssuePullRuntimePageSourceFactory>((final Ref ref) {
      final ResourceRuntime runtime = ref.watch(resourceRuntimeProvider);
      final RepositoryIssuePullPageResourceSpecFactory specFactory = ref.watch(
        repositoryIssuePullPageResourceSpecFactoryProvider,
      );
      return ({
        required final RepoRef repo,
        required final String query,
        required final bool signedIn,
        required final ResourceScope scope,
      }) {
        final RepositoryIssuePullPageTransport transport = signedIn
            ? RepositoryIssuePullPageTransport.authenticatedGraphql
            : RepositoryIssuePullPageTransport.publicRest;
        return RuntimeForwardPageSource<Object, RepositoryIssuePullPageKey>(
          runtime: runtime,
          firstPageKey: repositoryIssuePullFirstPageKey(transport),
          specFactory:
              ({
                required final RepositoryIssuePullPageKey pageKey,
                required final int pageSize,
              }) => specFactory(
                repo: repo,
                query: query,
                transport: transport,
                pageKey: pageKey,
                pageSize: pageSize,
                scope: scope,
              ),
          refreshSelector: repositoryIssuePullQuerySelector(
            repo: repo,
            query: query,
            transport: transport,
            scope: scope,
          ),
        );
      };
    });
