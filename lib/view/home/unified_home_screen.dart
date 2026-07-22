import 'dart:async';

import 'package:diohub/models/repositories/public_repository.dart';
import 'package:diohub/providers/repository/public_repository_providers.dart';
import 'package:diohub/services/repositories/public_repository_service.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
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
    super.key,
  });

  final AccountModel? account;
  final bool accountLoading;
  final Widget? activityFeedSliver;
  final Future<void> Function()? onRefreshActivity;
  final Future<void> Function() onSignIn;
  final Future<void> Function() onSignOut;

  @override
  ConsumerState<UnifiedHomeScreen> createState() => _UnifiedHomeScreenState();
}

class _UnifiedHomeScreenState extends ConsumerState<UnifiedHomeScreen> {
  static const double _masterDetailBreakpoint = 900;

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
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _query = query;
      _selectedRepository = null;
    });
  }

  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= _masterDetailBreakpoint;
        final PublicRepositorySummary? selected = _selectedRepository;
        return Scaffold(
          appBar: AppBar(
            leading: !wide && selected != null
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedRepository = null;
                      });
                    },
                    tooltip: 'Back to search',
                    icon: const Icon(Icons.arrow_back),
                  )
                : null,
            title: Text(
              selected != null && !wide ? selected.fullName : 'DioHub',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: <Widget>[
              _HomeAccountAction(
                account: widget.account,
                loading: widget.accountLoading,
                onSignIn: widget.onSignIn,
                onSignOut: widget.onSignOut,
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: wide
              ? Row(
                  children: <Widget>[
                    SizedBox(
                      width: 420,
                      child: _HomeSearchPane(
                        controller: _searchController,
                        query: _query,
                        account: widget.account,
                        selectedRepositoryId: selected?.id,
                        onSearch: _search,
                        onSelect: (final PublicRepositorySummary repository) {
                          setState(() {
                            _selectedRepository = repository;
                          });
                        },
                        onSignIn: widget.onSignIn,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: selected == null
                          ? widget.account == null
                                ? const _HomeDetailPlaceholder()
                                : _HomeActivityPane(
                                    feedSliver: widget.activityFeedSliver,
                                    onRefresh: widget.onRefreshActivity,
                                  )
                          : PublicRepositoryBrowser(
                              key: ValueKey<int>(selected.id),
                              repository: selected,
                              onSignIn: widget.account == null
                                  ? widget.onSignIn
                                  : null,
                            ),
                    ),
                  ],
                )
              : selected == null
              ? _HomeSearchPane(
                  controller: _searchController,
                  query: _query,
                  account: widget.account,
                  activityFeedSliver: widget.activityFeedSliver,
                  onRefreshActivity: widget.onRefreshActivity,
                  showActivityWhenIdle: true,
                  onSearch: _search,
                  onSelect: (final PublicRepositorySummary repository) {
                    setState(() {
                      _selectedRepository = repository;
                    });
                  },
                  onSignIn: widget.onSignIn,
                )
              : PublicRepositoryBrowser(
                  key: ValueKey<int>(selected.id),
                  repository: selected,
                  onSignIn: widget.account == null ? widget.onSignIn : null,
                ),
        );
      },
    );
  }
}

class _HomeAccountAction extends StatelessWidget {
  const _HomeAccountAction({
    required this.loading,
    required this.onSignIn,
    required this.onSignOut,
    this.account,
  });

  final AccountModel? account;
  final bool loading;
  final Future<void> Function() onSignIn;
  final Future<void> Function() onSignOut;

  @override
  Widget build(final BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final AccountModel? activeAccount = account;
    if (activeAccount == null) {
      return FilledButton.tonalIcon(
        onPressed: () => unawaited(onSignIn()),
        icon: const Icon(Icons.login),
        label: const Text('Sign in'),
      );
    }

    return MenuAnchor(
      menuChildren: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Text(
            activeAccount.displayName ?? activeAccount.username,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        MenuItemButton(
          onPressed: () => unawaited(onSignIn()),
          leadingIcon: const Icon(Icons.person_add_alt_1_outlined),
          child: const Text('Add account'),
        ),
        MenuItemButton(
          onPressed: () => unawaited(onSignOut()),
          leadingIcon: const Icon(Icons.logout),
          child: const Text('Sign out'),
        ),
      ],
      builder:
          (
            final BuildContext context,
            final MenuController controller,
            final Widget? child,
          ) => OutlinedButton.icon(
            onPressed: () {
              controller.isOpen ? controller.close() : controller.open();
            },
            icon: CircleAvatar(
              radius: 11,
              child: Text(
                _accountInitial(activeAccount.username),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 112),
              child: Text(
                '@${activeAccount.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
    );
  }
}

class _HomeSearchPane extends ConsumerWidget {
  const _HomeSearchPane({
    required this.controller,
    required this.query,
    required this.onSearch,
    required this.onSelect,
    required this.onSignIn,
    this.activityFeedSliver,
    this.account,
    this.onRefreshActivity,
    this.selectedRepositoryId,
    this.showActivityWhenIdle = false,
  });

  final AccountModel? account;
  final Widget? activityFeedSliver;
  final TextEditingController controller;
  final String query;
  final int? selectedRepositoryId;
  final ValueChanged<String> onSearch;
  final ValueChanged<PublicRepositorySummary> onSelect;
  final Future<void> Function() onSignIn;
  final Future<void> Function()? onRefreshActivity;
  final bool showActivityWhenIdle;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: SearchBar(
            controller: controller,
            hintText: 'Search repositories',
            leading: const Icon(Icons.search),
            trailing: <Widget>[
              IconButton(
                onPressed: () => onSearch(controller.text),
                tooltip: 'Search GitHub',
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
            onSubmitted: onSearch,
          ),
        ),
        Expanded(
          child: query.isEmpty
              ? account != null && showActivityWhenIdle
                    ? _HomeActivityPane(
                        feedSliver: activityFeedSliver,
                        onRefresh: onRefreshActivity,
                      )
                    : _HomeWelcome(account: account, onSignIn: onSignIn)
              : ref
                    .watch(publicRepositorySearchProvider(query))
                    .when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (final Object error, final StackTrace stack) =>
                          _HomeErrorPanel(
                            message: publicGitHubErrorMessage(error),
                            onRetry: () => ref.invalidate(
                              publicRepositorySearchProvider(query),
                            ),
                            onSignIn: account == null ? onSignIn : null,
                          ),
                      data: (final List<PublicRepositorySummary> repositories) {
                        if (repositories.isEmpty) {
                          return const Center(
                            child: Text('No repositories found.'),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          itemCount: repositories.length,
                          separatorBuilder:
                              (final BuildContext context, final int index) =>
                                  const SizedBox(height: 8),
                          itemBuilder:
                              (final BuildContext context, final int index) {
                                final PublicRepositorySummary repository =
                                    repositories[index];
                                return Card(
                                  color: repository.id == selectedRepositoryId
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.secondaryContainer
                                      : null,
                                  child: ListTile(
                                    onTap: () => onSelect(repository),
                                    title: Text(repository.fullName),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        if (repository.description != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              repository.description!,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 4,
                                          children: <Widget>[
                                            _RepositoryMetric(
                                              icon: Icons.star_outline,
                                              label: _compactNumber(
                                                repository.stargazerCount,
                                              ),
                                            ),
                                            _RepositoryMetric(
                                              icon: Icons.call_split,
                                              label: _compactNumber(
                                                repository.forkCount,
                                              ),
                                            ),
                                            if (repository.language != null)
                                              _RepositoryMetric(
                                                icon: Icons.code,
                                                label: repository.language!,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _HomeActivityPane extends StatelessWidget {
  const _HomeActivityPane({this.feedSliver, this.onRefresh});

  final Widget? feedSliver;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(final BuildContext context) {
    final Widget scrollView = CustomScrollView(
      key: const ValueKey<String>('home-activity-feed'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Feed',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const Chip(
                  avatar: Icon(Icons.dynamic_feed_outlined, size: 18),
                  label: Text('Following & watched'),
                ),
                if (onRefresh != null)
                  IconButton(
                    onPressed: () => unawaited(onRefresh!()),
                    tooltip: 'Refresh activity',
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
          ),
        ),
        feedSliver ??
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Activity feed is not connected.')),
            ),
      ],
    );
    final Future<void> Function()? refresh = onRefresh;
    return refresh == null
        ? scrollView
        : RefreshIndicator(onRefresh: refresh, child: scrollView);
  }
}

class _HomeWelcome extends StatelessWidget {
  const _HomeWelcome({required this.onSignIn, this.account});

  final AccountModel? account;
  final Future<void> Function() onSignIn;

  @override
  Widget build(final BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.explore_outlined,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Explore GitHub',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Search repositories and browse their directories and text files from the same home page.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (account == null) ...<Widget>[
            Text(
              'Browsing without an account',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const _HomeCapability(
              icon: Icons.lock_outline,
              text:
                  'Private repositories and organization-only data stay hidden.',
            ),
            const _HomeCapability(
              icon: Icons.edit_off_outlined,
              text:
                  'Writes such as stars, comments, issues, and pull requests ask you to sign in.',
            ),
            const _HomeCapability(
              icon: Icons.speed_outlined,
              text: 'Unsigned GitHub requests have a lower API rate limit.',
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => unawaited(onSignIn()),
              icon: const Icon(Icons.login),
              label: const Text('Sign in for account features'),
            ),
          ] else ...<Widget>[
            Text('Signed in', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _HomeCapability(
              icon: Icons.verified_user_outlined,
              text:
                  '${account!.displayName ?? account!.username} (@${account!.username})',
            ),
            const _HomeCapability(
              icon: Icons.lock_open_outlined,
              text:
                  'Authenticated requests can access repositories allowed by this account.',
            ),
            const _HomeCapability(
              icon: Icons.dashboard_outlined,
              text:
                  'Recent activity from people and repositories you follow appears in the Feed.',
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeCapability extends StatelessWidget {
  const _HomeCapability({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(final BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(text),
      dense: true,
    );
  }
}

class _HomeDetailPlaceholder extends StatelessWidget {
  const _HomeDetailPlaceholder();

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a repository',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Its Code view will open here.'),
          ],
        ),
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No system browser is available.')),
      );
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
                  tooltip: 'Open repository on GitHub',
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
                message: publicGitHubErrorMessage(error),
                onRetry: () => ref.invalidate(
                  publicRepositoryContentsProvider(_contentsRequest),
                ),
                onSignIn: widget.onSignIn,
              ),
          data: (final List<PublicRepositoryEntry> entries) {
            if (entries.isEmpty) {
              return const Center(child: Text('This directory is empty.'));
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
                      subtitle: const Text('Parent directory'),
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
                tooltip: 'Back to directory',
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
                tooltip: 'Open file on GitHub',
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
                      message: publicGitHubErrorMessage(error),
                      onRetry: () =>
                          ref.invalidate(publicRepositoryFileProvider(request)),
                      onSignIn: widget.onSignIn,
                      secondaryAction: () => _openInBrowser(file.htmlUrl),
                      secondaryLabel: 'Open on GitHub',
                    ),
                data: (final String content) => Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectionArea(
                      child: Text(
                        content,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
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
            TextButton(onPressed: onRoot, child: const Text('Code')),
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
                  label: const Text('Retry'),
                ),
                if (secondaryAction != null && secondaryLabel != null)
                  OutlinedButton(
                    onPressed: secondaryAction,
                    child: Text(secondaryLabel!),
                  ),
                if (onSignIn != null)
                  TextButton(
                    onPressed: () => unawaited(onSignIn!()),
                    child: const Text('Sign in'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RepositoryMetric extends StatelessWidget {
  const _RepositoryMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

String _compactNumber(final int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}m';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
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

String _accountInitial(final String username) {
  final String normalized = username.trim();
  return normalized.isEmpty ? '?' : normalized.characters.first.toUpperCase();
}
