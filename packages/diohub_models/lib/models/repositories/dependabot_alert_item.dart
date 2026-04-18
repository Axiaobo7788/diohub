import 'package:freezed_annotation/freezed_annotation.dart';

part 'dependabot_alert_item.freezed.dart';
part 'dependabot_alert_item.g.dart';

/// One Dependabot alert from REST GET /orgs/.../dependabot/alerts.
@freezed
abstract class DependabotAlertItem with _$DependabotAlertItem {
  const factory DependabotAlertItem({
    required int number,
    required String state,
    @JsonKey(name: 'security_advisory')
    required DependabotAdvisory securityAdvisory,
    DependabotDependency? dependency,
    @JsonKey(name: 'html_url') String? htmlUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'dismissed_at') DateTime? dismissedAt,
    @JsonKey(name: 'fixed_at') DateTime? fixedAt,
  }) = _DependabotAlertItem;

  factory DependabotAlertItem.fromJson(Map<String, dynamic> json) =>
      _$DependabotAlertItemFromJson(json);
}

@freezed
abstract class DependabotAdvisory with _$DependabotAdvisory {
  const factory DependabotAdvisory({
    required String summary,
    required String severity,
  }) = _DependabotAdvisory;

  factory DependabotAdvisory.fromJson(Map<String, dynamic> json) =>
      _$DependabotAdvisoryFromJson(json);
}

@freezed
abstract class DependabotDependency with _$DependabotDependency {
  const factory DependabotDependency({
    @JsonKey(name: 'package') DependabotPackage? pkg,
  }) = _DependabotDependency;

  factory DependabotDependency.fromJson(Map<String, dynamic> json) =>
      _$DependabotDependencyFromJson(json);
}

@freezed
abstract class DependabotPackage with _$DependabotPackage {
  const factory DependabotPackage({required String name}) = _DependabotPackage;

  factory DependabotPackage.fromJson(Map<String, dynamic> json) =>
      _$DependabotPackageFromJson(json);
}
