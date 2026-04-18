import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/nav_center/models/entity_action_defs.dart';
import 'package:diohub/common/popup/entity_popup_menu.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/router.gr.dart';

/// Builds popup menu sections for a commit (entity overlay / kebab).
List<PopupMenuSection> buildCommitPopupSections(
  Uri url,
  String oid,
  ClipboardService clipboard, {
  required BuildContext context,
  required WidgetRef ref,
  required RepoRef repoRef,
  String? parentOid,
}) {
  final String urlStr = url.toString();
  final List<ActionButtonData> primary = <ActionButtonData>[
    copyShaAction(
      sha: oid,
      copySha: () => clipboard.copy(oid),
    ),
    MinorActionButton(
      label: 'Copy URL',
      icon: Icons.copy_rounded,
      onTap: () => clipboard.copy(urlStr),
    ),
    MinorActionButton(
      label: 'Share',
      icon: Icons.share_rounded,
      onTap: () => Share.share(urlStr),
    ),
  ];

  if (parentOid != null && parentOid.isNotEmpty) {
    primary.add(
      MinorActionButton(
        icon: Octicons.git_compare,
        label: 'Compare with parent',
        onTapWithDismiss: (dismiss) {
          context.router.push(CompareViewRoute(
            repoRef: repoRef,
            base: parentOid,
            head: oid,
          ));
          dismiss();
        },
      ),
    );
    primary.add(
      MinorActionButton(
        label: 'View parent commit',
        icon: Icons.history,
        onTap: () {
          context.router.push(
            CommitInfoRoute(
              commitRef: CommitRef(repo: repoRef, oid: parentOid),
            ),
          );
        },
      ),
    );
  }

  return <PopupMenuSection>[
    PopupMenuSection(
      style: PopupSectionStyle.primary,
      actions: primary,
    ),
  ];
}
