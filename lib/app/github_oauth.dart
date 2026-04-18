import 'package:diohub/app/env_config.dart';
import 'package:diohub_models/models/server_config.dart';

/// GitHub.com OAuth app credentials.
final OAuthConfig gitHubDotComOAuth = OAuthConfig(
  clientId: EnvConfig.gitHubClientId,
  clientSecret: EnvConfig.gitHubClientSecret,
  tokenEndpoint: 'https://github.com/login/oauth/access_token',
  authorizationEndpoint: 'https://github.com/login/oauth/authorize',
  deviceCodeEndpoint: 'https://github.com/login/device/code',
);

/// GitHub.com server config with OAuth credentials injected.
final ServerConfig gitHubDotComWithOAuth = ServerConfig(
  id: 'github.com',
  displayName: 'GitHub',
  webBaseUrl: 'https://github.com',
  restBaseUrl: 'https://api.github.com',
  graphqlUrl: 'https://api.github.com/graphql',
  rawContentBaseUrl: 'https://raw.githubusercontent.com',
  uploadBaseUrl: 'https://uploads.github.com',
  supportedAuthMethods: const <AuthMethod>[
    AuthMethod.oauth,
    AuthMethod.deviceCode,
    AuthMethod.pat,
  ],
  oauthConfig: gitHubDotComOAuth,
);
