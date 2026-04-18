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

/// Card content for pull requests in timeline views.
/// Two modes:
///   - Direct render: pass [prData] (profile activity timeline)
///   - Compound event: pass [EventCompoundData] (events timeline)
class TimelinePullRequestContent extends ConsumerWidget {
  /// Direct render — already has full data (profile activity timeline, etc.)
  const TimelinePullRequestContent({
    required PullCardData this.prData,
    this.from,
    this.to,
    this.showDescription = true,
    super.key,
  }) : compoundData = null;

  /// Compound event — fetches PR by URL, applies compound overrides.
  const TimelinePullRequestContent.fromCompound(
    EventCompoundData this.compoundData, {
    super.key,
  })  : prData = null,
        from = null,
        to = null,
        showDescription = true;

  final PullCardData? prData;
  final EventCompoundData? compoundData;
  final String? from;
  final String? to;
  final bool showDescription;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Compound event path — use provider when URL parses, else fallback
    if (compoundData != null) {
      return _buildFromCompound(context, ref, compoundData!);
    }

    // Direct render path
    final PullCardData data = prData!;
    return BorderedContainer(
      ref: PullRequestRef.fromPullCardFields(data),
      child: IssuePullCard.fromPullRequest(
        data,
        showDescription: showDescription,
        branchFrom: from,
        branchTo: to,
      ),
    );
  }

  /// Fetch PR via provider (shared cache with PR screen) or fallback when URL invalid.
  Widget _buildFromCompound(
    final BuildContext context,
    final WidgetRef ref,
    final EventCompoundData cd,
  ) {
    final String? url = cd.prUrl;
    if (url == null) return const SizedBox.shrink();

    PullRequestRef? prRef;
    try {
      prRef = PullRequestRef.fromApiUrl(url);
    } catch (e, st) {
      AppLogger.warning(
        'Invalid PR URL for timeline',
        error: e,
        stackTrace: st,
        tag: 'TimelinePullRequestContent',
      );
      return const SizedBox.shrink();
    }

    final AsyncValue<PullInfo> asyncPr =
        ref.watch(pullDetailProvider(prRef));
    return AsyncValueBuilder<PullInfo>(
      value: asyncPr,
      skeleton: (final _) => ShimmerScope(
        child: BorderedContainer(
          child: IssuePullLoadingCard(
            showDescription: cd.showDescription,
          ),
        ),
      ),
      error: (final _, final __) => const SizedBox.shrink(),
      data: (final PullInfo data) {
        return _buildCompoundContent(context, data, cd);
      },
    );
  }

  /// Card with inline compound context below (labels, comment, assignee).
  Widget _buildCompoundContent(
    final BuildContext context,
    final PullCardData data,
    final EventCompoundData cd,
  ) {
    final String repoName =
        PullRequestRef.fromPullCardFields(data).repo.fullName;
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
          ref: PullRequestRef.fromPullCardFields(data),
          child: IssuePullCard.fromPullRequest(
            data,
            showDescription: cd.showDescription,
            branchFrom: cd.prFromRef,
            branchTo: cd.prToRef,
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
