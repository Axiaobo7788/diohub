import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/scoped_image_theme.dart';
import 'package:diohub/common/misc/scaffold_body.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/shell/nav_center_shell_widgets.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/entity_store_notifier.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/providers/settings/repository_provider.dart'
    as repo_settings;
import 'package:diohub/view/repository/readme/repository_readme.dart';
import 'package:diohub/view/repository/widgets/repo_screen_config.dart';
import 'package:diohub/view/repository/widgets/repository_screen_skeleton.dart';
import 'package:diohub/models/repositories/repository_initial_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class RepositoryScreen extends ConsumerStatefulWidget {
  const RepositoryScreen({
    required this.repo,
    super.key,
  });
  final RepoRef repo;

  String get owner => repo.owner;
  String get name => repo.name;

  @override
  RepositoryScreenState createState() => RepositoryScreenState();
}

class RepositoryScreenState extends ConsumerState<RepositoryScreen> {
  @override
  void initState() {
    super.initState();
    final initialRef = RepositoryInitialRef.fromRepo(widget.repo);
    applyInitialRef(ref, widget.repo, initialRef);
  }

  @override
  Widget build(final BuildContext context) {
    final repoAsync = ref.watch(repositoryProvider(widget.repo));

    return Scaffold(
      body: ScaffoldBody(
        child: repoAsync.maybeWhen(
          loading: () => const RepositoryScreenSkeleton(),
          error: (error, stack) {
            return Center(
              child: Text('Error loading repository: $error'),
            );
          },
          data: (data) {
            final repo = data.repository!;
            final ownerAvatarUrl = repo.owner.maybeWhen(
              user: (u) => u.avatarUrl.toString(),
              organization: (o) => o.avatarUrl.toString(),
              orElse: () => null,
            );
            RepositoryInitialState initialState =
                resolveRepoLocation(widget.repo.location);
            if (initialState.tabKind == null) {
              initialState = RepositoryInitialState(
                tabKind: RepositoryInitialState.tabKindFromRepositoryDefaultTab(
                  ref.read(repo_settings.repositoryProvider).defaultTab,
                ),
                branch: initialState.branch,
                codePath: initialState.codePath,
              );
            }
            return ScopedImageTheme(
              imageUrl: ownerAvatarUrl,
              child: _RepositoryTabsContent(
                repoRef: widget.repo,
                hasReadme: repo.readmeFile != null,
                hasLicense: repo.licenseInfo != null,
                owner: widget.owner,
                name: widget.name,
                initialState: initialState,
              ),
            );
          },
          orElse: () => const CenteredSpinner(),
        ),
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
  });

  final RepoRef repoRef;
  final bool hasReadme;
  final bool hasLicense;
  final String owner;
  final String name;
  final RepositoryInitialState initialState;

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
    final repo =
        ref.watch(repositoryProvider(widget.repoRef)).requireValue.repository!;
    final ownerAvatarUrl = repo.owner.maybeWhen(
      user: (u) => u.avatarUrl.toString(),
      organization: (o) => o.avatarUrl.toString(),
      orElse: () => null,
    );
    return ScopedImageTheme(
      imageUrl: ownerAvatarUrl,
      child: _RepositoryShellContent(
        repo: repo,
        repoRef: widget.repoRef,
        initialState: widget.initialState,
        readmeStateKey: _readmeStateKey,
        onRefresh: () => ref.invalidate(repositoryProvider(widget.repoRef)),
        deeplinkPathFromTabKind: _deeplinkPathFromTabKind,
      ),
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
      ref.read(entityStoreMutatorProvider).recordVisit(
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
      initialTabPath:
          widget.deeplinkPathFromTabKind(widget.initialState.tabKind),
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
