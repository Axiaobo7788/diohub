import 'package:diohub/common/animations/animations.dart';
import 'package:diohub/common/misc/license_overview_card.dart';
import 'package:diohub/common/misc/markdown_skeleton.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/wrappers/app_custom_scroll_view.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Displays the repository license: overview card (from [licenseInfo]) and
/// the actual LICENSE file content (branch-dependent, from [licenseContentAsync]).
class RepositoryLicense extends StatefulWidget {
  const RepositoryLicense({
    required this.licenseContentAsync,
    super.key,
    this.licenseInfo,
  });

  /// License metadata from the repo query (overview only; not branch-dependent).
  final RepoLicenseInfo? licenseInfo;

  /// Async state of the LICENSE file content (branch-dependent).
  final AsyncValue<String?> licenseContentAsync;

  @override
  State<RepositoryLicense> createState() => _RepositoryLicenseState();
}

/// Sliver-only version for use inside the shell's [AppCustomScrollView].
class RepositoryLicenseSliver extends StatelessWidget {
  const RepositoryLicenseSliver({
    required this.licenseContentAsync,
    super.key,
    this.licenseInfo,
  });

  final RepoLicenseInfo? licenseInfo;
  final AsyncValue<String?> licenseContentAsync;

  @override
  Widget build(final BuildContext context) {
    return AnimatedContentSwitcher(
      child: KeyedSubtree(
        key: ValueKey(_RepositoryLicenseState._phaseKey(licenseContentAsync)),
        child: MultiSliver(
          children: _RepositoryLicenseState._buildSlivers(
            context,
            licenseInfo,
            licenseContentAsync,
          ),
        ),
      ),
    );
  }
}

class _RepositoryLicenseState extends State<RepositoryLicense>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static List<LicenseRuleDisplay> _mapConditions(
    final List<RepoLicenseCondition?>
        list,
  ) =>
      list
          .whereType<RepoLicenseCondition>()
          .map((final e) => (key: e.key, label: e.label))
          .toList();

  static List<LicenseRuleDisplay> _mapPermissions(
    final List<RepoLicensePermission?>
        list,
  ) =>
      list
          .whereType<RepoLicensePermission>()
          .map((final e) => (key: e.key, label: e.label))
          .toList();

  static List<LicenseRuleDisplay> _mapLimitations(
    final List<RepoLicenseLimitation?>
        list,
  ) =>
      list
          .whereType<RepoLicenseLimitation>()
          .map((final e) => (key: e.key, label: e.label))
          .toList();

  static String _phaseKey(final AsyncValue<String?> v) => v.when(
        loading: () => 'loading',
        error: (final _, final __) => 'error',
        data: (final String? d) => d == null ? 'data-empty' : 'data',
      );

  static List<Widget> _buildSlivers(
    final BuildContext context,
    final RepoLicenseInfo? licenseInfo,
    final AsyncValue<String?> licenseContentAsync,
  ) {
    final List<Widget> slivers = <Widget>[];

    if (licenseInfo != null) {
      final Widget overviewCard = LicenseOverviewCard(
        description: licenseInfo.description,
        permissions: _mapPermissions(licenseInfo.permissions),
        conditions: _mapConditions(licenseInfo.conditions),
        limitations: _mapLimitations(licenseInfo.limitations),
      );
      slivers.add(
        SliverToBoxAdapter(
          child: overviewCard,
        ),
      );
    }

    slivers.addAll(
      licenseContentAsync.when(
        loading: () => <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: context.spacing.pagePadding,
              child: const ShimmerScope(
                child: MarkdownSkeleton(lineCount: 20),
              ),
            ),
          ),
        ],
        error: (final Object error, final StackTrace stack) => <Widget>[
          SliverFillRemaining(
            child: Center(
              child: Text('Error loading license file: $error'),
            ),
          ),
        ],
        data: (final String? content) {
          if (content == null || content.isEmpty) {
            return <Widget>[
              const SliverFillRemaining(child: _NoLicenseFileWidget()),
            ];
          }
          return <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: context.spacing.pagePadding,
                child: SelectableText(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
            ),
          ];
        },
      ),
    );

    return slivers;
  }

  /// For standalone/route use only. Shell positions must use [RepositoryLicenseSliver].
  Widget _buildScrollView(final BuildContext context) => AppCustomScrollView(
        slivers: _buildSlivers(
          context,
          widget.licenseInfo,
          widget.licenseContentAsync,
        ),
      );

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    return AnimatedContentSwitcher(
      child: KeyedSubtree(
        key: ValueKey(_phaseKey(widget.licenseContentAsync)),
        child: _buildScrollView(context),
      ),
    );
  }
}

class _NoLicenseFileWidget extends StatelessWidget {
  const _NoLicenseFileWidget();

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: context.spacing.emptyStatePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Octicons.law,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            context.spacing.sectionGap,
            Text(
              'No license file',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            context.spacing.tightGap,
            Text(
              'No LICENSE file found on this branch.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
