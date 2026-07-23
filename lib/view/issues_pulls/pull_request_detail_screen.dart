import 'package:auto_route/auto_route.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/view/issues_pulls/pull_screen.dart';
import 'package:diohub/view/repository/md3/repository_context_chrome.dart';
import 'package:diohub/view/repository/md3/repository_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class PullRequestDetailScreen extends ConsumerWidget {
  const PullRequestDetailScreen({
    required this.pullRef,
    super.key,
    this.commentsSince,
    this.initialIndex = 0,
  });

  final PullRequestRef pullRef;
  final DateTime? commentsSince;
  final int initialIndex;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return RepositoryContextChrome(
      repoRef: pullRef.repo,
      selectedDestination: RepositoryNavigationDestination.pullRequests,
      onRefresh: () => ref.invalidate(pullDetailProvider(pullRef)),
      body: PullScreen(
        pullRef: pullRef,
        commentsSince: commentsSince,
        initialIndex: initialIndex,
        embedded: true,
      ),
    );
  }
}
