/// Compile-time environment configuration.
///
/// Values are injected via --dart-define-from-file at build time.
/// Returns empty strings when not provided (features gracefully no-op).
abstract class EnvConfig {
  // GitHub OAuth. The client ID is public and may be overridden by downstream
  // builds. Device Flow never requires the client secret.
  static const gitHubClientId = String.fromEnvironment(
    'GITHUB_CLIENT_ID',
    defaultValue: '8bc7ca5b6ba3b0392bf4',
  );
  static const gitHubClientSecret = String.fromEnvironment(
    'GITHUB_CLIENT_SECRET',
  );

  // Sentry
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  // Slack MCP -- only service requiring pre-registered OAuth credentials
  static const slackClientId = String.fromEnvironment('SLACK_CLIENT_ID');
  static const slackClientSecret = String.fromEnvironment(
    'SLACK_CLIENT_SECRET',
  );

  // Release identification for changelog version comparison
  static const releaseTag = String.fromEnvironment('RELEASE_TAG');
}
