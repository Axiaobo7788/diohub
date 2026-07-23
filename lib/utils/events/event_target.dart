import 'package:diohub_models/models/events/events_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_target.freezed.dart';

/// Identifies the target of an event for compounding purposes.
@freezed
abstract class EventTarget with _$EventTarget {
  const EventTarget._();

  const factory EventTarget(String repositoryKey, int? number) = _EventTarget;

  static EventTarget from(EventsModel e) {
    final int? number = e.payload.issue?.number ??
        e.payload.pullRequest?.number ??
        e.payload.number;
    final int? repositoryId = e.repo.id;
    final String? repositoryName = e.repo.name?.trim().toLowerCase();
    final String repositoryKey;
    if (repositoryId != null) {
      repositoryKey = 'id:$repositoryId';
    } else if (repositoryName != null && repositoryName.isNotEmpty) {
      repositoryKey = 'name:$repositoryName';
    } else {
      // Keep redacted repository events distinct. A shared sentinel would
      // incorrectly compound unrelated events into the same repository.
      repositoryKey = 'event:${e.id}';
    }
    return EventTarget(repositoryKey, number);
  }
}
