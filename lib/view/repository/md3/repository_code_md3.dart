import 'package:diohub/app/settings/code_browser_settings.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_graphql/schema_typedefs.dart' show RepositoryPermission;
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code/code_browser_state.dart';
import 'package:diohub_models/models/repositories/code/code_tree_node.dart';
import 'package:diohub_models/models/repositories/code/directory_last_commit.dart';
import 'package:diohub/providers/code_browser/code_browser_state_provider.dart';
import 'package:diohub/providers/code_browser/directory_last_commit_provider.dart';
import 'package:diohub/providers/code_browser/directory_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/providers/settings/code_browser_settings_provider.dart';
import 'package:diohub/utils/permission_utils.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/view/repository/code/create_file_screen.dart';
import 'package:diohub/view/repository/code/file_viewer_screen.dart';
import 'package:diohub/view/repository/md3/repository_md3_layout.dart';
import 'package:diohub/view/repository/md3/tag_select_sheet.dart';
import 'package:diohub/view/repository/readme/repository_readme.dart';
import 'package:diohub/view/repository/widgets/branch_select_sheet.dart';
import 'package:diohub/view/repository/widgets/clone_url_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RepositoryCodeMd3 extends ConsumerWidget {
  const RepositoryCodeMd3({
    required this.repoRef,
    required this.repo,
    this.inlineAbout,
    super.key,
  });

  final RepoRef repoRef;
  final RepoInfo repo;
  final Widget? inlineAbout;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final BranchState branchState = ref.watch(branchProvider(repoRef));
    if (branchState is BranchStateLoading) {
      return const Center(child: CircularProgressIndicator());
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
    final AsyncValue<String?>? readme = navigation.currentPath.isEmpty
        ? ref.watch(readmeProvider(repoRef))
        : null;

    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final RepositoryWindowClass windowClass =
            RepositoryMd3Layout.windowClassFor(constraints.maxWidth);
        return RefreshIndicator(
          onRefresh: () => refreshRepositoryCode(ref, repoRef),
          child: CustomScrollView(
            key: PageStorageKey<String>(
              'repository-code-${repoRef.fullName}-${branch.refValue}',
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverPadding(
                padding: RepositoryMd3Layout.pagePaddingFor(windowClass),
                sliver: SliverToBoxAdapter(
                  child: _CodeToolbar(
                    repoRef: repoRef,
                    repo: repo,
                    branch: branch,
                    navigation: navigation,
                    inline:
                        constraints.maxWidth >=
                        RepositoryMd3Layout.inlineCodeToolbarBreakpoint,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      RepositoryMd3Layout.pagePaddingFor(
                        windowClass,
                      ).horizontal /
                      2,
                ),
                sliver: SliverToBoxAdapter(
                  child: _LatestCommitCard(
                    repoRef: repoRef,
                    branch: branch.refValue,
                    path: navigation.currentPath,
                  ),
                ),
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
              if (readme != null) ...<Widget>[
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: RepositoryMd3Layout.pagePaddingFor(windowClass).left,
                    right: RepositoryMd3Layout.pagePaddingFor(
                      windowClass,
                    ).right,
                    top: RepositoryMd3Layout.space24,
                    bottom: RepositoryMd3Layout.space12,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.menu_book_outlined),
                        const SizedBox(width: RepositoryMd3Layout.space8),
                        Text(
                          'README',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                RepositoryReadmeSliver(
                  readmeAsync: readme,
                  branch: branch.refValue,
                  repoFullName: repoRef.fullName,
                ),
              ],
              if (inlineAbout != null) ...<Widget>[
                const SliverToBoxAdapter(child: Divider()),
                SliverToBoxAdapter(child: inlineAbout),
              ],
              const SliverToBoxAdapter(
                child: SizedBox(height: RepositoryMd3Layout.space32),
              ),
            ],
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
    return directory.when(
      loading: () => const <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(RepositoryMd3Layout.space32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
      error: (final Object error, final StackTrace stack) => <Widget>[
        SliverToBoxAdapter(
          child: _CodeErrorState(
            error: error,
            onRetry: () => refreshRepositoryCode(ref, repoRef),
          ),
        ),
      ],
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
          return <Widget>[
            SliverToBoxAdapter(
              child: _CodeEmptyState(
                filtered: navigation.searchQuery.trim().isNotEmpty,
              ),
            ),
          ];
        }
        return <Widget>[
          if (windowClass != RepositoryWindowClass.compact)
            SliverPadding(
              padding: EdgeInsets.only(
                left: RepositoryMd3Layout.pagePaddingFor(windowClass).left,
                right: RepositoryMd3Layout.pagePaddingFor(windowClass).right,
                top: RepositoryMd3Layout.space16,
              ),
              sliver: const SliverToBoxAdapter(child: _DirectoryTableHeader()),
            ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: RepositoryMd3Layout.pagePaddingFor(windowClass).left,
            ),
            sliver: SliverList.separated(
              itemCount: visible.length,
              separatorBuilder: (final BuildContext context, final int index) =>
                  const Divider(),
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
            ),
          ),
        ];
      },
    );
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
          const SnackBar(
            content: Text('Opening submodules is not available in this phase.'),
          ),
        );
    }
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
    required this.branch,
    required this.navigation,
    required this.inline,
  });

  final RepoRef repoRef;
  final RepoInfo repo;
  final BranchStateResolved branch;
  final CodeBrowserState navigation;
  final bool inline;

  @override
  ConsumerState<_CodeToolbar> createState() => _CodeToolbarState();
}

class _CodeToolbarState extends ConsumerState<_CodeToolbar> {
  late final TextEditingController _searchController;

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
    );
    final Widget addFile = _AddFileButton(
      repoRef: widget.repoRef,
      repo: widget.repo,
      branch: widget.branch,
      parentPath: widget.navigation.currentPath,
    );
    final Widget clone = FilledButton.icon(
      onPressed: () => _showCloneSheet(context, widget.repo),
      icon: const Icon(Icons.code),
      label: const Text('Code'),
    );
    final Widget goToFile = Tooltip(
      message: 'Repository-wide file search is not available in this phase.',
      child: OutlinedButton.icon(
        onPressed: null,
        icon: Icon(Icons.manage_search),
        label: Text('Go to file'),
      ),
    );
    final Widget search = SearchBar(
      controller: _searchController,
      hintText: 'Filter current directory',
      leading: const Icon(Icons.search),
      trailing: widget.navigation.searchQuery.isNotEmpty
          ? <Widget>[
              IconButton(
                tooltip: 'Clear file filter',
                onPressed: () {
                  _searchController.clear();
                  ref
                      .read(codeBrowserStateProvider(widget.repoRef).notifier)
                      .setSearchQuery('');
                },
                icon: const Icon(Icons.close),
              ),
            ]
          : null,
      onChanged: (final String value) => ref
          .read(codeBrowserStateProvider(widget.repoRef).notifier)
          .setSearchQuery(value),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _RepositoryBreadcrumbs(
          repoRef: widget.repoRef,
          path: widget.navigation.currentPath,
        ),
        const SizedBox(height: RepositoryMd3Layout.space12),
        if (!widget.inline) ...<Widget>[
          Wrap(
            spacing: RepositoryMd3Layout.space8,
            runSpacing: RepositoryMd3Layout.space8,
            children: <Widget>[refSelector, goToFile, addFile, clone],
          ),
          const SizedBox(height: RepositoryMd3Layout.space12),
          search,
        ] else
          Row(
            children: <Widget>[
              refSelector,
              const SizedBox(width: RepositoryMd3Layout.space8),
              Expanded(child: search),
              const SizedBox(width: RepositoryMd3Layout.space8),
              goToFile,
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
              'Browsing commit ${_abbreviate(widget.branch.refValue)}. '
              'Editing is disabled.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: widget.repo.defaultBranchRef == null
                    ? null
                    : () => ref
                          .read(branchProvider(widget.repoRef).notifier)
                          .setBranchState(
                            BranchState.branch(
                              widget.repo.defaultBranchRef!.name,
                            ),
                          ),
                child: const Text('Default branch'),
              ),
            ],
          ),
        ],
        const SizedBox(height: RepositoryMd3Layout.space16),
      ],
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
  });

  final RepoRef repoRef;
  final RepoInfo repo;
  final BranchStateResolved branch;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return MenuAnchor(
      menuChildren: <Widget>[
        MenuItemButton(
          leadingIcon: const Icon(Icons.account_tree_outlined),
          onPressed: () => _showBranchPicker(context, ref),
          child: const Text('Switch branch…'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.sell_outlined),
          onPressed: () => _showTagPicker(context, ref),
          child: const Text('Switch tag…'),
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
              constraints: const BoxConstraints(
                maxWidth: RepositoryMd3Layout.refButtonLabelWidth,
              ),
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
      title: 'Switch branch',
      child: BranchSelectSheet(
        repoRef,
        defaultBranch: repo.defaultBranchRef?.name,
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
      title: 'Switch tag',
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
    required this.repo,
    required this.branch,
    required this.parentPath,
  });

  final RepoRef repoRef;
  final RepoInfo repo;
  final BranchStateResolved branch;
  final String parentPath;

  @override
  Widget build(final BuildContext context) {
    final bool canCreate =
        !branch.isCommit &&
        isAtLeast(repo.viewerPermission, RepositoryPermission.WRITE);
    return MenuAnchor(
      menuChildren: <Widget>[
        MenuItemButton(
          leadingIcon: const Icon(Icons.note_add_outlined),
          onPressed: canCreate ? () => _createFile(context) : null,
          child: const Text('Create new file'),
        ),
        const MenuItemButton(
          leadingIcon: Icon(Icons.upload_file_outlined),
          onPressed: null,
          child: Text('Upload files (not available)'),
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
            label: const Text('Add file'),
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
    return Card(
      child: latest.when(
        loading: () => const ListTile(
          leading: CircularProgressIndicator(),
          title: Text('Loading latest commit…'),
        ),
        error: (final Object error, final StackTrace stack) => ListTile(
          leading: const Icon(Icons.warning_amber_outlined),
          title: const Text('Latest commit unavailable'),
          subtitle: Text(
            '$error',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            tooltip: 'Retry latest commit',
            onPressed: () => ref.invalidate(directoryLastCommitProvider(key)),
            icon: const Icon(Icons.refresh),
          ),
        ),
        data: (final DirectoryLastCommit? commit) => ListTile(
          leading: const Icon(Icons.commit),
          title: Text(
            commit?.message ?? 'No commit information for this directory',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: commit == null
              ? null
              : Text(
                  '${commit.authorName ?? 'Unknown author'} · '
                  '${commit.abbreviatedOid}',
                ),
          trailing: commit == null
              ? null
              : Text(commit.committedDate.toRelativeDate()),
        ),
      ),
    );
  }
}

class _DirectoryTableHeader extends StatelessWidget {
  const _DirectoryTableHeader();

  @override
  Widget build(final BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: RepositoryMd3Layout.space12,
        vertical: RepositoryMd3Layout.space8,
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: RepositoryMd3Layout.fileIconWidth),
          Expanded(child: Text('Name', style: style)),
          SizedBox(
            width: RepositoryMd3Layout.fileMessageWidth,
            child: Text('Last commit', style: style),
          ),
          SizedBox(
            width: RepositoryMd3Layout.fileUpdatedWidth,
            child: Text('Updated', style: style),
          ),
        ],
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
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RepositoryMd3Layout.space8,
        ),
        leading: Icon(_iconForEntry(entry.kind)),
        title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          message ?? _entryMetadata(entry, showMetadata),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
    }
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RepositoryMd3Layout.space12,
          vertical: RepositoryMd3Layout.space12,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: RepositoryMd3Layout.fileIconWidth,
              child: Icon(_iconForEntry(entry.kind)),
            ),
            Expanded(
              child: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: RepositoryMd3Layout.fileMessageWidth,
              child: Text(
                message ?? _entryMetadata(entry, showMetadata),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: RepositoryMd3Layout.fileUpdatedWidth,
              child: Text(
                updated?.toRelativeDate() ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
            'Could not load repository files',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: RepositoryMd3Layout.space8),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: RepositoryMd3Layout.space16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
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
            filtered ? 'No matching files' : 'This directory is empty',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (filtered) ...<Widget>[
            const SizedBox(height: RepositoryMd3Layout.space8),
            const Text('Clear the file filter to show every entry.'),
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
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

Future<void> _showCloneSheet(final BuildContext context, final RepoInfo repo) {
  final String baseUrl = repo.url.toString();
  final String httpsUrl = baseUrl.endsWith('.git') ? baseUrl : '$baseUrl.git';
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
              'Clone repository',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: RepositoryMd3Layout.space16),
            CloneUrlSheet(httpsUrl: httpsUrl, sshUrl: repo.sshUrl),
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

String _entryMetadata(final CodeTreeNode entry, final bool showMetadata) {
  if (!showMetadata) {
    return '';
  }
  if (entry.kind == CodeEntryKind.directory) {
    return 'Directory';
  }
  if (entry.kind == CodeEntryKind.submodule) {
    return 'Submodule';
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
