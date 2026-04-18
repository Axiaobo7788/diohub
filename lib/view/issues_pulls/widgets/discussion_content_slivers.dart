import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/misc/reaction_bar.dart';
import 'package:diohub/common/nav_center/shell/nav_center_shell.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/html_utils.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion_detail_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Shared sliver content for both issue and PR discussion views.
///
/// Takes a single [payload]. Produces title, reactions, body, divider, timeline.
/// Author, date, comment count, labels, and branch refs are in metadata slivers only.
class DiscussionContentSlivers extends ConsumerWidget {
  const DiscussionContentSlivers({
    required this.payload,
    super.key,
  });

  final DiscussionDetailPayload payload;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) => MultiSliver(
        children: <Widget>[
          SliverPadding(
            padding: context.spacing.screenPadding.copyWith(
              top: context.spacing.itemSpacing,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MarkdownBody(
                    payload.title,
                    textStyle: context.textTheme.headlineSmall,
                  ),
                  SizedBox(height: context.spacing.sectionSpacing),
                  ReactionBar(
                    payload.reactionGroups,
                    viewerCanReact: payload.viewerCanReact,
                  ),
                  SizedBox(height: context.spacing.sectionSpacing),
                ],
              ),
            ),
          ),
          SliverMarkdownBody(
            payload.bodyHTML,
            textStyle: context.textTheme.bodyMedium,
            contentPadding: context.spacing.screenPadding,
          ),
          if (htmlToPlain(payload.bodyHTML).trim().isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: context.spacing.screenPadding.copyWith(
                  top: context.spacing.itemSpacing,
                  bottom: context.spacing.itemSpacing,
                ),
                child: ref.read(premiumAiProvider).buildAiSummaryChip(
                  context,
                  ref,
                  content: htmlToPlain(payload.bodyHTML),
                  label: 'Summarise thread',
                ) ?? const SizedBox.shrink(),
              ),
            ),
          if (payload.subIssuesSummary != null &&
              payload.subIssuesTabIndex != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: context.spacing.screenPadding.copyWith(
                  top: context.spacing.itemSpacing,
                  bottom: context.spacing.itemSpacing,
                ),
                child: InkWell(
                  onTap: () {
                    NavCenterShell.of(context)
                        .switchTab(payload.subIssuesTabIndex!);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        SubIssueProgressChip(
                          completed: payload.subIssuesSummary!.completed,
                          total: payload.subIssuesSummary!.total,
                        ),
                        context.spacing.compactGap,
                        Expanded(
                          child: Text(
                            'View all ${payload.subIssuesSummary!.total} sub-issues',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: context.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: context.spacing.screenPadding.copyWith(
                top: context.spacing.itemSpacing,
                bottom: context.spacing.itemSpacing,
              ),
              child: Divider(
                color: context.colorScheme.outlineVariant,
              ),
            ),
          ),
          IssuePullTimeline(
            repo: payload.repo,
            number: payload.number,
            isPull: payload.isPull,
            nodeID: payload.nodeID,
            isLocked: payload.isLocked,
            createdAt: payload.createdAt,
            commentsSince: payload.commentsSince,
            scrollToCommentId: payload.scrollToCommentId,
          ),
        ],
      );
}
