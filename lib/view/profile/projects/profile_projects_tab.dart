import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/search/search_filter_providers.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

const int _pageSize = 20;

/// Returns a [SliverListBody] for the projects (V2) list on a user/org profile.
TabBody createProfileProjectsBody(
  WidgetRef ref,
  UserRef userRef, {
  ValueNotifier<String>? queryNotifier,
}) {
  return SliverListBody<UserProjectV2Edge?>.textFilter(
    getCursor: (item) => item?.cursor,
    queryNotifier: queryNotifier,
    strategy: ref.watch(matchStrategyProvider),
    fields: [
      (item) => item?.node?.title,
      (item) => item?.node?.number.toString(),
    ],
    fetcher:
        ({String? after, int first = _pageSize, bool refresh = false}) async {
          final list = await ref
              .read(userInfoServiceProvider)
              .getUserProjectsV2(userRef.login, refresh: refresh, after: after);
          final last = list.isNotEmpty ? list.last : null;
          return PaginatedResult(
            items: list,
            hasNextPage: list.length >= first,
            endCursor: last?.cursor,
          );
        },
    itemBuilder: (BuildContext context, UserProjectV2Edge? item) {
      final UserProjectV2Node? node = item?.node;
      if (node == null) return const SizedBox.shrink();
      final ColorScheme cs = Theme.of(context).colorScheme;
      return TapFeedback(
        onTap: () => launchUrl(node.url),
        child: ListTile(
          leading: Icon(Octicons.project, color: cs.primary),
          title: Text(
            node.title,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          subtitle: Text(
            '#${node.number}${node.closed ? ' · Closed' : ''}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Icon(
            Icons.open_in_new,
            size: 18,
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    },
  );
}
