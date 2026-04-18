import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_release.freezed.dart';
part 'event_release.g.dart';

/// Lightweight summary of a Release as embedded in Events API payloads.
@freezed
abstract class EventRelease with _$EventRelease {
  const factory EventRelease({
    final String? tagName,
    final String? name,
    final String? body,
    final String? htmlUrl,
    final bool? prerelease,
    final bool? draft,
    final SimpleUser? author,
    final DateTime? createdAt,
    final DateTime? publishedAt,
  }) = _EventRelease;

  factory EventRelease.fromJson(final Map<String, dynamic> json) =>
      _$EventReleaseFromJson(json);
}
