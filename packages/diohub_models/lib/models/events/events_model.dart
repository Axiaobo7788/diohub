import 'package:diohub_models/models/events/event_discussion.dart';
import 'package:diohub_models/models/events/event_release.dart';
import 'package:diohub_models/models/events/event_review.dart';
import 'package:diohub_models/models/events/event_summaries.dart';
import 'package:diohub_models/models/events/gollum_page.dart';
import 'package:diohub_models/models/issues/issue_model.dart';
import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'events_model.freezed.dart';
part 'events_model.g.dart';

@freezed
abstract class Event with _$Event {
  const factory Event({
    required final String id,
    required final Actor actor,
    required final EventRepo repo,
    required final EventPayload payload,
    required final DateTime createdAt,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    final EventsType? type,
    @JsonKey(name: 'public') @Default(true) final bool isPublic,
    final EventOrg? org,
  }) = _Event;

  factory Event.fromJson(final Map<String, dynamic> json) =>
      _$EventFromJson(json);
}

@freezed
abstract class EventOrg with _$EventOrg {
  const factory EventOrg({
    required final int id,
    required final String login,
    final String? avatarUrl,
  }) = _EventOrg;

  factory EventOrg.fromJson(final Map<String, dynamic> json) =>
      _$EventOrgFromJson(json);
}

@freezed
abstract class Actor with _$Actor {
  const factory Actor({
    required final int id,
    required final String login,
    final String? avatarUrl,
  }) = _Actor;

  factory Actor.fromJson(final Map<String, dynamic> json) =>
      _$ActorFromJson(json);
}

@freezed
abstract class EventRepo with _$EventRepo {
  const factory EventRepo({
    required final int id,
    required final String name,
    final String? url,
  }) = _EventRepo;

  factory EventRepo.fromJson(final Map<String, dynamic> json) =>
      _$EventRepoFromJson(json);
}

/// Flat union of all event-type payload fields. GitHub's Events API returns
/// different shapes depending on event type; all fields are nullable.
///
/// Uses lightweight summary types (EventIssueSummary, EventPrSummary, etc.)
/// instead of the full shared models (Issue, PullRequest, etc.) because
/// GitHub trimmed embedded objects in October 2025, removing fields like
/// `title` that the shared models declare as `required`.
@freezed
abstract class EventPayload with _$EventPayload {
  const factory EventPayload({
    // Common
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    final PayloadAction? action,

    // IssuesEvent / IssueCommentEvent
    final EventIssueSummary? issue,
    final int? number,

    // IssueCommentEvent / CommitCommentEvent
    final EventCommentSummary? comment,

    // PullRequestEvent / PullRequestReviewEvent / PullRequestReviewCommentEvent
    final EventPrSummary? pullRequest,

    // PullRequestReviewEvent
    final EventReview? review,

    // PushEvent
    final String? ref,
    final String? head,
    final String? before,

    // CreateEvent / DeleteEvent
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    final RefType? refType,
    final String? fullRef,
    final String? masterBranch,
    final String? description,
    final String? pusherType,

    // ForkEvent
    final EventRepoSummary? forkee,

    // MemberEvent
    final SimpleUser? member,

    // ReleaseEvent
    final EventRelease? release,

    // DiscussionEvent
    final EventDiscussion? discussion,

    // GollumEvent
    final List<GollumPage>? pages,

    // Label from IssuesEvent/PullRequestEvent with action=labeled/unlabeled
    @JsonKey(name: 'label') final Label? eventLabel,

    // Full labels array from IssuesEvent/PullRequestEvent
    @JsonKey(name: 'labels') final List<Label>? eventLabels,

    // Assignee from IssuesEvent/PullRequestEvent with action=assigned/unassigned
    @JsonKey(name: 'assignee') final SimpleUser? eventAssignee,

    // Full assignees array from IssuesEvent/PullRequestEvent
    @JsonKey(name: 'assignees') final List<SimpleUser>? eventAssignees,
  }) = _EventPayload;

  factory EventPayload.fromJson(final Map<String, dynamic> json) =>
      _$EventPayloadFromJson(json);
}

enum PayloadAction {
  @JsonValue('opened')
  opened,
  @JsonValue('closed')
  closed,
  @JsonValue('reopened')
  reopened,
  @JsonValue('merged')
  merged,
  @JsonValue('labeled')
  labeled,
  @JsonValue('unlabeled')
  unlabeled,
  @JsonValue('assigned')
  assigned,
  @JsonValue('unassigned')
  unassigned,
  @JsonValue('created')
  created,
  @JsonValue('edited')
  edited,
  @JsonValue('deleted')
  deleted,
  @JsonValue('ready_for_review')
  readyForReview,
  @JsonValue('converted_to_draft')
  convertedToDraft,
  @JsonValue('added')
  added,
  @JsonValue('started')
  started,
  @JsonValue('published')
  published,
  @JsonValue('forked')
  forked,
  @JsonValue('dismissed')
  dismissed,
  @JsonValue('submitted')
  submitted,
}

enum RefType {
  @JsonValue('repository')
  repository,
  @JsonValue('branch')
  branch,
  @JsonValue('tag')
  tag,
}

/// Reverse lookup map for RefType display names.
final EnumValues<RefType> refTypeValues = EnumValues<RefType>(<String, RefType>{
  'repository': RefType.repository,
  'branch': RefType.branch,
  'tag': RefType.tag,
});

enum EventsType {
  @JsonValue('CommitCommentEvent')
  CommitCommentEvent,
  @JsonValue('CreateEvent')
  CreateEvent,
  @JsonValue('DeleteEvent')
  DeleteEvent,
  @JsonValue('DiscussionEvent')
  DiscussionEvent,
  @JsonValue('ForkEvent')
  ForkEvent,
  @JsonValue('GollumEvent')
  GollumEvent,
  @JsonValue('IssueCommentEvent')
  IssueCommentEvent,
  @JsonValue('IssuesEvent')
  IssuesEvent,
  @JsonValue('MemberEvent')
  MemberEvent,
  @JsonValue('PublicEvent')
  PublicEvent,
  @JsonValue('PullRequestEvent')
  PullRequestEvent,
  @JsonValue('PullRequestReviewEvent')
  PullRequestReviewEvent,
  @JsonValue('PullRequestReviewCommentEvent')
  PullRequestReviewCommentEvent,
  @JsonValue('PushEvent')
  PushEvent,
  @JsonValue('ReleaseEvent')
  ReleaseEvent,
  @JsonValue('SponsorshipEvent')
  SponsorshipEvent,
  @JsonValue('WatchEvent')
  WatchEvent,
}

/// Reverse lookup map for EventsType.
final EnumValues<EventsType> eventsValues =
    EnumValues<EventsType>(<String, EventsType>{
  for (final EventsType v in EventsType.values) v.name: v,
});

class EnumValues<T> {
  EnumValues(this.map);
  final Map<String, T> map;
  Map<T, String>? _reverseMap;

  Map<T, String>? get reverse {
    _reverseMap ??= map.map((final String k, final v) => MapEntry(v, k));
    return _reverseMap;
  }
}

typedef EventsModel = Event;
