import 'package:diohub/common/cards/commit_card.dart';
import 'package:diohub/common/events/view_commits_expand_row.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub/models/commits/commit_list_item_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repository/compare_result.dart'
    show CompareCommitSummary;
import 'package:diohub/providers/repository/push_compare_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/widgets/basic_event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

CompareCommitSummary compareCommitSummaryFromGcommit(final CommitEvent c) =>
    CompareCommitSummary(
      sha: c.oid,
      message: c.messageHeadline,
      authorName: c.author?.user?.login,
      authorAvatarUrl: c.author?.avatarUrl.toString(),
      date: c.authoredDate,
    );

/// Expandable card for "Made a commit" timeline event. Shows one line + "View commit"
/// and expands inline to show the commit with [CommitCard] (no fetch; data from timeline).
class SingleCommitExpandableCard extends StatefulWidget {
  const SingleCommitExpandableCard({
    required this.commit,
    required this.repoRef,
    required this.user,
    required this.date,
    super.key,
  });

  final CommitEvent commit;
  final RepoRef repoRef;
  final Actor? user;
  final DateTime date;

  @override
  State<SingleCommitExpandableCard> createState() =>
      _SingleCommitExpandableCardState();
}

class _SingleCommitExpandableCardState
    extends State<SingleCommitExpandableCard> {
  bool _expanded = false;

  @override
  Widget build(final BuildContext context) {
    final CompareCommitSummary summary =
        compareCommitSummaryFromGcommit(widget.commit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BasicEventTextCard(
          textContent: 'Made a commit.',
          user: widget.user,
          date: widget.date,
          leading: Octicons.git_commit,
        ),
        ViewCommitsExpandRow(
          isExpanded: _expanded,
          onTap: () => setState(() => _expanded = !_expanded),
          label: 'View commit',
          child: BorderedContainer(
            ref: CommitRef(repo: widget.repoRef, oid: summary.sha),
            child: CommitCard(
              data: CommitListItemModel.fromCompareCommitSummary(
                summary.sha,
                summary.message,
                widget.repoRef,
                authorName: summary.authorName,
                authorAvatarUrl: summary.authorAvatarUrl,
                date: summary.date,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Expandable card for force-push timeline events. Shows "View commits" and
/// expands inline to load and display commit list (same pattern as activity feed).
class ForcePushExpandableCard extends ConsumerStatefulWidget {
  const ForcePushExpandableCard({
    required this.repoRef,
    required this.beforeOid,
    required this.afterOid,
    required this.refName,
    required this.refLabel,
    required this.user,
    required this.date,
    super.key,
  });

  final RepoRef repoRef;
  final String beforeOid;
  final String afterOid;
  final String refName;
  final String refLabel;
  final Actor? user;
  final DateTime date;

  @override
  ConsumerState<ForcePushExpandableCard> createState() =>
      _ForcePushExpandableCardState();
}

class _ForcePushExpandableCardState
    extends ConsumerState<ForcePushExpandableCard> {
  bool _expanded = false;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final String beforeShort = widget.beforeOid.length >= 7
        ? widget.beforeOid.substring(0, 7)
        : widget.beforeOid;
    final String afterShort = widget.afterOid.length >= 7
        ? widget.afterOid.substring(0, 7)
        : widget.afterOid;
    final String textContent =
        'Force pushed to ${widget.refLabel} ${widget.refName}, from $beforeShort to $afterShort.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BasicEventTextCard(
          textContent: textContent,
          user: widget.user,
          leading: Octicons.repo_push,
          date: widget.date,
        ),
        ViewCommitsExpandRow(
          isExpanded: _expanded,
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: _expanded
              ? Consumer(
                  builder: (context, ref, _) {
                    final commits = ref.watch(pushCompareProvider((
                      repo: widget.repoRef,
                      base: widget.beforeOid,
                      head: widget.afterOid,
                    )));
                    return AsyncValueBuilder<List<CompareCommitSummary>>(
                      value: commits,
                      data: (list) => list.isEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: spacing.itemSpacing,
                              ),
                              child: Text(
                                'No commits found',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: context.colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: list.map(
                                (final CompareCommitSummary c) {
                                  final CommitListItemModel model =
                                      CommitListItemModel.fromCompareCommitSummary(
                                    c.sha,
                                    c.message,
                                    widget.repoRef,
                                    authorName: c.authorName,
                                    authorAvatarUrl: c.authorAvatarUrl,
                                    date: c.date,
                                  );
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: spacing.itemSpacing,
                                    ),
                                    child: BorderedContainer(
                                      ref: CommitRef(
                                          repo: widget.repoRef, oid: c.sha),
                                      child: CommitCard(data: model),
                                    ),
                                  );
                                },
                              ).toList(),
                            ),
                    );
                  },
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
