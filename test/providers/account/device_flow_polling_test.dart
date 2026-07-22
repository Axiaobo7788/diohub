import 'package:diohub/providers/account/auth_provider.dart';
import 'package:diohub_models/models/authentication/access_token_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextDeviceFlowPollInterval', () {
    test('adds the GitHub-required five seconds for slow_down', () {
      const AccessTokenResponse response = AccessTokenResponse(
        error: 'slow_down',
      );

      expect(
        nextDeviceFlowPollInterval(const Duration(seconds: 5), response),
        const Duration(seconds: 10),
      );
    });

    test('honors a longer interval returned by the server', () {
      const AccessTokenResponse response = AccessTokenResponse(
        error: 'slow_down',
        interval: 20,
      );

      expect(
        nextDeviceFlowPollInterval(const Duration(seconds: 5), response),
        const Duration(seconds: 20),
      );
    });

    test('does not let a shorter server interval cancel the backoff', () {
      const AccessTokenResponse response = AccessTokenResponse(
        error: 'slow_down',
        interval: 1,
      );

      expect(
        nextDeviceFlowPollInterval(const Duration(seconds: 10), response),
        const Duration(seconds: 15),
      );
    });
  });
}
