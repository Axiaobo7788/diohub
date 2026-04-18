import 'package:diohub/common/cards/issue_pull_card.dart';
import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/shell/nav_center_shell_widgets.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot.dart';
import 'package:diohub_models/models/entity_snapshot_factories.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/providers/entity_store_notifier.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/providers/search/search_session_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/issues_pulls/widgets/issue_pull_screen_skeleton.dart';
import 'package:diohub/view/issues_pulls/widgets/issue_screen_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Issue detail UI. Watches [issueDetailProvider(issueRef)] and builds
/// content when data is available. Pass [issueRef] only; no need to pass
/// resolved data from the parent.
class IssueScreen extends ConsumerWidget {
  const IssueScreen({
    required this.issueRef,
    this.initialIndex = 0,
    this.commentsSince,
    super.key,
  });

  final IssueRef issueRef;
  final DateTime? commentsSince;
  final int initialIndex;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<IssueInfo> asyncData =
        ref.watch(issueDetailProvider(issueRef));
    return AsyncValueBuilder<IssueInfo>(
      value: asyncData,
      presentation: LoadingPresentation.branded,
      skeleton: (final _) => const IssuePullScreenSkeleton(),
      error: (final Object error, final _) => ScaffoldError(
        error.toString(),
        appBar: AppBar(elevation: 0),
      ),
      data: (final IssueInfo data) =>
          _IssueScreenContent(
        issueRef: issueRef,
        data: data,
        commentsSince: commentsSince,
        initialIndex: initialIndex,
      ),
    );
  }
}

class _IssueScreenContent extends ConsumerWidget {
  const _IssueScreenContent({
    required this.issueRef,
    required this.data,
    this.commentsSince,
    this.initialIndex = 0,
  });

  final IssueRef issueRef;
  final IssueInfo data;
  final DateTime? commentsSince;
  final int initialIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _IssueShellContent(
      issueRef: issueRef,
      data: data,
      commentsSince: commentsSince,
      initialIndex: initialIndex,
      onRefresh: () => ref.invalidate(issueDetailProvider(issueRef)),
    );
  }
}

/// Builds config in didChangeDependencies / didUpdateWidget so we don't
/// allocate the full config tree on every build.
class _IssueShellContent extends ConsumerStatefulWidget {
  const _IssueShellContent({
    required this.issueRef,
    required this.data,
    required this.onRefresh,
    this.commentsSince,
    this.initialIndex = 0,
  });

  final IssueRef issueRef;
  final IssueInfo data;
  final VoidCallback onRefresh;
  final DateTime? commentsSince;
  final int initialIndex;

  @override
  ConsumerState<_IssueShellContent> createState() => _IssueShellContentState();
}

class _IssueShellContentState extends ConsumerState<_IssueShellContent> {
  ScreenConfig? _config;
  bool _visitRecorded = false;

  void _buildConfig() {
    final data = widget.data;
    if (!_visitRecorded) {
      _visitRecorded = true;
      final session = ref.read(searchSessionProvider);
      ref.read(entityStoreMutatorProvider).recordVisit(
            widget.issueRef,
            snapshot: EntitySnapshot(title: data.title),
          );
    }
    _config = data.toScreenConfig(
      context,
      ref,
      issueRef: widget.issueRef,
      onRefresh: () async => widget.onRefresh(),
      commentsSince: widget.commentsSince,
      scrollToCommentId: null,
      linkedPRsSliverBuilder: (data.closedByPullRequestsReferences != null &&
              data.closedByPullRequestsReferences!.totalCount > 0)
          ? (ctx) => _buildLinkedPRsSlivers(
                ctx,
                ref,
                data.closedByPullRequestsReferences!.nodes
                        ?.whereType<
                            IssueClosedByPRNode>()
                        .toList() ??
                    <IssueClosedByPRNode>[],
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
  void didUpdateWidget(covariant _IssueShellContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data ||
        widget.issueRef != oldWidget.issueRef) {
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
    );
  }
}

List<Widget> _buildLinkedPRsSlivers(
  final BuildContext context,
  final WidgetRef ref,
  final List<
          IssueClosedByPRNode>
      nodes,
) {
  final AppSpacing spacing = context.spacing;
  return <Widget>[
    SliverPadding(
      key: const PageStorageKey<String>('IssueLinkedPRs'),
      padding: spacing.screenPadding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (final BuildContext context, final int index) {
            final IssueClosedByPRNode
                node = nodes[index];
            final RepoRef repoRef = RepoRef(
              owner: node.repository.owner.login,
              name: node.repository.name,
            );
            final PullRequestRef pullRef =
                PullRequestRef(repo: repoRef, number: node.number);
            final PullRequestCardData cardData =
                PullRequestCardData.fromGitHubGql(node);
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < nodes.length - 1 ? spacing.itemSpacing : 0,
              ),
              child: TapFeedback(
                onTap: () => pullRef.navigate(context, ref),
                child: PullRequestCard(cardData),
              ),
            );
          },
          childCount: nodes.length,
        ),
      ),
    ),
  ];
}
