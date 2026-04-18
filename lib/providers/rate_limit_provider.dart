import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/providers/database_providers.dart' show apiClientProvider;
import 'package:diohub_graphql/queries/common/rate_limit.graphql.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches current GraphQL API rate limit (limit, remaining, used, resetAt, etc.).
/// Used by the "View GraphQL quota" settings row.
final FutureProvider<RateLimitData?> rateLimitProvider = FutureProvider<RateLimitData?>((final Ref ref) async {
  final GQLResponse response = await ref.read(apiClientProvider).gql.query(
    documentNodeQuerygetRateLimit,
    <String, dynamic>{},
  );
  final RateLimitData data = RateLimitData.fromJson(response.data!);
  return data;
});
