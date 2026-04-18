import 'package:diohub/common/cards/issue_pull_card.dart';
import 'package:diohub/common/markdown_view/trimmable_markdown_content.dart';
import 'package:diohub/common/misc/inline_container.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Unified content for pull request events in timeline
class TimelinePullRequestContent extends StatelessWidget {
  const TimelinePullRequestContent({
    required this.prData,
    this.from,
    this.to,
    super.key,
  });

  final PullCardData prData;
  final String? from; // Head branch ref (source branch)
  final String? to; // Base branch ref (target branch)

  @override
  Widget build(final BuildContext context) {
    final String repoFullName =
        PullRequestRef.fromPullCardFields(prData).repo.fullName;
    final bool hasBody = prData.body.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BorderedContainer(
          ref: PullRequestRef.fromPullCardFields(prData),
          child: IssuePullCard.fromPullRequest(
            prData,
            showDescription: false,
            branchFrom: from,
            branchTo: to,
          ),
        ),
        if (hasBody) ...<Widget>[
          context.spacing.itemGap,
          InlineContainer(
            child: TrimmableMarkdownContent(
              text: prData.body.trim(),
              repo: repoFullName,
            ),
          ),
        ],
      ],
    );
  }
}
