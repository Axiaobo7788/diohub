import 'package:freezed_annotation/freezed_annotation.dart';

part 'traffic_referrer.freezed.dart';
part 'traffic_referrer.g.dart';

/// One entry from GitHub REST GET /repos/{owner}/{repo}/traffic/popular/referrers.
@freezed
abstract class TrafficReferrer with _$TrafficReferrer {
  const factory TrafficReferrer({
    required final String referrer,
    @Default(0) final int count,
    @Default(0) final int uniques,
  }) = _TrafficReferrer;

  factory TrafficReferrer.fromJson(final Map<String, dynamic> json) =>
      _$TrafficReferrerFromJson(json);
}
