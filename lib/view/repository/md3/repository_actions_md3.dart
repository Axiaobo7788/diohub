import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/pagination_phase.dart';
import 'package:diohub/common/pagination/pagination_state.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/l10n/relative_time.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/view/repository/md3/repository_md3_layout.dart';
import 'package:diohub/view/repository/md3/repository_tab_scaffold.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub_models/models/repositories/workflow.dart';
import 'package:diohub_models/models/repositories/workflow_run.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

part 'repository_actions_widgets.dart';

class RepositoryActionsMd3Page extends ConsumerStatefulWidget {
  const RepositoryActionsMd3Page({
    required this.repoRef,
    required this.signedIn,
    required this.onRefreshReady,
    super.key,
  });

  final RepoRef repoRef;
  final bool signedIn;
  final ValueChanged<Future<void> Function()?> onRefreshReady;

  @override
  ConsumerState<RepositoryActionsMd3Page> createState() =>
      _RepositoryActionsMd3PageState();
}

class _RepositoryActionsMd3PageState
    extends ConsumerState<RepositoryActionsMd3Page> {
  static const int _pageSize = 30;

  late final PaginationController<WorkflowRunItem, WorkflowRunItem>
  _runsController;
  final TextEditingController _branchController = TextEditingController();
  List<Workflow> _workflows = const <Workflow>[];
  Workflow? _selectedWorkflow;
  Object? _workflowError;
  bool _workflowsLoading = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _runsController = PaginationController<WorkflowRunItem, WorkflowRunItem>(
      source: SliceForwardSource<WorkflowRunItem>(
        fetch: _fetchRuns,
        resetState: () => _page = 1,
      ),
      idOf: (final WorkflowRunItem run) => '${run.id}',
      pageSize: _pageSize,
      autoFetch: widget.signedIn,
    );
    widget.onRefreshReady(widget.signedIn ? _refresh : null);
    if (widget.signedIn) {
      unawaited(_loadWorkflows());
    }
  }

  @override
  void didUpdateWidget(final RepositoryActionsMd3Page oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signedIn == widget.signedIn) return;
    widget.onRefreshReady(widget.signedIn ? _refresh : null);
    if (widget.signedIn) {
      unawaited(_loadWorkflows());
      unawaited(_runsController.refresh(retainItems: false));
    }
  }

  @override
  void dispose() {
    widget.onRefreshReady(null);
    _branchController.dispose();
    _runsController.dispose();
    super.dispose();
  }

  Future<PageSlice<WorkflowRunItem>> _fetchRuns(final int count) async {
    final response = await widget.repoRef
        .workflows(ref.read(apiClientProvider))
        .listWorkflowRuns(
          workflowId: _selectedWorkflow?.id,
          perPage: count,
          page: _page,
          branch: _normalizedBranch,
          refresh: _page == 1,
        );
    _page++;
    final int loadedBefore = (_page - 2) * count;
    return PageSlice<WorkflowRunItem>(
      items: response.workflowRuns,
      hasNextPage:
          response.workflowRuns.length == count &&
          loadedBefore + response.workflowRuns.length < response.totalCount,
      totalCount: response.totalCount,
    );
  }

  String? get _normalizedBranch {
    final String value = _branchController.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _loadWorkflows() async {
    if (mounted) {
      setState(() {
        _workflowsLoading = true;
        _workflowError = null;
      });
    }
    try {
      final response = await widget.repoRef
          .workflows(ref.read(apiClientProvider))
          .listWorkflows(perPage: 100);
      if (!mounted) return;
      setState(() {
        _workflows = response.workflows;
        _workflowsLoading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _workflowError = error;
        _workflowsLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await Future.wait<void>(<Future<void>>[
      _loadWorkflows(),
      _runsController.refresh(),
    ]);
  }

  void _selectWorkflow(final Workflow? workflow) {
    if (_selectedWorkflow?.id == workflow?.id) return;
    setState(() => _selectedWorkflow = workflow);
    unawaited(_runsController.refresh(retainItems: false));
  }

  @override
  Widget build(final BuildContext context) {
    if (!widget.signedIn) {
      return RepositoryTabScaffold(
        title: context.l10n.repoActions,
        slivers: <Widget>[
          SliverPadding(
            padding: RepositoryMd3Layout.pagePaddingFor(
              RepositoryWindowClass.compact,
            ),
            sliver: SliverToBoxAdapter(
              child: RepositoryTabSignInState(
                onSignIn: () =>
                    unawaited(context.router.push<void>(const AuthRoute())),
              ),
            ),
          ),
        ],
      );
    }
    final List<RepositoryTabNavigationDestination> destinations =
        <RepositoryTabNavigationDestination>[
          RepositoryTabNavigationDestination(
            icon: Icons.play_circle_outline,
            label: context.l10n.repoAllWorkflows,
          ),
          for (final Workflow workflow in _workflows)
            RepositoryTabNavigationDestination(
              icon: Icons.account_tree_outlined,
              label: workflow.name,
            ),
        ];
    final int selectedIndex = _selectedWorkflow == null
        ? 0
        : _workflows.indexWhere(
                (final Workflow workflow) =>
                    workflow.id == _selectedWorkflow!.id,
              ) +
              1;

    return ValueListenableBuilder<PaginationState<WorkflowRunItem>>(
      valueListenable: _runsController.state,
      builder:
          (
            final BuildContext context,
            final PaginationState<WorkflowRunItem> state,
            final Widget? child,
          ) {
            return RepositoryTabScaffold(
              title: _selectedWorkflow?.name ?? context.l10n.repoAllWorkflows,
              refreshing: state.phase is Refreshing,
              onRefresh: _refresh,
              navigation: _buildNavigation(destinations, selectedIndex),
              compactNavigation: _WorkflowPicker(
                workflows: _workflows,
                selected: _selectedWorkflow,
                loading: _workflowsLoading,
                onSelected: _selectWorkflow,
              ),
              actions: <Widget>[
                IconButton.outlined(
                  tooltip: context.l10n.activityRefresh,
                  onPressed: state.phase is Refreshing
                      ? null
                      : () => unawaited(_refresh()),
                  icon: const Icon(Icons.refresh),
                ),
              ],
              slivers: <Widget>[
                SliverLayoutBuilder(
                  builder:
                      (
                        final BuildContext context,
                        final SliverConstraints constraints,
                      ) {
                        final double inset = RepositoryMd3Layout.pagePaddingFor(
                          RepositoryMd3Layout.windowClassFor(
                            constraints.crossAxisExtent,
                          ),
                        ).left;
                        return SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            inset,
                            0,
                            inset,
                            RepositoryMd3Layout.space16,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _buildToolbar(context, state),
                          ),
                        );
                      },
                ),
                SliverLayoutBuilder(
                  builder:
                      (
                        final BuildContext context,
                        final SliverConstraints constraints,
                      ) {
                        final double inset = RepositoryMd3Layout.pagePaddingFor(
                          RepositoryMd3Layout.windowClassFor(
                            constraints.crossAxisExtent,
                          ),
                        ).left;
                        return SliverPadding(
                          padding: EdgeInsets.fromLTRB(inset, 0, inset, inset),
                          sliver: PaginatedSliverList<WorkflowRunItem>(
                            controller: _runsController,
                            itemBuilder:
                                (
                                  final BuildContext context,
                                  final WorkflowRunItem run,
                                  final int index,
                                ) => RepositoryWorkflowRunRow(
                                  run: run,
                                  first: index == 0,
                                ),
                            emptyBuilder: (final BuildContext context) =>
                                RepositoryTabStateCard(
                                  icon: Icons.play_circle_outline,
                                  title: context.l10n.repoNoWorkflowRuns,
                                  message: context.l10n.repoNoWorkflowRunsBody,
                                ),
                            errorBuilder:
                                (
                                  final BuildContext context,
                                  final Object error,
                                  final VoidCallback retry,
                                ) => RepositoryTabStateCard(
                                  icon: Icons.error_outline,
                                  title: context.l10n.repoActionsLoadError,
                                  message: '$error',
                                  action: OutlinedButton.icon(
                                    onPressed: retry,
                                    icon: const Icon(Icons.refresh),
                                    label: Text(context.l10n.commonRetry),
                                  ),
                                ),
                          ),
                        );
                      },
                ),
              ],
            );
          },
    );
  }

  Widget _buildNavigation(
    final List<RepositoryTabNavigationDestination> destinations,
    final int selectedIndex,
  ) {
    if (_workflowsLoading && _workflows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_workflowError != null && _workflows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(RepositoryMd3Layout.space16),
        child: RepositoryTabStateCard(
          icon: Icons.error_outline,
          title: context.l10n.repoWorkflowsLoadError,
          message: '$_workflowError',
          action: OutlinedButton.icon(
            onPressed: () => unawaited(_loadWorkflows()),
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.commonRetry),
          ),
        ),
      );
    }
    return RepositoryTabNavigation(
      title: context.l10n.repoActions,
      destinations: destinations,
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onSelected: (final int index) =>
          _selectWorkflow(index == 0 ? null : _workflows[index - 1]),
    );
  }

  Widget _buildToolbar(
    final BuildContext context,
    final PaginationState<WorkflowRunItem> state,
  ) {
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(RepositoryMd3Layout.space12),
        child: LayoutBuilder(
          builder:
              (final BuildContext context, final BoxConstraints constraints) {
                final Widget count = Text(
                  context.l10n.repoWorkflowRunsCount(
                    state.totalCount ?? state.items.length,
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                );
                final Widget branch = TextField(
                  controller: _branchController,
                  decoration: InputDecoration(
                    labelText: context.l10n.repoFilterBranch,
                    prefixIcon: const Icon(Icons.call_split),
                    suffixIcon: IconButton(
                      tooltip: context.l10n.commonSearch,
                      onPressed: () => unawaited(
                        _runsController.refresh(retainItems: false),
                      ),
                      icon: const Icon(Icons.search),
                    ),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (final String _) =>
                      unawaited(_runsController.refresh(retainItems: false)),
                );
                if (constraints.maxWidth < 600) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      count,
                      const SizedBox(height: RepositoryMd3Layout.space12),
                      branch,
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    Expanded(child: count),
                    SizedBox(width: 320, child: branch),
                  ],
                );
              },
        ),
      ),
    );
  }
}
