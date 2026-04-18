import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/common/context_dock/models/dock_pill_phase.dart';
import 'package:diohub/common/context_dock/models/pill_tap_behaviour.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';

/// Abstract base for all dock pills.
///
/// A DockPill is a state machine (ValueNotifier<DockPillPhase>) that
/// also defines its own identity (icon), behavior (onTap), and
/// content rendering (buildContent).
///
/// Subclasses are parameterized with pure DATA — scopes, provider
/// references, option lists. Never with WidgetRef or BuildContext.
///
/// The content widgets returned by [buildContent] are ConsumerWidgets
/// that own their own WidgetRef from the widget tree.
///
/// ## Layering contract
///
/// - The pill itself is a state machine. It holds data, transitions
///   between phases, and defines what to render. It never reads
///   from or writes to providers directly.
///
/// - Callbacks that need provider access are typed as
///   `void Function(WidgetRef, T)`. The widget layer calls them,
///   passing its own ref at invocation time. The pill declares
///   WHAT should happen; the widget provides the HOW.
///
/// - Content returned by [buildContent] is a ConsumerWidget that
///   obtains its own ref via build(context, ref). The pill never
///   passes, stores, or captures a WidgetRef.
abstract class DockPill extends ValueNotifier<DockPillPhase> {
  DockPill() : super(const IdlePhase());

  /// Called once when the pill is first mounted in the widget tree.
  /// Override to read initial state (e.g. filter pill sets [value] to [HintPhase]
  /// when [searchStateNotifierProvider] has active filters).
  void onMount(WidgetRef ref) {}

  /// Icon shown in every phase — always visible.
  IconData get icon;

  /// How this pill responds to tap (R8: [DockPillWidget] switches on this only).
  PillTapBehaviour get tapBehaviour => const ActivatePill();

  /// Optional popup content when [tapBehaviour] is [PopupPill] and [buildActions] is null or empty.
  Widget? buildPopupContent(VoidCallback onDismiss) => null;

  /// Called when pill is tapped in idle or hint phase. The widget layer
  /// supplies [context] and [ref] at invocation time. Single entry point for
  /// both [ActivatePill] (set `value = ActivePhase(...)`) and [FireAndForget]
  /// (run action, e.g. show sheet). [PopupPill] uses the popup path instead.
  void onTap(BuildContext context, WidgetRef ref) {}

  /// Builds content rendered NEXT TO the icon based on current phase.
  /// Returns null → icon only (idle appearance).
  ///
  /// The returned widget MUST be a ConsumerWidget or
  /// ConsumerStatefulWidget if it needs provider access.
  /// It gets its own WidgetRef from the widget tree.
  ///
  /// The dock shell handles glass surface, animations, layout.
  Widget? buildContent(BuildContext context);

  /// Builds inline overlay above this pill when active.
  ///
  /// Returns null by default. Override in subclasses that show
  /// floating content above the pill (e.g. branch list, filter drill-down).
  /// The overlay is declarative — [DockPillWidget] calls this on each rebuild.
  /// Call [notifyListeners] when pill state changes to trigger a rebuild.
  Widget? buildOverlay(BuildContext context) => null;

  /// Builds action list for popup when this pill uses [PopupButton] with actions.
  ///
  /// When non-null, [DockPillWidget] uses [PopupButton] with [PopupButton.actions]
  /// (glass via [PopupMenu]) instead of [popupBuilder]. [onDismiss] is passed
  /// so actions can close the popup after selection.
  List<ActionButtonData>? buildActions(WidgetRef ref, VoidCallback onDismiss) =>
      null;
}
