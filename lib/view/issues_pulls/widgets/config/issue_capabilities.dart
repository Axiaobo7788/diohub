import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/nav_center/models/entity_capability.dart';
import 'package:diohub_graphql/schema.graphql.dart' as gql;
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';

List<EntityCapability> issueCapabilities({
  required BuildContext context,
  required WidgetRef ref,
  required IssueRef issueRef,
  required IssueInfo data,
}) {
  final notifier = ref.read(issueDetailProvider(issueRef).notifier);
  final urlStr = ref.webUrlFor(issueRef).toString();
  final clipboard = ref.read(clipboardServiceProvider);

  return <EntityCapability>[
    Subscribable(
      currentState:
          data.viewerSubscription ?? gql.Enum$SubscriptionState.UNSUBSCRIBED,
      viewerCanSubscribe: data.viewerCanSubscribe,
      onChanged: notifier.setSubscription,
    ),
    CloseableIssue(
      state: data.issueState,
      viewerCanClose: data.viewerCanClose,
      viewerCanReopen: data.viewerCanReopen,
      onClose: notifier.close,
      onReopen: notifier.reopen,
    ),
    Utility(
      url: urlStr,
      copyUrl: () => clipboard.copy(urlStr),
      share: () => Share.share(urlStr),
    ),
    ...ref
        .read(premiumCapabilitiesProvider)
        .issueCapabilities(
          context: context,
          ref: ref,
          issueRef: issueRef,
          data: data,
        )
        .cast<EntityCapability>(),
  ];
}
