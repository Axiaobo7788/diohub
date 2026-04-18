import 'package:auto_route/auto_route.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/view/issues_pulls/pull_screen.dart';
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
    return Material(
      child: PullScreen(
        pullRef: pullRef,
        commentsSince: commentsSince,
        initialIndex: initialIndex,
      ),
    );
  }
}
