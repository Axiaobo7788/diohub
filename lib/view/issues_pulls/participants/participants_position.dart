import 'package:diohub/common/widgets/metadata_rows.dart';
import 'package:diohub/common/widgets/metadata_section_sliver.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/fragments/common_exports.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Participants position body for Issue: Author, Assignees, Commenters.
class IssueParticipantsPosition extends ConsumerWidget {
  const IssueParticipantsPosition({
    required this.issueRef,
    required this.data,
    super.key,
  });

  final IssueRef issueRef;
  final IssueInfo data;

  /// Slivers for use inside the shell's [CustomScrollView]. Use this from
  /// [SliverBuilderBody]; [build] is for standalone use.
  List<Widget> buildSlivers(final BuildContext context, final WidgetRef ref) {
    final AppSpacing spacing = context.spacing;
    final Actor? author = data.author;
    final List<Actor> assignees =
        data.assignees.nodes?.whereType<Actor>().toList() ?? <Actor>[];
    final List<Actor> participantNodes =
        data.participants.nodes?.whereType<Actor>().toList() ?? <Actor>[];
    final Set<String> authorAndAssignees = <String>{
      if (author != null) author.login,
      ...assignees.map((final Actor e) => e.login),
    };
    final List<Actor> commenters = participantNodes
        .where((final Actor p) => !authorAndAssignees.contains(p.login))
        .toList();

    final List<Widget> sectionSlivers = <Widget>[];

    if (author != null) {
      sectionSlivers.add(
        MetadataSectionSliver(
          title: 'Author',
          children: <Widget>[
            MetadataUserRow(
              avatarUrl: author.avatarUrl.toString(),
              login: author.login,
              onTap: () => UserRef(login: author.login).navigate(context, ref),
            ),
          ],
        ),
      );
    }

    if (assignees.isNotEmpty) {
      sectionSlivers.add(
        MetadataSectionSliver(
          title: 'Assignees',
          children: assignees
              .map(
                (final Actor a) => MetadataUserRow(
                  avatarUrl: a.avatarUrl.toString(),
                  login: a.login,
                  onTap: () => UserRef(login: a.login).navigate(context, ref),
                ),
              )
              .toList(),
        ),
      );
    }

    if (commenters.isNotEmpty) {
      sectionSlivers.add(
        MetadataSectionSliver(
          title: 'Commenters',
          children: commenters
              .map(
                (final Actor c) => MetadataUserRow(
                  avatarUrl: c.avatarUrl.toString(),
                  login: c.login,
                  onTap: () => UserRef(login: c.login).navigate(context, ref),
                ),
              )
              .toList(),
        ),
      );
    }

    if (sectionSlivers.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              'No participants',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      ];
    }

    return <Widget>[
      SliverPadding(
        padding: spacing.pagePadding,
        sliver: SliverList(
          delegate: SliverChildListDelegate(sectionSlivers),
        ),
      ),
    ];
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) =>
      CustomScrollView(slivers: buildSlivers(context, ref));
}

/// Participants position body for PR: Author, Assignees, Reviewers, Commenters.
class PullParticipantsPosition extends ConsumerWidget {
  const PullParticipantsPosition({
    required this.pullRef,
    required this.data,
    super.key,
  });

  final PullRequestRef pullRef;
  final PullInfo data;

  static IconData _reviewStateIcon(final PullRequestReviewState state) {
    switch (state) {
      case PullRequestReviewState.APPROVED:
        return Icons.check_circle;
      case PullRequestReviewState.CHANGES_REQUESTED:
        return Icons.cancel;
      case PullRequestReviewState.PENDING:
      case PullRequestReviewState.COMMENTED:
      case PullRequestReviewState.DISMISSED:
        return Icons.radio_button_unchecked;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  /// Slivers for use inside the shell's [CustomScrollView]. Use this from
  /// [SliverBuilderBody]; [build] is for standalone use.
  List<Widget> buildSlivers(final BuildContext context, final WidgetRef ref) {
    final AppSpacing spacing = context.spacing;
    final Actor? author = data.author;
    final List<Actor> assignees =
        data.assignees.nodes?.whereType<Actor>().toList() ?? <Actor>[];
    final List<Actor> participantNodes =
        data.participants.nodes?.whereType<Actor>().toList() ?? <Actor>[];
    final List<
            PullLatestReviewNode?>?
        reviewNodes = data.latestReviews?.nodes;
    final Set<String> reviewerLogins = <String>{};
    final List<Widget> reviewerRows = <Widget>[];
    if (reviewNodes != null) {
      for (final PullLatestReviewNode? node
          in reviewNodes) {
        if (node == null) continue;
        final PullLatestReviewAuthor?
            authorNode = node.author;
        if (authorNode != null) {
          reviewerLogins.add(authorNode.login);
          final PullRequestReviewState state = node.state;
          reviewerRows.add(
            MetadataUserRow(
              avatarUrl: authorNode.avatarUrl.toString(),
              login: authorNode.login,
              trailing: Icon(
                _reviewStateIcon(state),
                size: 18,
                color: state == PullRequestReviewState.APPROVED
                    ? Colors.green
                    : state == PullRequestReviewState.CHANGES_REQUESTED
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onTap: () =>
                  UserRef(login: authorNode.login).navigate(context, ref),
            ),
          );
        }
      }
    }

    final Set<String> authorAssigneesReviewers = <String>{
      if (author != null) author.login,
      ...assignees.map((final Actor e) => e.login),
      ...reviewerLogins,
    };
    final List<Actor> commenters = participantNodes
        .where((final Actor p) => !authorAssigneesReviewers.contains(p.login))
        .toList();

    final List<Widget> slivers = <Widget>[];

    if (author != null) {
      slivers.add(
        MetadataSectionSliver(
          title: 'Author',
          children: <Widget>[
            MetadataUserRow(
              avatarUrl: author.avatarUrl.toString(),
              login: author.login,
              onTap: () => UserRef(login: author.login).navigate(context, ref),
            ),
          ],
        ),
      );
    }

    if (assignees.isNotEmpty) {
      slivers.add(
        MetadataSectionSliver(
          title: 'Assignees',
          children: assignees
              .map(
                (final Actor a) => MetadataUserRow(
                  avatarUrl: a.avatarUrl.toString(),
                  login: a.login,
                  onTap: () => UserRef(login: a.login).navigate(context, ref),
                ),
              )
              .toList(),
        ),
      );
    }

    if (reviewerRows.isNotEmpty) {
      slivers.add(
        MetadataSectionSliver(
          title: 'Reviewers',
          children: reviewerRows,
        ),
      );
    }

    if (commenters.isNotEmpty) {
      slivers.add(
        MetadataSectionSliver(
          title: 'Commenters',
          children: commenters
              .map(
                (final Actor c) => MetadataUserRow(
                  avatarUrl: c.avatarUrl.toString(),
                  login: c.login,
                  onTap: () => UserRef(login: c.login).navigate(context, ref),
                ),
              )
              .toList(),
        ),
      );
    }

    if (slivers.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              'No participants',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      ];
    }

    return <Widget>[
      SliverPadding(
        padding: spacing.pagePadding,
        sliver: SliverList(
          delegate: SliverChildListDelegate(slivers),
        ),
      ),
    ];
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) =>
      CustomScrollView(slivers: buildSlivers(context, ref));
}
