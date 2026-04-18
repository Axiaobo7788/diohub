import 'package:freezed_annotation/freezed_annotation.dart';

part 'notifications_model.freezed.dart';
part 'notifications_model.g.dart';

@freezed
abstract class Thread with _$Thread {
  const factory Thread({
    required final String id,
    required final ThreadSubject subject,
    required final String reason,
    required final MinimalRepository repository,
    @Default(false) final bool unread,
    final DateTime? updatedAt,
    final DateTime? lastReadAt,
    final String? url,
  }) = _Thread;

  factory Thread.fromJson(final Map<String, dynamic> json) =>
      _$ThreadFromJson(json);
}

@freezed
abstract class ThreadSubject with _$ThreadSubject {
  const factory ThreadSubject({
    required final String title,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    final NotificationSubjectType? type,
    final String? url,
    final String? latestCommentUrl,
  }) = _ThreadSubject;

  factory ThreadSubject.fromJson(final Map<String, dynamic> json) =>
      _$ThreadSubjectFromJson(json);
}

/// Minimal repository as returned in notification threads.
@freezed
abstract class MinimalRepository with _$MinimalRepository {
  const factory MinimalRepository({
    required final String fullName,
    final MinimalOwner? owner,
  }) = _MinimalRepository;

  factory MinimalRepository.fromJson(final Map<String, dynamic> json) =>
      _$MinimalRepositoryFromJson(json);
}

@freezed
abstract class MinimalOwner with _$MinimalOwner {
  const factory MinimalOwner({
    required final String login,
    final String? avatarUrl,
  }) = _MinimalOwner;

  factory MinimalOwner.fromJson(final Map<String, dynamic> json) =>
      _$MinimalOwnerFromJson(json);
}

enum NotificationSubjectType {
  @JsonValue('Issue')
  issue,
  @JsonValue('PullRequest')
  pullRequest,
  @JsonValue('Release')
  release,
  @JsonValue('Discussion')
  discussion,
  @JsonValue('Commit')
  commit,
  @JsonValue('CheckSuite')
  checkSuite,
}

typedef NotificationModel = Thread;
