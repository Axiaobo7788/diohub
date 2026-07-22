import 'package:diohub_models/models/server_config.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a URL with the system browser.
///
/// Kept as a compatibility entry point for existing callers that previously
/// used an embedded browser implementation.
Future<void> openInAppBrowser(
  final Uri link, {
  final ServerConfig? server,
}) async {
  Uri uri = link;
  final ServerConfig effectiveServer = server ?? ServerConfig.gitHubDotCom;
  if (!<String>['http', 'https'].contains(uri.scheme)) {
    uri = _handleGithubPaths(uri, effectiveServer);
  }
  final bool launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
  if (!launched) {
    throw StateError('Could not open $uri in the system browser.');
  }
}

Uri _handleGithubPaths(final Uri uri, final ServerConfig server) =>
    server.webUrl(uri.path);
