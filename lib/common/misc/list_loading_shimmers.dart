import 'package:diohub/common/cards/code_result_card.dart';
import 'package:diohub/common/cards/commit_card.dart';
import 'package:diohub/common/cards/discussion_card.dart';
import 'package:diohub/common/cards/issue_pull_card.dart';
import 'package:diohub/common/cards/package_card.dart';
import 'package:diohub/common/cards/topic_card.dart';
import 'package:diohub/common/cards/wiki_card.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/list_card_shimmer_list.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/timeline/timeline_shimmer_item.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shared first-page loading builders for paginated card lists.
///
/// Use these as [firstPageLoadingBuilder] so every card list shows
/// BorderedContainer + skeleton shimmers consistent with the loaded content.
class ListLoadingShimmers {
  ListLoadingShimmers._();

  /// Issue/PR list: BorderedContainer + [IssuePullLoadingCard].
  /// Use for search (issues/pulls), notifications.
  static Widget issuePullList(
    final BuildContext context, {
    final int itemCount = 5,
  }) {
    final AppSpacing sp = context.spacing;
    return ListCardShimmerList(
      itemCount: itemCount,
      separatorHeight: sp.itemSpacing,
      padding: EdgeInsets.only(
        left: sp.listInset.left,
        right: sp.listInset.right,
        bottom: sp.listPaddingBottom,
      ),
      itemBuilder: (final _) => Padding(
        padding: EdgeInsets.only(bottom: sp.itemSpacing),
        child: const ShimmerScope(
          child: BorderedContainer(
            child: IssuePullLoadingCard(),
          ),
        ),
      ),
    );
  }

  /// Repo list: BorderedContainer + [RepositoryCardSkeleton].
  /// Use for user repositories, repo search results.
  static Widget repoList(
    final BuildContext context, {
    final int itemCount = 5,
  }) =>
      ListCardShimmerList(
        itemCount: itemCount,
        itemBuilder: (final BuildContext context) => Padding(
          padding: context.spacing.listInset,
          child: const ShimmerScope(
            child: BorderedContainer(
              child: RepositoryCardSkeleton(),
            ),
          ),
        ),
      );

  /// Timeline list: [TimelineShimmerList] with optional user headers.
  /// Use for events, discussion timeline, activity timeline.
  static Widget timeline(
    final BuildContext context, {
    final int itemCount = 5,
    final bool showAvatar = false,
    final bool showUserHeaders = false,
    final EdgeInsets? padding,
  }) =>
      TimelineShimmerList(
        itemCount: itemCount,
        showAvatar: showAvatar,
        showUserHeaders: showUserHeaders,
        padding: padding ?? const EdgeInsets.only(left: 8, right: 8, top: 8),
      );

  /// Commit list: BorderedContainer + [CommitCardSkeleton].
  /// Use for commit browser, commit graph, pull commits tab.
  static Widget commitList(
    final BuildContext context, {
    final int itemCount = 5,
  }) {
    final AppSpacing sp = context.spacing;
    return ListCardShimmerList(
      itemCount: itemCount,
      separatorHeight: sp.itemSpacing,
      padding: EdgeInsets.only(
        left: sp.listInset.left,
        right: sp.listInset.right,
        bottom: sp.listPaddingBottom,
      ),
      itemBuilder: (final _) => Padding(
        padding: EdgeInsets.only(bottom: sp.itemSpacing),
        child: const ShimmerScope(
          child: BorderedContainer(
            child: CommitCardSkeleton(),
          ),
        ),
      ),
    );
  }

  /// Discussion list: BorderedContainer + [DiscussionCardSkeleton].
  static Widget discussionList(
    final BuildContext context, {
    final int itemCount = 5,
  }) =>
      _skeletonList(
        context,
        itemCount: itemCount,
        builder: () => const ShimmerScope(
          child: BorderedContainer(
            child: DiscussionCardSkeleton(),
          ),
        ),
      );

  /// Code result list: BorderedContainer + [CodeResultCardSkeleton].
  static Widget codeList(
    final BuildContext context, {
    final int itemCount = 5,
  }) =>
      _skeletonList(
        context,
        itemCount: itemCount,
        builder: () => const ShimmerScope(
          child: BorderedContainer(
            child: CodeResultCardSkeleton(),
          ),
        ),
      );

  /// Topic list: BorderedContainer + [TopicCardSkeleton].
  static Widget topicList(
    final BuildContext context, {
    final int itemCount = 5,
  }) =>
      _skeletonList(
        context,
        itemCount: itemCount,
        builder: () => const ShimmerScope(
          child: BorderedContainer(
            child: TopicCardSkeleton(),
          ),
        ),
      );

  /// Package list: BorderedContainer + [PackageCardSkeleton].
  static Widget packageList(
    final BuildContext context, {
    final int itemCount = 5,
  }) =>
      _skeletonList(
        context,
        itemCount: itemCount,
        builder: () => const ShimmerScope(
          child: BorderedContainer(
            child: PackageCardSkeleton(),
          ),
        ),
      );

  /// Wiki list: BorderedContainer + [WikiCardSkeleton].
  static Widget wikiList(
    final BuildContext context, {
    final int itemCount = 5,
  }) =>
      _skeletonList(
        context,
        itemCount: itemCount,
        builder: () => const ShimmerScope(
          child: BorderedContainer(
            child: WikiCardSkeleton(),
          ),
        ),
      );

  /// User / profile list: timeline-style shimmer with user headers.
  /// Use for user/org search results.
  static Widget userList(
    final BuildContext context, {
    final int itemCount = 5,
  }) =>
      timeline(
        context,
        itemCount: itemCount,
        showUserHeaders: true,
      );

  static Widget _skeletonList(
    final BuildContext context, {
    final int itemCount = 5,
    required final Widget Function() builder,
  }) {
    final AppSpacing sp = context.spacing;
    return ListCardShimmerList(
      itemCount: itemCount,
      separatorHeight: sp.itemSpacing,
      padding: EdgeInsets.only(
        left: sp.listInset.left,
        right: sp.listInset.right,
        bottom: sp.listPaddingBottom,
      ),
      itemBuilder: (final _) => Padding(
        padding: EdgeInsets.only(bottom: sp.itemSpacing),
        child: builder(),
      ),
    );
  }
}
