import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _ActivePillDescriptorNotifier extends Notifier<DockPillDescriptor?> {
  @override
  DockPillDescriptor? build() => null;
}

/// Private — only written by [DockPillPhaseNotifier].
/// External code cannot bypass mutual exclusion by writing directly.
final _activePillDescriptorProvider =
    NotifierProvider<_ActivePillDescriptorNotifier, DockPillDescriptor?>(
  _ActivePillDescriptorNotifier.new,
);

/// Public read-only: the currently active pill descriptor (or null).
final activeDockPillDescriptorProvider = Provider<DockPillDescriptor?>(
  (ref) => ref.watch(_activePillDescriptorProvider),
);

/// Phase state for a single dock pill, keyed by descriptor (structural equality).
/// Auto-disposes when no widget watches this pill (e.g. after tab change).
final dockPillPhaseProvider = NotifierProvider.autoDispose
    .family<DockPillPhaseNotifier, PillPhase, DockPillDescriptor>(
  DockPillPhaseNotifier.new,
);

class DockPillPhaseNotifier extends Notifier<PillPhase> {
  DockPillPhaseNotifier(this.descriptor);
  final DockPillDescriptor descriptor;

  @override
  PillPhase build() => PillPhase.idle;

  void activate() {
    final prev = ref.read(_activePillDescriptorProvider);
    if (prev != null && prev != descriptor) {
      ref.read(dockPillPhaseProvider(prev).notifier).idle();
    }
    ref.read(_activePillDescriptorProvider.notifier).state = descriptor;
    state = PillPhase.active;
  }

  void idle() {
    if (ref.read(_activePillDescriptorProvider) == descriptor) {
      ref.read(_activePillDescriptorProvider.notifier).state = null;
    }
    state = PillPhase.idle;
  }

  void hint() => state = PillPhase.hint;
}
