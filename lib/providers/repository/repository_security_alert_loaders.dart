import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub_models/models/repositories/code_scanning_alert_item.dart';
import 'package:diohub_models/models/repositories/secret_scanning_alert.dart';
import 'package:diohub_models/models/repositories/vulnerability_alert_item.dart';
import 'package:diohub_models/models/repositories/vulnerability_alerts_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef DependabotAlertsPageLoader =
    Future<PaginatedResult<VulnerabilityAlertEdge>> Function({
      required int first,
      String? after,
    });

typedef CodeScanningAlertsPageLoader =
    Future<List<CodeScanningAlertItem>> Function({
      required int page,
      required int perPage,
    });

typedef SecretScanningAlertsPageLoader =
    Future<List<SecretScanningAlert>> Function({
      required int page,
      required int perPage,
    });

/// Formal repository security transports used by the three lazy alert lists.
///
/// This is an injectable domain boundary, not another loading framework: the
/// existing services still own GitHub transport and projection, while the
/// existing pagination controllers continue to own list paging.
final class RepositorySecurityAlertLoaders {
  const RepositorySecurityAlertLoaders({
    required this.loadDependabot,
    required this.loadCodeScanning,
    required this.loadSecretScanning,
  });

  final DependabotAlertsPageLoader loadDependabot;
  final CodeScanningAlertsPageLoader loadCodeScanning;
  final SecretScanningAlertsPageLoader loadSecretScanning;
}

final repositorySecurityAlertLoadersProvider =
    Provider.family<RepositorySecurityAlertLoaders, RepoRef>(
      (final Ref ref, final RepoRef repoRef) => RepositorySecurityAlertLoaders(
        loadDependabot:
            ({required final int first, final String? after}) async {
              final VulnerabilityAlertsResult result = await repoRef
                  .stats(ref.read(apiClientProvider))
                  .fetchVulnerabilityAlerts(first: first, after: after);
              return PaginatedResult<VulnerabilityAlertEdge>(
                items: result.items,
                hasNextPage: result.hasNextPage,
                endCursor: result.endCursor,
              );
            },
        loadCodeScanning:
            ({required final int page, required final int perPage}) async {
              final PaginatedResult<CodeScanningAlertItem> result =
                  await repoRef
                      .stats(ref.read(apiClientProvider))
                      .listCodeScanningAlerts(page: page, perPage: perPage);
              return result.items;
            },
        loadSecretScanning:
            ({required final int page, required final int perPage}) => repoRef
                .services(ref.read(apiClientProvider))
                .listSecretScanningAlerts(page: page, perPage: perPage),
      ),
    );
