import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/cards/issue_pull_card.dart';
import 'package:diohub/common/events/compound_annotation_chips.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/utils/events/compound_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Card content for issues in timeline views.
/// Two modes:
///   - Direct render: pass [issueData] (profile activity timeline)
///   - Compound event: pass [EventCompoundData] (events timeline)
class TimelineIssueContent extends ConsumerWidget {
  /// Direct render — already has full data (profile activity timeline, etc.)
  const TimelineIssueContent({
    required IssueCardData this.issueData,
    this.showDescription = true,
    super.key,
  }) : compoundData = null;

  /// Compound event — fetches issue by URL, applies compound overrides.
  const TimelineIssueContent.fromCompound(
    EventCompoundData this.compoundData, {
    super.key,
  })  : issueData = null,
        showDescription = true;

  final IssueCardData? issueData;
  final EventCompoundData? compoundData;
  final bool showDescription;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Compound event path — use provider when URL parses, else fallback
    if (compoundData != null) {
      return _buildFromCompound(context, ref, compoundData!);
    }

    // Direct render path
    return _buildCard(context, issueData!);
  }

  /// Fetch issue via provider (shared cache with issue screen).
  Widget _buildFromCompound(
    final BuildContext context,
    final WidgetRef ref,
    final EventCompoundData cd,
  ) {
    final String? url = cd.issueUrl;
    if (url == null) return const SizedBox.shrink();

    IssueRef? issueRef;
    try {
      issueRef = IssueRef.fromApiUrl(url);
    } catch (e, st) {
      AppLogger.warning(
        'Failed to parse issue URL for timeline content',
        error: e,
        stackTrace: st,
        tag: 'TimelineIssueContent',
      );
      return const SizedBox.shrink();
    }

    final AsyncValue<IssueInfo> asyncIssue =
        ref.watch(issueDetailProvider(issueRef));
    return AsyncValueBuilder<IssueInfo>(
      value: asyncIssue,
      skeleton: (final _) => ShimmerScope(
        child: BorderedContainer(
          child: IssuePullLoadingCard(
            showDescription: cd.showDescription,
          ),
        ),
      ),
      error: (final _, final __) => const SizedBox.shrink(),
      data: (final IssueInfo data) {
        return _buildCompoundContent(context, data, cd);
      },
    );
  }

  /// Simple card (direct render, no compound annotations).
  Widget _buildCard(final BuildContext context, final IssueCardData data) =>
      BorderedContainer(
        ref: IssueRef.fromIssueCardFields(data),
        child: IssuePullCard.fromIssue(
          data,
          showDescription: showDescription,
        ),
      );

  /// Card with inline compound context below (labels, comment, assignee).
  Widget _buildCompoundContent(
    final BuildContext context,
    final IssueCardData data,
    final EventCompoundData cd,
  ) {
    final String repoName = IssueRef.fromIssueCardFields(data).repo.fullName;
    final bool hasLabels = cd.labels.isNotEmpty;
    final String? commentBody = cd.commentBody;
    final bool hasComment =
        commentBody != null && commentBody.trim().isNotEmpty;
    final UserInfoModel? assignee = cd.assignee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BorderedContainer(
          ref: IssueRef.fromIssueCardFields(data),
          child: IssuePullCard.fromIssue(
            data,
            showDescription: cd.showDescription,
            displayStateAtEventTime: cd.displayStateAtEventTime,
          ),
        ),
        if (hasLabels)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InlineLabels(
              labels: cd.labels,
              removedLabelNames: cd.removedLabelNames,
            ),
          ),
        if (hasComment)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InlineComment(body: commentBody, repoName: repoName),
          ),
        if (assignee != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AssigneeChip(login: assignee.login),
          ),
      ],
    );
  }
}
