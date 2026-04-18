import 'package:flutter/foundation.dart';

/// A quick-filter preset for a tab.
///
/// Presets appear in the [NavigationOverlay] as a nested popup
/// (via [PresetMenu]) on positions that declare them. Tapping a preset
/// applies its [qualifier] to the position's search state
/// ([searchStateNotifierProvider(scope)]), modifying the active search query.
///
/// Presets are **shared constants** — identical across screens for the
/// same entity type:
/// - Issues presets are the same on Repo Issues and Home Issues.
/// - PRs presets are the same on Repo PRs and Home PRs.
@immutable
class NavigationPreset {
  const NavigationPreset({
    required this.label,
    required this.qualifier,
    this.isDefault = false,
  });

  /// Display label in the preset menu (e.g. "Open", "Closed").
  final String label;

  /// Search qualifier appended to the base query.
  /// Examples: `'is:open'`, `'assignee:@me'`, `'review-requested:@me'`.
  /// Empty string means "no filter" (show all).
  final String qualifier;

  /// When true, this preset is pre-selected on first load.
  /// Exactly one preset per list should be default.
  final bool isDefault;
}

/// Shared preset constants for reuse across screens.
///
/// Usage in tab configs:
/// ```dart
/// TabConfig(
///   label: 'Issues',
///   searchScope: scope,
///   presets: NavigationPresets.issues,
///   body: SearchListBody(scope: scope),
///   ...
/// )
/// ```
abstract final class NavigationPresets {
  NavigationPresets._();

  // ── Issues (Repo + Home) ──

  static const List<NavigationPreset> issues = <NavigationPreset>[
    NavigationPreset(
      label: 'Open',
      qualifier: 'is:open',
      isDefault: true,
    ),
    NavigationPreset(
      label: 'Closed',
      qualifier: 'is:closed',
    ),
    NavigationPreset(
      label: 'Assigned to me',
      qualifier: 'assignee:@me',
    ),
    NavigationPreset(
      label: 'Created by me',
      qualifier: 'author:@me',
    ),
    NavigationPreset(
      label: 'Mentioned',
      qualifier: 'mentions:@me',
    ),
  ];

  // ── Pull Requests (Repo + Home) ──

  static const List<NavigationPreset> pulls = <NavigationPreset>[
    NavigationPreset(
      label: 'Open',
      qualifier: 'is:open',
      isDefault: true,
    ),
    NavigationPreset(
      label: 'Needs your review',
      qualifier: 'review-requested:@me is:open',
    ),
    NavigationPreset(
      label: 'Created by me',
      qualifier: 'author:@me is:open',
    ),
    NavigationPreset(
      label: 'Assigned to me',
      qualifier: 'assignee:@me',
    ),
    NavigationPreset(
      label: 'Closed',
      qualifier: 'is:closed',
    ),
  ];

  // ── Inbox (Home only) ──

  static const List<NavigationPreset> inbox = <NavigationPreset>[
    NavigationPreset(
      label: 'All',
      qualifier: '',
      isDefault: true,
    ),
    NavigationPreset(
      label: 'Unread only',
      qualifier: 'is:unread',
    ),
    NavigationPreset(
      label: 'Participating',
      qualifier: 'reason:participating',
    ),
  ];

  // ── Discussions (Repo only) ──

  static const List<NavigationPreset> discussions = <NavigationPreset>[
    NavigationPreset(
      label: 'All',
      qualifier: '',
      isDefault: true,
    ),
    NavigationPreset(
      label: 'Answered',
      qualifier: 'answered:true',
    ),
    NavigationPreset(
      label: 'Unanswered',
      qualifier: 'answered:false',
    ),
  ];
}
