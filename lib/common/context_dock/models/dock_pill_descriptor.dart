import 'package:collection/collection.dart' show ListEquality;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How a dock pill responds to tap.
enum DockPillKind {
  /// Enters active phase, shows overlay/companions.
  activate,

  /// Opens a popup (e.g. sort/filter options).
  popup,

  /// Fires action and stays idle. No phase change.
  fireAndForget,
}

/// Visual phase of a dock pill. State is managed by the dock phase notifier.
enum PillPhase { idle, hint, active }

/// Pure data descriptor for a dock pill. Polymorphic content via [buildContent]/[buildOverlay].
///
/// Identity is structural (equality via [props]). Used as Riverpod family key and for list comparison;
/// never parse or prefix-match for logic (R4).
@immutable
abstract class DockPillDescriptor {
  const DockPillDescriptor({required this.icon, this.startsActive = false});

  /// Icon shown in every phase.
  final IconData icon;

  /// How the pill responds to tap. Each subclass overrides with the correct value.
  DockPillKind get kind;

  /// Companion pills shown alongside this pill when active.
  /// Override in subclasses that have companions (e.g. compose -> submit/cancel).
  List<DockPillDescriptor> get companions => const [];

  /// When true, the dock activates this pill on first mount (e.g. search screen).
  final bool startsActive;

  /// Subclasses override to add their fields; base provides shared fields for equality.
  List<Object?> get props => [icon, startsActive];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DockPillDescriptor &&
          runtimeType == other.runtimeType &&
          const ListEquality<Object?>().equals(props, other.props));

  @override
  int get hashCode => Object.hashAll(props);

  /// Build the inline content widget for hint/active phases.
  /// Returns null for idle or pills with no inline content.
  Widget? buildContent(final PillPhase phase, final BuildContext context);

  /// Build the overlay widget shown above the pill when active.
  /// Returns null when not active or for pills with no overlay.
  Widget? buildOverlay(final PillPhase phase, final BuildContext context);

  /// For [DockPillKind.fireAndForget] pills only. Called by the dock on tap.
  /// Default no-op.
  void fireAction(WidgetRef ref) {}
}
