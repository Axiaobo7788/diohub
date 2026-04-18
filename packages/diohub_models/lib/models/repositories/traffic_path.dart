import 'package:freezed_annotation/freezed_annotation.dart';

part 'traffic_path.freezed.dart';
part 'traffic_path.g.dart';

/// One entry from GitHub REST GET /repos/{owner}/{repo}/traffic/popular/paths.
@freezed
abstract class TrafficPath with _$TrafficPath {
  const factory TrafficPath({
    required final String path,
    final String? title,
    @Default(0) final int count,
    @Default(0) final int uniques,
  }) = _TrafficPath;

  factory TrafficPath.fromJson(final Map<String, dynamic> json) =>
      _$TrafficPathFromJson(json);
}
