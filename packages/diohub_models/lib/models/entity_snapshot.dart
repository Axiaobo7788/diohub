import 'package:freezed_annotation/freezed_annotation.dart';

part 'entity_snapshot.freezed.dart';
part 'entity_snapshot.g.dart';

/// Lightweight filterable metadata snapshot captured at bookmark/history/download time.
///
/// Stored as flat columns in Drift for SQL-level filtering, sorting, and indexing.
/// Nullable fields: not all entity types have all fields (e.g. stars is repos only).
@freezed
abstract class EntitySnapshot with _$EntitySnapshot {
  const factory EntitySnapshot({
    String? title,
    String? state,
    String? stateReason,
    String? authorLogin,
    String? authorAvatarUrl,
    List<SnapshotLabel>? labels,
    String? language,
    String? languageColor,
    int? stars,
    bool? isDraft,
    bool? isPrivate,
    bool? isFork,
    bool? isArchived,
    String? reviewDecision,
    String? milestone,
    int? commentCount,
    DateTime? updatedAt,
  }) = _EntitySnapshot;

  factory EntitySnapshot.fromJson(Map<String, dynamic> json) =>
      _$EntitySnapshotFromJson(json);
}

@freezed
abstract class SnapshotLabel with _$SnapshotLabel {
  const factory SnapshotLabel({
    required String name,
    required String color,
  }) = _SnapshotLabel;

  factory SnapshotLabel.fromJson(Map<String, dynamic> json) =>
      _$SnapshotLabelFromJson(json);
}
