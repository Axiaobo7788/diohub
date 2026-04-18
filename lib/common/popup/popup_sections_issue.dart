import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/nav_center/models/entity_capability.dart';
import 'package:diohub/common/nav_center/models/entity_capability_renderers.dart';
import 'package:diohub/common/popup/entity_popup_menu.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot_factories.dart';
import 'package:diohub/providers/server_config_provider.dart';

extension IssueInfoPopup on IssueInfo {
  List<PopupMenuSection> popupSections(
    final BuildContext context,
    final WidgetRef ref, {
    final List<EntityCapability>? capabilities,
  }) =>
      buildIssuePopupSections(
        context,
        this,
        ref,
        this.toRef,
        capabilities: capabilities,
      );
}

/// Builds popup menu sections for an issue (entity overlay).
/// When [capabilities] is provided, uses [buildPopupFromCapabilities].
/// Otherwise returns a minimal popup (caller should pass capabilities from [issueCapabilities]).
List<PopupMenuSection> buildIssuePopupSections(
  final BuildContext context,
  final IssueInfo data,
  final WidgetRef ref,
  final IssueRef issueRef, {
  final List<EntityCapability>? capabilities,
}) {
  if (capabilities != null) {
    return buildPopupFromCapabilities(capabilities);
  }
  final String urlStr = ref.webUrlFor(issueRef).toString();
  final ClipboardService clipboard = ref.read(clipboardServiceProvider);
  return buildPopupFromCapabilities(
    <EntityCapability>[
      Utility(
        url: urlStr,
        copyUrl: () => clipboard.copy(urlStr),
        share: () => Share.share(urlStr),
      ),
    ],
  );
}
