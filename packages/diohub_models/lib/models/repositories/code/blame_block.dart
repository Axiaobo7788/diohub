import 'package:freezed_annotation/freezed_annotation.dart';

part 'blame_block.freezed.dart';
part 'blame_block.g.dart';

/// Domain model for a blame range. Isolates UI from GQL blame types.
@freezed
abstract class BlameBlock with _$BlameBlock {
  const factory BlameBlock({
    required int age,
    required int startingLine,
    required int endingLine,
    required BlameCommitSummary commit,
  }) = _BlameBlock;

  factory BlameBlock.fromJson(Map<String, dynamic> json) =>
      _$BlameBlockFromJson(json);
}

@freezed
abstract class BlameCommitSummary with _$BlameCommitSummary {
  const factory BlameCommitSummary({
    required String oid,
    required String abbreviatedOid,
    required String message,
    required DateTime authoredDate,
    String? authorName,
    String? authorAvatarUrl,
    String? authorLogin,
    String? parentOid,
    int? additions,
    int? deletions,
    bool? isVerified,
    String? statusCheckState,
    int? associatedPRNumber,
  }) = _BlameCommitSummary;

  factory BlameCommitSummary.fromJson(Map<String, dynamic> json) =>
      _$BlameCommitSummaryFromJson(json);
}
