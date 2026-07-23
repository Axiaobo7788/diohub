import 'package:diohub/common/cards/issue_pull_card.dart';
import 'package:diohub/common/cards/issue_pull_card_data.dart'
    show IssueCardData, checksStateFromGitHubGql;
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/shell/nav_center_shell_widgets.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub/common/widgets/metadata_composites.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/providers/entity_store_notifier.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/issues_pulls/widgets/issue_pull_screen_skeleton.dart';
import 'package:diohub/view/issues_pulls/widgets/pull_screen_config.dart';
import 'package:diohub/view/issues_pulls/widgets/pull_screen_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pull request detail UI. Watches [pullDetailProvider(pullRef)] and builds
/// content when data is available. Pass [pullRef] only; no need to pass
/// resolved data from the parent.
class PullScreen extends ConsumerWidget {
  const PullScreen({
    required this.pullRef,
    this.initialIndex = 0,
    this.commentsSince,
    this.embedded = false,
    super.key,
  });

  final PullRequestRef pullRef;
  final DateTime? commentsSince;
  final int initialIndex;
  final bool embedded;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<PullInfo> asyncData = ref.watch(
      pullDetailProvider(pullRef),
    );
    return AsyncValueBuilder<PullInfo>(
      value: asyncData,
      presentation: LoadingPresentation.branded,
      duration: kContentTransitionDuration,
      skeleton: (final _) => IssuePullScreenSkeleton(embedded: embedded),
      error: (final Object error, final _) => _PullLoadError(
        error: error,
        onRetry: () => ref.invalidate(pullDetailProvider(pullRef)),
      ),
      data: (final PullInfo data) => _PullScreenContent(
        pullRef: pullRef,
        data: data,
        commentsSince: commentsSince,
        initialIndex: initialIndex,
        embedded: embedded,
      ),
    );
  }
}

class _PullLoadError extends StatelessWidget {
  const _PullLoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.pullRequestDetailLoadError,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _PullScreenContent extends ConsumerWidget {
  const _PullScreenContent({
    required this.pullRef,
    required this.data,
    required this.embedded,
    this.commentsSince,
    this.initialIndex = 0,
  });

  final PullRequestRef pullRef;
  final PullInfo data;
  final DateTime? commentsSince;
  final int initialIndex;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PullShellContent(
      pullRef: pullRef,
      data: data,
      commentsSince: commentsSince,
      initialIndex: initialIndex,
      embedded: embedded,
      onRefresh: () => ref.invalidate(pullDetailProvider(pullRef)),
    );
  }
}

/// Builds config in didChangeDependencies / didUpdateWidget so we don't
/// allocate the full config tree on every build.
class _PullShellContent extends ConsumerStatefulWidget {
  const _PullShellContent({
    required this.pullRef,
    required this.data,
    required this.onRefresh,
    required this.embedded,
    this.commentsSince,
    this.initialIndex = 0,
  });

  final PullRequestRef pullRef;
  final PullInfo data;
  final VoidCallback onRefresh;
  final DateTime? commentsSince;
  final int initialIndex;
  final bool embedded;

  @override
  ConsumerState<_PullShellContent> createState() => _PullShellContentState();
}

class _PullShellContentState extends ConsumerState<_PullShellContent> {
  ScreenConfig? _config;
  bool _visitRecorded = false;

  void _buildConfig() {
    final data = widget.data;
    if (!_visitRecorded) {
      _visitRecorded = true;
      ref
          .read(entityStoreMutatorProvider)
          .recordVisit(
            widget.pullRef,
            snapshot: EntitySnapshot(title: data.title),
          );
    }
    _config = data.toScreenConfig(
      context,
      ref,
      pullRef: widget.pullRef,
      onRefresh: () async => widget.onRefresh(),
      commentsSince: widget.commentsSince,
      scrollToCommentId: null,
      checksSliverBuilder: data.statusCheckRollup != null
          ? (ctx) => buildChecksSlivers(
              ctx,
              data.statusCheckRollup!,
              ciRunsFromStatusCheckRollup(data.statusCheckRollup),
            )
          : null,
      linkedIssuesSliverBuilder:
          (data.closingIssuesReferences != null &&
              data.closingIssuesReferences!.totalCount > 0)
          ? (ctx) => buildLinkedIssuesSlivers(
              ctx,
              data.closingIssuesReferences!.nodes
                      ?.whereType<PullClosingIssueNode>()
                      .toList() ??
                  <PullClosingIssueNode>[],
            )
          : null,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_config == null) _buildConfig();
  }

  @override
  void didUpdateWidget(covariant _PullShellContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data || widget.pullRef != oldWidget.pullRef) {
      _buildConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _config!.visibleTabs;
    final initialIndexClamped = tabs.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, tabs.length - 1);
    return NavCenterShell(
      config: _config!,
      initialTabIndex: initialIndexClamped,
      embedded: widget.embedded,
    );
  }
}

/// Slivers for the Checks position. Use with [SliverBuilderBody] or wrap in
/// [AppCustomScrollView] for standalone.
List<Widget> buildChecksSlivers(
  final BuildContext context,
  final PullStatusCheckRollup rollup,
  final List<CICheckRunRowData> ciRuns,
) {
  final AppSpacing spacing = context.spacing;
  return <Widget>[
    SliverPadding(
      key: const PageStorageKey<String>('PullChecks'),
      padding: spacing.screenPadding,
      sliver: SliverToBoxAdapter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ChecksStatusChip(state: checksStateFromGitHubGql(rollup.state)),
            if (ciRuns.isNotEmpty) ...[
              spacing.sectionGap,
              CIChecksList(runs: ciRuns),
            ],
          ],
        ),
      ),
    ),
  ];
}

/// Slivers for the Linked Issues position. Use with [SliverBuilderBody] or
/// wrap in [AppCustomScrollView] for standalone.
List<Widget> buildLinkedIssuesSlivers(
  final BuildContext context,
  final List<PullClosingIssueNode> nodes,
) {
  final AppSpacing spacing = context.spacing;
  return <Widget>[
    SliverPadding(
      key: const PageStorageKey<String>('PullLinkedIssues'),
      padding: spacing.screenPadding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((
          final BuildContext context,
          final int index,
        ) {
          final PullClosingIssueNode node = nodes[index];
          final RepoRef repoRef = RepoRef(
            owner: node.repository.owner.login,
            name: node.repository.name,
          );
          final IssueRef issueRef = IssueRef(
            repo: repoRef,
            number: node.number,
          );
          final IssueCardData cardData = IssueCardData.fromGitHubGql(node);
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < nodes.length - 1 ? spacing.itemSpacing : 0,
            ),
            child: Consumer(
              builder:
                  (final BuildContext context, final WidgetRef ref, final _) =>
                      TapFeedback(
                        onTap: () => issueRef.navigate(context, ref),
                        child: IssueCard(cardData),
                      ),
            ),
          );
        }, childCount: nodes.length),
      ),
    ),
  ];
}
