import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub/providers/database_providers.dart';

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key for fetching a single release by repo + tag (e.g. events feed).
typedef ReleaseByTagKey = ({RepoRef repoRef, String tagName});

/// Fetches a single release by tag name. Use for [ReleaseCard] in events feed.
final releaseByTagProvider = FutureProvider.autoDispose
    .family<ReleaseListItemData?, ReleaseByTagKey>(
        (final Ref ref, final ReleaseByTagKey key) async {
  return key.repoRef.releases(ref.read(apiClientProvider)).fetchReleaseByTag(key.tagName);
});

/// Fetches a single discussion by number. Use for [DiscussionCard] in events feed and notifications.
final discussionByNumberProvider = FutureProvider.autoDispose
    .family<DiscussionCardData?, DiscussionRef>(
        (final Ref ref, final DiscussionRef discussionRef) async {
  return discussionRef.repo.services(ref.read(apiClientProvider)).fetchDiscussionByNumber(discussionRef.number);
});
