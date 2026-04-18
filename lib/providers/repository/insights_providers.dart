import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_lists.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code_frequency_entry.dart';
import 'package:diohub_models/models/repositories/community_profile.dart';
import 'package:diohub_models/models/repositories/commit_activity_entry.dart';
import 'package:diohub_models/models/repositories/pages_info.dart';
import 'package:diohub_models/models/repositories/contributor_stat.dart';
import 'package:diohub_models/models/repositories/participation_response.dart';
import 'package:diohub_models/models/repositories/punch_card_entry.dart';
import 'package:diohub_models/models/repositories/traffic_clones.dart';
import 'package:diohub_models/models/repositories/traffic_path.dart';
import 'package:diohub_models/models/repositories/traffic_referrer.dart';
import 'package:diohub_models/models/repositories/traffic_views.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

/// One language entry from repository GQL data (name + byte size).
typedef RepoLanguageEntry = ({String name, int size});

/// Languages from repository GQL data (repositoryInfo query). No REST call.
final languagesProvider =
    Provider.family<AsyncValue<List<RepoLanguageEntry>>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) {
    final repoAsync = ref.watch(repositoryProvider(repoRef));
    return repoAsync.when(
      data: (final RepoInfoData data) {
        final repo = data.repository;
        if (repo == null) return const AsyncValue.loading();
        final edges = repo.languages?.edges ?? const <RepoLanguageEdge?>[];
        final list = edges
            .whereType<RepoLanguageEdge>()
            .map(
              (final RepoLanguageEdge e) => (name: e.node.name, size: e.size),
            )
            .toList();
        return AsyncValue.data(list);
      },
      loading: () => const AsyncValue.loading(),
      error: (final Object err, final StackTrace st) =>
          AsyncValue.error(err, st),
    );
  },
);

final trafficViewsProvider =
    FutureProvider.autoDispose.family<TrafficViewsResponse, RepoRef>(
  (final Ref ref, final RepoRef repoRef) => repoRef.stats(ref.read(apiClientProvider)).getTrafficViews(),
);

final trafficClonesProvider =
    FutureProvider.autoDispose.family<TrafficClonesResponse, RepoRef>(
  (final Ref ref, final RepoRef repoRef) => repoRef.stats(ref.read(apiClientProvider)).getTrafficClones(),
);

final contributorsProvider =
    FutureProvider.autoDispose.family<List<ContributorStat>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) =>
      repoRef.stats(ref.read(apiClientProvider)).getStatsContributors(),
);

final commitActivityProvider =
    FutureProvider.autoDispose.family<List<CommitActivityEntry>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) => repoRef.stats(ref.read(apiClientProvider)).getCommitActivity(),
);

final codeFrequencyProvider =
    FutureProvider.autoDispose.family<List<CodeFrequencyEntry>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) => repoRef.stats(ref.read(apiClientProvider)).getCodeFrequency(),
);

final punchCardProvider = FutureProvider.autoDispose.family<List<PunchCardEntry>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) => repoRef.stats(ref.read(apiClientProvider)).getPunchCard(),
);

final topReferrersProvider =
    FutureProvider.autoDispose.family<List<TrafficReferrer>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) => repoRef.stats(ref.read(apiClientProvider)).getTopReferrers(),
);

final topPathsProvider = FutureProvider.autoDispose.family<List<TrafficPath>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) => repoRef.stats(ref.read(apiClientProvider)).getTopPaths(),
);

final participationProvider =
    FutureProvider.autoDispose.family<ParticipationResponse, RepoRef>(
  (final Ref ref, final RepoRef repoRef) => repoRef.stats(ref.read(apiClientProvider)).getParticipation(),
);

final communityProfileProvider =
    FutureProvider.autoDispose.family<CommunityProfile, RepoRef>(
  (final Ref ref, final RepoRef repoRef) =>
      repoRef.services(ref.read(apiClientProvider)).getCommunityProfile(),
);

final pagesInfoProvider = FutureProvider.autoDispose.family<PagesInfo?, RepoRef>(
  (final Ref ref, final RepoRef repoRef) => repoRef.services(ref.read(apiClientProvider)).getPagesInfo(),
);

/// Star history: starredAt timestamps (capped at 500). 
final starHistoryProvider = FutureProvider.autoDispose.family<List<DateTime>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) async {
    return await repoRef
        .services(ref.read(apiClientProvider))
        .fetchStargazerTimestamps(maxPages: 5);
  },
);

/// Milestone progress data for insights (up to 5 open milestones).
typedef MilestoneProgressData = ({
  String id,
  String title,
  int openCount,
  int closedCount,
  double progressPercentage,
  DateTime? dueOn,
});

final milestoneProgressProvider =
    FutureProvider.autoDispose.family<List<MilestoneProgressData>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) async {
    final result = await repoRef
        .labelsAndMilestones(ref.read(apiClientProvider))
        .listMilestonesGQL(
          first: 5,
          states: [Enum$MilestoneState.OPEN],
        );

    return result.items
        .where((e) => e != null && e.node != null)
        .map((e) {
      final edge = e as MilestoneEdge;
      final node = edge.node!;
      return (
        id: node.id,
        title: node.title,
        openCount: node.openIssues?.totalCount ?? 0,
        closedCount: node.closedIssues?.totalCount ?? 0,
        progressPercentage: node.progressPercentage ?? 0.0,
        dueOn: node.dueOn,
      );
    }).toList();
  },
);

/// Release dates for cadence section (publishedAt from releases list).
final releasesForInsightsProvider =
    FutureProvider.autoDispose.family<List<DateTime>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) async {
    final edges = await repoRef.releases(ref.read(apiClientProvider)).fetchReleasesListGQL(first: 100);
    final dates = <DateTime>[];
    for (final e in edges) {
      final node = e.node;
      if (node == null) continue;
      final publishedAt = node.publishedAt;
      if (publishedAt != null) {
        dates.add(publishedAt);
      }
    }
    dates.sort();
    return dates;
  },
);

/// Trend comparing last 4 weeks vs prior 4 weeks of commit activity.
/// Returns a percentage change (positive = increasing, negative = decreasing).
/// Null when data is insufficient (< 8 weeks).
final commitActivityTrendProvider =
    Provider.family<AsyncValue<double?>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) {
    final asyncWeeks = ref.watch(commitActivityProvider(repoRef));
    return asyncWeeks.when(
      data: (final List<CommitActivityEntry> weeks) {
        if (weeks.length < 8) return const AsyncValue.data(null);
        final int recent = weeks.sublist(weeks.length - 4).fold<int>(
            0, (final int s, final CommitActivityEntry w) => s + w.total);
        final int prior = weeks
            .sublist(weeks.length - 8, weeks.length - 4)
            .fold<int>(
                0, (final int s, final CommitActivityEntry w) => s + w.total);
        if (prior == 0) return const AsyncValue.data(null);
        return AsyncValue.data((recent - prior) / prior * 100);
      },
      loading: () => const AsyncValue.loading(),
      error: (final Object e, final StackTrace st) => AsyncValue.error(e, st),
    );
  },
);

/// Code churn summary computed from code frequency data.
typedef CodeChurnSummary = ({
  int totalAdditions,
  int totalDeletions,
  int netLines,
  double? ratio,
});

final codeChurnProvider =
    Provider.family<AsyncValue<CodeChurnSummary>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) {
    final asyncFreq = ref.watch(codeFrequencyProvider(repoRef));
    return asyncFreq.when(
      data: (final List<CodeFrequencyEntry> entries) {
        final int adds = entries.fold<int>(
            0, (final int s, final CodeFrequencyEntry e) => s + e.additions);
        final int dels = entries.fold<int>(
            0, (final int s, final CodeFrequencyEntry e) => s + e.deletions);
        return AsyncValue.data((
          totalAdditions: adds,
          totalDeletions: dels.abs(),
          netLines: adds + dels,
          ratio: dels == 0 ? null : adds / dels.abs(),
        ));
      },
      loading: () => const AsyncValue.loading(),
      error: (final Object e, final StackTrace st) => AsyncValue.error(e, st),
    );
  },
);

/// The day-of-week (0=Sun) and hour (0-23) with most commits.
typedef PeakCommitTime = ({int day, int hour, int commits});

final peakCommitTimeProvider =
    Provider.family<AsyncValue<PeakCommitTime?>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) {
    final asyncPunch = ref.watch(punchCardProvider(repoRef));
    return asyncPunch.when(
      data: (final List<PunchCardEntry> entries) {
        if (entries.isEmpty) return const AsyncValue.data(null);
        final PunchCardEntry peak = entries.reduce(
          (final PunchCardEntry a, final PunchCardEntry b) =>
              a.commits >= b.commits ? a : b,
        );
        if (peak.commits == 0) return const AsyncValue.data(null);
        return AsyncValue.data(
          (day: peak.day, hour: peak.hour, commits: peak.commits),
        );
      },
      loading: () => const AsyncValue.loading(),
      error: (final Object e, final StackTrace st) => AsyncValue.error(e, st),
    );
  },
);

/// Weekday (Mon-Fri) vs Weekend (Sat-Sun) commit split.
typedef WeekdayWeekendSplit = ({int weekday, int weekend});

final weekdayWeekendSplitProvider =
    Provider.family<AsyncValue<WeekdayWeekendSplit?>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) {
    final asyncWeeks = ref.watch(commitActivityProvider(repoRef));
    return asyncWeeks.when(
      data: (final List<CommitActivityEntry> weeks) {
        if (weeks.isEmpty) return const AsyncValue.data(null);
        int weekday = 0;
        int weekend = 0;
        for (final CommitActivityEntry w in weeks) {
          if (w.days.length != 7) continue;
          weekend += w.days[0] + w.days[6];
          weekday += w.days[1] + w.days[2] + w.days[3] + w.days[4] + w.days[5];
        }
        if (weekday == 0 && weekend == 0) return const AsyncValue.data(null);
        return AsyncValue.data((weekday: weekday, weekend: weekend));
      },
      loading: () => const AsyncValue.loading(),
      error: (final Object e, final StackTrace st) => AsyncValue.error(e, st),
    );
  },
);

/// Contributor diversity: percentage of commits from non-owner contributors.
final contributorDiversityProvider =
    Provider.family<AsyncValue<double?>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) {
    final asyncPart = ref.watch(participationProvider(repoRef));
    return asyncPart.when(
      data: (final ParticipationResponse p) {
        final int totalAll =
            p.all.fold<int>(0, (final int s, final int v) => s + v);
        if (totalAll == 0) return const AsyncValue.data(null);
        final int totalOwner =
            p.owner.fold<int>(0, (final int s, final int v) => s + v);
        return AsyncValue.data((totalAll - totalOwner) / totalAll * 100);
      },
      loading: () => const AsyncValue.loading(),
      error: (final Object e, final StackTrace st) => AsyncValue.error(e, st),
    );
  },
);

/// Bus factor assessment. Returns true when >80% of weeks have owner
/// contributing >80% of commits — indicates single-contributor risk.
final busFactorProvider = Provider.family<AsyncValue<bool>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) {
    final asyncPart = ref.watch(participationProvider(repoRef));
    return asyncPart.when(
      data: (final ParticipationResponse p) {
        if (p.all.isEmpty || p.owner.isEmpty) {
          return const AsyncValue.data(false);
        }
        int highConcentration = 0;
        for (int i = 0; i < p.all.length && i < p.owner.length; i++) {
          if (p.all[i] == 0) continue;
          if (p.owner[i] / p.all[i] > 0.8) highConcentration++;
        }
        final int activeWeeks = p.all.where((final int v) => v > 0).length;
        if (activeWeeks == 0) return const AsyncValue.data(false);
        return AsyncValue.data(highConcentration / activeWeeks > 0.75);
      },
      loading: () => const AsyncValue.loading(),
      error: (final Object e, final StackTrace st) => AsyncValue.error(e, st),
    );
  },
);

/// Visitor funnel: views → clones → stars.
typedef TrafficConversion = ({
  int views,
  int clones,
  int stars,
  double cloneRate,
  double starRate,
});

final trafficConversionProvider =
    Provider.family<AsyncValue<TrafficConversion?>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) {
    final asyncViews = ref.watch(trafficViewsProvider(repoRef));
    final asyncClones = ref.watch(trafficClonesProvider(repoRef));
    final repoAsync = ref.watch(repositoryProvider(repoRef));
    return asyncViews.when(
      data: (final TrafficViewsResponse views) {
        return asyncClones.when(
          data: (final TrafficClonesResponse clones) {
            return repoAsync.when(
              data: (final RepoInfoData data) {
                final repo = data.repository;
                if (repo == null) return const AsyncValue.loading();
                final int viewCount = views.uniques;
                final int cloneCount = clones.uniques;
                final int starCount = repo.stargazerCount;
                if (viewCount == 0) return const AsyncValue.data(null);
                return AsyncValue.data((
                  views: viewCount,
                  clones: cloneCount,
                  stars: starCount,
                  cloneRate: cloneCount / viewCount,
                  starRate: starCount / viewCount,
                ));
              },
              loading: () => const AsyncValue.loading(),
              error: (final Object e, final StackTrace st) =>
                  AsyncValue.error(e, st),
            );
          },
          loading: () => const AsyncValue.loading(),
          error: (final Object e, final StackTrace st) =>
              AsyncValue.error(e, st),
        );
      },
      loading: () => const AsyncValue.loading(),
      error: (final Object e, final StackTrace st) => AsyncValue.error(e, st),
    );
  },
);

/// Repo Pulse Score (0–100) composite health metric.
typedef RepoPulseScore = ({
  double overall,
  double activityScore,
  double trafficScore,
  double communityScore,
  double diversityScore,
  double churnScore,
});

final repoPulseScoreProvider =
    Provider.family<AsyncValue<RepoPulseScore?>, RepoRef>(
  (final Ref ref, final RepoRef repoRef) {
    final weeksAsync = ref.watch(commitActivityProvider(repoRef));
    final trafficAsync = ref.watch(trafficViewsProvider(repoRef));
    final communityAsync = ref.watch(communityProfileProvider(repoRef));
    final diversityAsync = ref.watch(contributorDiversityProvider(repoRef));
    final churnAsync = ref.watch(codeChurnProvider(repoRef));

    if (weeksAsync is AsyncLoading) return const AsyncValue.loading();
    final List<CommitActivityEntry>? weeks = weeksAsync.value;
    if (weeks == null || weeks.isEmpty) return const AsyncValue.data(null);

    double activityScore = 0;
    if (weeks.length >= 4) {
      final recent = weeks.sublist(weeks.length - 4).fold<int>(
          0, (final int s, final CommitActivityEntry w) => s + w.total);
      int maxWindow = 0;
      for (int i = 0; i <= weeks.length - 4; i++) {
        final windowTotal = weeks.sublist(i, i + 4).fold<int>(
            0, (final int s, final CommitActivityEntry w) => s + w.total);
        if (windowTotal > maxWindow) maxWindow = windowTotal;
      }
      activityScore =
          maxWindow > 0 ? (recent / maxWindow * 100).clamp(0.0, 100.0) : 0;
    }

    double trafficScore = 0;
    final TrafficViewsResponse? traffic = trafficAsync.value;
    if (traffic != null) {
      final dailyUniques = traffic.uniques / 14;
      trafficScore = (dailyUniques / 10 * 100).clamp(0.0, 100.0);
    }

    double communityScore = 0;
    final CommunityProfile? community = communityAsync.value;
    if (community != null) {
      communityScore = community.healthPercentage.toDouble().clamp(0.0, 100.0);
    }

    double diversityScore = 0;
    final double? diversityVal = diversityAsync.value;
    if (diversityVal != null) {
      diversityScore = diversityVal.clamp(0.0, 100.0);
    }

    double churnScore = 50;
    final CodeChurnSummary? churn = churnAsync.value;
    if (churn != null) {
      final double? ratio = churn.ratio;
      if (ratio != null) {
        churnScore = ((1 - (ratio.clamp(0.0, 2.0) - 0.5).abs() * 2) * 100)
            .clamp(0.0, 100.0);
      }
    }

    final overall = (activityScore +
            trafficScore +
            communityScore +
            diversityScore +
            churnScore) /
        5;

    return AsyncValue.data((
      overall: overall,
      activityScore: activityScore,
      trafficScore: trafficScore,
      communityScore: communityScore,
      diversityScore: diversityScore,
      churnScore: churnScore,
    ));
  },
);
