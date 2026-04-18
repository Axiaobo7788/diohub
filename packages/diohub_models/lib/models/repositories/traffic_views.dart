import 'package:freezed_annotation/freezed_annotation.dart';

part 'traffic_views.freezed.dart';
part 'traffic_views.g.dart';

/// Response of GitHub REST GET /repos/{owner}/{repo}/traffic/views.
@freezed
abstract class TrafficViewsResponse with _$TrafficViewsResponse {
  const factory TrafficViewsResponse({
    @Default(0) final int count,
    @Default(0) final int uniques,
    @Default([]) final List<TrafficViewEntry> views,
  }) = _TrafficViewsResponse;

  factory TrafficViewsResponse.fromJson(final Map<String, dynamic> json) =>
      _$TrafficViewsResponseFromJson(json);
}

@freezed
abstract class TrafficViewEntry with _$TrafficViewEntry {
  const factory TrafficViewEntry({
    final String? timestamp,
    @Default(0) final int count,
    @Default(0) final int uniques,
  }) = _TrafficViewEntry;

  factory TrafficViewEntry.fromJson(final Map<String, dynamic> json) =>
      _$TrafficViewEntryFromJson(json);
}
