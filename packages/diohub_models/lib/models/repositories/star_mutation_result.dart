import 'package:freezed_annotation/freezed_annotation.dart';

part 'star_mutation_result.freezed.dart';
part 'star_mutation_result.g.dart';

/// Response from star/unstar GraphQL mutations.
/// Contains the updated state for optimistic UI updates.
@freezed
abstract class StarMutationResult with _$StarMutationResult {
  const factory StarMutationResult({
    required bool viewerHasStarred,
    required int stargazerCount,
  }) = _StarMutationResult;

  factory StarMutationResult.fromJson(Map<String, dynamic> json) =>
      _$StarMutationResultFromJson(json);
}
