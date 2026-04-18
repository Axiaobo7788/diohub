import 'package:freezed_annotation/freezed_annotation.dart';

part 'branch_rename_result.freezed.dart';
part 'branch_rename_result.g.dart';

/// REST response for branch rename.
@freezed
abstract class BranchRenameResult with _$BranchRenameResult {
  const factory BranchRenameResult({
    required String name,
    @JsonKey(name: 'protected') @Default(false) bool isProtected,
  }) = _BranchRenameResult;

  factory BranchRenameResult.fromJson(final Map<String, dynamic> json) =>
      _$BranchRenameResultFromJson(json);
}
