import 'package:diohub/common/bottom_sheet/url_actions.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/providers/settings/links_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LinkText extends StatelessWidget {
  const LinkText(this.link, {this.style, super.key, this.text});
  final TextStyle? style;
  final String? text;
  final String link;
  @override
  Widget build(final BuildContext context) {
    final links = ProviderScope.containerOf(context).read(linksProvider);
    final URLActions urlActions = URLActions(
      uri: Uri.parse(link),
      clipboard:
          ProviderScope.containerOf(context).read(clipboardServiceProvider),
      openGitHubInApp: links.openGitHubInApp,
      confirmBeforeBrowser: links.confirmBeforeBrowser,
    );
    return GestureDetector(
      onTap: () => urlActions.launchURL(context),
      onLongPress: () async {
        await urlActions.showMenu(context);
      },
      child: Text(
        text ?? link,
        style: const TextStyle(color: Colors.blue).merge(style),
      ),
    );
  }
}
