import 'package:auto_route/auto_route.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/nav_center/models/entity_action_defs.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/providers/code_browser/directory_last_commit_provider.dart';
import 'package:diohub/providers/code_browser/file_content_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/permission_utils.dart';
import 'package:diohub/view/repository/code/widgets/breadcrumb_bar.dart';
import 'package:diohub/view/repository/code/widgets/file_edit_sheet.dart';
import 'package:diohub/view/repository/code/widgets/file_metadata_bar.dart';
import 'package:diohub/view/repository/code/widgets/file_viewer_blame_tab.dart';
import 'package:diohub/view/repository/code/widgets/file_viewer_history_tab.dart';
import 'package:diohub/view/repository/code/widgets/file_viewer_view_tab.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_graphql/schema_typedefs.dart' show RepositoryPermission;
import 'package:diohub_models/models/download/download_item.dart';
import 'package:diohub_models/models/download/download_metadata.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code/code_tree_node.dart';
import 'package:diohub_models/models/repositories/code/directory_last_commit.dart';
import 'package:diohub_models/models/repositories/code/file_content.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:share_plus/share_plus.dart';

@RoutePage()
class FileViewerScreen extends ConsumerStatefulWidget {
  const FileViewerScreen({
    required this.repoRef,
    required this.branch,
    required this.filePath,
    this.sha,
    this.lineStart,
    this.lineEnd,
    this.siblingFiles,
    this.initialIndex = 0,
    super.key,
  });

  final RepoRef repoRef;
  final String branch;
  final String filePath;
  final String? sha;
  final int? lineStart;
  final int? lineEnd;
  final List<CodeTreeNode>? siblingFiles;
  final int initialIndex;

  @override
  ConsumerState<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends ConsumerState<FileViewerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late int _currentPageIndex;
  late String _currentFilePath;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentPageIndex = widget.initialIndex.clamp(
      0,
      (widget.siblingFiles?.length ?? 1) - 1,
    );
    _currentFilePath = _effectiveFilePathAt(_currentPageIndex);
    if (widget.siblingFiles != null && widget.siblingFiles!.length > 1) {
      _pageController = PageController(initialPage: _currentPageIndex);
    }
  }

  String _effectiveFilePathAt(int index) {
    final List<CodeTreeNode>? siblings = widget.siblingFiles;
    if (siblings == null ||
        siblings.isEmpty ||
        index < 0 ||
        index >= siblings.length) {
      return widget.filePath;
    }
    return siblings[index].path;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  bool _canEdit(WidgetRef r) {
    if (widget.branch.length == 40) return false;
    final permission = r.read(
      repositoryProvider(
        widget.repoRef,
      ).select((v) => v.value?.repository?.viewerPermission),
    );
    return isAtLeast(permission, RepositoryPermission.WRITE);
  }

  String? _expectedHeadOid(WidgetRef r) {
    final repo = r.read(repositoryProvider(widget.repoRef)).value?.repository;
    final String refName = widget.branch.startsWith('refs/')
        ? widget.branch
        : 'refs/heads/${widget.branch}';
    final initialRef = repo?.initialRef;
    if (initialRef?.name != refName) return null;
    return initialRef?.target?.maybeWhen(
      commit: (c) => c.oid,
      orElse: () => null,
    );
  }

  String? _languageFromPath(String path) {
    final String ext = path.contains('.')
        ? path.split('.').last.toLowerCase()
        : '';
    return ext.isEmpty ? 'plaintext' : ext;
  }

  Uri _fileWebUrl(ServerConfig server) => server.webUrl(
    '/${widget.repoRef.owner}/${widget.repoRef.name}/blob/${widget.branch}/${_currentFilePath}',
  );

  String _fileDownloadUrl(ServerConfig server) => server
      .rawUrl(
        widget.repoRef.owner,
        widget.repoRef.name,
        widget.branch,
        _currentFilePath,
      )
      .toString();

  DownloadItem _buildFileDownloadItem(ServerConfig server) => DownloadItem(
    id: '${widget.repoRef.owner}-${widget.repoRef.name}-${widget.branch}-$_currentFilePath',
    displayName: _currentFilePath.split('/').last,
    fileName: _currentFilePath.split('/').last,
    downloadUrl: _fileDownloadUrl(server),
    totalBytes: null,
    type: DownloadType.singleFile,
    contentType: null,
    createdAt: DateTime.now(),
    metadata: DownloadMetadata.singleFile(
      repoRef: widget.repoRef,
      branch: widget.branch,
      fullPath: _currentFilePath,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(activeServerConfigProvider);
    final Uri fileUrl = _fileWebUrl(server);
    final ClipboardService clipboard = ref.read(clipboardServiceProvider);
    final List<ActionButtonData> appBarUtilityActions = utilityActions(
      url: fileUrl.toString(),
      copyUrl: () async => clipboard.copy(fileUrl.toString()),
      share: () => Share.share(fileUrl.toString()),
    );
    final bool hasSiblings =
        widget.siblingFiles != null && widget.siblingFiles!.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_currentFilePath.split('/').last),
            Text(
              '${widget.repoRef.owner}/${widget.repoRef.name}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Tab>[
            Tab(text: 'View', icon: Icon(Octicons.file_code)),
            Tab(text: 'Blame', icon: Icon(Octicons.history)),
            Tab(text: 'History', icon: Icon(Octicons.git_commit)),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Octicons.issue_opened),
            tooltip: 'Report issue',
            onPressed: () {
              final String lineInfo = widget.lineStart != null
                  ? ' (line${widget.lineEnd != null && widget.lineEnd != widget.lineStart ? 's ${widget.lineStart}-${widget.lineEnd}' : ' ${widget.lineStart}'})'
                  : '';
              final String body =
                  '**File:** `$_currentFilePath`\n'
                  '**Ref:** `${widget.branch}`$lineInfo\n\n'
                  '_Reported from [$_currentFilePath](${_fileWebUrl(server)})_';
              context.router.push(
                NewIssueRoute(
                  repoRef: widget.repoRef,
                  initialTitle: '',
                  initialBody: body,
                ),
              );
            },
          ),
          ...appBarUtilityActions.map((ActionButtonData a) {
            final m = a as MinorActionButton;
            return IconButton(
              icon: Icon(m.icon),
              onPressed: m.onTap != null ? () => m.onTap!() : null,
              tooltip: m.label,
            );
          }),
        ],
      ),
      body: hasSiblings ? _buildPageView() : _buildSingleFileBody(),
      floatingActionButton: _canEdit(ref)
          ? FloatingActionButton(
              onPressed: () async {
                final String? expectedOid = _expectedHeadOid(ref);
                if (expectedOid == null) {
                  if (!context.mounted) return;
                  ref
                      .read(notificationServiceProvider)
                      .error(
                        'Open this branch from the repository to edit files',
                      );
                  return;
                }
                final FileContentKey key = (
                  repo: widget.repoRef,
                  branch: widget.branch,
                  path: _currentFilePath,
                );
                try {
                  final content = await ref.read(
                    fileContentProvider(key).future,
                  );
                  if (!context.mounted) return;
                  if (content.isBinary) {
                    ref
                        .read(notificationServiceProvider)
                        .error('Binary files cannot be edited');
                    return;
                  }
                  FileEditSheet.show(
                    context,
                    ref,
                    repoRef: widget.repoRef,
                    branchRef: widget.branch,
                    filePath: _currentFilePath,
                    initialText: content.text ?? '',
                    expectedHeadOid: expectedOid,
                    language: _languageFromPath(_currentFilePath),
                  );
                } catch (e, st) {
                  AppLogger.warning(
                    'Failed to open file edit sheet',
                    error: e,
                    stackTrace: st,
                    tag: 'FileViewerScreen',
                  );
                  if (!context.mounted) return;
                  ref
                      .read(notificationServiceProvider)
                      .error('Failed to load file');
                }
              },
              child: const Icon(Icons.edit_rounded),
            )
          : null,
    );
  }

  Widget _buildPageView() {
    final List<CodeTreeNode> siblings = widget.siblingFiles!;
    return PageView.builder(
      controller: _pageController!,
      itemCount: siblings.length,
      onPageChanged: (int index) {
        setState(() {
          _currentPageIndex = index;
          _currentFilePath = _effectiveFilePathAt(index);
          _tabController.animateTo(0);
        });
      },
      itemBuilder: (BuildContext context, int index) {
        final String path = siblings[index].path;
        return _buildTabBarView(path);
      },
    );
  }

  Widget _buildSingleFileBody() {
    return _buildTabBarView(widget.filePath);
  }

  Widget _buildTabBarView(String filePath) {
    final String repoName = ref.watch(
      repositoryProvider(
        widget.repoRef,
      ).select((v) => v.value?.repository?.name ?? ''),
    );
    final String parentPath = filePath.contains('/')
        ? filePath
              .split('/')
              .sublist(0, filePath.split('/').length - 1)
              .join('/')
        : '';

    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverToBoxAdapter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                BreadcrumbBar(
                  repoName: repoName,
                  currentPath: parentPath,
                  onSegmentTap: (_) {},
                  onRootTap: () {},
                ),
                _FileMetadataBarForPath(
                  repoRef: widget.repoRef,
                  branch: widget.branch,
                  path: filePath,
                ),
              ],
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          FileViewerViewTab(
            repoRef: widget.repoRef,
            branch: widget.branch,
            filePath: filePath,
            lineStart: widget.lineStart,
            lineEnd: widget.lineEnd,
          ),
          FileViewerBlameTab(
            repoRef: widget.repoRef,
            branch: widget.branch,
            filePath: filePath,
            lineStart: widget.lineStart,
            lineEnd: widget.lineEnd,
          ),
          FileViewerHistoryTab(
            repoRef: widget.repoRef,
            branch: widget.branch,
            filePath: filePath,
          ),
        ],
      ),
    );
  }
}

class _FileMetadataBarForPath extends ConsumerWidget {
  const _FileMetadataBarForPath({
    required this.repoRef,
    required this.branch,
    required this.path,
  });

  final RepoRef repoRef;
  final String branch;
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FileContentKey contentKey = (
      repo: repoRef,
      branch: branch,
      path: path,
    );
    final AsyncValue<FileContent> contentAsync = ref.watch(
      fileContentProvider(contentKey),
    );
    final LastCommitKey commitKey = (repo: repoRef, branch: branch, path: path);
    final AsyncValue<DirectoryLastCommit?> lastCommitAsync = ref.watch(
      directoryLastCommitProvider(commitKey),
    );

    return contentAsync.maybeWhen(
      data: (content) {
        final DirectoryLastCommit? lastCommit = lastCommitAsync.hasValue
            ? lastCommitAsync.value
            : null;
        final int? lineCount = content.text != null
            ? content.text!.split('\n').length
            : null;
        return FileMetadataBar(
          languageName: null,
          lineCount: lineCount,
          byteSize: content.byteSize,
          lastCommit: lastCommit,
        );
      },
      loading: () => const FileMetadataBar(),
      error: (_, __) => const FileMetadataBar(),
      orElse: () => const FileMetadataBar(),
    );
  }
}
