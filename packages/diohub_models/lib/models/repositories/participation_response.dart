import 'package:freezed_annotation/freezed_annotation.dart';

part 'participation_response.freezed.dart';
part 'participation_response.g.dart';

/// Response of GitHub REST GET /repos/{owner}/{repo}/stats/participation.
/// Weekly commit counts: [owner] = repo owner only, [all] = all contributors (52 weeks).
@freezed
abstract class ParticipationResponse with _$ParticipationResponse {
  const factory ParticipationResponse({
    @Default(<int>[]) final List<int> all,
    @Default(<int>[]) final List<int> owner,
  }) = _ParticipationResponse;

  factory ParticipationResponse.fromJson(final Map<String, dynamic> json) =>
      _$ParticipationResponseFromJson(json);
}
