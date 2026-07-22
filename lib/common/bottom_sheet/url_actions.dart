import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/adapters/github_link_parser.dart';
import 'package:diohub/common/bottom_sheet/confirm_action_sheet.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/const/app_info.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/popup/show_popup_menu.dart';
import 'package:diohub/utils/open_in_app_browser.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub_models/models/unrecognized_destination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:share_plus/share_plus.dart';

class URLActions {
  URLActions({
    required this.uri,
    required this.clipboard,
    this.shareDescription,
    this.showOpenAction = true,
    this.openGitHubInApp = true,
    this.confirmBeforeBrowser = true,
  });
  final ClipboardService clipboard;
  final bool showOpenAction;
  final String? shareDescription;
  final Uri uri;

  /// When true, "Open in App" is offered for GitHub deep links.
  final bool openGitHubInApp;

  /// When true, show a confirmation dialog before opening a URL in the browser.
  final bool confirmBeforeBrowser;

  bool get _isDeepLink {
    final Navigable? parsed = GitHubLinkParser.parse(uri);
    return parsed != null && parsed is! UnrecognizedDestination;
  }

  List<ActionButtonData> actions(final BuildContext context) =>
      <ActionButtonData>[
        MinorActionButton(
          label: 'Copy',
          icon: Icons.copy,
          onTap: () async {
            await clipboard.copy(uri.toString());
          },
        ),
        MinorActionButton(
          label: 'Share',
          icon: Icons.adaptive.share,
          onTap: () async {
            String shareText;
            if (shareDescription != null) {
              shareText = '$shareDescription\n$uri';
            } else {
              shareText = uri.toString();
            }
            await Share.share(shareText);
          },
        ),
        if (_isDeepLink && showOpenAction && openGitHubInApp)
          MinorActionButton(
            label: 'Open in App',
            icon: Icons.open_in_new, // Required but overridden by leading
            leading: const AppLogoWidget(size: 25),
            onTap: () => openInApp(context),
          ),
        MinorActionButton(
          label: _getOpenText,
          icon: _getOpenIcon,
          onTap: () => launchURLInBrowser(context),
        ),
      ];

  IconData get _getOpenIcon => switch (uri.scheme) {
    'mailto' => MdiIcons.email,
    _ => MdiIcons.openInNew,
  };
  String get _getOpenText => switch (uri.scheme) {
    'mailto' => 'Mail',
    _ => 'Open${_isDeepLink ? ' in Browser' : ''}',
  };

  Future<void> openInApp(final BuildContext context) async {
    if (!_isDeepLink) {
      throw Exception('Not a deep link');
    }
    await deepLinkNavigate(uri, context);
  }

  Future<void> launchURL(final BuildContext context) {
    if (_isDeepLink && openGitHubInApp) {
      return openInApp(context);
    }
    return launchURLInBrowser(context);
  }

  Future<void> launchURLInBrowser(final BuildContext context) async {
    if (confirmBeforeBrowser) {
      final bool? confirmed = await showConfirmAction(
        context,
        title: 'Open in browser?',
        explanation: uri.toString(),
        confirmLabel: 'Open',
        isDestructive: false,
      );
      if (confirmed != true) return;
    }
    await openInAppBrowser(uri);
  }

  Future<void> showMenu(final BuildContext context) async {
    await showPopupMenu(
      context,
      actions: actions(context),
      title: uri.toString(),
      anchorRect: context._getRect,
      actionLayout: PopupActionLayout.iconStrip,
    );
  }
}

extension _RectExtension on BuildContext {
  /// Given a [BuildContext], return the [Rect] of the corresponding
  /// [RenderBox]'s paintBounds in global coordinates.
  Rect get _getRect {
    final RenderBox? renderBox = findRenderObject() as RenderBox?;
    if (renderBox == null) {
      // Fallback to screen center
      final Size size = MediaQuery.of(this).size;
      return Rect.fromLTWH(size.width / 2, size.height / 2, 0, 0);
    }

    return Rect.fromPoints(
      renderBox.localToGlobal(renderBox.paintBounds.topLeft),
      renderBox.localToGlobal(renderBox.paintBounds.bottomRight),
    );
  }
}
