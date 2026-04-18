import 'package:freezed_annotation/freezed_annotation.dart';

part 'secret_scanning_alert.freezed.dart';
part 'secret_scanning_alert.g.dart';

/// One secret scanning alert from REST GET /repos/.../secret-scanning/alerts.
@freezed
abstract class SecretScanningAlert with _$SecretScanningAlert {
  const factory SecretScanningAlert({
    required int number,
    required String state,
    @JsonKey(name: 'secret_type') required String secretType,
    @JsonKey(name: 'secret_type_display_name')
    required String secretTypeDisplayName,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'resolved_at') DateTime? resolvedAt,
    @JsonKey(name: 'resolved_by') Map<String, dynamic>? resolvedBy,
    String? resolution,
    @JsonKey(name: 'resolution_comment') String? resolutionComment,
    @JsonKey(name: 'html_url') String? htmlUrl,
    String? secret,
    @JsonKey(name: 'locations_url') String? locationsUrl,
  }) = _SecretScanningAlert;

  factory SecretScanningAlert.fromJson(Map<String, dynamic> json) =>
      _$SecretScanningAlertFromJson(json);
}
