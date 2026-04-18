/// Where an action should be rendered (popup, settings tab, or adaptive).
enum ActionSurface {
  /// Always in the entity popup menu.
  popup,

  /// Always in the settings tab (requires permissions).
  settings,

  /// In settings tab on full screens, in popup on cards (no settings tab).
  adaptive,
}
