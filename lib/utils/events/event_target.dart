import 'package:diohub_models/models/events/events_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_target.freezed.dart';

/// Identifies the target of an event for compounding purposes.
@freezed
abstract class EventTarget with _$EventTarget {
  const EventTarget._();

  const factory EventTarget(int repoId, int? number) = _EventTarget;

  static EventTarget from(EventsModel e) {
    final int? number = e.payload.issue?.number ??
        e.payload.pullRequest?.number ??
        e.payload.number;
    return EventTarget(e.repo.id, number);
  }
}
