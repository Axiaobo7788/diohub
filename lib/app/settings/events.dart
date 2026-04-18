import 'package:diohub/app/settings/settings_descriptor.dart';

/// Events feed settings: combine related actions (compound grouping),
/// and whether to use timeline layout (rail + icons) or plain cards.
class EventsSettings {
  const EventsSettings({
    this.compoundActions = true,
    this.useTimelineView = true,
  });

  factory EventsSettings.fromJson(final Map<String, dynamic> json) =>
      EventsSettings(
        compoundActions: json['compoundActions'] as bool? ?? true,
        useTimelineView: json['useTimelineView'] as bool? ?? true,
      );

  final bool compoundActions;
  final bool useTimelineView;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'compoundActions': compoundActions,
        'useTimelineView': useTimelineView,
      };

  EventsSettings copyWith({
    final bool? compoundActions,
    final bool? useTimelineView,
  }) =>
      EventsSettings(
        compoundActions: compoundActions ?? this.compoundActions,
        useTimelineView: useTimelineView ?? this.useTimelineView,
      );
}

Map<String, dynamic> _eventsToJson(final EventsSettings v) => v.toJson();

const SettingsDescriptor<EventsSettings> eventsDescriptor =
    SettingsDescriptor<EventsSettings>(
  key: 'app_events',
  defaultValue: EventsSettings(),
  fromJson: EventsSettings.fromJson,
  toJson: _eventsToJson,
);
