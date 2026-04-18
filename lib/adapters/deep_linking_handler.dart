import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:diohub/adapters/github_link_parser.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/bottom_sheet/url_actions.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub_models/models/unrecognized_destination.dart';
import 'package:diohub/providers/router_provider.dart';
import 'package:diohub/providers/settings/links_provider.dart';
import 'package:diohub/utils/open_in_app_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Get the initial deep link that launched the app (if any).
Future<String?> initUniLink() async {
  final String? initialLink = await AppLinks().getInitialLinkString();
  return initialLink;
}

/// Get the initial shared media from iOS Share Extension (if any).
/// Sets [pendingDeepLinkProvider] on [container] when a URL is found.
Future<void> getInitialSharedMedia(ProviderContainer container) async {
  final List<SharedMediaFile> sharedMediaList =
      await ReceiveSharingIntent.instance.getInitialMedia();
  if (sharedMediaList.isNotEmpty) {
    for (final SharedMediaFile media in sharedMediaList) {
      if (media.type == SharedMediaType.url ||
          media.type == SharedMediaType.text) {
        final String url = media.path;
        if (url.isNotEmpty) {
          container.read(pendingDeepLinkProvider.notifier).state =
              Uri.parse(url);
          break; // Only handle first URL
        }
      }
    }
  }
}

/// Navigate to a deep link using the typed [Navigable] system.
///
/// Parses the URI into a [Navigable] and navigates to it,
/// or opens it in a browser if it's unrecognized.
/// [context] is used for navigation; pass from the widget tree.
Future<void> deepLinkNavigate(
    final Uri link, final BuildContext context) async {
  // Theme sharing links: not yet implemented; open in browser instead of dead UI.
  if (_themeLinkPattern.hasMatch(link.toString())) {
    await openInAppBrowser(link);
    return;
  }

  final Navigable? parsed = GitHubLinkParser.parse(link);

  if (parsed == null || parsed is UnrecognizedDestination) {
    await openInAppBrowser(link);
    return;
  }

  await parsed.navigateWithStack(context);
}

/// Check if a URL is a navigable GitHub deep link.
///
/// Returns true if the URL can be parsed and navigated to within the app.
bool isDeepLink(final String link) {
  try {
    final Navigable? parsed = GitHubLinkParser.parse(Uri.parse(link));
    return parsed != null && parsed is! UnrecognizedDestination;
  } catch (e, st) {
    AppLogger.warning(
      'Deep link parse failed',
      error: e,
      stackTrace: st,
      tag: 'DeepLinking',
    );
    return false;
  }
}

RegExp get _themeLinkPattern =>
    RegExp('((http(s)?)(:(//)))?(theme.felix.diohub)');

/// Handler for URL actions (copy, share, open in app/browser).
class AppLinkHandler {
  AppLinkHandler({required this.uri});

  AppLinkHandler.fromString({
    required final String uri,
  }) : uri = Uri.parse(uri);

  final Uri uri;

  URLActions urlActions(
    final BuildContext context, {
    final String? shareDescription,
    final bool showOpenAction = true,
  }) {
    final links = ProviderScope.containerOf(context).read(linksProvider);
    return URLActions(
      uri: uri,
      clipboard:
          ProviderScope.containerOf(context).read(clipboardServiceProvider),
      shareDescription: shareDescription,
      showOpenAction: showOpenAction,
      openGitHubInApp: links.openGitHubInApp,
      confirmBeforeBrowser: links.confirmBeforeBrowser,
    );
  }

  Future<void> openInBrowser(final BuildContext context) async =>
      urlActions(context).launchURLInBrowser(context);
}
