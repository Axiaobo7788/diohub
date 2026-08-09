import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/models/github_changelog_item.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/models/repository_preview.dart';
import 'package:diohub/models/repositories/public_repository.dart';
import 'package:diohub/providers/code_browser/directory_resource.dart';
import 'package:diohub/providers/dashboard/github_changelog_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/providers/repository/repository_preview_provider.dart';
import 'package:diohub/providers/repository/public_repository_providers.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/services/dashboard/github_changelog_service.dart';
import 'package:diohub/services/repositories/public_repository_service.dart';
import 'package:diohub/style/app_typography.dart';
import 'package:diohub/view/app_chrome/app_chrome.dart';
import 'package:diohub/view/app_chrome/global_header.dart';
import 'package:diohub/view/app_chrome/global_navigation_drawer.dart';
import 'package:diohub/view/home/github_dashboard_home.dart';
import 'package:diohub/view/home/home_layout.dart';
import 'package:diohub/view/home/widgets/switch_account_sheet.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class UnifiedHomeScreen extends ConsumerStatefulWidget {
  const UnifiedHomeScreen({
    required this.onSignIn,
    required this.onSignOut,
    this.activityFeedSliver,
    this.account,
    this.accountLoading = false,
    this.onRefreshActivity,
    this.onLoadMoreActivity,
    this.topRepositories,
    this.onRefreshTopRepositories,
    this.changelog,
    this.onRefreshChangelog,
    this.statusEmoji,
    this.statusMessage,
    super.key,
  });

  final AccountModel? account;
  final bool accountLoading;
  final Widget? activityFeedSliver;
  final Future<void> Function()? onRefreshActivity;
  final Future<bool> Function()? onLoadMoreActivity;
  final AsyncValue<List<HomeRepositoryItem>>? topRepositories;
  final VoidCallback? onRefreshTopRepositories;
  final AsyncValue<List<GitHubChangelogItem>>? changelog;
  final VoidCallback? onRefreshChangelog;
  final String? statusEmoji;
  final String? statusMessage;
  final Future<void> Function() onSignIn;
  final Future<void> Function() onSignOut;

  @override
  ConsumerState<UnifiedHomeScreen> createState() => _UnifiedHomeScreenState();
}

class _UnifiedHomeScreenState extends ConsumerState<UnifiedHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  PublicRepositorySummary? _selectedRepository;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(final String value) {
    final String query = value.trim();
    if (query.isEmpty) {
      return;
    }
    if (_searchController.text != query) {
      _searchController.text = query;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _query = query;
      _selectedRepository = null;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
    });
  }

  Future<void> _showCompactSearch(final BuildContext context) async {
    final l10n = context.l10n;
    final TextEditingController dialogController = TextEditingController(
      text: _query,
    );
    final String? query = await showDialog<String>(
      context: context,
      builder: (final BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.homeSearchRepositories),
        content: TextField(
          controller: dialogController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.homeSearchRepositoriesHint,
            prefixIcon: const Icon(Icons.search),
          ),
          onSubmitted: (final String value) =>
              Navigator.of(dialogContext).pop(value),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(dialogController.text),
            child: Text(l10n.commonSearch),
          ),
        ],
      ),
    );
    dialogController.dispose();
    if (query != null && mounted) {
      _search(query);
    }
  }

  void _openSearchResult(final PublicRepositorySummary repository) {
    setState(() {
      _selectedRepository = repository;
    });
  }

  void _openTopRepository(final HomeRepositoryItem repository) {
    final RepoRef repoRef = RepoRef(
      owner: repository.owner,
      name: repository.name,
      nodeId: repository.nodeId,
    );
    ref
        .read(repositoryPreviewProvider(repoRef).notifier)
        .seed(
          RepositoryPreview(
            fullName: repository.fullName,
            name: repository.name,
            owner: repository.owner,
            ownerAvatarUrl: repository.ownerAvatarUrl,
            isPrivate: repository.isPrivate,
            nodeId: repository.nodeId,
            defaultBranch: repository.defaultBranch,
          ),
        );
    final String? defaultBranch = repository.defaultBranch;
    if (defaultBranch != null && defaultBranch.isNotEmpty) {
      prefetchRepositoryRootDirectory(
        ref,
        repo: repoRef,
        branch: defaultBranch,
      );
    }
    // Start the repository request before the adaptive route transition. The
    // destination watches the same family key, so the transition animation and
    // network request can overlap instead of running strictly in sequence.
    ref.read(repositoryProvider(repoRef));
    unawaited(repoRef.navigate(context, ref));
  }

  Future<void> _createRepository() async {
    final AccountModel? account = widget.account;
    if (account == null) {
      await widget.onSignIn();
      return;
    }
    await launchUrl(
      account.serverConfig.webUrl('/new'),
      mode: LaunchMode.externalApplication,
    );
  }

  void _openProfileTab(final String? tab) {
    if (tab == 'settings' || (tab?.startsWith('settings/') ?? false)) {
      final String? section = tab == 'settings'
          ? null
          : tab!.substring('settings/'.length);
      unawaited(
        context.router.push<void>(SettingsRoute(initialSection: section)),
      );
      return;
    }
    final AccountModel? account = widget.account;
    if (account == null) {
      unawaited(widget.onSignIn());
      return;
    }
    unawaited(
      UserRef(login: account.username, tab: tab).navigate(context, ref),
    );
  }

  void _switchAccount() => SwitchAccountSheet.show(context, ref);

  Future<void> _openExternalUri(final Uri uri) async {
    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.homeCouldNotOpenLink)),
      );
    }
  }

  void _openChangelogItem(final GitHubChangelogItem item) {
    unawaited(_openExternalUri(item.link));
  }

  void _openChangelog() {
    unawaited(
      _openExternalUri(Uri.parse(GitHubChangelogService.changelogPageUrl)),
    );
  }

  void _showStagedAction(final String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.homeFeatureNotAvailable(label))),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final bool desktop =
            constraints.maxWidth >= HomeLayout.desktopBreakpoint;
        final bool showAside =
            constraints.maxWidth >= HomeLayout.asideBreakpoint;
        final PublicRepositorySummary? selected = _selectedRepository;
        final AsyncValue<List<HomeRepositoryItem>> topRepositories =
            widget.topRepositories ??
            const AsyncData<List<HomeRepositoryItem>>(<HomeRepositoryItem>[]);
        final AsyncValue<List<GitHubChangelogItem>> changelog =
            widget.changelog ??
            (showAside
                ? ref.watch(githubChangelogProvider)
                : const AsyncData<List<GitHubChangelogItem>>(
                    <GitHubChangelogItem>[],
                  ));
        return AppChrome(
          account: widget.account,
          accountLoading: widget.accountLoading,
          topRepositories: topRepositories,
          selectedNavigation: GlobalNavigationDestination.home,
          statusEmoji: widget.statusEmoji,
          statusMessage: widget.statusMessage,
          onSignIn: widget.onSignIn,
          onSignOut: widget.onSignOut,
          onOpenProfileTab: _openProfileTab,
          onSwitchAccount: _switchAccount,
          onStagedAction: _showStagedAction,
          onOpenTopRepository: _openTopRepository,
          onGlobalSearch: (final String? query) {
            if (query == null || query.trim().isEmpty) {
              unawaited(_showCompactSearch(context));
              return;
            }
            _search(query);
          },
          onSearchRepositories: () => _showCompactSearch(context),
          title: GlobalHeaderTitle(
            owner: selected?.owner,
            title: selected?.name ?? context.l10n.homeDashboard,
            compact: !desktop,
          ),
          pageActions: selected == null
              ? const <Widget>[]
              : <Widget>[
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedRepository = null;
                      });
                    },
                    tooltip: context.l10n.homeBackToSearch,
                    icon: const Icon(Icons.arrow_back),
                  ),
                ],
          body: selected != null
              ? PublicRepositoryBrowser(
                  key: ValueKey<int>(selected.id),
                  repository: selected,
                  onSignIn: widget.account == null ? widget.onSignIn : null,
                )
              : GitHubDashboardHome(
                  account: widget.account,
                  activityFeedSliver: widget.activityFeedSliver,
                  topRepositories: topRepositories,
                  changelog: changelog,
                  query: _query,
                  desktop: desktop,
                  showAside: showAside,
                  onClearSearch: _clearSearch,
                  onSelectSearchResult: _openSearchResult,
                  onOpenTopRepository: _openTopRepository,
                  onCreateRepository: _createRepository,
                  onRefreshTopRepositories: widget.onRefreshTopRepositories,
                  onRefreshChangelog:
                      widget.onRefreshChangelog ??
                      () => ref.invalidate(githubChangelogProvider),
                  onOpenChangelogItem: _openChangelogItem,
                  onOpenChangelog: _openChangelog,
                  onRefreshActivity: widget.onRefreshActivity,
                  onLoadMoreActivity: widget.onLoadMoreActivity,
                  onSignIn: widget.onSignIn,
                  onSwitchAccount: _switchAccount,
                  onStagedAction: _showStagedAction,
                ),
        );
      },
    );
  }
}

class PublicRepositoryBrowser extends ConsumerStatefulWidget {
  const PublicRepositoryBrowser({
    required this.repository,
    this.onSignIn,
    super.key,
  });

  final PublicRepositorySummary repository;
  final Future<void> Function()? onSignIn;

  @override
  ConsumerState<PublicRepositoryBrowser> createState() =>
      _PublicRepositoryBrowserState();
}

class _PublicRepositoryBrowserState
    extends ConsumerState<PublicRepositoryBrowser> {
  String _path = '';
  PublicRepositoryEntry? _selectedFile;

  PublicRepositoryContentsRequest get _contentsRequest => (
    fullName: widget.repository.fullName,
    path: _path,
    ref: widget.repository.defaultBranch,
  );

  void _openDirectory(final String path) {
    setState(() {
      _path = path;
      _selectedFile = null;
    });
  }

  void _openParent() {
    final List<String> segments = _path
        .split('/')
        .where((final String segment) => segment.isNotEmpty)
        .toList();
    if (segments.isNotEmpty) {
      segments.removeLast();
    }
    _openDirectory(segments.join('/'));
  }

  Future<void> _openInBrowser(final Uri uri) async {
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.homeNoSystemBrowser)));
    }
  }

  @override
  Widget build(final BuildContext context) {
    final PublicRepositoryEntry? selectedFile = _selectedFile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Row(
              children: <Widget>[
                const Icon(Icons.book_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.repository.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.repository.description != null)
                        Text(
                          widget.repository.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.account_tree_outlined, size: 16),
                  label: Text(widget.repository.defaultBranch),
                ),
                IconButton(
                  onPressed: () => _openInBrowser(widget.repository.htmlUrl),
                  tooltip: context.l10n.homeOpenRepositoryOnGitHub,
                  icon: const Icon(Icons.open_in_new),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        _RepositoryBreadcrumb(
          path: _path,
          fileName: selectedFile?.name,
          onRoot: () => _openDirectory(''),
          onDirectory: _openDirectory,
        ),
        const Divider(height: 1),
        Expanded(
          child: selectedFile == null
              ? _buildDirectory(context)
              : _buildFile(context, selectedFile),
        ),
      ],
    );
  }

  Widget _buildDirectory(final BuildContext context) {
    return ref
        .watch(publicRepositoryContentsProvider(_contentsRequest))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (final Object error, final StackTrace stack) =>
              _HomeErrorPanel(
                message: publicGitHubErrorMessage(
                  error,
                  rateLimitMessage: context.l10n.publicGitHubRateLimitReached,
                ),
                onRetry: () => ref.invalidate(
                  publicRepositoryContentsProvider(_contentsRequest),
                ),
                onSignIn: widget.onSignIn,
              ),
          data: (final List<PublicRepositoryEntry> entries) {
            if (entries.isEmpty) {
              return Center(child: Text(context.l10n.homeDirectoryEmpty));
            }
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                  publicRepositoryContentsProvider(_contentsRequest),
                );
                await ref.read(
                  publicRepositoryContentsProvider(_contentsRequest).future,
                );
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: entries.length + (_path.isEmpty ? 0 : 1),
                separatorBuilder:
                    (final BuildContext context, final int index) =>
                        const Divider(height: 1),
                itemBuilder: (final BuildContext context, final int index) {
                  if (_path.isNotEmpty && index == 0) {
                    return ListTile(
                      leading: const Icon(Icons.drive_folder_upload_outlined),
                      title: const Text('..'),
                      subtitle: Text(context.l10n.homeParentDirectory),
                      onTap: _openParent,
                    );
                  }
                  final int entryIndex = index - (_path.isEmpty ? 0 : 1);
                  final PublicRepositoryEntry entry = entries[entryIndex];
                  return ListTile(
                    leading: Icon(
                      entry.isDirectory
                          ? Icons.folder_outlined
                          : Icons.insert_drive_file_outlined,
                    ),
                    title: Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: entry.isDirectory
                        ? null
                        : Text(_formatBytes(entry.size)),
                    trailing: Icon(
                      entry.isDirectory
                          ? Icons.chevron_right
                          : Icons.description_outlined,
                    ),
                    onTap: entry.isDirectory
                        ? () => _openDirectory(entry.path)
                        : entry.isFile
                        ? () {
                            setState(() {
                              _selectedFile = entry;
                            });
                          }
                        : () => _openInBrowser(entry.htmlUrl),
                  );
                },
              ),
            );
          },
        );
  }

  Widget _buildFile(
    final BuildContext context,
    final PublicRepositoryEntry file,
  ) {
    final PublicRepositoryFileRequest request = (
      fullName: widget.repository.fullName,
      path: file.path,
      ref: widget.repository.defaultBranch,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: <Widget>[
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedFile = null;
                  });
                },
                tooltip: context.l10n.homeBackToDirectory,
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  file.path,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => _openInBrowser(file.htmlUrl),
                tooltip: context.l10n.homeOpenFileOnGitHub,
                icon: const Icon(Icons.open_in_new),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ref
              .watch(publicRepositoryFileProvider(request))
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (final Object error, final StackTrace stack) =>
                    _HomeErrorPanel(
                      message: publicGitHubErrorMessage(
                        error,
                        rateLimitMessage:
                            context.l10n.publicGitHubRateLimitReached,
                      ),
                      onRetry: () =>
                          ref.invalidate(publicRepositoryFileProvider(request)),
                      onSignIn: widget.onSignIn,
                      secondaryAction: () => _openInBrowser(file.htmlUrl),
                      secondaryLabel: context.l10n.homeOpenOnGitHub,
                    ),
                data: (final String content) => Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectionArea(
                      child: Text(content, style: context.appTypography.mono),
                    ),
                  ),
                ),
              ),
        ),
      ],
    );
  }
}

class _RepositoryBreadcrumb extends StatelessWidget {
  const _RepositoryBreadcrumb({
    required this.path,
    required this.onRoot,
    required this.onDirectory,
    this.fileName,
  });

  final String path;
  final String? fileName;
  final VoidCallback onRoot;
  final ValueChanged<String> onDirectory;

  @override
  Widget build(final BuildContext context) {
    final List<String> segments = path
        .split('/')
        .where((final String segment) => segment.isNotEmpty)
        .toList();
    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: <Widget>[
            TextButton(onPressed: onRoot, child: Text(context.l10n.commonCode)),
            for (int index = 0; index < segments.length; index++) ...<Widget>[
              const Icon(Icons.chevron_right, size: 18),
              TextButton(
                onPressed: () =>
                    onDirectory(segments.take(index + 1).join('/')),
                child: Text(segments[index]),
              ),
            ],
            if (fileName != null) ...<Widget>[
              const Icon(Icons.chevron_right, size: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(fileName!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeErrorPanel extends StatelessWidget {
  const _HomeErrorPanel({
    required this.message,
    required this.onRetry,
    required this.onSignIn,
    this.secondaryAction,
    this.secondaryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<void> Function()? onSignIn;
  final VoidCallback? secondaryAction;
  final String? secondaryLabel;

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.commonRetry),
                ),
                if (secondaryAction != null && secondaryLabel != null)
                  OutlinedButton(
                    onPressed: secondaryAction,
                    child: Text(secondaryLabel!),
                  ),
                if (onSignIn != null)
                  TextButton(
                    onPressed: () => unawaited(onSignIn!()),
                    child: Text(context.l10n.commonSignIn),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
