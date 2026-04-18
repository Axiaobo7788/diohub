import 'package:diohub/common/cards/team_card.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/search/search_filter_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub_graphql/queries/common/common_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _pageSize = 20;

/// Returns a [SliverListBody] for the teams list on an org profile.
TabBody createTeamsBody(
  WidgetRef ref,
  UserRef orgRef, {
  ValueNotifier<String>? queryNotifier,
}) {
  return SliverListBody<OrgTeamEdge?>.textFilter(
    getCursor: (item) => item?.cursor,
    queryNotifier: queryNotifier,
    strategy: ref.watch(matchStrategyProvider),
    fields: [(item) => item?.node?.name, (item) => item?.node?.slug],
    fetcher:
        ({String? after, int first = _pageSize, bool refresh = false}) async {
          final list = await ref
              .read(userInfoServiceProvider)
              .getOrgTeams(orgRef.login, refresh: refresh, after: after);
          final last = list.isNotEmpty ? list.last : null;
          return PaginatedResult(
            items: list,
            hasNextPage: list.length >= first,
            endCursor: last?.cursor,
          );
        },
    itemBuilder: (BuildContext context, OrgTeamEdge? item) =>
        switch (item?.node) {
          null => const SizedBox.shrink(),
          final node => Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.pagePadding.horizontal / 2,
              vertical: context.spacing.tightSpacing / 2,
            ),
            child: BorderedContainer(
              child: TeamCard(team: node, orgLogin: orgRef.login),
            ),
          ),
        },
  );
}
