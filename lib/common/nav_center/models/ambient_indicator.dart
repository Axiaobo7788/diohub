import 'package:flutter/material.dart';
import 'package:diohub_graphql/schema_typedefs.dart';

/// Data descriptor for ambient metadata rendered in the context dock FAB
/// Trailing area. The bar owns the `switch` rendering — no
/// dedicated widget files per variant.
///
/// Each variant maps to an existing widget:
/// - [BranchAmbient] → [TintedChip] with fork icon + ref name
/// - [DiffStatAmbient] → [DiffDistribution.compact] (existing widget)
/// - [CIStatusAmbient] → [TintedChip] with status color + icon + label
/// - [ReviewDecisionAmbient] → [TintedChip] with decision color + icon + label
/// - [ProgressAmbient] → linear progress bar (existing [SubIssueProgressChip] or similar)
/// - [FilterChipAmbient] → [TintedChip] with filter icon + label
/// - [LicenseAmbient] → plain [Text] with secondary style
/// - [TagAmbient] → [TintedChip] with label icon + tag name
sealed class AmbientIndicator {
  const AmbientIndicator();
}

/// Branch name chip — Code tab, Commits tab.
class BranchAmbient extends AmbientIndicator {
  const BranchAmbient(this.ref);

  /// Branch or tag name (e.g. "main", "v1.2.3").
  final String ref;
}

/// Diff stat bar — PR Files tab, Commit Files tab.
class DiffStatAmbient extends AmbientIndicator {
  const DiffStatAmbient({
    required this.additions,
    required this.deletions,
    this.changedFiles,
  });

  final int additions;
  final int deletions;

  /// Optional changed files count for display (e.g. "8 files").
  final int? changedFiles;
}

/// CI status dot — Commit Files tab, PR Discussion tab.
class CIStatusAmbient extends AmbientIndicator {
  const CIStatusAmbient(this.state);

  /// [StatusState] from GraphQL schema.
  /// Framework maps: SUCCESS → green, FAILURE → red, PENDING → yellow,
  /// ERROR → red, EXPECTED → grey.
  final StatusState state;
}

/// Review decision chip — PR Discussion tab.
class ReviewDecisionAmbient extends AmbientIndicator {
  const ReviewDecisionAmbient(this.decision);

  /// [PullRequestReviewDecision] from GraphQL schema.
  /// Framework maps: APPROVED → green ✓, CHANGES_REQUESTED → red ✗,
  /// REVIEW_REQUIRED → yellow ◌.
  final PullRequestReviewDecision decision;
}

/// Progress bar — Issue Sub-Issues tab, Issue Content (milestone).
class ProgressAmbient extends AmbientIndicator {
  const ProgressAmbient({
    required this.completed,
    required this.total,
    this.label,
  });

  final int completed;
  final int total;

  /// Optional label override (e.g. "Sprint 4"). When null, framework
  /// renders "{completed}/{total} completed".
  final String? label;
}

/// Active filter chip — Home Issues/PRs tab.
class FilterChipAmbient extends AmbientIndicator {
  const FilterChipAmbient(this.label);

  /// Human-readable filter state (e.g. "Open · Assigned").
  final String label;
}

/// License name — Repo License tab.
class LicenseAmbient extends AmbientIndicator {
  const LicenseAmbient(this.name);

  /// Full license name (e.g. "MIT License", "Apache License 2.0").
  final String name;
}

/// Release tag chip — Repo Releases tab.
class TagAmbient extends AmbientIndicator {
  const TagAmbient({
    required this.tagName,
    this.date,
    this.isPrerelease = false,
  });

  final String tagName;
  final DateTime? date;
  final bool isPrerelease;
}

/// Segment for [LanguageBarAmbient] (color hex + byte size). No name needed for compact bar.
class LanguageBarSegment {
  const LanguageBarSegment({required this.color, required this.size});
  final String color;
  final int size;
}

/// Mini language bar — Repo Code tab (Tier 2). Rendered as a thin row of colored segments.
class LanguageBarAmbient extends AmbientIndicator {
  const LanguageBarAmbient({required this.segments});
  final List<LanguageBarSegment> segments;
}

/// Mini avatar stack — Repo Contributors, Issue/PR Participants (Tier 2). Rendered as overlapping circles.
class AvatarStackAmbient extends AmbientIndicator {
  const AvatarStackAmbient({required this.avatarUrls});
  final List<String> avatarUrls;
}

/// Mini sparkline — Repo Insights, Actions (Tier 3). Rendered as a tiny line chart.
class SparklineAmbient extends AmbientIndicator {
  const SparklineAmbient({required this.values});
  final List<double> values;
}
