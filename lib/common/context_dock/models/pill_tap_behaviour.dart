/// How a dock pill responds to tap (R8: polymorphic dispatch).
///
/// [DockPillWidget] switches on this only; no `is`/`as` on pill types.
sealed class PillTapBehaviour {
  const PillTapBehaviour();
}

/// Opens a popup (e.g. sort/filter options). Uses [DockPill.buildActions] or [DockPill.buildPopupContent].
final class PopupPill extends PillTapBehaviour {
  const PopupPill();
}

/// Fires [BasicDockPill.onTapAction] and stays idle. No phase change.
final class FireAndForget extends PillTapBehaviour {
  const FireAndForget();
}

/// Enters [ActivePhase], shows overlay/companions. Default for branch, filter, compose, etc.
final class ActivatePill extends PillTapBehaviour {
  const ActivatePill();
}
