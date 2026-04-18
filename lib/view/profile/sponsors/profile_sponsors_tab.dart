import 'package:diohub/common/misc/profile_card.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/users/profile_card_input.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _pageSize = 20;

/// Returns a [SliverListBody] for the sponsors list on a user profile.
TabBody createSponsorsBody(WidgetRef ref, UserRef userRef) {
  return SliverListBody<UserSponsorEdge?>(
    getCursor: (item) => item?.cursor,
    fetcher:
        ({String? after, int first = _pageSize, bool refresh = false}) async {
          final list = await ref
              .read(userInfoServiceProvider)
              .getUserSponsors(userRef.login, refresh: refresh, after: after);
          final last = list.isNotEmpty ? list.last : null;
          return PaginatedResult(
            items: list,
            hasNextPage: list.length >= first,
            endCursor: last?.cursor,
          );
        },
    itemBuilder: (BuildContext context, UserSponsorEdge? item) {
      final UserSponsorNode? node = item?.node;
      if (node == null) return const SizedBox.shrink();
      final ProfileCardInput? input = node.maybeWhen(
        user: (UserSponsorAsUser u) => ProfileCardInputUser(FragmentUser(u)),
        organization: (UserSponsorAsOrg o) =>
            ProfileCardInputOrg(FragmentOrg(o)),
        orElse: () => null,
      );
      if (input == null) return const SizedBox.shrink();
      return BorderedContainer(
        ref: UserRef(login: input.login),
        child: ProfileCard(input),
      );
    },
  );
}
