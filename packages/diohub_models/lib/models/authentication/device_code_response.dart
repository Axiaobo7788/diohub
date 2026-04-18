import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_code_response.freezed.dart';
part 'device_code_response.g.dart';

/// OAuth device flow: POST /device/code response.
@freezed
abstract class DeviceCodeResponse with _$DeviceCodeResponse {
  const factory DeviceCodeResponse({
    @JsonKey(name: 'device_code') required String deviceCode,
    @JsonKey(name: 'user_code') required String userCode,
    @JsonKey(name: 'verification_uri') required String verificationUri,
    @JsonKey(name: 'expires_in') required int expiresIn,
    @Default(5) int interval,
  }) = _DeviceCodeResponse;

  factory DeviceCodeResponse.fromJson(final Map<String, dynamic> json) =>
      _$DeviceCodeResponseFromJson(json);
}
