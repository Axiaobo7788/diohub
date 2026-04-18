import 'package:auto_route/auto_route.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/log_issue_draft_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sets [pendingLogIssueDraftProvider] with [title] and [body], then pushes
/// [NewIssueRoute] for [repo]. [NewIssueScreen] will pre-fill from the draft.
/// Call from view layer when user chooses "Report issue" from a log entry.
void navigateToCreateIssueFromLog(
  BuildContext context,
  WidgetRef ref,
  RepoRef repo,
  String title,
  String body,
) {
  ref.read(pendingLogIssueDraftProvider.notifier).state =
      (title: title, body: body);
  context.router.push(NewIssueRoute(repoRef: repo));
}
