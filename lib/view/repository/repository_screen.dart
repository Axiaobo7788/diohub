import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/scoped_image_theme.dart';
import 'package:diohub/common/misc/scaffold_body.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/shell/nav_center_shell_widgets.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot.dart';
import 'package:diohub/providers/entity_store_notifier.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/providers/settings/repository_provider.dart'
    as repo_settings;
import 'package:diohub/view/repository/readme/repository_readme.dart';
import 'package:diohub/view/repository/md3/repository_md3_screen.dart';
import 'package:diohub/view/repository/md3/repository_md3_layout.dart';
import 'package:diohub/view/repository/md3/repository_md3_theme.dart';
import 'package:diohub/view/repository/widgets/repo_screen_config.dart';
import 'package:diohub/models/repositories/repository_initial_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class RepositoryScreen extends ConsumerStatefulWidget {
  const RepositoryScreen({required this.repo, super.key});
  final RepoRef repo;

  String get owner => repo.owner;
  String get name => repo.name;

  @override
  RepositoryScreenState createState() => RepositoryScreenState();
}

class RepositoryScreenState extends ConsumerState<RepositoryScreen> {
  bool _useLegacyLayout = false;

  @override
  void initState() {
    super.initState();
    final initialRef = RepositoryInitialRef.fromRepo(widget.repo);
    applyInitialRef(ref, widget.repo, initialRef);
  }

  @override
  Widget build(final BuildContext context) {
    final repoAsync = ref.watch(repositoryProvider(widget.repo));

    return repoAsync.when(
      loading: () => _RepositoryMd3StatusView(
        repositoryLabel: '${widget.owner}/${widget.name}',
        child: const CenteredSpinner(),
      ),
      error: (final Object error, final StackTrace stack) =>
          _RepositoryMd3StatusView(
            repositoryLabel: '${widget.owner}/${widget.name}',
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(RepositoryMd3Layout.space24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline,
                      size: RepositoryMd3Layout.statusIconSize,
                    ),
                    const SizedBox(height: RepositoryMd3Layout.space16),
                    Text(
                      'Error loading repository: $error',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: RepositoryMd3Layout.space16),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.invalidate(repositoryProvider(widget.repo)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      data: (final RepoInfoData data) {
        final repo = data.repository!;
        RepositoryInitialState initialState = resolveRepoLocation(
          widget.repo.location,
        );
        if (initialState.tabKind == null) {
          initialState = RepositoryInitialState(
            tabKind: RepositoryInitialState.tabKindFromRepositoryDefaultTab(
              ref.read(repo_settings.repositoryProvider).defaultTab,
            ),
            branch: initialState.branch,
            codePath: initialState.codePath,
          );
        }
        if (!_useLegacyLayout) {
          return RepositoryMd3Screen(
            repoRef: widget.repo,
            repo: repo,
            initialState: initialState,
            onOpenLegacy: () => setState(() => _useLegacyLayout = true),
          );
        }
        final ownerAvatarUrl = repo.owner.maybeWhen(
          user: (final user) => user.avatarUrl.toString(),
          organization: (final organization) =>
              organization.avatarUrl.toString(),
          orElse: () => null,
        );
        return Scaffold(
          body: ScaffoldBody(
            child: ScopedImageTheme(
              imageUrl: ownerAvatarUrl,
              child: _RepositoryTabsContent(
                repoRef: widget.repo,
                hasReadme: repo.readmeFile != null,
                hasLicense: repo.licenseInfo != null,
                owner: widget.owner,
                name: widget.name,
                initialState: initialState,
                onReturnToMd3: () => setState(() => _useLegacyLayout = false),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RepositoryMd3StatusView extends StatelessWidget {
  const _RepositoryMd3StatusView({
    required this.repositoryLabel,
    required this.child,
  });

  final String repositoryLabel;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    return Theme(
      data: repositoryMd3ThemeFor(Theme.of(context)),
      child: Scaffold(
        appBar: AppBar(title: Text(repositoryLabel)),
        body: child,
      ),
    );
  }
}

/// Inner widget that creates tabs after repo data is available.
class _RepositoryTabsContent extends ConsumerStatefulWidget {
  const _RepositoryTabsContent({
    required this.repoRef,
    required this.hasReadme,
    required this.hasLicense,
    required this.owner,
    required this.name,
    required this.initialState,
    required this.onReturnToMd3,
  });

  final RepoRef repoRef;
  final bool hasReadme;
  final bool hasLicense;
  final String owner;
  final String name;
  final RepositoryInitialState initialState;
  final VoidCallback onReturnToMd3;

  @override
  _RepositoryTabsContentState createState() => _RepositoryTabsContentState();
}

class _RepositoryTabsContentState
    extends ConsumerState<_RepositoryTabsContent> {
  final GlobalKey<RepositoryReadmeState> _readmeStateKey =
      GlobalKey<RepositoryReadmeState>();

  static String? _deeplinkPathFromTabKind(RepositoryTabKind? kind) {
    if (kind == null) return null;
    return switch (kind) {
      RepositoryTabKind.readme => 'readme',
      RepositoryTabKind.code => 'code',
      RepositoryTabKind.issues => 'issues',
      RepositoryTabKind.pulls => 'pulls',
      RepositoryTabKind.commits => 'commits',
      RepositoryTabKind.license => 'license',
      RepositoryTabKind.releases => 'releases',
      RepositoryTabKind.discussions => 'discussions',
      RepositoryTabKind.projects => 'projects',
      RepositoryTabKind.wiki => 'wiki',
    };
  }

  @override
  Widget build(final BuildContext context) {
    final repo = ref
        .watch(repositoryProvider(widget.repoRef))
        .requireValue
        .repository!;
    final ownerAvatarUrl = repo.owner.maybeWhen(
      user: (u) => u.avatarUrl.toString(),
      organization: (o) => o.avatarUrl.toString(),
      orElse: () => null,
    );
    return Stack(
      children: <Widget>[
        ScopedImageTheme(
          imageUrl: ownerAvatarUrl,
          child: _RepositoryShellContent(
            repo: repo,
            repoRef: widget.repoRef,
            initialState: widget.initialState,
            readmeStateKey: _readmeStateKey,
            onRefresh: () => ref.invalidate(repositoryProvider(widget.repoRef)),
            deeplinkPathFromTabKind: _deeplinkPathFromTabKind,
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: SafeArea(
            child: FilledButton.tonalIcon(
              onPressed: widget.onReturnToMd3,
              icon: const Icon(Icons.view_quilt_outlined),
              label: const Text('New layout'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Builds config in didChangeDependencies / didUpdateWidget so we don't
/// allocate the full config tree on every build.
class _RepositoryShellContent extends ConsumerStatefulWidget {
  const _RepositoryShellContent({
    required this.repo,
    required this.repoRef,
    required this.initialState,
    required this.readmeStateKey,
    required this.onRefresh,
    required this.deeplinkPathFromTabKind,
  });

  final RepoInfo repo;
  final RepoRef repoRef;
  final RepositoryInitialState initialState;
  final GlobalKey<RepositoryReadmeState> readmeStateKey;
  final VoidCallback onRefresh;
  final String? Function(RepositoryTabKind? kind) deeplinkPathFromTabKind;

  @override
  ConsumerState<_RepositoryShellContent> createState() =>
      _RepositoryShellContentState();
}

class _RepositoryShellContentState
    extends ConsumerState<_RepositoryShellContent> {
  ScreenConfig? _config;
  bool _visitRecorded = false;

  void _buildConfig() {
    if (!_visitRecorded) {
      _visitRecorded = true;
      ref
          .read(entityStoreMutatorProvider)
          .recordVisit(
            widget.repoRef,
            snapshot: EntitySnapshot(title: widget.repo.name),
          );
    }
    _config = widget.repo.toScreenConfig(
      context,
      ref,
      repoRef: widget.repoRef,
      readmeStateKey: widget.readmeStateKey,
      onRefresh: () async => widget.onRefresh(),
      onWillPop: (_) => Future.value(true),
      initialTabPath: widget.deeplinkPathFromTabKind(
        widget.initialState.tabKind,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_config == null) _buildConfig();
  }

  @override
  void didUpdateWidget(covariant _RepositoryShellContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.repo != oldWidget.repo) _buildConfig();
  }

  @override
  Widget build(BuildContext context) {
    return NavCenterShell(config: _config!);
  }
}
