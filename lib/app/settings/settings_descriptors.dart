/// Barrel file for all settings descriptors.
///
/// Import this file in provider files instead of individual settings files.
library;

export 'accessibility.dart' show accessibilityDescriptor, AccessibilitySettings;
export 'card_display.dart' show cardDisplayDescriptor, CardDisplaySettings;
export 'code_browser_settings.dart'
    show codeBrowserSettingsDescriptor, CodeBrowserSettings;
export 'diff_settings.dart' show diffSettingsDescriptor, DiffSettings;
export 'error_tracking.dart'
    show errorTrackingDescriptor, ErrorTrackingSettings;
export 'events.dart' show eventsDescriptor, EventsSettings;
export 'glass_pill.dart' show glassPillDescriptor, GlassPillSettings;
export 'links.dart' show linksDescriptor, LinksSettings;
export 'repository.dart' show repositoryDescriptor, RepositorySettings;
