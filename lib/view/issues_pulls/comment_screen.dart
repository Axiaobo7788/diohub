import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/compose/compose_scaffold.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/common/compose/editor/markdown_live_text_field.dart';
import 'package:diohub/common/compose/models/compose_config.dart';
import 'package:diohub/common/compose/models/compose_mode.dart';
import 'package:diohub_models/models/database_types.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/routes/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class CommentScreen extends ConsumerWidget {
  const CommentScreen({
    super.key,
    this.issueRef,
    this.pullRef,
  })  : assert(
          issueRef != null || pullRef != null,
          'Exactly one of issueRef or pullRef must be non-null',
        ),
        assert(
          issueRef == null || pullRef == null,
          'Only one of issueRef or pullRef may be set',
        );

  final IssueRef? issueRef;
  final PullRequestRef? pullRef;

  RepoRef get repoRef => issueRef?.repo ?? pullRef!.repo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String viewerLogin =
        ref.read(accountProvider).value?.activeAccount ?? '';
    final config = ComposeConfig(
      mode: CommentMode(issueRef: issueRef, pullRef: pullRef),
      repoRef: repoRef,
      title: 'Comment',
      subtitle: repoRef.fullName,
      showTitle: false,
      submitIcon: Icons.reply,
      submitLabel: 'Reply',
      loadingVerb: 'Sending…',
      draftSubject: issueRef ?? pullRef,
      draftScope: DraftScope.comment,
      onSubmit: (String title, String body) async {
        if (issueRef != null) {
          await ref
              .read(issueDetailProvider(issueRef!).notifier)
              .addComment(body);
        } else {
          await ref
              .read(pullDetailProvider(pullRef!).notifier)
              .addComment(body);
        }
      },
    );

    return ComposeScaffold(
      config: config,
      bodyBuilder: (
        BuildContext context,
        TextEditingController titleController,
        TextEditingController bodyController,
        FocusNode bodyFocusNode,
      ) {
        return MarkdownLiveTextField(
          controller: bodyController,
          focusNode: bodyFocusNode,
          onChanged: (_) {},
          placeholder: 'Write a comment…',
          maxLines: 12,
        );
      },
    );
  }
}
