import 'package:freezed_annotation/freezed_annotation.dart';

part 'traffic_clones.freezed.dart';
part 'traffic_clones.g.dart';

/// Response of GitHub REST GET /repos/{owner}/{repo}/traffic/clones.
@freezed
abstract class TrafficClonesResponse with _$TrafficClonesResponse {
  const factory TrafficClonesResponse({
    @Default(0) final int count,
    @Default(0) final int uniques,
    @Default([]) final List<TrafficCloneEntry> clones,
  }) = _TrafficClonesResponse;

  factory TrafficClonesResponse.fromJson(final Map<String, dynamic> json) =>
      _$TrafficClonesResponseFromJson(json);
}

@freezed
abstract class TrafficCloneEntry with _$TrafficCloneEntry {
  const factory TrafficCloneEntry({
    final String? timestamp,
    @Default(0) final int count,
    @Default(0) final int uniques,
  }) = _TrafficCloneEntry;

  factory TrafficCloneEntry.fromJson(final Map<String, dynamic> json) =>
      _$TrafficCloneEntryFromJson(json);
}
