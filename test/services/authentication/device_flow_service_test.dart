import 'package:diohub/services/authentication/device_flow_service.dart';
import 'package:diohub_models/models/authentication/access_token_response.dart';
import 'package:diohub_models/models/authentication/device_code_response.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const OAuthConfig config = OAuthConfig(
    clientId: 'public-client-id',
    clientSecret: '',
    tokenEndpoint: 'https://github.example/login/oauth/access_token',
    authorizationEndpoint: 'https://github.example/login/oauth/authorize',
    deviceCodeEndpoint: 'https://github.example/login/device/code',
  );

  group('DeviceFlowService', () {
    test('requests a device code without sending a client secret', () async {
      late Uri receivedEndpoint;
      late Map<String, String> receivedForm;
      final DeviceFlowService service = DeviceFlowService(
        post: (final Uri endpoint, final Map<String, String> form) async {
          receivedEndpoint = endpoint;
          receivedForm = form;
          return <String, dynamic>{
            'device_code': 'device-code',
            'user_code': 'ABCD-EFGH',
            'verification_uri': 'https://github.example/login/device',
            'expires_in': 900,
            'interval': 5,
          };
        },
      );

      final DeviceCodeResponse response = await service.requestDeviceCode(
        config: config,
        scopes: const <String>['repo', 'user'],
      );

      expect(receivedEndpoint, Uri.parse(config.deviceCodeEndpoint));
      expect(receivedForm, <String, String>{
        'client_id': config.clientId,
        'scope': 'repo user',
      });
      expect(receivedForm, isNot(contains('client_secret')));
      expect(response.deviceCode, 'device-code');
      expect(response.userCode, 'ABCD-EFGH');
    });

    test('polls the token endpoint with the device grant type', () async {
      late Uri receivedEndpoint;
      late Map<String, String> receivedForm;
      final DeviceFlowService service = DeviceFlowService(
        post: (final Uri endpoint, final Map<String, String> form) async {
          receivedEndpoint = endpoint;
          receivedForm = form;
          return <String, dynamic>{
            'error': 'authorization_pending',
            'interval': 5,
          };
        },
      );

      final AccessTokenResponse response = await service.pollAccessToken(
        config: config,
        deviceCode: 'device-code',
      );

      expect(receivedEndpoint, Uri.parse(config.tokenEndpoint));
      expect(receivedForm, <String, String>{
        'client_id': config.clientId,
        'device_code': 'device-code',
        'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
      });
      expect(receivedForm, isNot(contains('client_secret')));
      expect(response.error, 'authorization_pending');
    });

    test('surfaces an OAuth error from device code creation', () async {
      final DeviceFlowService service = DeviceFlowService(
        post: (final Uri endpoint, final Map<String, String> form) async =>
            <String, dynamic>{
              'error': 'device_flow_disabled',
              'error_description': 'Device Flow is not enabled.',
            },
      );

      await expectLater(
        service.requestDeviceCode(config: config, scopes: const <String>[]),
        throwsA(
          isA<StateError>().having(
            (final StateError error) => error.message,
            'message',
            'Device Flow is not enabled.',
          ),
        ),
      );
    });

    test('rejects missing client and device codes before HTTP', () async {
      var called = false;
      final DeviceFlowService service = DeviceFlowService(
        post: (final Uri endpoint, final Map<String, String> form) async {
          called = true;
          return <String, dynamic>{};
        },
      );
      final OAuthConfig missingClient = config.copyWith(clientId: '  ');

      await expectLater(
        service.requestDeviceCode(
          config: missingClient,
          scopes: const <String>[],
        ),
        throwsFormatException,
      );
      await expectLater(
        service.pollAccessToken(config: config, deviceCode: '  '),
        throwsFormatException,
      );
      expect(called, isFalse);
    });
  });
}
