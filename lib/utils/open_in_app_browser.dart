import 'package:diohub_models/models/server_config.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Future<void> openInAppBrowser(
  final Uri link, {
  final ServerConfig? server,
}) async {
  Uri uri = link;
  final ServerConfig effectiveServer = server ?? ServerConfig.gitHubDotCom;
  // ignore: prefer_async_await
  await ChromeSafariBrowser.isAvailable().then(
    (final bool value) {
      if (!<String>['http', 'https'].contains(uri.scheme)) {
        uri = _handleGithubPaths(uri, effectiveServer);
      }
      if (value) {
        ChromeSafariBrowser().open(
          url: WebUri.uri(uri),
        );
      } else {
        InAppBrowser.openWithSystemBrowser(
          url: WebUri.uri(uri),
        );
      }
    },
  );
}

Uri _handleGithubPaths(final Uri uri, final ServerConfig server) =>
    server.webUrl(uri.path);
