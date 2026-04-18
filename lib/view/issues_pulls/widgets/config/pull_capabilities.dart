import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/nav_center/models/entity_capability.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub/view/issues_pulls/widgets/config/suggested_reviewer_mapper.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub/view/issues_pulls/widgets/review_request_sheet.dart';
import 'package:diohub/view/issues_pulls/widgets/suggested_reviewers_section.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';

/// Builds the capability list for a pull request. Used by popup and settings.
List<EntityCapability> pullCapabilities({
  required BuildContext context,
  required WidgetRef ref,
  required PullRequestRef pullRef,
  required PullInfo data,
}) {
  final notifier = ref.read(pullDetailProvider(pullRef).notifier);
  final urlStr = ref.webUrlFor(pullRef).toString();
  final clipboard = ref.read(clipboardServiceProvider);

  final List<SuggestedReviewerData> suggested = mapSuggestedReviewers(
    data.suggestedReviewers,
  );
  final SheetBuilder reviewSheetBuilder =
      (BuildContext ctx, [ScrollController? sc]) => ReviewRequestSheet(
        pullRef: pullRef,
        authorLogin: data.author?.login,
        suggestedReviewers: suggested.isEmpty ? null : suggested,
        scrollController: sc,
      );

  final repo = data.repository;
  final List<PullRequestMergeMethod> availableMergeMethods =
      <PullRequestMergeMethod>[
        if (repo?.viewerDefaultMergeMethod != null)
          repo!.viewerDefaultMergeMethod!,
      ];
  if (availableMergeMethods.isEmpty) {
    availableMergeMethods.add(PullRequestMergeMethod.MERGE);
  }

  return <EntityCapability>[
    Subscribable(
      currentState: data.viewerSubscription ?? SubscriptionState.UNSUBSCRIBED,
      viewerCanSubscribe: data.viewerCanSubscribe,
      onChanged: notifier.setSubscription,
    ),
    Reviewable(
      viewerCanUpdate: data.viewerCanUpdate,
      sheetBuilder: reviewSheetBuilder,
    ),
    CloseablePull(
      state: data.pullRequestState,
      viewerCanClose: data.viewerCanClose,
      viewerCanReopen: data.viewerCanReopen,
      mergeableState: data.mergeable,
      onClose: notifier.close,
      onReopen: notifier.reopen,
      onMerge: notifier.merge,
      availableMergeMethods: availableMergeMethods,
    ),
    Utility(
      url: urlStr,
      copyUrl: () => clipboard.copy(urlStr),
      share: () => Share.share(urlStr),
    ),
    ...ref
        .read(premiumCapabilitiesProvider)
        .pullCapabilities(
          context: context,
          ref: ref,
          pullRef: pullRef,
          data: data,
        )
        .cast<EntityCapability>(),
  ];
}
