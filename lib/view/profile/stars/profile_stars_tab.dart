import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/search/search_filter_providers.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub_models/models/repositories/star_mutation_result.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _pageSize = 20;

/// Returns a [SliverListBody] for the starred repos list on a user profile.
TabBody createStarsBody(
  WidgetRef ref,
  UserRef userRef, {
  ValueNotifier<String>? queryNotifier,
}) {
  return SliverListBody<UserStarredRepoEdge?>.textFilter(
    getCursor: (item) => item?.cursor,
    queryNotifier: queryNotifier,
    strategy: ref.watch(matchStrategyProvider),
    fields: [(item) => item?.node.nameWithOwner, (item) => item?.node.name],
    fetcher:
        ({String? after, int first = _pageSize, bool refresh = false}) async {
          final list = await ref
              .read(userInfoServiceProvider)
              .getUserStarredRepositories(
                userRef.login,
                refresh: refresh,
                after: after,
              );
          if (refresh) {
            for (final UserStarredRepoEdge? edge in list) {
              final UserStarredRepoNode? node = edge?.node;
              if (node == null) continue;
              final RepoCardData repository = node;
              final RepoRef repositoryRef = RepoRef.fromRepoCardFields(
                repository,
              );
              if (!ref.exists(repositoryStarProvider(repositoryRef))) continue;
              ref
                  .read(repositoryStarProvider(repositoryRef).notifier)
                  .acceptAuthoritativeSeed(
                    StarMutationResult(
                      viewerHasStarred: repository.viewerHasStarred,
                      stargazerCount: repository.stargazerCount,
                    ),
                  );
            }
          }
          final last = list.isNotEmpty ? list.last : null;
          return PaginatedResult(
            items: list,
            hasNextPage: list.length >= first,
            endCursor: last?.cursor,
          );
        },
    itemBuilder: (BuildContext context, UserStarredRepoEdge? item) {
      final UserStarredRepoNode? node = item?.node;
      if (node == null) return const SizedBox.shrink();
      final RepoCardData repoFields = node;
      final RepoRef repoRef = RepoRef.fromRepoCardFields(repoFields);
      return Consumer(
        builder: (BuildContext ctx, WidgetRef r, _) => BorderedContainer(
          ref: repoRef,
          child: RepositoryCard(
            repoFields,
            starChip: RepoStarChipFromData(
              repoRef: repoRef,
              repoNodeId: repoFields.id,
              initialStarCount: repoFields.stargazerCount,
              initialIsStarred: repoFields.viewerHasStarred,
            ),
          ),
        ),
      );
    },
  );
}
