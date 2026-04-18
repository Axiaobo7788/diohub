import 'package:freezed_annotation/freezed_annotation.dart';

part 'access_token_response.freezed.dart';
part 'access_token_response.g.dart';

/// OAuth device flow: POST /oauth/access_token response.
@freezed
abstract class AccessTokenResponse with _$AccessTokenResponse {
  const factory AccessTokenResponse({
    @JsonKey(name: 'access_token') String? accessToken,
    @JsonKey(name: 'token_type') String? tokenType,
    String? scope,
    String? error,
    @JsonKey(name: 'error_description') String? errorDescription,
    int? interval,
    @JsonKey(name: 'refresh_token') String? refreshToken,
    @JsonKey(name: 'expires_in') int? expiresIn,
    @JsonKey(name: 'refresh_token_expires_in') int? refreshTokenExpiresIn,
  }) = _AccessTokenResponse;

  factory AccessTokenResponse.fromJson(final Map<String, dynamic> json) =>
      _$AccessTokenResponseFromJson(json);
}
