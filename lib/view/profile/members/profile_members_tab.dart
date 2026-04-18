import 'package:diohub/common/misc/profile_card.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/search/search_filter_providers.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart' as gql;
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/users/profile_card_input.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _pageSize = 20;

/// Returns a [SliverListBody] for the members list on an org profile.
TabBody createMembersBody(
  WidgetRef ref,
  UserRef orgRef, {
  ValueNotifier<String>? queryNotifier,
}) {
  return SliverListBody<OrgMemberEdge?>.textFilter(
    getCursor: (item) => item?.cursor,
    queryNotifier: queryNotifier,
    strategy: ref.watch(matchStrategyProvider),
    fields: [
      (item) => (item?.node as gql.UserCardData?)?.login,
      (item) => (item?.node as gql.UserCardData?)?.name,
    ],
    fetcher:
        ({String? after, int first = _pageSize, bool refresh = false}) async {
          final list = await ref
              .read(userInfoServiceProvider)
              .getOrgMembers(orgRef.login, refresh: refresh, after: after);
          final last = list.isNotEmpty ? list.last : null;
          return PaginatedResult(
            items: list,
            hasNextPage: list.length >= first,
            endCursor: last?.cursor,
          );
        },
    itemBuilder: (BuildContext context, OrgMemberEdge? item) {
      final OrgMemberNode? node = item?.node;
      if (node == null) return const SizedBox.shrink();
      final ProfileCardInputUser input = ProfileCardInputUser(
        FragmentUser(node as gql.UserCardData),
      );
      return BorderedContainer(
        ref: UserRef(login: input.login),
        child: ProfileCard(input),
      );
    },
  );
}
