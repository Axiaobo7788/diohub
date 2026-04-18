import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/nav_center/models/entity_capability.dart';
import 'package:diohub/common/nav_center/models/entity_capability_renderers.dart';
import 'package:diohub/common/popup/entity_popup_menu.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot_factories.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/repository/widgets/clone_url_sheet.dart';

extension RepoInfoPopup on RepoInfo {
  List<PopupMenuSection> popupSections(
    final BuildContext context,
    final WidgetRef ref,
  ) =>
      buildRepoPopupSections(context, this, ref, this.toRef);
}

/// Builds popup menu sections for a repository (entity overlay).
List<PopupMenuSection> buildRepoPopupSections(
  final BuildContext context,
  final RepoInfo repo,
  final WidgetRef ref,
  final RepoRef repoRef,
) {
  final String urlStr = ref.webUrlFor(repoRef).toString();
  final ClipboardService clipboard = ref.read(clipboardServiceProvider);
  final String httpsUrl = urlStr.endsWith('.git') ? urlStr : '$urlStr.git';

  final caps = <EntityCapability>[
    RepoUtility(
      onCompare: () => context.router.push(CompareViewRoute(repoRef: repoRef)),
      onClone: () {
        AppSheet.simple<void>(
          context,
          header: AppSheetHeader.text('Clone'),
          bodyBuilder: (BuildContext ctx, StateSetter setState) =>
              CloneUrlSheet(httpsUrl: httpsUrl, sshUrl: repo.sshUrl),
        );
      },
      url: urlStr,
      copyUrl: () => clipboard.copy(urlStr),
      share: () => Share.share(urlStr),
    ),
  ];
  return buildPopupFromCapabilities(caps);
}
