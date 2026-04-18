import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/pills/compose_dock_pill.dart';

part 'tab_action.freezed.dart';

/// Polymorphic abstraction for tab-level actions.
///
/// Replaces BasicDockPill/ComposeDockPill declarations
/// in dockActions with a single sealed hierarchy that the shell dispatches on.
///
/// Each variant defines WHAT action the tab needs; the shell
/// renders the HOW (which pill, where it goes).
@freezed
sealed class TabAction with _$TabAction {
  /// Simple fire-and-forget action (New Issue, Mark All Read, Open in Browser).
  const factory TabAction.create({
    required IconData icon,
    required String label,
    required void Function(WidgetRef) onTap,
  }) = CreateTabAction;

  /// Compose action with draft persistence (Comment, Review).
  const factory TabAction.compose({required ComposeDockPill pill}) =
      ComposeTabAction;

  /// Escape hatch for truly unique pills.
  const factory TabAction.custom({required DockPill pill}) = CustomTabAction;
}
