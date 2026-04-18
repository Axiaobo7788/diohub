import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/bottom_sheet/url_actions.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/models/home_destination.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub_models/models/unrecognized_destination.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub/providers/settings/links_provider.dart';
import 'package:diohub/routes/entity_ref_routes.dart';
import 'package:diohub/utils/open_in_app_browser.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation actions for [Navigable] types. Lives in routes/ because it
/// depends on providers and routing — not appropriate for models/.
extension NavigableActions on Navigable {
  Future<void> navigate(BuildContext context, WidgetRef ref) async {
    if (!hasNativeRoute) {
      final server = ref.read(activeServerConfigProvider);
      await openInAppBrowser(webUrlFor(server));
      return;
    }
    await context.router.push(_toRoute(this));
  }

  Future<void> navigateWithStack(BuildContext context) async {
    final List<PageRouteInfo> stack = _toRouteStack(this);
    for (final PageRouteInfo route in stack) {
      await context.router.push(route);
    }
  }

  URLActions urlActions(BuildContext context, WidgetRef ref,
      {String? shareDescription}) {
    final links = ref.read(linksProvider);
    final Uri uri = webUrlFor(ref.read(activeServerConfigProvider));
    return URLActions(
      uri: uri,
      clipboard: ref.read(clipboardServiceProvider),
      shareDescription: shareDescription,
      openGitHubInApp: links.openGitHubInApp,
      confirmBeforeBrowser: links.confirmBeforeBrowser,
    );
  }

  Future<void> showUrlActions(
    BuildContext context,
    WidgetRef ref, {
    String? shareDescription,
  }) async {
    await urlActions(context, ref, shareDescription: shareDescription)
        .showMenu(context);
  }
}

PageRouteInfo _toRoute(Navigable n) {
  return switch (n) {
    EntityRef r => r.toRoute(),
    HomeDestination r => r.toRoute(),
    UnrecognizedDestination r => r.toRoute(),
    _ => throw StateError('Unknown Navigable: ${n.runtimeType}'),
  };
}

List<PageRouteInfo> _toRouteStack(Navigable n) {
  return switch (n) {
    EntityRef r => r.toRouteStack(),
    HomeDestination r => r.toRouteStack(),
    UnrecognizedDestination r => r.toRouteStack(),
    _ => throw StateError('Unknown Navigable: ${n.runtimeType}'),
  };
}
