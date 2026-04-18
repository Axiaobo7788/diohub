import 'package:diohub_graphql/queries/common/common_typedefs.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/global_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Type of the mention-user search used by [UserSearchDropdown].
typedef MentionUserSearchFetch = Future<List<MentionUserEdge?>> Function(
  String query,
  String type, {
  String? cursor,
});

/// Provides the mention-user search so common layer can avoid importing [SearchService].
final Provider<MentionUserSearchFetch> mentionUserSearchFetchProvider =
    Provider<MentionUserSearchFetch>((ref) => (
          String query,
          String type, {
          String? cursor,
        }) =>
            ref.read(globalServicesProvider).search
                .searchMentionUsers(query, type, cursor: cursor));
