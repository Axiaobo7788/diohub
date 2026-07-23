import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/providers/repository/insights_providers.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/repository/md3/repository_md3_layout.dart';
import 'package:diohub/view/repository/md3/repository_tab_scaffold.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/community_profile.dart';
import 'package:diohub_models/models/repositories/contributor_stat.dart';
import 'package:diohub_models/models/repositories/participation_response.dart';
import 'package:diohub_models/models/repositories/traffic_clones.dart';
import 'package:diohub_models/models/repositories/traffic_path.dart';
import 'package:diohub_models/models/repositories/traffic_referrer.dart';
import 'package:diohub_models/models/repositories/traffic_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

part 'repository_insights_widgets.dart';

enum _InsightsSection { pulse, contributors, traffic, community }

class RepositoryInsightsMd3Page extends ConsumerStatefulWidget {
  const RepositoryInsightsMd3Page({
    required this.repoRef,
    required this.signedIn,
    required this.onRefreshReady,
    super.key,
  });

  final RepoRef repoRef;
  final bool signedIn;
  final ValueChanged<Future<void> Function()?> onRefreshReady;

  @override
  ConsumerState<RepositoryInsightsMd3Page> createState() =>
      _RepositoryInsightsMd3PageState();
}

class _RepositoryInsightsMd3PageState
    extends ConsumerState<RepositoryInsightsMd3Page> {
  _InsightsSection _section = _InsightsSection.pulse;

  @override
  void initState() {
    super.initState();
    widget.onRefreshReady(widget.signedIn ? _refresh : null);
  }

  @override
  void didUpdateWidget(final RepositoryInsightsMd3Page oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signedIn != widget.signedIn) {
      widget.onRefreshReady(widget.signedIn ? _refresh : null);
    }
  }

  @override
  void dispose() {
    widget.onRefreshReady(null);
    super.dispose();
  }

  Future<void> _refresh() async {
    switch (_section) {
      case _InsightsSection.pulse:
        ref
          ..invalidate(participationProvider(widget.repoRef))
          ..invalidate(languagesProvider(widget.repoRef));
      case _InsightsSection.contributors:
        ref.invalidate(contributorsProvider(widget.repoRef));
      case _InsightsSection.traffic:
        ref
          ..invalidate(trafficViewsProvider(widget.repoRef))
          ..invalidate(trafficClonesProvider(widget.repoRef))
          ..invalidate(topReferrersProvider(widget.repoRef))
          ..invalidate(topPathsProvider(widget.repoRef));
      case _InsightsSection.community:
        ref.invalidate(communityProfileProvider(widget.repoRef));
    }
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Widget build(final BuildContext context) {
    if (!widget.signedIn) {
      return RepositoryTabScaffold(
        title: context.l10n.repoInsights,
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
            icon: Icons.monitor_heart_outlined,
            label: context.l10n.repoPulse,
          ),
          RepositoryTabNavigationDestination(
            icon: Icons.people_outline,
            label: context.l10n.repoContributors,
          ),
          RepositoryTabNavigationDestination(
            icon: Icons.query_stats,
            label: context.l10n.repoTraffic,
          ),
          RepositoryTabNavigationDestination(
            icon: Icons.fact_check_outlined,
            label: context.l10n.repoCommunityStandards,
          ),
        ];
    return RepositoryTabScaffold(
      title: destinations[_section.index].label,
      onRefresh: _refresh,
      navigation: RepositoryTabNavigation(
        title: context.l10n.repoInsights,
        destinations: destinations,
        selectedIndex: _section.index,
        onSelected: _selectSection,
      ),
      compactNavigation: DropdownButtonFormField<_InsightsSection>(
        isExpanded: true,
        initialValue: _section,
        decoration: InputDecoration(
          labelText: context.l10n.repoInsights,
          prefixIcon: const Icon(Icons.insights_outlined),
        ),
        items: <DropdownMenuItem<_InsightsSection>>[
          for (final _InsightsSection section in _InsightsSection.values)
            DropdownMenuItem<_InsightsSection>(
              value: section,
              child: Text(destinations[section.index].label),
            ),
        ],
        onChanged: (final _InsightsSection? section) {
          if (section != null) _selectSection(section.index);
        },
      ),
      actions: <Widget>[
        IconButton.outlined(
          tooltip: context.l10n.activityRefresh,
          onPressed: () => unawaited(_refresh()),
          icon: const Icon(Icons.refresh),
        ),
      ],
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            RepositoryMd3Layout.regularPageInset,
            0,
            RepositoryMd3Layout.regularPageInset,
            RepositoryMd3Layout.regularPageInset,
          ),
          sliver: SliverToBoxAdapter(child: _buildSection()),
        ),
      ],
    );
  }

  void _selectSection(final int index) {
    final _InsightsSection next = _InsightsSection.values[index];
    if (next == _section) return;
    setState(() => _section = next);
  }

  Widget _buildSection() => switch (_section) {
    _InsightsSection.pulse => _PulseOverview(repoRef: widget.repoRef),
    _InsightsSection.contributors => _Contributors(repoRef: widget.repoRef),
    _InsightsSection.traffic => _Traffic(repoRef: widget.repoRef),
    _InsightsSection.community => _Community(repoRef: widget.repoRef),
  };
}

class _PulseOverview extends ConsumerWidget {
  const _PulseOverview({required this.repoRef});

  final RepoRef repoRef;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<ParticipationResponse> participation = ref.watch(
      participationProvider(repoRef),
    );
    final AsyncValue<List<RepoLanguageEntry>> languages = ref.watch(
      languagesProvider(repoRef),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _AsyncSection<ParticipationResponse>(
          value: participation,
          title: context.l10n.repoCommitActivity,
          builder: (final ParticipationResponse data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ActivityBars(values: data.all),
              const SizedBox(height: RepositoryMd3Layout.space12),
              Text(
                context.l10n.repoCommitsLastYear(
                  data.all.fold<int>(
                    0,
                    (final int total, final int value) => total + value,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: RepositoryMd3Layout.space16),
        _AsyncSection<List<RepoLanguageEntry>>(
          value: languages,
          title: context.l10n.repoLanguages,
          builder: (final List<RepoLanguageEntry> data) =>
              _LanguageBreakdown(entries: data),
        ),
      ],
    );
  }
}

class _Contributors extends ConsumerWidget {
  const _Contributors({required this.repoRef});

  final RepoRef repoRef;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<List<ContributorStat>> value = ref.watch(
      contributorsProvider(repoRef),
    );
    return _AsyncSection<List<ContributorStat>>(
      value: value,
      title: context.l10n.repoContributors,
      emptyTitle: context.l10n.repoNoContributors,
      builder: (final List<ContributorStat> contributors) {
        final List<ContributorStat> sorted =
            List<ContributorStat>.of(contributors)..sort(
              (final ContributorStat a, final ContributorStat b) =>
                  b.total.compareTo(a.total),
            );
        return Column(
          children: <Widget>[
            for (int index = 0; index < sorted.length; index++) ...<Widget>[
              if (index > 0) const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: UserAvatar(
                  avatarUrl: sorted[index].author?.avatarUrl,
                  fallbackText:
                      sorted[index].author?.login ??
                      context.l10n.repoUnknownContributor,
                  size: 36,
                ),
                title: Text(
                  sorted[index].author?.login ??
                      context.l10n.repoUnknownContributor,
                ),
                trailing: Text(
                  context.l10n.repoContributionsCount(sorted[index].total),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Traffic extends ConsumerWidget {
  const _Traffic({required this.repoRef});

  final RepoRef repoRef;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<TrafficViewsResponse> views = ref.watch(
      trafficViewsProvider(repoRef),
    );
    final AsyncValue<TrafficClonesResponse> clones = ref.watch(
      trafficClonesProvider(repoRef),
    );
    final AsyncValue<List<TrafficReferrer>> referrers = ref.watch(
      topReferrersProvider(repoRef),
    );
    final AsyncValue<List<TrafficPath>> paths = ref.watch(
      topPathsProvider(repoRef),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder:
              (final BuildContext context, final BoxConstraints constraints) {
                final double width = constraints.maxWidth >= 720
                    ? (constraints.maxWidth - RepositoryMd3Layout.space16) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: RepositoryMd3Layout.space16,
                  runSpacing: RepositoryMd3Layout.space16,
                  children: <Widget>[
                    SizedBox(
                      width: width,
                      child: _AsyncSection<TrafficViewsResponse>(
                        value: views,
                        title: context.l10n.repoViews,
                        builder: (final TrafficViewsResponse data) =>
                            _TrafficNumbers(
                              total: data.count,
                              unique: data.uniques,
                            ),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _AsyncSection<TrafficClonesResponse>(
                        value: clones,
                        title: context.l10n.repoClones,
                        builder: (final TrafficClonesResponse data) =>
                            _TrafficNumbers(
                              total: data.count,
                              unique: data.uniques,
                            ),
                      ),
                    ),
                  ],
                );
              },
        ),
        const SizedBox(height: RepositoryMd3Layout.space16),
        _AsyncSection<List<TrafficReferrer>>(
          value: referrers,
          title: context.l10n.repoTopReferrers,
          builder: (final List<TrafficReferrer> data) => _MetricRows(
            rows: <({String label, int count, int unique})>[
              for (final TrafficReferrer item in data)
                (label: item.referrer, count: item.count, unique: item.uniques),
            ],
          ),
        ),
        const SizedBox(height: RepositoryMd3Layout.space16),
        _AsyncSection<List<TrafficPath>>(
          value: paths,
          title: context.l10n.repoPopularContent,
          builder: (final List<TrafficPath> data) => _MetricRows(
            rows: <({String label, int count, int unique})>[
              for (final TrafficPath item in data)
                (
                  label: item.title ?? item.path,
                  count: item.count,
                  unique: item.uniques,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Community extends ConsumerWidget {
  const _Community({required this.repoRef});

  final RepoRef repoRef;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return _AsyncSection<CommunityProfile>(
      value: ref.watch(communityProfileProvider(repoRef)),
      title: context.l10n.repoCommunityStandards,
      builder: (final CommunityProfile profile) {
        final files = profile.files;
        final entries = <({String label, String? url, bool present})>[
          (
            label: context.l10n.repoReadme,
            url: files?.readme?.htmlUrl,
            present: files?.readme != null,
          ),
          (
            label: context.l10n.repoLicense,
            url: files?.license?.htmlUrl,
            present: files?.license != null,
          ),
          (
            label: context.l10n.repoContributing,
            url: files?.contributing?.htmlUrl,
            present: files?.contributing != null,
          ),
          (
            label: context.l10n.repoCodeOfConduct,
            url:
                files?.codeOfConductFile?.htmlUrl ??
                files?.codeOfConduct?.htmlUrl,
            present:
                files?.codeOfConductFile != null ||
                files?.codeOfConduct != null,
          ),
          (
            label: context.l10n.repoIssueTemplate,
            url: files?.issueTemplate?.htmlUrl,
            present: files?.issueTemplate != null,
          ),
          (
            label: context.l10n.repoPullRequestTemplate,
            url: files?.pullRequestTemplate?.htmlUrl,
            present: files?.pullRequestTemplate != null,
          ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            LinearProgressIndicator(
              value: profile.healthPercentage / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(
                RepositoryMd3Layout.sectionRadius,
              ),
            ),
            const SizedBox(height: RepositoryMd3Layout.space8),
            Text(context.l10n.repoCommunityHealth(profile.healthPercentage)),
            const SizedBox(height: RepositoryMd3Layout.space12),
            for (final entry in entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  entry.present ? Icons.check_circle : Icons.circle_outlined,
                  color: entry.present ? Colors.green.shade700 : null,
                ),
                title: Text(entry.label),
                trailing: entry.url == null
                    ? null
                    : const Icon(Icons.open_in_new, size: 18),
                onTap: entry.url == null
                    ? null
                    : () => unawaited(launchUrl(Uri.parse(entry.url!))),
              ),
          ],
        );
      },
    );
  }
}
