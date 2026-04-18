import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_discussion.freezed.dart';
part 'event_discussion.g.dart';

/// Lightweight summary of a Discussion as embedded in Events API payloads.
@freezed
abstract class EventDiscussion with _$EventDiscussion {
  const factory EventDiscussion({
    final int? number,
    final String? title,
    final String? body,
    final String? htmlUrl,
    final EventDiscussionCategory? category,
    final SimpleUser? user,
  }) = _EventDiscussion;

  factory EventDiscussion.fromJson(final Map<String, dynamic> json) =>
      _$EventDiscussionFromJson(json);
}

/// Discussion category with name and optional emoji.
@freezed
abstract class EventDiscussionCategory with _$EventDiscussionCategory {
  const factory EventDiscussionCategory({
    final String? name,
    final String? emoji,
  }) = _EventDiscussionCategory;

  factory EventDiscussionCategory.fromJson(final Map<String, dynamic> json) =>
      _$EventDiscussionCategoryFromJson(json);
}
