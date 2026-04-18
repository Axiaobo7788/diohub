import 'package:flutter/material.dart';
import 'package:diohub/common/popup/entity_popup_menu.dart';
import 'package:diohub/common/widgets/metadata_section_sliver.dart';
import 'package:diohub_models/models/entity_ref.dart';

/// Metadata section descriptor for the entity info popup.
///
/// Each instance maps to a [MetadataSectionSliver] in the overlay's
/// [CustomScrollView]. The framework renders them in order with
/// [sectionGap] (16dp) vertical spacing between sections.
@immutable
class MetadataSectionData {
  const MetadataSectionData({
    required this.title,
    required this.icon,
    this.variant = MetadataSectionVariant.neutral,
    required this.children,
    this.statRail,
    this.visibleWhen,
  });

  /// Section header title (e.g. "Identity", "Code", "Timeline").
  final String title;

  /// Section header icon.
  final IconData icon;

  /// Visual variant: [strong] (emphasized), [neutral] (default), [muted].
  final MetadataSectionVariant variant;

  /// Metadata row widgets. These are existing [MetadataRow], [MetadataTimestampRow],
  /// [MetadataContactRow], etc. from `metadata_rows.dart`.
  final List<Widget> children;

  /// Optional stat rail widget displayed at the trailing edge of the
  /// section header (e.g. counts, progress bars).
  final Widget? statRail;

  /// Optional visibility predicate. When non-null, the section is only
  /// rendered when this returns true. Used for conditional sections
  /// (e.g. "Fork Source" only when repo is a fork).
  final bool Function()? visibleWhen;
}

/// Configuration for the entity displayed in the [CollapseBar] and
/// the entity info popup (tap on entity opens [EntityInfoContent]).
///
/// Composed by screen config builders from provider-watched data.
@immutable
class EntityConfig {
  const EntityConfig({
    this.leading,
    required this.title,
    this.subtitle,
    this.statusIndicators,
    this.metadataSections = const <MetadataSectionData>[],
    this.actionSections = const <PopupMenuSection>[],
    this.headerSlivers,
    this.ref,
  });

  /// The entity this screen displays, when applicable (repo, issue, PR, etc.).
  /// Used for entity store, scoped logging, and navigation.
  final EntityRef? ref;

  /// Leading widget for [CollapseBar]. Typically an avatar.
  final Widget? leading;

  /// Title widget for [CollapseBar]. Entity name/number.
  /// Tapping this opens the entity info popup.
  final Widget title;

  /// Subtitle widget for [CollapseBar]. Collapses with scroll progress.
  final Widget? subtitle;

  /// Always-visible status indicators below the title in [CollapseBar].
  final Widget? statusIndicators;

  /// Metadata sections shown in the entity info popup.
  /// Rendered as flat column rows (not slivers). Order matters.
  final List<MetadataSectionData> metadataSections;

  /// Action sections shown below metadata in the entity info popup.
  /// Rendered via existing [EntityPopupMenu] logic.
  /// Order: primary → management → utility.
  final List<PopupMenuSection> actionSections;

  /// Optional slivers prepended above the shell's default header slivers
  /// (e.g. [DownloadBannerSliver]). Used for
  /// entity-specific banners such as [PendingReviewBanner] on PR screens.
  final List<Widget>? headerSlivers;
}
