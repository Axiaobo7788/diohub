import 'package:auto_route/auto_route.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class PremiumRouting {
  const PremiumRouting();

  PageRouteInfo? resolveEntityRoute(EntityRef ref) => null;

  PageRouteInfo? logViewerRoute({
    required String owner,
    required String repoName,
    required int jobId,
    String? jobName,
    int? runId,
  }) => null;

  PageRouteInfo? prReviewRoute(PRReviewRef ref) => null;

  PageRouteInfo? downloadsRoute() => null;

  List<AutoRoute> get routes => const [];
}

class DefaultPremiumRouting extends PremiumRouting {
  const DefaultPremiumRouting();
}

final premiumRoutingProvider = Provider<PremiumRouting>((ref) {
  return const DefaultPremiumRouting();
});

List<AutoRoute> get premiumRoutes => const [];
