import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_review.freezed.dart';
part 'event_review.g.dart';

/// Review states returned by the Events API for PullRequestReviewEvent.
enum ReviewState {
  @JsonValue('approved')
  approved,
  @JsonValue('changes_requested')
  changesRequested,
  @JsonValue('commented')
  commented,
  @JsonValue('dismissed')
  dismissed,
}

/// Lightweight summary of a PR review as embedded in Events API payloads.
@freezed
abstract class EventReview with _$EventReview {
  const factory EventReview({
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    final ReviewState? state,
    final String? body,
    final String? htmlUrl,
    final SimpleUser? user,
  }) = _EventReview;

  factory EventReview.fromJson(final Map<String, dynamic> json) =>
      _$EventReviewFromJson(json);
}
