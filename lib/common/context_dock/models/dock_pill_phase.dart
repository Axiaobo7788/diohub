/// Visual phase of a dock pill.
sealed class DockPillPhase {
  const DockPillPhase();
}

/// Circular glass icon. Default state.
final class IdlePhase extends DockPillPhase {
  const IdlePhase();
}

/// Accented pill with metadata preview next to icon.
/// No data stored — the pill's buildContent reads state
/// from providers via a ConsumerWidget to determine what to show.
final class HintPhase extends DockPillPhase {
  const HintPhase();
}

/// Expanded with interactive content. Others hide. Companions appear.
///
/// [companions] are [DockPill] instances (cast when using).
/// New descriptor-based overlay uses [DockPillDescriptor.companions] instead.
final class ActivePhase extends DockPillPhase {
  const ActivePhase({this.companions = const []});

  /// Companion pills shown alongside this pill when active.
  final List<Object> companions;
}
