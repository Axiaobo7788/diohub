import 'dart:async';

import 'package:diohub/app/settings/code_browser_settings.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_graphql/schema_typedefs.dart' show RepositoryPermission;
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code/code_browser_state.dart';
import 'package:diohub_models/models/repositories/code/code_tree_node.dart';
import 'package:diohub_models/models/repositories/code/directory_last_commit.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/l10n/relative_time.dart';
import 'package:diohub/models/repository_document.dart';
import 'package:diohub/providers/code_browser/code_browser_state_provider.dart';
import 'package:diohub/providers/code_browser/directory_last_commit_provider.dart';
import 'package:diohub/providers/code_browser/directory_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/providers/settings/code_browser_settings_provider.dart';
import 'package:diohub/utils/permission_utils.dart';
import 'package:diohub/view/repository/code/create_file_screen.dart';
import 'package:diohub/view/repository/code/file_viewer_screen.dart';
import 'package:diohub/view/repository/md3/repository_md3_layout.dart';
import 'package:diohub/view/repository/md3/tag_select_sheet.dart';
import 'package:diohub/view/repository/readme/repository_readme.dart';
import 'package:diohub/view/repository/widgets/branch_select_sheet.dart';
import 'package:diohub/view/repository/widgets/clone_url_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class RepositoryCodeMd3 extends ConsumerWidget {
  const RepositoryCodeMd3({
    required this.repoRef,
    required this.repo,
    required this.details,
    required this.detailsLoading,
    required this.detailsError,
    required this.onRetryDetails,
    required this.header,
    this.inlineAbout,
    this.aside,
    super.key,
  });

  final RepoRef repoRef;
  final RepoCardData? repo;
  final RepoInfo? details;
  final bool detailsLoading;
  final Object? detailsError;
  final Future<void> Function() onRetryDetails;
  final Widget header;
  final Widget? inlineAbout;
  final Widget? aside;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final BranchState branchState = ref.watch(branchProvider(repoRef));
    if (branchState is BranchStateLoading) {
      return _RepositoryCodeLoadingView(
        repoRef: repoRef,
        header: header,
        inlineAbout: inlineAbout,
        aside: aside,
        error: detailsError,
        onRetry: onRetryDetails,
      );
    }
    final BranchStateResolved branch = branchState as BranchStateResolved;
    final CodeBrowserState navigation = ref.watch(
      codeBrowserStateProvider(repoRef),
    );
    final CodeBrowserSettings settings = ref.watch(codeBrowserSettingsProvider);
    final DirectoryKey directoryKey = (
      repo: repoRef,
      branch: branch.refValue,
      path: navigation.currentPath,
    );
    final AsyncValue<List<CodeTreeNode>> directory = ref.watch(
      directoryProvider(directoryKey),
    );
    final bool showDocuments = navigation.currentPath.isEmpty;

    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final RepositoryWindowClass windowClass =
            RepositoryMd3Layout.windowClassFor(constraints.maxWidth);
        final EdgeInsets pagePadding = RepositoryMd3Layout.pagePaddingFor(
          windowClass,
        );
        final double codeContentWidth =
            windowClass == RepositoryWindowClass.expanded && aside != null
            ? constraints.maxWidth * 0.75
            : constraints.maxWidth;
        final List<Widget> mainSlivers = <Widget>[
          if (inlineAbout != null &&
              windowClass != RepositoryWindowClass.expanded) ...<Widget>[
            SliverToBoxAdapter(child: inlineAbout),
            const SliverToBoxAdapter(child: Divider()),
          ],
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              pagePadding.left,
              windowClass == RepositoryWindowClass.compact
                  ? RepositoryMd3Layout.space16
                  : RepositoryMd3Layout.space24,
              pagePadding.right,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _CodeToolbar(
                repoRef: repoRef,
                repo: repo,
                details: details,
                branch: branch,
                navigation: navigation,
                compact: windowClass == RepositoryWindowClass.compact,
                inline:
                    codeContentWidth >=
                    RepositoryMd3Layout.inlineCodeToolbarBreakpoint,
              ),
            ),
          ),
          if (repo?.isFork == true && repo?.parent != null)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                RepositoryMd3Layout.pagePaddingFor(windowClass).left,
                0,
                RepositoryMd3Layout.pagePaddingFor(windowClass).right,
                RepositoryMd3Layout.space12,
              ),
              sliver: SliverToBoxAdapter(child: _ForkStatusCard(repo: repo!)),
            ),
          ..._buildDirectorySlivers(
            context,
            ref,
            directory,
            branch,
            navigation,
            settings,
            windowClass,
          ),
          if (showDocuments)
            _RepositoryDocumentsSliver(
              repoRef: repoRef,
              repo: repo,
              details: details,
              branch: branch.refValue,
              windowClass: windowClass,
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: RepositoryMd3Layout.space32),
          ),
        ];
        final List<Widget> pageSlivers = <Widget>[
          SliverToBoxAdapter(child: header),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          if (detailsLoading)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(minHeight: 2),
            )
          else if (detailsError != null)
            SliverToBoxAdapter(
              child: _RepositoryDetailsError(
                error: detailsError!,
                onRetry: onRetryDetails,
              ),
            ),
          if (windowClass == RepositoryWindowClass.expanded && aside != null)
            SliverCrossAxisGroup(
              slivers: <Widget>[
                SliverCrossAxisExpanded(
                  flex: 3,
                  sliver: SliverMainAxisGroup(slivers: mainSlivers),
                ),
                SliverCrossAxisExpanded(
                  flex: 1,
                  sliver: SliverMainAxisGroup(
                    slivers: <Widget>[SliverToBoxAdapter(child: aside)],
                  ),
                ),
              ],
            )
          else
            ...mainSlivers,
        ];
        return RefreshIndicator(
          onRefresh: () => refreshRepositoryCode(ref, repoRef),
          child: CustomScrollView(
            key: PageStorageKey<String>(
              'repository-code-${repoRef.fullName}-${branch.refValue}-${navigation.currentPath}',
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: pageSlivers,
          ),
        );
      },
    );
  }

  List<Widget> _buildDirectorySlivers(
    final BuildContext context,
    final WidgetRef ref,
    final AsyncValue<List<CodeTreeNode>> directory,
    final BranchStateResolved branch,
    final CodeBrowserState navigation,
    final CodeBrowserSettings settings,
    final RepositoryWindowClass windowClass,
  ) {
    final Widget directorySliver = directory.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(RepositoryMd3Layout.space32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (final Object error, final StackTrace stack) => SliverToBoxAdapter(
        child: _CodeErrorState(
          error: error,
          onRetry: () => refreshRepositoryCode(ref, repoRef),
        ),
      ),
      data: (final List<CodeTreeNode> entries) {
        final List<CodeTreeNode> visible = _sortedEntries(
          _filteredEntries(entries, settings, navigation.searchQuery),
          settings.sortOrder,
        );
        final List<CodeTreeNode> fileSiblings = visible
            .where(
              (final CodeTreeNode entry) =>
                  entry.kind == CodeEntryKind.file ||
                  entry.kind == CodeEntryKind.symlink,
            )
            .toList();
        if (visible.isEmpty) {
          return SliverToBoxAdapter(
            child: _CodeEmptyState(
              filtered: navigation.searchQuery.trim().isNotEmpty,
            ),
          );
        }
        return SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (final BuildContext context, final int index) =>
              const Divider(height: 1),
          itemBuilder: (final BuildContext context, final int index) {
            final CodeTreeNode entry = visible[index];
            return _DirectoryEntryRow(
              entry: entry,
              repoRef: repoRef,
              branch: branch.refValue,
              compact: windowClass == RepositoryWindowClass.compact,
              showLastCommit: settings.showLastCommitInfo,
              showMetadata: settings.showMetadata,
              onTap: () => _openEntry(
                context,
                ref,
                entry,
                branch.refValue,
                fileSiblings,
              ),
            );
          },
        );
      },
    );
    final EdgeInsets pagePadding = RepositoryMd3Layout.pagePaddingFor(
      windowClass,
    );
    final ColorScheme colors = Theme.of(context).colorScheme;
    return <Widget>[
      SliverPadding(
        key: const ValueKey<String>('repository-file-table'),
        padding: EdgeInsets.symmetric(horizontal: pagePadding.left),
        sliver: DecoratedSliver(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(
              RepositoryMd3Layout.sectionRadius,
            ),
          ),
          sliver: SliverMainAxisGroup(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _LatestCommitCard(
                  repoRef: repoRef,
                  branch: branch.refValue,
                  path: navigation.currentPath,
                ),
              ),
              const SliverToBoxAdapter(child: Divider(height: 1)),
              directorySliver,
            ],
          ),
        ),
      ),
    ];
  }

  void _openEntry(
    final BuildContext context,
    final WidgetRef ref,
    final CodeTreeNode entry,
    final String branch,
    final List<CodeTreeNode> fileSiblings,
  ) {
    switch (entry.kind) {
      case CodeEntryKind.directory:
        ref
            .read(codeBrowserStateProvider(repoRef).notifier)
            .pushDirectory(entry.path);
      case CodeEntryKind.file:
      case CodeEntryKind.symlink:
        final int index = fileSiblings.indexWhere(
          (final CodeTreeNode sibling) => sibling.path == entry.path,
        );
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (final BuildContext context) => FileViewerScreen(
              repoRef: repoRef,
              branch: branch,
              filePath: entry.path,
              siblingFiles: fileSiblings.length > 1 ? fileSiblings : null,
              initialIndex: index < 0 ? 0 : index,
            ),
          ),
        );
      case CodeEntryKind.submodule:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.repoOpenSubmoduleUnavailable)),
        );
    }
  }
}

class _RepositoryCodeLoadingView extends StatelessWidget {
  const _RepositoryCodeLoadingView({
    required this.repoRef,
    required this.header,
    required this.inlineAbout,
    required this.aside,
    required this.error,
    required this.onRetry,
  });

  final RepoRef repoRef;
  final Widget header;
  final Widget? inlineAbout;
  final Widget? aside;
  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final RepositoryWindowClass windowClass =
            RepositoryMd3Layout.windowClassFor(constraints.maxWidth);
        final EdgeInsets pagePadding = RepositoryMd3Layout.pagePaddingFor(
          windowClass,
        );
        final ColorScheme colors = Theme.of(context).colorScheme;
        final List<Widget> mainSlivers = <Widget>[
          if (inlineAbout != null &&
              windowClass != RepositoryWindowClass.expanded) ...<Widget>[
            SliverToBoxAdapter(child: inlineAbout),
            const SliverToBoxAdapter(child: Divider()),
          ],
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              pagePadding.left,
              windowClass == RepositoryWindowClass.compact
                  ? RepositoryMd3Layout.space16
                  : RepositoryMd3Layout.space24,
              pagePadding.right,
              RepositoryMd3Layout.space16,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: <Widget>[
                  const _CodeLoadingBlock(width: 156, height: 40),
                  const Spacer(),
                  if (windowClass != RepositoryWindowClass.compact) ...<Widget>[
                    const Expanded(child: _CodeLoadingBlock(height: 40)),
                    const SizedBox(width: RepositoryMd3Layout.space8),
                  ],
                  const _CodeLoadingBlock(width: 108, height: 40),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pagePadding.left),
            sliver: DecoratedSliver(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(
                  RepositoryMd3Layout.sectionRadius,
                ),
              ),
              sliver: SliverMainAxisGroup(
                slivers: <Widget>[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(RepositoryMd3Layout.space16),
                      child: Row(
                        children: <Widget>[
                          _CodeLoadingBlock(width: 28, height: 28),
                          SizedBox(width: RepositoryMd3Layout.space12),
                          Expanded(child: _CodeLoadingBlock(height: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: Divider(height: 1)),
                  SliverList.separated(
                    itemCount: 9,
                    separatorBuilder:
                        (final BuildContext context, final int index) =>
                            const Divider(height: 1),
                    itemBuilder:
                        (
                          final BuildContext context,
                          final int index,
                        ) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: RepositoryMd3Layout.space12,
                            vertical: RepositoryMd3Layout.space12,
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.folder_outlined),
                              const SizedBox(
                                width: RepositoryMd3Layout.space12,
                              ),
                              _CodeLoadingBlock(
                                width: 112 + (index % 3) * 28,
                                height: 16,
                              ),
                              if (windowClass !=
                                  RepositoryWindowClass.compact) ...<Widget>[
                                const Spacer(),
                                const _CodeLoadingBlock(width: 160, height: 16),
                                const SizedBox(
                                  width: RepositoryMd3Layout.space24,
                                ),
                                const _CodeLoadingBlock(width: 72, height: 16),
                              ],
                            ],
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ];
        final List<Widget> pageSlivers = <Widget>[
          SliverToBoxAdapter(child: header),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          if (error == null)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(minHeight: 2),
            )
          else
            SliverToBoxAdapter(
              child: _RepositoryDetailsError(error: error!, onRetry: onRetry),
            ),
          if (windowClass == RepositoryWindowClass.expanded && aside != null)
            SliverCrossAxisGroup(
              slivers: <Widget>[
                SliverCrossAxisExpanded(
                  flex: 3,
                  sliver: SliverMainAxisGroup(slivers: mainSlivers),
                ),
                SliverCrossAxisExpanded(
                  flex: 1,
                  sliver: SliverToBoxAdapter(child: aside),
                ),
              ],
            )
          else
            ...mainSlivers,
        ];
        return CustomScrollView(
          key: PageStorageKey<String>(
            'repository-code-${repoRef.fullName}-loading',
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: pageSlivers,
        );
      },
    );
  }
}

class _CodeLoadingBlock extends StatelessWidget {
  const _CodeLoadingBlock({this.width, required this.height});

  final double? width;
  final double height;

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _RepositoryDetailsError extends StatelessWidget {
  const _RepositoryDetailsError({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(final BuildContext context) {
    return MaterialBanner(
      leading: const Icon(Icons.warning_amber_outlined),
      content: Text(
        context.l10n.repoLoadError('$error'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => unawaited(onRetry()),
          child: Text(context.l10n.commonRetry),
        ),
      ],
    );
  }
}

Future<void> refreshRepositoryCode(
  final WidgetRef ref,
  final RepoRef repoRef,
) async {
  final BranchState branch = ref.read(branchProvider(repoRef));
  if (branch is! BranchStateResolved) {
    return;
  }
  final String path = ref.read(codeBrowserStateProvider(repoRef)).currentPath;
  final DirectoryKey key = (repo: repoRef, branch: branch.refValue, path: path);
  ref
    ..invalidate(
      directoryLastCommitProvider((
        repo: repoRef,
        branch: branch.refValue,
        path: path,
      )),
    )
    ..invalidate(readmeProvider(repoRef));
  final List<CodeTreeNode> _ = await ref.refresh(directoryProvider(key).future);
}

class _CodeToolbar extends ConsumerStatefulWidget {
  const _CodeToolbar({
    required this.repoRef,
    required this.repo,
    required this.details,
    required this.branch,
    required this.navigation,
    required this.compact,
    required this.inline,
  });

  final RepoRef repoRef;
  final RepoCardData? repo;
  final RepoInfo? details;
  final BranchStateResolved branch;
  final CodeBrowserState navigation;
  final bool compact;
  final bool inline;

  @override
  ConsumerState<_CodeToolbar> createState() => _CodeToolbarState();
}

class _CodeToolbarState extends ConsumerState<_CodeToolbar> {
  late final TextEditingController _searchController;
  bool _showCompactFilter = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.navigation.searchQuery,
    );
  }

  @override
  void didUpdateWidget(final _CodeToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_searchController.text != widget.navigation.searchQuery) {
      _searchController.value = TextEditingValue(
        text: widget.navigation.searchQuery,
        selection: TextSelection.collapsed(
          offset: widget.navigation.searchQuery.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final Widget refSelector = _RefSelectorButton(
      repoRef: widget.repoRef,
      repo: widget.repo,
      branch: widget.branch,
      maxLabelWidth: widget.compact
          ? 104
          : RepositoryMd3Layout.refButtonLabelWidth,
    );
    final Widget addFile = _AddFileButton(
      repoRef: widget.repoRef,
      details: widget.details,
      branch: widget.branch,
      parentPath: widget.navigation.currentPath,
    );
    final Widget clone = FilledButton.icon(
      onPressed: widget.repo == null
          ? null
          : () => _showCloneSheet(context, widget.repo!, widget.details),
      icon: const Icon(Icons.code),
      label: Text(context.l10n.repoCode),
    );
    final Widget search = _DirectoryFilterField(
      controller: _searchController,
      hintText: context.l10n.repoFilterCurrentDirectory,
      onClear: widget.navigation.searchQuery.isEmpty
          ? null
          : () {
              _searchController.clear();
              ref
                  .read(codeBrowserStateProvider(widget.repoRef).notifier)
                  .setSearchQuery('');
            },
      onChanged: (final String value) => ref
          .read(codeBrowserStateProvider(widget.repoRef).notifier)
          .setSearchQuery(value),
    );
    final int? branchCount = widget.details?.branchCount?.totalCount;
    final int? tagCount = widget.details?.tagCount?.totalCount;
    final List<Widget> refCounts = <Widget>[
      if (branchCount != null)
        TextButton.icon(
          onPressed: () => _showBranchPicker(context),
          icon: const Icon(Icons.account_tree_outlined, size: 18),
          label: Text(context.l10n.repoBranchesCount('$branchCount')),
        ),
      if (tagCount != null)
        TextButton.icon(
          onPressed: () => _showTagPicker(context),
          icon: const Icon(Icons.sell_outlined, size: 18),
          label: Text(context.l10n.repoTagsCount('$tagCount')),
        ),
    ];
    final bool canCreate =
        !widget.branch.isCommit &&
        widget.details != null &&
        isAtLeast(widget.details!.viewerPermission, RepositoryPermission.WRITE);
    final Widget compactMore = MenuAnchor(
      menuChildren: <Widget>[
        MenuItemButton(
          leadingIcon: const Icon(Icons.filter_list),
          onPressed: () => setState(() => _showCompactFilter = true),
          child: Text(context.l10n.repoFilterCurrentDirectory),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.manage_search),
          onPressed: null,
          child: Text(context.l10n.repoGoToFileUnavailable),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.note_add_outlined),
          onPressed: canCreate ? () => _createFile(context) : null,
          child: Text(context.l10n.repoCreateNewFile),
        ),
      ],
      builder:
          (
            final BuildContext context,
            final MenuController controller,
            final Widget? child,
          ) => IconButton.outlined(
            tooltip: context.l10n.repoCodeOptions,
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
            icon: const Icon(Icons.more_horiz),
          ),
    );
    final bool showBreadcrumbs = widget.navigation.currentPath.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showBreadcrumbs) ...<Widget>[
          _RepositoryBreadcrumbs(
            repoRef: widget.repoRef,
            path: widget.navigation.currentPath,
          ),
          const SizedBox(height: RepositoryMd3Layout.space12),
        ],
        if (!widget.inline) ...<Widget>[
          Row(
            children: <Widget>[
              refSelector,
              const Spacer(),
              clone,
              const SizedBox(width: RepositoryMd3Layout.space8),
              compactMore,
            ],
          ),
          if (!widget.compact && refCounts.isNotEmpty) ...<Widget>[
            const SizedBox(height: RepositoryMd3Layout.space4),
            Wrap(
              spacing: RepositoryMd3Layout.space4,
              runSpacing: RepositoryMd3Layout.space4,
              children: refCounts,
            ),
          ],
          if (_showCompactFilter ||
              widget.navigation.searchQuery.isNotEmpty) ...<Widget>[
            const SizedBox(height: RepositoryMd3Layout.space12),
            search,
          ],
        ] else
          Row(
            children: <Widget>[
              refSelector,
              const SizedBox(width: RepositoryMd3Layout.space8),
              ...refCounts.expand(
                (final Widget item) => <Widget>[
                  item,
                  const SizedBox(width: RepositoryMd3Layout.space4),
                ],
              ),
              Expanded(child: search),
              const SizedBox(width: RepositoryMd3Layout.space8),
              addFile,
              const SizedBox(width: RepositoryMd3Layout.space8),
              clone,
            ],
          ),
        if (widget.branch.isCommit) ...<Widget>[
          const SizedBox(height: RepositoryMd3Layout.space12),
          MaterialBanner(
            content: Text(
              context.l10n.repoBrowsingCommit(
                _abbreviate(widget.branch.refValue),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: widget.repo?.defaultBranchRef == null
                    ? null
                    : () => ref
                          .read(branchProvider(widget.repoRef).notifier)
                          .setBranchState(
                            BranchState.branch(
                              widget.repo!.defaultBranchRef!.name,
                            ),
                          ),
                child: Text(context.l10n.repoDefaultBranch),
              ),
            ],
          ),
        ],
        const SizedBox(height: RepositoryMd3Layout.space16),
      ],
    );
  }

  void _createFile(final BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (final BuildContext context) => CreateFileScreen(
          repoRef: widget.repoRef,
          branchRef: widget.branch.refValue,
          parentPath: widget.navigation.currentPath,
        ),
      ),
    );
  }

  Future<void> _showBranchPicker(final BuildContext context) async {
    await _showRefDialog(
      context,
      title: context.l10n.repoSwitchBranch,
      child: BranchSelectSheet(
        widget.repoRef,
        defaultBranch: widget.repo?.defaultBranchRef?.name,
        currentBranch: widget.branch.refKind == RefKind.branch
            ? widget.branch.refValue
            : null,
        onSelected: (final String name) => _selectRef(BranchState.branch(name)),
      ),
    );
  }

  Future<void> _showTagPicker(final BuildContext context) async {
    await _showRefDialog(
      context,
      title: context.l10n.repoSwitchTag,
      child: TagSelectSheet(
        widget.repoRef,
        currentTag: widget.branch.isTag ? widget.branch.refValue : null,
        onSelected: (final String name) => _selectRef(BranchState.tag(name)),
      ),
    );
  }

  void _selectRef(final BranchState value) {
    ref.read(branchProvider(widget.repoRef).notifier).setBranchState(value);
    ref
        .read(codeBrowserStateProvider(widget.repoRef).notifier)
        .jumpToPathIndex(-1);
  }
}

class _DirectoryFilterField extends StatelessWidget {
  const _DirectoryFilterField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hintText,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: RepositoryMd3Layout.space12,
          ),
          prefixIcon: const Icon(Icons.search, size: 20),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  tooltip: context.l10n.repoClearFileFilter,
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 18),
                ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              RepositoryMd3Layout.sectionRadius / 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _RepositoryBreadcrumbs extends ConsumerWidget {
  const _RepositoryBreadcrumbs({required this.repoRef, required this.path});

  final RepoRef repoRef;
  final String path;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final List<String> segments = path
        .split('/')
        .where((final String part) => part.isNotEmpty)
        .toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          TextButton(
            onPressed: () => ref
                .read(codeBrowserStateProvider(repoRef).notifier)
                .jumpToPathIndex(-1),
            child: Text(repoRef.name),
          ),
          for (int index = 0; index < segments.length; index++) ...<Widget>[
            const Icon(Icons.chevron_right),
            TextButton(
              onPressed: index == segments.length - 1
                  ? null
                  : () => ref
                        .read(codeBrowserStateProvider(repoRef).notifier)
                        .jumpToPathIndex(index),
              child: Text(segments[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _RefSelectorButton extends ConsumerWidget {
  const _RefSelectorButton({
    required this.repoRef,
    required this.repo,
    required this.branch,
    required this.maxLabelWidth,
  });

  final RepoRef repoRef;
  final RepoCardData? repo;
  final BranchStateResolved branch;
  final double maxLabelWidth;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return MenuAnchor(
      menuChildren: <Widget>[
        MenuItemButton(
          leadingIcon: const Icon(Icons.account_tree_outlined),
          onPressed: () => _showBranchPicker(context, ref),
          child: Text(context.l10n.repoSwitchBranch),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.sell_outlined),
          onPressed: () => _showTagPicker(context, ref),
          child: Text(context.l10n.repoSwitchTag),
        ),
      ],
      builder:
          (
            final BuildContext context,
            final MenuController controller,
            final Widget? child,
          ) => OutlinedButton.icon(
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
            icon: Icon(branch.isTag ? Icons.sell_outlined : Icons.account_tree),
            label: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxLabelWidth),
              child: Text(branch.refValue, overflow: TextOverflow.ellipsis),
            ),
          ),
    );
  }

  Future<void> _showBranchPicker(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    await _showRefDialog(
      context,
      title: context.l10n.repoSwitchBranch,
      child: BranchSelectSheet(
        repoRef,
        defaultBranch: repo?.defaultBranchRef?.name,
        currentBranch: branch.refKind == RefKind.branch
            ? branch.refValue
            : null,
        onSelected: (final String name) =>
            _selectRef(ref, BranchState.branch(name)),
      ),
    );
  }

  Future<void> _showTagPicker(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    await _showRefDialog(
      context,
      title: context.l10n.repoSwitchTag,
      child: TagSelectSheet(
        repoRef,
        currentTag: branch.isTag ? branch.refValue : null,
        onSelected: (final String name) =>
            _selectRef(ref, BranchState.tag(name)),
      ),
    );
  }

  void _selectRef(final WidgetRef ref, final BranchState value) {
    ref.read(branchProvider(repoRef).notifier).setBranchState(value);
    ref.read(codeBrowserStateProvider(repoRef).notifier).jumpToPathIndex(-1);
  }
}

class _AddFileButton extends StatelessWidget {
  const _AddFileButton({
    required this.repoRef,
    required this.details,
    required this.branch,
    required this.parentPath,
  });

  final RepoRef repoRef;
  final RepoInfo? details;
  final BranchStateResolved branch;
  final String parentPath;

  @override
  Widget build(final BuildContext context) {
    final bool canCreate =
        !branch.isCommit &&
        details != null &&
        isAtLeast(details!.viewerPermission, RepositoryPermission.WRITE);
    return MenuAnchor(
      menuChildren: <Widget>[
        MenuItemButton(
          leadingIcon: const Icon(Icons.note_add_outlined),
          onPressed: canCreate ? () => _createFile(context) : null,
          child: Text(context.l10n.repoCreateNewFile),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.upload_file_outlined),
          onPressed: null,
          child: Text(context.l10n.repoUploadFilesUnavailable),
        ),
      ],
      builder:
          (
            final BuildContext context,
            final MenuController controller,
            final Widget? child,
          ) => OutlinedButton.icon(
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
            icon: const Icon(Icons.add),
            label: Text(context.l10n.repoAddFile),
          ),
    );
  }

  void _createFile(final BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (final BuildContext context) => CreateFileScreen(
          repoRef: repoRef,
          branchRef: branch.refValue,
          parentPath: parentPath,
        ),
      ),
    );
  }
}

class _ForkStatusCard extends StatelessWidget {
  const _ForkStatusCard({required this.repo});

  final RepoCardData repo;

  @override
  Widget build(final BuildContext context) {
    final parent = repo.parent!;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RepositoryMd3Layout.space16,
          vertical: RepositoryMd3Layout.space8,
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.call_split, size: 20),
            const SizedBox(width: RepositoryMd3Layout.space8),
            Expanded(
              child: Text(
                context.l10n.repoForkedFrom(parent.nameWithOwner),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => unawaited(launchUrl(parent.url)),
              child: Text(context.l10n.repoViewUpstream),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestCommitCard extends ConsumerWidget {
  const _LatestCommitCard({
    required this.repoRef,
    required this.branch,
    required this.path,
  });

  final RepoRef repoRef;
  final String branch;
  final String path;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final LastCommitKey key = (repo: repoRef, branch: branch, path: path);
    final AsyncValue<DirectoryLastCommit?> latest = ref.watch(
      directoryLastCommitProvider(key),
    );
    return latest.when(
      loading: () => ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RepositoryMd3Layout.space16,
        ),
        leading: const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text(context.l10n.repoLoadingLatestCommit),
      ),
      error: (final Object error, final StackTrace stack) => ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RepositoryMd3Layout.space16,
        ),
        leading: const Icon(Icons.warning_amber_outlined),
        title: Text(context.l10n.repoLatestCommitUnavailable),
        subtitle: Text('$error', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          tooltip: context.l10n.repoRetryLatestCommit,
          onPressed: () => ref.invalidate(directoryLastCommitProvider(key)),
          icon: const Icon(Icons.refresh),
        ),
      ),
      data: (final DirectoryLastCommit? commit) {
        if (commit == null) {
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: RepositoryMd3Layout.space16,
            ),
            leading: const Icon(Icons.commit, size: 20),
            title: Text(context.l10n.repoNoCommitInformation),
          );
        }
        return LayoutBuilder(
          builder:
              (final BuildContext context, final BoxConstraints constraints) {
                final bool compact =
                    constraints.maxWidth <
                    RepositoryMd3Layout.compactBreakpoint;
                final String author =
                    commit.authorName ?? context.l10n.repoUnknownAuthor;
                final String updated = formatRelativeTime(
                  context,
                  commit.committedDate,
                  compact: true,
                );
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: RepositoryMd3Layout.space16,
                  ),
                  leading: const Icon(Icons.commit, size: 20),
                  title: compact
                      ? Text(
                          commit.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Row(
                          children: <Widget>[
                            Text(
                              author,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: RepositoryMd3Layout.space8),
                            Expanded(
                              child: Text(
                                commit.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                  subtitle: compact
                      ? Text(
                          '$author · ${commit.abbreviatedOid} · $updated',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: compact
                      ? null
                      : Text('${commit.abbreviatedOid} · $updated'),
                );
              },
        );
      },
    );
  }
}

class _RepositoryDocumentsSliver extends ConsumerStatefulWidget {
  const _RepositoryDocumentsSliver({
    required this.repoRef,
    required this.repo,
    required this.details,
    required this.branch,
    required this.windowClass,
  });

  final RepoRef repoRef;
  final RepoCardData? repo;
  final RepoInfo? details;
  final String branch;
  final RepositoryWindowClass windowClass;

  @override
  ConsumerState<_RepositoryDocumentsSliver> createState() =>
      _RepositoryDocumentsSliverState();
}

class _RepositoryDocumentsSliverState
    extends ConsumerState<_RepositoryDocumentsSliver> {
  RepositoryDocumentKind _selected = RepositoryDocumentKind.readme;

  List<RepositoryDocumentKind> get _availableKinds => <RepositoryDocumentKind>[
    RepositoryDocumentKind.readme,
    if (widget.details?.contributingGuidelines?.url != null)
      RepositoryDocumentKind.contributing,
    if (widget.details?.licenseInfo != null || widget.repo?.licenseInfo != null)
      RepositoryDocumentKind.license,
    if (widget.details?.isSecurityPolicyEnabled == true)
      RepositoryDocumentKind.security,
  ];

  @override
  Widget build(final BuildContext context) {
    final List<RepositoryDocumentKind> availableKinds = _availableKinds;
    final RepositoryDocumentKind selected = availableKinds.contains(_selected)
        ? _selected
        : RepositoryDocumentKind.readme;
    final RepositoryDocumentKey key = (
      repoRef: widget.repoRef,
      branch: widget.branch,
      kind: selected,
    );
    final AsyncValue<RepositoryDocument?> document = ref.watch(
      repositoryDocumentProvider(key),
    );
    final EdgeInsets pagePadding = RepositoryMd3Layout.pagePaddingFor(
      widget.windowClass,
    );
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SliverPadding(
      key: const ValueKey<String>('repository-document-card'),
      padding: EdgeInsets.fromLTRB(
        pagePadding.left,
        RepositoryMd3Layout.space24,
        pagePadding.right,
        0,
      ),
      sliver: DecoratedSliver(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(
            RepositoryMd3Layout.sectionRadius,
          ),
        ),
        sliver: SliverMainAxisGroup(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: _RepositoryDocumentHeader(
                repo: widget.repo,
                details: widget.details,
                availableKinds: availableKinds,
                selected: selected,
                onSelected: (final RepositoryDocumentKind kind) {
                  if (kind == selected) return;
                  setState(() => _selected = kind);
                },
              ),
            ),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            _buildDocumentSliver(context, document, key, selected),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSliver(
    final BuildContext context,
    final AsyncValue<RepositoryDocument?> document,
    final RepositoryDocumentKey key,
    final RepositoryDocumentKind selected,
  ) => document.when(
    loading: () => const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: RepositoryMd3Layout.space32),
        child: Center(child: CircularProgressIndicator()),
      ),
    ),
    error: (final Object error, final StackTrace stack) => SliverToBoxAdapter(
      child: ListTile(
        leading: const Icon(Icons.warning_amber_outlined),
        title: Text(context.l10n.repoDocumentLoadError('$error')),
        trailing: IconButton(
          tooltip: context.l10n.commonRetry,
          onPressed: () => ref.invalidate(repositoryDocumentProvider(key)),
          icon: const Icon(Icons.refresh),
        ),
      ),
    ),
    data: (final RepositoryDocument? value) {
      if (value == null) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: RepositoryMd3Layout.space32,
            ),
            child: Center(child: Text(context.l10n.repoDocumentNotFound)),
          ),
        );
      }
      return switch (value.format) {
        RepositoryDocumentFormat.html => RepositoryReadmeSliver(
          key: ValueKey<String>(
            '${widget.repoRef.fullName}-${widget.branch}-${selected.name}',
          ),
          readmeAsync: AsyncData<String?>(value.content),
          branch: widget.branch,
          repoFullName: widget.repoRef.fullName,
          contentPadding: RepositoryMd3Layout.documentContentPaddingFor(
            widget.windowClass,
          ),
        ),
        RepositoryDocumentFormat.markdown => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(RepositoryMd3Layout.space16),
            child: SelectableText(
              value.content,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ),
      };
    },
  );
}

class _RepositoryDocumentHeader extends StatelessWidget {
  const _RepositoryDocumentHeader({
    required this.repo,
    required this.details,
    required this.availableKinds,
    required this.selected,
    required this.onSelected,
  });

  final RepoCardData? repo;
  final RepoInfo? details;
  final List<RepositoryDocumentKind> availableKinds;
  final RepositoryDocumentKind selected;
  final ValueChanged<RepositoryDocumentKind> onSelected;

  @override
  Widget build(final BuildContext context) {
    final List<Widget> documents = availableKinds
        .map(
          (final RepositoryDocumentKind kind) => _RepositoryDocumentTab(
            icon: switch (kind) {
              RepositoryDocumentKind.readme => Icons.menu_book_outlined,
              RepositoryDocumentKind.contributing => Icons.group_outlined,
              RepositoryDocumentKind.license => Icons.balance_outlined,
              RepositoryDocumentKind.security => Icons.security_outlined,
            },
            label: switch (kind) {
              RepositoryDocumentKind.readme => context.l10n.repoReadme,
              RepositoryDocumentKind.contributing =>
                context.l10n.repoContributing,
              RepositoryDocumentKind.license =>
                details?.licenseInfo?.name ??
                    repo?.licenseInfo?.name ??
                    context.l10n.repoLicense,
              RepositoryDocumentKind.security => context.l10n.repoSecurity,
            },
            selected: selected == kind,
            onPressed: () => onSelected(kind),
          ),
        )
        .toList();
    final bool canEdit =
        details != null &&
        repo != null &&
        isAtLeast(details!.viewerPermission, RepositoryPermission.WRITE) &&
        repo!.defaultBranchRef != null;
    return SizedBox(
      height: 52,
      child: Row(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: RepositoryMd3Layout.space8,
              ),
              child: Row(children: documents),
            ),
          ),
          if (selected == RepositoryDocumentKind.readme) ...<Widget>[
            Tooltip(
              message: canEdit
                  ? context.l10n.repoEditReadme
                  : context.l10n.repoEditReadmeRequiresWrite,
              child: IconButton(
                onPressed: canEdit
                    ? () => unawaited(
                        launchUrl(
                          repo!.url.replace(
                            path:
                                '${repo!.url.path}/edit/${repo!.defaultBranchRef!.name}/README.md',
                          ),
                        ),
                      )
                    : null,
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
            Tooltip(
              message: context.l10n.repoReadmeOutlineUnavailable,
              child: const IconButton(
                onPressed: null,
                icon: Icon(Icons.format_list_bulleted),
              ),
            ),
          ],
          const SizedBox(width: RepositoryMd3Layout.space4),
        ],
      ),
    );
  }
}

class _RepositoryDocumentTab extends StatelessWidget {
  const _RepositoryDocumentTab({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: selected ? null : onPressed,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(
            horizontal: RepositoryMd3Layout.space12,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? colors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18),
              const SizedBox(width: RepositoryMd3Layout.space8),
              Text(
                label,
                style: TextStyle(fontWeight: selected ? FontWeight.w700 : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectoryEntryRow extends ConsumerWidget {
  const _DirectoryEntryRow({
    required this.entry,
    required this.repoRef,
    required this.branch,
    required this.compact,
    required this.showLastCommit,
    required this.showMetadata,
    required this.onTap,
  });

  final CodeTreeNode entry;
  final RepoRef repoRef;
  final String branch;
  final bool compact;
  final bool showLastCommit;
  final bool showMetadata;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<DirectoryLastCommit?>? lastCommit = showLastCommit
        ? ref.watch(
            directoryLastCommitProvider((
              repo: repoRef,
              branch: branch,
              path: entry.path,
            )),
          )
        : null;
    final String? message = lastCommit?.value?.message;
    final DateTime? updated = lastCommit?.value?.committedDate;
    if (compact) {
      final String metadata = _entryMetadata(context, entry, showMetadata);
      final String? supportingText =
          message ?? (metadata.isEmpty ? null : metadata);
      return ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RepositoryMd3Layout.space12,
        ),
        leading: Icon(
          _iconForEntry(entry.kind),
          color: _iconColorForEntry(context, entry.kind),
        ),
        title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: supportingText == null
            ? null
            : Text(
                supportingText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        onTap: onTap,
      );
    }
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RepositoryMd3Layout.space12,
          vertical: RepositoryMd3Layout.space8,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: RepositoryMd3Layout.fileIconWidth,
              child: Icon(
                _iconForEntry(entry.kind),
                color: _iconColorForEntry(context, entry.kind),
              ),
            ),
            Expanded(
              child: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showLastCommit) ...<Widget>[
              SizedBox(
                width: RepositoryMd3Layout.fileMessageWidth,
                child: Text(
                  message ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                width: RepositoryMd3Layout.fileUpdatedWidth,
                child: Text(
                  updated == null
                      ? ''
                      : formatRelativeTime(context, updated, compact: true),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CodeErrorState extends StatelessWidget {
  const _CodeErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(RepositoryMd3Layout.space32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.error_outline,
            size: RepositoryMd3Layout.statusIconSize,
          ),
          const SizedBox(height: RepositoryMd3Layout.space16),
          Text(
            context.l10n.repoCouldNotLoadFiles,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: RepositoryMd3Layout.space8),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: RepositoryMd3Layout.space16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }
}

class _CodeEmptyState extends StatelessWidget {
  const _CodeEmptyState({required this.filtered});

  final bool filtered;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(RepositoryMd3Layout.space32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.folder_off_outlined,
            size: RepositoryMd3Layout.statusIconSize,
          ),
          const SizedBox(height: RepositoryMd3Layout.space16),
          Text(
            filtered
                ? context.l10n.repoNoMatchingFiles
                : context.l10n.repoDirectoryEmpty,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (filtered) ...<Widget>[
            const SizedBox(height: RepositoryMd3Layout.space8),
            Text(context.l10n.repoClearFilterHint),
          ],
        ],
      ),
    );
  }
}

Future<void> _showRefDialog(
  final BuildContext context, {
  required final String title,
  required final Widget child,
}) {
  return showDialog<void>(
    context: context,
    builder: (final BuildContext context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: RepositoryMd3Layout.pickerWidth,
        height: RepositoryMd3Layout.pickerHeight,
        child: child,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
      ],
    ),
  );
}

Future<void> _showCloneSheet(
  final BuildContext context,
  final RepoCardData repo,
  final RepoInfo? details,
) {
  final String baseUrl = repo.url.toString();
  final String httpsUrl = baseUrl.endsWith('.git') ? baseUrl : '$baseUrl.git';
  final String sshUrl =
      details?.sshUrl ?? 'git@${repo.url.host}:${repo.nameWithOwner}.git';
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (final BuildContext context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          RepositoryMd3Layout.space24,
          0,
          RepositoryMd3Layout.space24,
          RepositoryMd3Layout.space24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              context.l10n.repoCloneRepository,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: RepositoryMd3Layout.space16),
            CloneUrlSheet(httpsUrl: httpsUrl, sshUrl: sshUrl),
          ],
        ),
      ),
    ),
  );
}

List<CodeTreeNode> _filteredEntries(
  final List<CodeTreeNode> entries,
  final CodeBrowserSettings settings,
  final String query,
) {
  final String normalizedQuery = query.trim().toLowerCase();
  return entries.where((final CodeTreeNode entry) {
    if (!settings.showDotfiles && entry.name.startsWith('.')) {
      return false;
    }
    if (!settings.showGeneratedFiles && entry.isGenerated) {
      return false;
    }
    return normalizedQuery.isEmpty ||
        entry.name.toLowerCase().contains(normalizedQuery);
  }).toList();
}

List<CodeTreeNode> _sortedEntries(
  final List<CodeTreeNode> entries,
  final CodeSortOrder order,
) {
  final List<CodeTreeNode> sorted = List<CodeTreeNode>.from(entries);
  switch (order) {
    case CodeSortOrder.type:
      sorted.sort((final CodeTreeNode a, final CodeTreeNode b) {
        final int byKind = _kindOrder(a.kind).compareTo(_kindOrder(b.kind));
        return byKind != 0
            ? byKind
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    case CodeSortOrder.nameAsc:
      sorted.sort(
        (final CodeTreeNode a, final CodeTreeNode b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    case CodeSortOrder.nameDesc:
      sorted.sort(
        (final CodeTreeNode a, final CodeTreeNode b) =>
            b.name.toLowerCase().compareTo(a.name.toLowerCase()),
      );
    case CodeSortOrder.size:
      sorted.sort((final CodeTreeNode a, final CodeTreeNode b) {
        final int bySize = b.size.compareTo(a.size);
        return bySize != 0 ? bySize : a.name.compareTo(b.name);
      });
    case CodeSortOrder.extension:
      sorted.sort((final CodeTreeNode a, final CodeTreeNode b) {
        final int byExtension = (a.extension ?? '').compareTo(
          b.extension ?? '',
        );
        return byExtension != 0 ? byExtension : a.name.compareTo(b.name);
      });
  }
  return sorted;
}

int _kindOrder(final CodeEntryKind kind) {
  return switch (kind) {
    CodeEntryKind.directory => 0,
    CodeEntryKind.file => 1,
    CodeEntryKind.symlink => 2,
    CodeEntryKind.submodule => 3,
  };
}

IconData _iconForEntry(final CodeEntryKind kind) {
  return switch (kind) {
    CodeEntryKind.directory => Icons.folder_outlined,
    CodeEntryKind.file => Icons.insert_drive_file_outlined,
    CodeEntryKind.symlink => Icons.link,
    CodeEntryKind.submodule => Icons.folder_copy_outlined,
  };
}

Color _iconColorForEntry(final BuildContext context, final CodeEntryKind kind) {
  final ColorScheme colors = Theme.of(context).colorScheme;
  return kind == CodeEntryKind.directory
      ? colors.primary
      : colors.onSurfaceVariant;
}

String _entryMetadata(
  final BuildContext context,
  final CodeTreeNode entry,
  final bool showMetadata,
) {
  if (!showMetadata) {
    return '';
  }
  if (entry.kind == CodeEntryKind.directory) {
    return '';
  }
  if (entry.kind == CodeEntryKind.submodule) {
    return context.l10n.repoSubmodule;
  }
  return _formatBytes(entry.byteSize ?? entry.size);
}

String _formatBytes(final int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}

String _abbreviate(final String value) {
  return value.length > 7 ? value.substring(0, 7) : value;
}
