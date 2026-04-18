import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';

/// Manages the phase state for a specific dock pill descriptor.
/// Family keyed by descriptor for identity.
final dockPillPhaseProvider = NotifierProvider.family<
    _DockPillPhaseNotifier,
    PillPhase,
    DockPillDescriptor>(_DockPillPhaseNotifier.new);

class _DockPillPhaseNotifier extends Notifier<PillPhase> {
  _DockPillPhaseNotifier(this._descriptor);
  
  final DockPillDescriptor _descriptor;

  @override
  PillPhase build() {
    // Initialize to idle unless descriptor says to start active
    return _descriptor.startsActive ? PillPhase.active : PillPhase.idle;
  }

  /// Set the phase to active.
  void activate() {
    if (state != PillPhase.active) {
      state = PillPhase.active;
    }
  }

  /// Set the phase to hint.
  void hint() {
    if (state != PillPhase.hint) {
      state = PillPhase.hint;
    }
  }

  /// Set the phase to idle.
  void deactivate() {
    if (state != PillPhase.idle) {
      state = PillPhase.idle;
    }
  }

  /// Toggle between idle and active.
  void toggle() {
    state = state == PillPhase.active ? PillPhase.idle : PillPhase.active;
  }
}
