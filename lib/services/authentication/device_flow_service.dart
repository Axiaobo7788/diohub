import 'package:dio/dio.dart';
import 'package:diohub_models/models/authentication/access_token_response.dart';
import 'package:diohub_models/models/authentication/device_code_response.dart';
import 'package:diohub_models/models/server_config.dart';

typedef DeviceFlowPost =
    Future<Map<String, dynamic>> Function(
      Uri endpoint,
      Map<String, String> form,
    );

/// HTTP client for the OAuth 2.0 device authorization grant.
///
/// The flow is intentionally independent of Flutter platform plugins so the
/// same implementation runs on Android and desktop targets.
class DeviceFlowService {
  DeviceFlowService({final DeviceFlowPost? post}) : _postOverride = post;

  final DeviceFlowPost? _postOverride;

  Future<DeviceCodeResponse> requestDeviceCode({
    required final OAuthConfig config,
    required final List<String> scopes,
  }) async {
    _validateClientId(config);
    final Map<String, dynamic> json = await _post(
      Uri.parse(config.deviceCodeEndpoint),
      <String, String>{'client_id': config.clientId, 'scope': scopes.join(' ')},
    );
    _throwIfOAuthError(json);
    return DeviceCodeResponse.fromJson(json);
  }

  Future<AccessTokenResponse> pollAccessToken({
    required final OAuthConfig config,
    required final String deviceCode,
  }) async {
    _validateClientId(config);
    if (deviceCode.trim().isEmpty) {
      throw const FormatException('Device code is empty.');
    }
    final Map<String, dynamic> json =
        await _post(Uri.parse(config.tokenEndpoint), <String, String>{
          'client_id': config.clientId,
          'device_code': deviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        });
    return AccessTokenResponse.fromJson(json);
  }

  Future<Map<String, dynamic>> _post(
    final Uri endpoint,
    final Map<String, String> form,
  ) async {
    final DeviceFlowPost? override = _postOverride;
    if (override != null) {
      return override(endpoint, form);
    }

    final Dio dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    final Response<Map<String, dynamic>> response = await dio
        .postUri<Map<String, dynamic>>(
          endpoint,
          data: form,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            headers: const <String, String>{
              'Accept': 'application/json',
              'User-Agent': 'com.felix.diohub',
            },
          ),
        );
    final Map<String, dynamic>? data = response.data;
    if (data == null) {
      throw const FormatException('GitHub returned an empty OAuth response.');
    }
    return data;
  }

  static void _validateClientId(final OAuthConfig config) {
    if (config.clientId.trim().isEmpty) {
      throw const FormatException(
        'GitHub Device Flow is not configured: GITHUB_CLIENT_ID is empty.',
      );
    }
  }

  static void _throwIfOAuthError(final Map<String, dynamic> json) {
    final String? error = json['error'] as String?;
    if (error == null) {
      return;
    }
    final String? description = json['error_description'] as String?;
    throw StateError(description ?? error);
  }
}
