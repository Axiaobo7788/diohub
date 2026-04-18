import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/submit_button.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/discussions/discussion_poll_vote_mutation_provider.dart';
import 'package:diohub/providers/repository/release_discussion_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Displays a discussion poll with options, percentage bars, and voting.
/// Shown below discussion body when [poll] is non-null.
class DiscussionPollCard extends ConsumerStatefulWidget {
  const DiscussionPollCard({
    required this.poll,
    required this.discussionId,
    required this.repoRef,
    required this.discussionNumber,
    super.key,
  });

  final DiscussionCardPoll poll;
  final String discussionId;
  final RepoRef repoRef;
  final int discussionNumber;

  @override
  ConsumerState<DiscussionPollCard> createState() => _DiscussionPollCardState();
}

class _DiscussionPollCardState extends ConsumerState<DiscussionPollCard> {
  /// Option id currently submitting; used for optimistic check and disabling others.
  String? _submittingOptionId;

  @override
  Widget build(final BuildContext context) {
    final poll = widget.poll;
    final spacing = context.spacing;
    final theme = Theme.of(context);
    final totalVotes = poll.totalVoteCount;
    final canVote = poll.viewerCanVote &&
        !poll.viewerHasVoted &&
        _submittingOptionId == null;
    final options = poll.options?.nodes
            ?.whereType<DiscussionCardPollOptionNode>()
            .toList() ??
        <DiscussionCardPollOptionNode>[];

    return BorderedContainer(
      child: Padding(
        padding: spacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Octicons.graph,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: spacing.tightSpacing),
                Expanded(
                  child: Text(
                    poll.question,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.itemSpacing),
            ...options.map(
              (final DiscussionCardPollOptionNode option) {
                final count = option.totalVoteCount;
                final pct =
                    totalVotes > 0 ? (count / totalVotes).clamp(0.0, 1.0) : 0.0;
                final voted =
                    option.viewerHasVoted || _submittingOptionId == option.id;
                final isTappable = canVote && !voted;

                return Padding(
                  padding: EdgeInsets.only(bottom: spacing.tightSpacing),
                  child: SubmitButton(
                    variant: SubmitButtonVariant.text,
                    enabled: isTappable,
                    onSubmit: () async {
                      setState(() => _submittingOptionId = option.id);
                      await ref
                          .read(
                            discussionPollVoteMutationProvider((
                              optionId: option.id,
                              discussionId: widget.discussionId,
                            ))
                                .notifier,
                          )
                          .mutate();
                      if (mounted) {
                        ref.invalidate(discussionByNumberProvider(
                          DiscussionRef(
                            repo: widget.repoRef,
                            number: widget.discussionNumber,
                          ),
                        ));
                        setState(() => _submittingOptionId = null);
                      }
                    },
                    onError: (_) {
                      if (mounted) setState(() => _submittingOptionId = null);
                    },
                    icon: voted
                        ? Icon(
                            Icons.check_circle,
                            size: 18,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    label: (isSubmitting) => Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 8,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              SizedBox(height: spacing.compactSpacing / 2),
                              Text(
                                option.option,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: spacing.tightSpacing),
                        Text(
                          '$count',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: spacing.tightSpacing),
            Text(
              totalVotes == 1 ? '1 total vote' : '$totalVotes total votes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (poll.viewerHasVoted || _submittingOptionId != null)
              Text(
                'You voted',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
