import 'package:diohub/app/github_oauth.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerConfig', () {
    test('gitHubDotCom has correct URLs', () {
      expect(ServerConfig.gitHubDotCom.id, 'github.com');
      expect(ServerConfig.gitHubDotCom.webBaseUrl, 'https://github.com');
      expect(ServerConfig.gitHubDotCom.restBaseUrl, 'https://api.github.com');
      expect(
        ServerConfig.gitHubDotCom.graphqlUrl,
        'https://api.github.com/graphql',
      );
      expect(
        ServerConfig.gitHubDotCom.rawContentBaseUrl,
        'https://raw.githubusercontent.com',
      );
      expect(ServerConfig.gitHubDotCom.isDefault, isTrue);
      expect(ServerConfig.gitHubDotCom.host, 'github.com');
    });

    test('gitHubEnterprise produces correct URLs', () {
      final config = ServerConfig.gitHubEnterprise('https://ghes.company.com');
      expect(config.id, 'ghes.company.com');
      expect(config.webBaseUrl, 'https://ghes.company.com');
      expect(config.restBaseUrl, 'https://ghes.company.com/api/v3');
      expect(config.graphqlUrl, 'https://ghes.company.com/api/graphql');
      expect(config.rawContentBaseUrl, 'https://ghes.company.com/raw');
      expect(config.uploadBaseUrl, 'https://ghes.company.com/api/uploads');
      expect(config.isDefault, isFalse);
      expect(config.host, 'ghes.company.com');
    });

    test('gitHubEnterprise strips trailing slash from hostUrl', () {
      final config = ServerConfig.gitHubEnterprise('https://ghes.company.com/');
      expect(config.webBaseUrl, 'https://ghes.company.com');
      expect(config.restBaseUrl, 'https://ghes.company.com/api/v3');
    });

    test('round-trips through toJson/fromJson', () {
      final config = ServerConfig.gitHubDotCom;
      final json = config.toJson();
      final restored = ServerConfig.fromJson(json);
      expect(restored.id, config.id);
      expect(restored.webBaseUrl, config.webBaseUrl);
      expect(restored, equals(config));
    });

    test('two configs with same id are equal', () {
      final a = ServerConfig.gitHubEnterprise('https://h.example.com');
      final b = ServerConfig.gitHubEnterprise('https://h.example.com');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('webUrl builds correct URI', () {
      final uri = ServerConfig.gitHubDotCom.webUrl('/flutter/flutter');
      expect(uri.toString(), 'https://github.com/flutter/flutter');
    });

    test('rawUrl builds correct URI', () {
      final uri = ServerConfig.gitHubDotCom.rawUrl(
        'owner',
        'repo',
        'main',
        'lib/foo.dart',
      );
      expect(
        uri.toString(),
        'https://raw.githubusercontent.com/owner/repo/main/lib/foo.dart',
      );
    });

    test('wikiRawUrl builds correct URI', () {
      final uri = ServerConfig.gitHubDotCom.wikiRawUrl(
        'o',
        'r',
        'images/foo.png',
      );
      expect(
        uri.toString(),
        'https://raw.githubusercontent.com/wiki/o/r/images/foo.png',
      );
    });

    test('restUrl builds correct URI', () {
      final uri = ServerConfig.gitHubDotCom.restUrl('/repos/flutter/flutter');
      expect(uri.toString(), 'https://api.github.com/repos/flutter/flutter');
    });
  });

  group('OAuthConfig', () {
    test('gitHubDotCom has required endpoints', () {
      expect(gitHubDotComOAuth.clientId, isNotEmpty);
      expect(
        gitHubDotComOAuth.tokenEndpoint,
        'https://github.com/login/oauth/access_token',
      );
      expect(
        gitHubDotComOAuth.authorizationEndpoint,
        'https://github.com/login/oauth/authorize',
      );
      expect(
        gitHubDotComOAuth.deviceCodeEndpoint,
        'https://github.com/login/device/code',
      );
    });

    test('round-trips through toJson/fromJson', () {
      final oauth = gitHubDotComOAuth;
      final restored = OAuthConfig.fromJson(oauth.toJson());
      expect(restored.clientId, oauth.clientId);
      expect(restored.tokenEndpoint, oauth.tokenEndpoint);
    });
  });
}
