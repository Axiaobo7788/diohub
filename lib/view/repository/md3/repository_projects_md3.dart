import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/user_avatar.dart';
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
import 'package:diohub/view/repository/md3/repository_md3_layout.dart';
import 'package:diohub/view/repository/md3/repository_tab_scaffold.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class RepositoryProjectsMd3Page extends ConsumerStatefulWidget {
  const RepositoryProjectsMd3Page({
    required this.repoRef,
    required this.signedIn,
    required this.onRefreshReady,
    super.key,
  });

  final RepoRef repoRef;
  final bool signedIn;
  final ValueChanged<Future<void> Function()?> onRefreshReady;

  @override
  ConsumerState<RepositoryProjectsMd3Page> createState() =>
      _RepositoryProjectsMd3PageState();
}

class _RepositoryProjectsMd3PageState
    extends ConsumerState<RepositoryProjectsMd3Page> {
  late final PaginationController<ProjectV2Edge, ProjectV2Edge> _controller;
  ProjectV2OrderField _orderField = ProjectV2OrderField.UPDATED_AT;

  @override
  void initState() {
    super.initState();
    _controller = PaginationController<ProjectV2Edge, ProjectV2Edge>(
      source: CursorForwardSource<ProjectV2Edge>(fetch: _fetchProjects),
      idOf: (final ProjectV2Edge project) => project.cursor,
      pageSize: 20,
      autoFetch: widget.signedIn,
    );
    widget.onRefreshReady(widget.signedIn ? _refresh : null);
  }

  @override
  void didUpdateWidget(final RepositoryProjectsMd3Page oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signedIn == widget.signedIn) return;
    widget.onRefreshReady(widget.signedIn ? _refresh : null);
    if (widget.signedIn) {
      unawaited(_controller.refresh(retainItems: false));
    }
  }

  @override
  void dispose() {
    widget.onRefreshReady(null);
    _controller.dispose();
    super.dispose();
  }

  Future<PaginatedResult<ProjectV2Edge>> _fetchProjects({
    required final int first,
    final String? after,
  }) {
    return widget.repoRef
        .services(ref.read(apiClientProvider))
        .fetchProjectsPaginated(
          first: first,
          after: after,
          orderBy: ProjectV2Order(
            direction: _orderField == ProjectV2OrderField.UPDATED_AT
                ? OrderDirection.DESC
                : OrderDirection.ASC,
            field: _orderField,
          ),
          refresh: after == null,
        );
  }

  Future<void> _refresh() => _controller.refresh();

  void _changeOrder(final ProjectV2OrderField? field) {
    if (field == null || field == _orderField) return;
    setState(() => _orderField = field);
    unawaited(_controller.refresh(retainItems: false));
  }

  @override
  Widget build(final BuildContext context) {
    if (!widget.signedIn) {
      return RepositoryTabScaffold(
        title: context.l10n.repoProjects,
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
    return ValueListenableBuilder<PaginationState<ProjectV2Edge>>(
      valueListenable: _controller.state,
      builder:
          (
            final BuildContext context,
            final PaginationState<ProjectV2Edge> state,
            final Widget? child,
          ) {
            return RepositoryTabScaffold(
              title: context.l10n.repoProjects,
              refreshing: state.phase is Refreshing,
              onRefresh: _refresh,
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
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    RepositoryMd3Layout.regularPageInset,
                    0,
                    RepositoryMd3Layout.regularPageInset,
                    RepositoryMd3Layout.space16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _ProjectsToolbar(
                      orderField: _orderField,
                      onChanged: _changeOrder,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    RepositoryMd3Layout.regularPageInset,
                    0,
                    RepositoryMd3Layout.regularPageInset,
                    RepositoryMd3Layout.regularPageInset,
                  ),
                  sliver: PaginatedSliverList<ProjectV2Edge>(
                    controller: _controller,
                    itemBuilder:
                        (
                          final BuildContext context,
                          final ProjectV2Edge edge,
                          final int index,
                        ) {
                          final ProjectV2Node? project = edge.node;
                          if (project == null) {
                            return const SizedBox.shrink();
                          }
                          return _ProjectRow(
                            project: project,
                            first: index == 0,
                          );
                        },
                    emptyBuilder: (final BuildContext context) =>
                        RepositoryTabStateCard(
                          icon: Icons.table_chart_outlined,
                          title: context.l10n.repoNoProjects,
                          message: context.l10n.repoNoProjectsBody,
                        ),
                    errorBuilder:
                        (
                          final BuildContext context,
                          final Object error,
                          final VoidCallback retry,
                        ) => RepositoryTabStateCard(
                          icon: Icons.error_outline,
                          title: context.l10n.repoProjectsLoadError,
                          message: '$error',
                          action: OutlinedButton.icon(
                            onPressed: retry,
                            icon: const Icon(Icons.refresh),
                            label: Text(context.l10n.commonRetry),
                          ),
                        ),
                  ),
                ),
              ],
            );
          },
    );
  }
}

class _ProjectsToolbar extends StatelessWidget {
  const _ProjectsToolbar({required this.orderField, required this.onChanged});

  final ProjectV2OrderField orderField;
  final ValueChanged<ProjectV2OrderField?> onChanged;

  @override
  Widget build(final BuildContext context) {
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(RepositoryMd3Layout.space12),
        child: Row(
          children: <Widget>[
            const Icon(Icons.view_kanban_outlined),
            const SizedBox(width: RepositoryMd3Layout.space8),
            Expanded(
              child: Text(
                context.l10n.repoProjectsDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: RepositoryMd3Layout.space12),
            DropdownButton<ProjectV2OrderField>(
              value: orderField,
              onChanged: onChanged,
              items: <DropdownMenuItem<ProjectV2OrderField>>[
                DropdownMenuItem<ProjectV2OrderField>(
                  value: ProjectV2OrderField.UPDATED_AT,
                  child: Text(context.l10n.filterOptionRecentlyUpdated),
                ),
                DropdownMenuItem<ProjectV2OrderField>(
                  value: ProjectV2OrderField.CREATED_AT,
                  child: Text(context.l10n.filterOptionNewest),
                ),
                DropdownMenuItem<ProjectV2OrderField>(
                  value: ProjectV2OrderField.TITLE,
                  child: Text(context.l10n.repoSortTitle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.project, required this.first});

  final ProjectV2Node project;
  final bool first;

  @override
  Widget build(final BuildContext context) {
    return Card.outlined(
      margin: EdgeInsets.only(top: first ? 0 : RepositoryMd3Layout.space8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(launchUrl(project.url)),
        child: Padding(
          padding: const EdgeInsets.all(RepositoryMd3Layout.space16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.view_kanban_outlined),
              const SizedBox(width: RepositoryMd3Layout.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            project.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (project.closed)
                          Chip(
                            label: Text(context.l10n.filterClosed),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    if (project.shortDescription?.isNotEmpty == true) ...[
                      const SizedBox(height: RepositoryMd3Layout.space4),
                      Text(project.shortDescription!),
                    ],
                    const SizedBox(height: RepositoryMd3Layout.space8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: RepositoryMd3Layout.space8,
                      runSpacing: RepositoryMd3Layout.space4,
                      children: <Widget>[
                        if (project.creator != null)
                          UserAvatar(
                            avatarUrl: project.creator!.avatarUrl.toString(),
                            fallbackText: project.creator!.login,
                            size: 20,
                          ),
                        if (project.creator != null)
                          Text(project.creator!.login),
                        Text(
                          context.l10n.repoProjectItemsCount(
                            project.items.totalCount,
                          ),
                        ),
                        Text(
                          context.l10n.repoUpdatedTime(
                            formatRelativeTime(context, project.updatedAt),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: RepositoryMd3Layout.space8),
              const Icon(Icons.open_in_new, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
